-- HotPotato: pass-the-potato elimination round. A Parts-only "potato" sits in
-- the center. On touch, the touching player becomes the holder. A countdown
-- wave pressures the holder to pass the potato; the player still holding when
-- time runs out is eliminated. Timer shortens each wave. Last standing wins.
-- Conforms to RoundContract (src/shared/RoundContract).
-- play() is async — starts a Heartbeat loop, signals completion via onRoundComplete.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RoundContract = require(game.ReplicatedStorage.Shared.RoundContract)

local HotConfig = {
	roundDuration = 45,
	initialTimer = 6,
	timerDecrement = 0.8,
	minTimer = 1.5,
	potatoSize = Vector3.new(3, 3, 3),
	potatoColor = BrickColor.new("Bright red"),
	potatoStartY = 15,
	eliminateThreshold = -50,
	playerSpawnRadius = 15,
	playerSpawnY = 16,
}

local HotPotato = {}

HotPotato._potato = nil
HotPotato._holderUserId = nil
HotPotato._timer = 0
HotPotato._waveElapsed = 0
HotPotato._touchConn = nil
HotPotato._heartbeatConn = nil
HotPotato._roundEnded = false

function HotPotato.setup(context: RoundContract.RoundContext)
	HotPotato._potato = Instance.new("Part")
	HotPotato._potato.Size = HotConfig.potatoSize
	HotPotato._potato.CFrame = CFrame.new(0, HotConfig.potatoStartY, 0)
	HotPotato._potato.BrickColor = HotConfig.potatoColor
	HotPotato._potato.Anchored = true
	HotPotato._potato.CanCollide = false
	HotPotato._potato.Name = "HotPotato"
	HotPotato._potato.Parent = Workspace

	HotPotato._holderUserId = nil
	HotPotato._timer = HotConfig.initialTimer
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
					math.cos(angle) * HotConfig.playerSpawnRadius,
					HotConfig.playerSpawnY,
					math.sin(angle) * HotConfig.playerSpawnRadius
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
	local roundDuration = (context.config and context.config.duration) or HotConfig.roundDuration
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
		if HotPotato._touchConn then
			HotPotato._touchConn:Disconnect()
			HotPotato._touchConn = nil
		end
		if HotPotato._heartbeatConn then
			HotPotato._heartbeatConn:Disconnect()
			HotPotato._heartbeatConn = nil
		end
		if HotPotato._potato and HotPotato._potato.Parent then
			HotPotato._potato:Destroy()
		end
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
		if HotPotato._holderUserId == nil then
			return
		end
		local elapsedUserId = HotPotato._holderUserId
		HotPotato._holderUserId = nil
		local eliminated = alive[elapsedUserId]
		if eliminated then
			alive[elapsedUserId] = nil
			print("[PartyPanic] HotPotato: " .. eliminated.Name .. " eliminated")
		end
		HotPotato._timer = math.max(HotConfig.minTimer, HotPotato._timer - HotConfig.timerDecrement)
		HotPotato._waveElapsed = 0
	end

	HotPotato._touchConn = HotPotato._potato.Touched:Connect(function(hit)
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
		HotPotato._holderUserId = player.UserId
		print("[PartyPanic] HotPotato: " .. player.Name .. " holding potato")
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
	if HotPotato._touchConn then
		HotPotato._touchConn:Disconnect()
		HotPotato._touchConn = nil
	end
	if HotPotato._heartbeatConn then
		HotPotato._heartbeatConn:Disconnect()
		HotPotato._heartbeatConn = nil
	end
	if HotPotato._potato and HotPotato._potato.Parent then
		HotPotato._potato:Destroy()
	end
	HotPotato._potato = nil
	HotPotato._holderUserId = nil
	HotPotato._timer = 0
	HotPotato._waveElapsed = 0
	print("[PartyPanic] HotPotato cleanup — " .. #context.players .. " players")
end

return HotPotato
