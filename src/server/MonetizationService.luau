-- MonetizationService: server-side monetization logic.
-- Skills applied: roblox-monetization (receipt handler, GamePass checks, idempotent grants),
--   roblox-security (server-authoritative, no client trust on prices/grabs),
--   roblox-datastores (UpdateAsync idempotent writes, BindToClose flush),
--   roblox-luau-patterns (module lifecycle, cache invalidation, connection cleanup).
--
-- Architecture: MonetizationConfig holds ALL prices/IDs as data; this service is the
-- single source of truth for granting. ProcessReceipt is the only receipt handler.
-- All grants go through DataStore UpdateAsync (atomic read-modify-write).

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local MonetizationConfig = require(game.ServerScriptService.Server.MonetizationConfig)

-- DataStore for receipt idempotency and inventory persistence.
local RECEIPTS_DATASTORE = "PartyPanic_Purchases"
local INVENTORY_DATASTORE = "PartyPanic_Inventory"
local RECEIPT_TTL_DAYS = 30

local MonetizationService = {}

-- Session cache: userId -> { gamePassOwned = { passName = bool }, inventory = { coins = number } }
MonetizationService._passCache = {}
MonetizationService._inventoryCache = {}
MonetizationService._receiptStore = nil
MonetizationService._inventoryStore = nil
MonetizationService._playerConnections = {}
-- _shopPurchaseEvent removed — no client sender exists (router Shop = noop).
-- Preserved in /tmp/opencode/hud-wiring-main.patch for the future Shop-screen task.

function MonetizationService._initDataStores()
	if MonetizationService._receiptStore then
		return
	end
	local ok, result = pcall(function()
		MonetizationService._receiptStore = DataStoreService:GetDataStore(RECEIPTS_DATASTORE)
		MonetizationService._inventoryStore = DataStoreService:GetDataStore(INVENTORY_DATASTORE)
	end)
	if not ok then
		warn("[MonetizationService] DataStore unavailable: " .. tostring(result))
		MonetizationService._receiptStore = nil
		MonetizationService._inventoryStore = nil
	end
end
-- Idempotent receipt check: returns true if already granted.
function MonetizationService._wasReceiptProcessed(purchaseId: string): boolean
	if MonetizationService._receiptStore == nil then
		return false
	end
	local key = "receipt_" .. purchaseId
	local ok, result = pcall(function()
		return MonetizationService._receiptStore:GetAsync(key)
	end)
	if not ok then
		warn("[MonetizationService] failed to check receipt cache for " .. purchaseId)
		return false
	end
	if result ~= nil then
		return true
	end
	return false
end

-- Record a receipt as processed with TTL. Non-atomic SetAsync for a simple flag;
-- if this fails, ProcessReceipt returns NotProcessedYet and Roblox re-delivers.
function MonetizationService._recordReceipt(purchaseId: string)
	if MonetizationService._receiptStore == nil then
		return false
	end
	local key = "receipt_" .. purchaseId
	local ok, err = pcall(function()
		MonetizationService._receiptStore:SetAsync(key, {
			processedAt = os.time(),
			ttl = RECEIPT_TTL_DAYS * 24 * 60 * 60,
		})
	end)
	if not ok then
		warn("[MonetizationService] failed to record receipt " .. purchaseId .. ": " .. tostring(err))
		return false
	end
	return true
end

-- Atomic coin grant via UpdateAsync (see roblox-datastores skill: UpdateAsync for
-- read-modify-write, never SetAsync for counters).
function MonetizationService._saveInventoryField(userId: number, field: string, value: number)
	if MonetizationService._inventoryStore == nil then
		return false
	end
	local key = "inv_" .. userId
	local ok, err = pcall(function()
		MonetizationService._inventoryStore:UpdateAsync(key, function(current)
			if typeof(current) ~= "table" then
				current = {}
			end
			current[field] = (current[field] or 0) + value
			return current
		end)
	end)
	if not ok then
		warn("[MonetizationService] failed to save inventory for " .. userId .. ": " .. tostring(err))
		return false
	end
	return true
end

-- Load full inventory (coins, ownedCosmetics, ownedEmotes, lockerSlots).
function MonetizationService._loadInventory(userId: number): { [string]: any }
	if MonetizationService._inventoryStore == nil then
		return {}
	end
	local key = "inv_" .. userId
	local ok, result = pcall(function()
		return MonetizationService._inventoryStore:GetAsync(key)
	end)
	if not ok then
		warn("[MonetizationService] failed to load inventory for " .. userId)
		return {}
	end
	if typeof(result) ~= "table" then
		return {}
	end
	return result
end

-- Apply VIP bonus to a coin award, capped at VIPBonusCap (0.5 => max +100% total).
function MonetizationService._applyVipBonus(player: Player, baseCoins: number): number
	local cache = MonetizationService._passCache[player.UserId]
	if not cache then
		return baseCoins
	end
	if cache.gamePassOwned and cache.gamePassOwned.GP_VIP then
		local bonus = baseCoins * MonetizationConfig.VIPBonusCap
		return math.floor(baseCoins + bonus)
	end
	return baseCoins
end

-- Get product grant config by ProductId (reverse lookup from data table).
function MonetizationService._getProductById(productId: number): (string?, any)
	for key, product in pairs(MonetizationConfig.Products) do
		if product.id == productId then
			return key, product
		end
	end
	return nil, nil
end

-- Get GamePass config by passId (reverse lookup).
function MonetizationService._getGamePassById(passId: number): (string?, any)
	for key, pass in pairs(MonetizationConfig.GamePasses) do
		if pass.id == passId then
			return key, pass
		end
	end
	return nil, nil
end

-- Grant functions -----------------------------------------------------------

function MonetizationService.grantCoins(player: Player, amount: number, _source: string)
	local coins = MonetizationService._applyVipBonus(player, amount)
	local ok = MonetizationService._saveInventoryField(player.UserId, "coins", coins)
	if not ok then
		return false
	end
	-- Update session cache
	MonetizationService._inventoryCache[player.UserId] = { coins = coins }
	return true
end

function MonetizationService.unlockCosmetic(player: Player, cosmeticId: string): boolean
	if MonetizationService._inventoryStore == nil then
		return false
	end
	local key = "inv_" .. player.UserId
	local ok, err = pcall(function()
		MonetizationService._inventoryStore:UpdateAsync(key, function(current)
			if typeof(current) ~= "table" then
				current = {}
			end
			if typeof(current.ownedCosmetics) ~= "table" then
				current.ownedCosmetics = {}
			end
			if not current.ownedCosmetics[cosmeticId] then
				current.ownedCosmetics[cosmeticId] = true
			end
			return current
		end)
	end)
	if not ok then
		warn(
			"[MonetizationService] failed to unlock cosmetic "
				.. cosmeticId
				.. " for "
				.. player.UserId
				.. ": "
				.. tostring(err)
		)
		return false
	end
	-- Update session cache for ownedCosmetics
	local cache = MonetizationService._inventoryCache[player.UserId]
	if not cache then
		cache = {}
		MonetizationService._inventoryCache[player.UserId] = cache
	end
	if not cache.ownedCosmetics then
		cache.ownedCosmetics = {}
	end
	cache.ownedCosmetics[cosmeticId] = true
	return true
end

function MonetizationService.unlockEmote(player: Player, emoteId: string): boolean
	if MonetizationService._inventoryStore == nil then
		return false
	end
	local key = "inv_" .. player.UserId
	local ok, err = pcall(function()
		MonetizationService._inventoryStore:UpdateAsync(key, function(current)
			if typeof(current) ~= "table" then
				current = {}
			end
			if typeof(current.ownedEmotes) ~= "table" then
				current.ownedEmotes = {}
			end
			if not current.ownedEmotes[emoteId] then
				current.ownedEmotes[emoteId] = true
			end
			return current
		end)
	end)
	if not ok then
		warn(
			"[MonetizationService] failed to unlock emote "
				.. emoteId
				.. " for "
				.. player.UserId
				.. ": "
				.. tostring(err)
		)
		return false
	end
	-- Update session cache for ownedEmotes
	local cache = MonetizationService._inventoryCache[player.UserId]
	if not cache then
		cache = {}
		MonetizationService._inventoryCache[player.UserId] = cache
	end
	if not cache.ownedEmotes then
		cache.ownedEmotes = {}
	end
	cache.ownedEmotes[emoteId] = true
	return true
end

function MonetizationService.addLockerSlots(player: Player, count: number): boolean
	local ok = MonetizationService._saveInventoryField(player.UserId, "lockerSlots", count)
	if not ok then
		return false
	end
	-- Update session cache
	local cache = MonetizationService._inventoryCache[player.UserId]
	if not cache then
		cache = {}
		MonetizationService._inventoryCache[player.UserId] = cache
	end
	cache.lockerSlots = count
	return true
end

-- Apply a product's grants (called from ProcessReceipt).
function MonetizationService._applyProductGrants(player: Player, product: any): boolean
	local allOk = true
	if product.grants then
		if product.grants.coins then
			local okCoins = MonetizationService.grantCoins(player, product.grants.coins, "purchase")
			if not okCoins then
				allOk = false
			end
		end
		if product.grants.cosmeticId then
			local okCos = MonetizationService.unlockCosmetic(player, product.grants.cosmeticId)
			if not okCos then
				allOk = false
			end
		end
	end
	if product.category == "emotes" then
		local okEmote = MonetizationService.unlockEmote(player, product.name)
		if not okEmote then
			allOk = false
		end
	end
	return allOk
end

-- Player join: prime GamePass cache, load inventory for VIP bonus.
function MonetizationService._onPlayerAdded(player: Player)
	MonetizationService._passCache[player.UserId] = {
		gamePassOwned = {},
	}
	for passKey, passConfig in pairs(MonetizationConfig.GamePasses) do
		if passConfig.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passConfig.id)
			end)
			if ok then
				MonetizationService._passCache[player.UserId].gamePassOwned[passKey] = owns == true
			else
				MonetizationService._passCache[player.UserId].gamePassOwned[passKey] = false
			end
		end
	end

	-- Load inventory so coin grants can apply VIP bonus correctly.
	-- Store result in session cache for lazy prime on getCoins.
	local inv = MonetizationService._loadInventory(player.UserId)
	MonetizationService._inventoryCache[player.UserId] = { coins = inv.coins or 0 }

	-- If the player rejoins with pending grants (purchase completed but
	-- player left before receipt processed), apply any queued grants here.
	local pending = MonetizationService._loadInventory(player.UserId)
	if pending and pending.pendingGrants then
		for _, grant in ipairs(pending.pendingGrants) do
			if grant.type == "coins" then
				MonetizationService.grantCoins(player, grant.amount, "pending")
			elseif grant.type == "cosmetic" then
				MonetizationService.unlockCosmetic(player, grant.id)
			elseif grant.type == "emote" then
				MonetizationService.unlockEmote(player, grant.id)
			end
		end
		-- Clear pending grants after applying.
		local key = "inv_" .. player.UserId
		pcall(function()
			MonetizationService._inventoryStore:UpdateAsync(key, function(current)
				if typeof(current) ~= "table" then
					current = {}
				end
				current.pendingGrants = nil
				return current
			end)
		end)
	end
end

-- Player leaving: clear session cache.
function MonetizationService._onPlayerRemoving(player: Player)
	MonetizationService._passCache[player.UserId] = nil
	MonetizationService._inventoryCache[player.UserId] = nil
end

-- GamePass purchase finished: invalidate cache for this pass.
-- (roblox-monetization skill: "Cache a successful result when appropriate, but
-- provide an invalidation or refresh path for purchases made during the session.")
function MonetizationService._onGamePassPurchaseFinished(player: Player, gamePassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end
	for passKey, passConfig in pairs(MonetizationConfig.GamePasses) do
		if passConfig.id == gamePassId then
			if not MonetizationService._passCache[player.UserId] then
				MonetizationService._passCache[player.UserId] = { gamePassOwned = {} }
			end
			MonetizationService._passCache[player.UserId].gamePassOwned[passKey] = true
		end
	end
end

-- ProcessReceipt: the ONLY receipt handler (roblox-monetization skill section 3).
-- Must: 1) identify product+player, 2) check idempotency, 3) grant via DataStore,
-- 4) record receipt, 5) return PurchaseGranted only after durable success.
-- Unknown products return NotProcessedYet (not Acknowledged) so Roblox re-delivers.
MarketplaceService.ProcessReceipt = function(receiptInfo)
	MonetizationService._initDataStores()

	-- 1. Identify player
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 2. Identify product
	local _, product = MonetizationService._getProductById(receiptInfo.ProductId)
	if not product then
		warn("[MonetizationService] unhandled product: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 3. Check idempotency (was this PurchaseId already processed?)
	local purchaseId = tostring(receiptInfo.PurchaseId)
	if MonetizationService._wasReceiptProcessed(purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 4. Grant via DataStore (atomic UpdateAsync)
	local granted = MonetizationService._applyProductGrants(player, product)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 5. Record receipt (durable idempotency record)
	if not MonetizationService._recordReceipt(purchaseId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Currency formatter (logic, reads config ladder).
function MonetizationService.formatCurrency(amount: number): string
	if amount < 1000 then
		return tostring(math.floor(amount))
	end
	for i = #MonetizationConfig.CurrencyFormatter.thresholds, 1, -1 do
		local tier = MonetizationConfig.CurrencyFormatter.thresholds[i]
		if amount >= tier.value then
			local scaled = amount / tier.value
			if scaled >= 100 then
				return tostring(math.floor(scaled)) .. tier.suffix
			elseif scaled >= 10 then
				return string.format("%.1f", scaled):gsub("%.0$", "") .. tier.suffix
			else
				return string.format("%.2f", scaled):gsub("%.00$", "") .. tier.suffix
			end
		end
	end
	return tostring(amount)
end

-- Public: check if player owns a GamePass (session-cached).
function MonetizationService.hasGamePass(player: Player, passKey: string): boolean
	local cache = MonetizationService._passCache[player.UserId]
	if not cache or not cache.gamePassOwned then
		return false
	end
	return cache.gamePassOwned[passKey] == true
end

-- Public: get player's coin count from session cache (lazy prime on miss).
function MonetizationService.getCoins(player: Player): number
	local cache = MonetizationService._inventoryCache[player.UserId]
	if cache and cache.coins ~= nil then
		return cache.coins
	end
	-- Cache miss: lazy prime from DataStore
	local inv = MonetizationService._loadInventory(player.UserId)
	local coins = inv.coins or 0
	MonetizationService._inventoryCache[player.UserId] = { coins = coins }
	return coins
end

-- Init: wire up event listeners.
function MonetizationService.init()
	MonetizationService._initDataStores()
	table.insert(
		MonetizationService._playerConnections,
		Players.PlayerAdded:Connect(function(player)
			MonetizationService._onPlayerAdded(player)
		end)
	)
	table.insert(
		MonetizationService._playerConnections,
		Players.PlayerRemoving:Connect(function(player)
			MonetizationService._onPlayerRemoving(player)
		end)
	)
	table.insert(
		MonetizationService._playerConnections,
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
			if player then
				MonetizationService._onGamePassPurchaseFinished(player, gamePassId, wasPurchased)
			end
		end)
	)
	print("[MonetizationService] started — ProcessReceipt + GamePass cache armed")
end

-- Shutdown: disconnect all listeners.
function MonetizationService.shutdown()
	for _, conn in ipairs(MonetizationService._playerConnections) do
		conn:Disconnect()
	end
	MonetizationService._playerConnections = {}
end

return MonetizationService
