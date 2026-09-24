-- FloorFall: tile-vanish elimination round. A grid of Parts forms a floor
-- that vanishes over time. Players who fall below the Y threshold are eliminated.
-- Last standing wins. Conforms to RoundContract (src/shared/RoundContract).
-- play() is async — starts a Heartbeat loop, signals completion via onRoundComplete.

local RunService = game:GetService("RunService")

local RoundContract = require(game.ReplicatedStorage.Shared.RoundContract)

local config = require(script.config)
local floor = require(script.floor)
local players = require(script.players)

local FloorFall = {}

FloorFall._tiles = {}
FloorFall._elapsed = 0
FloorFall._nextWave = 0
FloorFall._pendingDrops = {}
FloorFall._roundEnded = false
FloorFall._heartbeatConn = nil

function FloorFall.setup(context: RoundContract.RoundContext)
	floor.build()
	FloorFall._tiles = floor.tiles
	FloorFall._elapsed = 0
	FloorFall._nextWave = config.dropInterval
	FloorFall._pendingDrops = {}
	FloorFall._roundEnded = false

	local placed = players.placeOnGrid(context.players, FloorFall._tiles)

	print("[PartyPanic] FloorFall setup — placed " .. placed .. "/" .. #context.players .. " players")
end

function FloorFall.play(context: RoundContract.RoundContext)
	local roundDuration = (context.config and context.config.duration) or 75
	local startingCount = #context.players
	local living = {}
	for _, player in ipairs(context.players) do
		living[player.UserId] = player
	end

	local function endRound(winner: number?)
		if FloorFall._roundEnded then
			return
		end
		FloorFall._roundEnded = true
		if FloorFall._heartbeatConn then
			FloorFall._heartbeatConn:Disconnect()
			FloorFall._heartbeatConn = nil
		end
		floor.cleanup()
		FloorFall._tiles = {}
		FloorFall._pendingDrops = {}
		FloorFall._roundEnded = false
		context.onRoundComplete({
			winnerUserId = winner,
			scores = {},
		})
	end

	local function dropWave()
		floor.dropWave()
	end

	FloorFall._heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		FloorFall._elapsed = floor.elapsed + dt
		floor.elapsed = FloorFall._elapsed
		FloorFall._pendingDrops = floor.pendingDrops

		-- Prune ghosts (disconnected or missing character) before any checks
		players.pruneGhosts(living)

		-- Timeout fallback (PRD §4: 60-90s cap)
		if FloorFall._elapsed >= roundDuration then
			local bestUserId = players.timeoutAward(living)
			endRound(bestUserId)
			return
		end

		-- Wave drops (solo-safe: only when >1 player alive)
		if players.getAliveCount(living) > 1 and FloorFall._elapsed >= FloorFall._nextWave then
			FloorFall._nextWave += config.dropInterval
			floor.nextWave = FloorFall._nextWave
			dropWave()
		end

		-- Process pending tile destructions
		floor.processPendingDrops()

		-- Eliminate fallen players
		players.checkEliminations(living)

		-- Last standing wins (solo-safe: skip for single-player, runs to timeout)
		if startingCount > 1 and players.getAliveCount(living) <= 1 then
			local winner = players.lastStanding(living)
			endRound(winner)
		end
	end)
	floor.heartbeatConn = FloorFall._heartbeatConn
end

function FloorFall.cleanup(context: RoundContract.RoundContext)
	if FloorFall._heartbeatConn then
		FloorFall._heartbeatConn:Disconnect()
		FloorFall._heartbeatConn = nil
	end
	floor.cleanup()
	FloorFall._tiles = {}
	FloorFall._pendingDrops = {}
	FloorFall._roundEnded = false
	print("[PartyPanic] FloorFall cleanup — " .. #context.players .. " players")
end

return FloorFall
