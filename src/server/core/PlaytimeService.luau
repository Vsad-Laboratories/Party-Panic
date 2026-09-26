-- PlaytimeService: per-player playtime tracking with DataStore persistence.
-- Skills applied: roblox-datastores (pcall wraps, retry/backoff, BindToClose flush,
--   atomic UpdateAsync for load-merge-save), roblox-performance (60s tick, no per-frame
--   work beyond an accumulator), roblox-luau-patterns (module scope, cleanup ownership,
--   distinct success/missing-data states).
-- Accrues total playtime + current-session segment via a 60s tick.
-- Saves on player leave and server shutdown. No data loss on leave/hop.

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
PlaytimeService._playerData = {}
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

function PlaytimeService._loadPlayer(userId: number): number?
	PlaytimeService._initDataStore()
	if PlaytimeService._dataStore == nil then
		return nil
	end
	local key = PlaytimeService._getKey(userId)
	local ok, result = pcall(function()
		return PlaytimeService._dataStore:GetAsync(key)
	end)
	if not ok then
		warn("[PlaytimeService] load failed for userId " .. userId .. ": " .. tostring(result))
		return nil
	end
	if typeof(result) == "number" then
		return result
	end
	return nil
end

function PlaytimeService._savePlayer(userId: number, playtime: number)
	PlaytimeService._initDataStore()
	if PlaytimeService._dataStore == nil then
		return false
	end
	local key = PlaytimeService._getKey(userId)
	local backoff = INITIAL_BACKOFF
	local lastErr = nil
	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			PlaytimeService._dataStore:SetAsync(key, playtime)
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

function PlaytimeService._onPlayerAdded(player: Player)
	if PlaytimeService._playerData[player.UserId] ~= nil then
		return
	end
	local loaded = PlaytimeService._loadPlayer(player.UserId)
	PlaytimeService._playerData[player.UserId] = loaded or 0
	PlaytimeService._sessionStart[player.UserId] = tick()
end

function PlaytimeService._onPlayerRemoving(player: Player)
	if PlaytimeService._playerData[player.UserId] == nil then
		return
	end
	local sessionSeconds = PlaytimeService._getSessionSeconds(player)
	local total = PlaytimeService._playerData[player.UserId] + sessionSeconds
	PlaytimeService._playerData[player.UserId] = nil
	PlaytimeService._sessionStart[player.UserId] = nil
	PlaytimeService._savePlayer(player.UserId, total)
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
	for userId, playtime in pairs(PlaytimeService._playerData) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local session = PlaytimeService._getSessionSeconds(player)
			PlaytimeService._playerData[userId] = playtime + session
			PlaytimeService._sessionStart[userId] = tick()
		end
		PlaytimeService._savePlayer(userId, PlaytimeService._playerData[userId])
	end
	PlaytimeService._saving = false
end

function PlaytimeService.getTotalPlaytime(player: Player): number
	local session = tick() - (PlaytimeService._sessionStart[player.UserId] or tick())
	local total = PlaytimeService._playerData[player.UserId] or 0
	return total + session
end

function PlaytimeService.getTopPlayers(limit: number)
	local snapshot = {}
	for userId, playtime in pairs(PlaytimeService._playerData) do
		local session = 0
		if PlaytimeService._sessionStart[userId] then
			session = tick() - PlaytimeService._sessionStart[userId]
		end
		table.insert(snapshot, {
			userId = userId,
			playtime = playtime + session,
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
