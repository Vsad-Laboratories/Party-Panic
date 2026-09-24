-- HotPotato: pass-the-potato elimination round. A Parts-only "potato" sits in
-- the center. On touch, the touching player becomes the holder. A countdown
-- wave pressures the holder to pass the potato; the player still holding when
-- time runs out is eliminated. Timer shortens each wave. Last standing wins.
-- Conforms to RoundContract (src/shared/RoundContract).
-- play() is async — starts a Heartbeat loop, signals completion via onRoundComplete.

local RunService = game:GetService("RunService")

local RoundContract = require(game.ReplicatedStorage.Shared.RoundContract)

local config = require(script.config)
local potato = require(script.potato)

local HotPotato = {}

HotPotato._timer = 0
HotPotato._waveElapsed = 0
HotPotato._roundEnded = false
HotPotato._heartbeatConn = nil

function HotPotato.setup(context: RoundContract.RoundContext)
	potato.create()

	HotPotato._timer = config.initialTimer
	HotPotato._waveElapsed = 0
	HotPotato._roundEnded = false

	local placed = 0
	for i, player in ipairs(context.players) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				placed += 1
				local angle = (i / #context.players) * 2 * math.pi
				local offset = Vector3.new(
					math.cos(angle) * config.playerSpawnRadius,
					config.playerSpawnY,
					math.sin(angle) * config.playerSpawnRadius
				)
				hrp.CFrame = CFrame.new(offset)
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	print("[PartyPanic] HotPotato setup — placed " .. placed .. "/" .. #context.players .. " players")
end

function HotPotato.play(context: RoundContract.RoundContext)
	local roundDuration = (context.config and context.config.duration) or config.roundDuration
	local startingCount = #context.players
	local alive = {}

	for _, player in ipairs(context.players) do
		alive[player.UserId] = player
	end

	local function endRound(winner: number?)
		if HotPotato._roundEnded then
			return
		end
		HotPotato._roundEnded = true
		if HotPotato._heartbeatConn then
			HotPotato._heartbeatConn:Disconnect()
			HotPotato._heartbeatConn = nil
		end
		potato.destroy()
		context.onRoundComplete({
			winnerUserId = winner,
			scores = {},
		})
	end

	local function pruneGhosts()
		for userId, player in pairs(alive) do
			if player.Parent == nil or player.Character == nil then
				alive[userId] = nil
			end
		end
	end

	local function getAliveCount()
		local count = 0
		for _ in pairs(alive) do
			count += 1
		end
		return count
	end

	local function eliminateHolder()
		if potato.holderUserId == nil then
			return
		end
		local elapsedUserId = potato.holderUserId
		potato.pass()
		local eliminated = alive[elapsedUserId]
		if eliminated then
			alive[elapsedUserId] = nil
			print("[PartyPanic] HotPotato: " .. eliminated.Name .. " eliminated")
		end
		HotPotato._timer = math.max(config.minTimer, HotPotato._timer - config.timerDecrement)
		HotPotato._waveElapsed = 0
	end

	potato.onTouch(function(hit)
		if HotPotato._roundEnded then
			return
		end
		local char = hit.Parent
		if not char then
			return
		end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local player = game.Players:GetPlayerFromCharacter(char)
		if not player or alive[player.UserId] == nil then
			return
		end
		potato.setHolder(player)
	end)

	HotPotato._heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		HotPotato._waveElapsed += dt

		pruneGhosts()

		if HotPotato._waveElapsed >= HotPotato._timer then
			if startingCount > 1 and getAliveCount() <= 1 then
				for userId in pairs(alive) do
					endRound(userId)
					return
				end
			end
			eliminateHolder()

			if startingCount > 1 and getAliveCount() <= 1 then
				for userId in pairs(alive) do
					endRound(userId)
					return
				end
			end
		end

		if HotPotato._waveElapsed >= roundDuration then
			local bestUserId = nil
			local bestY = -math.huge
			for userId, player in pairs(alive) do
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if hrp and hrp.Position.Y > bestY then
					bestY = hrp.Position.Y
					bestUserId = userId
				end
			end
			endRound(bestUserId)
		end
	end)
end

function HotPotato.cleanup(context: RoundContract.RoundContext)
	HotPotato._roundEnded = true
	if HotPotato._heartbeatConn then
		HotPotato._heartbeatConn:Disconnect()
		HotPotato._heartbeatConn = nil
	end
	potato.destroy()
	HotPotato._timer = 0
	HotPotato._waveElapsed = 0
	print("[PartyPanic] HotPotato cleanup — " .. #context.players .. " players")
end

return HotPotato
