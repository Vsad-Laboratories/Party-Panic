--!strict
-- MonetizationConfig.luau — client-side monetization constants + the coin ladder formatter.
-- Owns:
--   * formatCoins (K/10k/1M..100T ladder) — used by the lobby coin counter and the
--     Shop buy button price text.
--   * Game Pass catalog (GP_EmotePack, GP_LockerSlots) including the Emote Pack's
--     animationAssetId (Animator:LoadAnimation source) and selectorAssetId (the emote
--     selector ModuleScript asset).
--   * ShopPurchase RemoteEvent name + locker slot math.
-- Robux transfers / ownership / grants live on the SERVER (roblox-monetization): the
-- client only caches server-replicated owned passes (see src/client/ui/Profile.luau).
-- Game Pass numeric IDs are pending the Operator (0 = not yet claimed => locked state,
-- which is an honest default, not mock data).

local GamePasses = {
	EmotePack = {
		-- TODO(ops): set the real Roblox gamePassId for the Emote Pack.
		gamePassId = 0,
		animationAssetId = 109991912171331,
		selectorAssetId = 8944416554,
	},
	LockerSlots = {
		-- TODO(ops): set the real Roblox gamePassId for the Locker Slots pass.
		gamePassId = 0,
	},
}

local ShopPurchaseEvent = "ShopPurchase"

local LOCKER_SLOTS_BASE = 5
local LOCKER_SLOTS_GP_BONUS = 10

local Tier = {
	{ exp = 3, suffix = "K" },
	{ exp = 6, suffix = "M" },
	{ exp = 9, suffix = "B" },
	{ exp = 12, suffix = "T" },
}

-- Trim a mantissa's trailing zero for mantissas < 10 (1 decimal), integer for >= 10.
local function formatMantissa(mantissa: number): string
	local rounded = math.floor(mantissa * 10 + 0.5) / 10
	if rounded >= 10 then
		-- 9.999K -> 10.0 -> head "10" (no decimal, not a bump)
		return tostring(math.floor(rounded + 0.5))
	end
	local text = string.format("%.1f", rounded)
	-- drop a trailing ".0" (1.0 -> "1"); keep 1.5 / 9.9
	text = string.gsub(text, "%.0$", "")
	return text
end

-- Compact coin ladder (Operator spec):
--   <1000 plain; 1000+ -> <mantissa><K|M|B|T> with 1 decimal below 10 else integer;
--   9999 -> "10K" (rounds up), 999999 -> "1M" (bump when rounding reaches 1000);
--   each of K/M/B spans 3 powers; T capped at 100T => >= 1e14 is "100T+".
local function formatCoins(value: number): string
	value = math.floor(value + 0.5)
	if value < 1000 then
		return tostring(value)
	end
	if value >= 1e14 then
		return "100T+"
	end
	for i, tier in ipairs(Tier) do
		local exp = tier.exp
		local base = 10 ^ exp
		local nextExp = Tier[i + 1] and Tier[i + 1].exp
		local upper = if nextExp then (10 ^ nextExp) else 1e14
		if value < upper then
			local mantissa = value / base
			if mantissa >= 10 then
				local rounded = math.floor(mantissa + 0.5)
				if rounded >= 1000 and nextExp then
					-- 999.5K -> rounds to 1000K -> bump to next letter tier (1M)
					base = 10 ^ nextExp
					return formatMantissa(value / base) .. Tier[i + 1].suffix
				end
				return tostring(rounded) .. tier.suffix
			end
			return formatMantissa(mantissa) .. tier.suffix
		end
	end
	return "100T+"
end

return {
	GamePasses = GamePasses,
	ShopPurchaseEvent = ShopPurchaseEvent,
	LOCKER_SLOTS_BASE = LOCKER_SLOTS_BASE,
	LOCKER_SLOTS_GP_BONUS = LOCKER_SLOTS_GP_BONUS,
	formatCoins = formatCoins,
}
