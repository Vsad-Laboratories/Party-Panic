-- PlaytimeService: per-player playtime tracking with DataStore persistence.
-- Skills applied: roblox-datastores (pcall wraps, retry/backoff, BindToClose flush,
--   UpdateAsync atomic read-merge-save), roblox-security (server-authoritative, no
--   client writes), roblox-luau-patterns (module scope, cleanup ownership,
--   distinct success/missing-data states), roblox-performance (60s tick, no
--   per-frame work beyond an accumulator), roblox-luau-core (module shape).
-- Accrues session playtime via a 60s tick; loaded base is read-only, session
-- delta is the only thing persisted (via UpdateAsync add).
-- Saves on player leave, periodic 60s tick, and server shutdown (BindToClose).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DATA_STORE_NAME = "PartyPanic_Playtime"
local PLAYTIME_KEY_PREFIX = "PlayerPlaytime_"
local TICK_INTERVAL = 60
local MAX_RETRIES = 3
local INITIAL_BACKOFF = 1

local PlaytimeService = {}

PlaytimeService._dataStore = nil
PlaytimeService._loadedBase = {}
PlaytimeService._sessionDelta = {}
PlaytimeService._sessionStart = {}
PlaytimeService._tickAccumulator = 0
PlaytimeService._heartbeatConn = nil
PlaytimeService._saving = false

function PlaytimeService._initDataStore()
	if PlaytimeService._dataStore then
		return
	end
	local ok, result = pcall(function()
		PlaytimeService._dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	if not ok then
		warn("[PlaytimeService] DataStore unavailable: " .. tostring(result))
		PlaytimeService._dataStore = nil
	end
end

function PlaytimeService._getKey(userId: number): string
	return PLAYTIME_KEY_PREFIX .. tostring(userId)
end

-- Returns (ok, value): ok=false on error (distinct from missing key).
-- ok=true + nil value = key not yet set (first-time player).
-- ok=true + number = persisted total playtime (loaded base).
function PlaytimeService._loadPlayer(userId: number): (boolean, number?)
	PlaytimeService._initDataStore()
	if PlaytimeService._dataStore == nil then
		return false, nil
	end
	local key = PlaytimeService._getKey(userId)
	local ok, result = pcall(function()
		return PlaytimeService._dataStore:GetAsync(key)
	end)
	if not ok then
		warn("[PlaytimeService] load failed for userId " .. userId .. ": " .. tostring(result))
		return false, nil
	end
	if typeof(result) == "number" then
		return true, result
	end
	return true, nil
end

-- Persists an INCREMENT to the stored value via UpdateAsync (atomic
-- read-merge-save). The increment is session accrual only — the loaded base
-- is never passed here, preventing double-count. Returns true on save success.
-- On failure, the caller retains _sessionDelta (retry does not drop accrual).
function PlaytimeService._savePlayer(userId: number, delta: number): boolean
	PlaytimeService._initDataStore()
	if PlaytimeService._dataStore == nil then
		return false
	end
	local key = PlaytimeService._getKey(userId)
	local backoff = INITIAL_BACKOFF
	local lastErr = nil
	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			PlaytimeService._dataStore:UpdateAsync(key, function(current)
				local stored = 0
				if typeof(current) == "number" then
					stored = current
				end
				return stored + delta
			end)
		end)
		if ok then
			return true
		end
		lastErr = err
		if attempt < MAX_RETRIES then
			task.wait(backoff)
			backoff = backoff * 2
		end
	end
	warn(
		"[PlaytimeService] save failed for userId "
			.. userId
			.. " after "
			.. MAX_RETRIES
			.. " attempts: "
			.. tostring(lastErr)
	)
	return false
end

function PlaytimeService._getSessionSeconds(player: Player): number
	return tick() - (PlaytimeService._sessionStart[player.UserId] or tick())
end

-- On join: load persisted base. On load ERROR (not missing key), do NOT arm
-- persistence — skip this session entirely (bounded loss of accrual, no data wipe).
-- _loadedBase holds the persisted total (read-only); _sessionDelta accumulates
-- this session's playtime (reset only after successful save).
function PlaytimeService._onPlayerAdded(player: Player)
	if PlaytimeService._sessionStart[player.UserId] ~= nil then
		return
	end
	local ok, loaded = PlaytimeService._loadPlayer(player.UserId)
	if not ok then
		warn("[PlaytimeService] player " .. player.Name .. " skipped (load error); persistence disarmed for session")
		return
	end
	PlaytimeService._loadedBase[player.UserId] = loaded or 0
	PlaytimeService._sessionDelta[player.UserId] = 0
	PlaytimeService._sessionStart[player.UserId] = tick()
end

function PlaytimeService._onPlayerRemoving(player: Player)
	if PlaytimeService._sessionStart[player.UserId] == nil then
		return
	end
	local sessionSeconds = PlaytimeService._getSessionSeconds(player)
	local delta = PlaytimeService._sessionDelta[player.UserId] + sessionSeconds
	PlaytimeService._loadedBase[player.UserId] = nil
	PlaytimeService._sessionDelta[player.UserId] = nil
	PlaytimeService._sessionStart[player.UserId] = nil
	PlaytimeService._savePlayer(player.UserId, delta)
end

function PlaytimeService._tick(dt: number)
	PlaytimeService._tickAccumulator += dt
	if PlaytimeService._tickAccumulator < TICK_INTERVAL then
		return
	end
	PlaytimeService._tickAccumulator -= TICK_INTERVAL
	PlaytimeService._saveAll()
end

function PlaytimeService._saveAll()
	if PlaytimeService._saving then
		return
	end
	PlaytimeService._saving = true
	for userId in pairs(PlaytimeService._sessionStart) do
		local session = PlaytimeService._getSessionSeconds({ UserId = userId })
		local delta = PlaytimeService._sessionDelta[userId] + session
		local saved = PlaytimeService._savePlayer(userId, delta)
		if saved then
			PlaytimeService._sessionDelta[userId] = 0
			PlaytimeService._sessionStart[userId] = tick()
		end
	end
	PlaytimeService._saving = false
end

-- Read surface for the future TOP Playtime leaderboard (asset 5352156968).
-- Operator-directive scope: total playtime + top-N readers required for the
-- lobby leaderboard prop (see task directive). Not speculative.
-- Total = loadedBase + sessionDelta + live session seconds.
function PlaytimeService.getTotalPlaytime(player: Player): number
	if PlaytimeService._sessionStart[player.UserId] == nil then
		return 0
	end
	local session = tick() - (PlaytimeService._sessionStart[player.UserId] or tick())
	return (PlaytimeService._loadedBase[player.UserId] or 0)
		+ (PlaytimeService._sessionDelta[player.UserId] or 0)
		+ session
end

function PlaytimeService.getTopPlayers(limit: number)
	local snapshot = {}
	for userId in pairs(PlaytimeService._sessionStart) do
		local session = tick() - (PlaytimeService._sessionStart[userId] or tick())
		local total = (PlaytimeService._loadedBase[userId] or 0)
			+ (PlaytimeService._sessionDelta[userId] or 0)
			+ session
		table.insert(snapshot, {
			userId = userId,
			playtime = total,
		})
	end
	table.sort(snapshot, function(a, b)
		return a.playtime > b.playtime
	end)
	local result = {}
	for i = 1, math.min(limit or 10, #snapshot) do
		result[i] = snapshot[i]
	end
	return result
end

function PlaytimeService.start()
	PlaytimeService._initDataStore()
	for _, player in ipairs(Players:GetPlayers()) do
		PlaytimeService._onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(function(player)
		PlaytimeService._onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlaytimeService._onPlayerRemoving(player)
	end)
	PlaytimeService._tickAccumulator = 0
	PlaytimeService._heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		PlaytimeService._tick(dt)
	end)
	print("[PlaytimeService] started — 60s tick accrual + save on leave")
end

function PlaytimeService.shutdown()
	if PlaytimeService._heartbeatConn then
		PlaytimeService._heartbeatConn:Disconnect()
		PlaytimeService._heartbeatConn = nil
	end
	PlaytimeService._saving = false
	for _, player in ipairs(Players:GetPlayers()) do
		PlaytimeService._onPlayerRemoving(player)
	end
end

return PlaytimeService
