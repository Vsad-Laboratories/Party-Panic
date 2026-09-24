-- FloorFall: tile-vanish elimination round. A grid of Parts forms a floor
-- that vanishes over time. Players who fall below the Y threshold are eliminated.
-- Last standing wins. Conforms to RoundContract (src/shared/RoundContract).
-- play() is async — starts a Heartbeat loop, signals completion via onRoundComplete.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RoundContract = require(game.ReplicatedStorage.Shared.RoundContract)

-- FloorFall data table: tuning edits this, never code.
local FloorConfig = {
	gridRows = 10,
	gridCols = 10,
	tileSize = 4,
	tileThickness = 1,
	startY = 20,

	colors = {
		safe = BrickColor.new("Bright green"),
		warning = BrickColor.new("Bright yellow"),
	},

	warningDuration = 2,
	dropInterval = 3,
	tilesPerWave = 5,

	yThreshold = 5,
}

local FloorFall = {}

FloorFall._tiles = {}
FloorFall._elapsed = 0
FloorFall._nextWave = 0
FloorFall._pendingDrops = {}
FloorFall._roundEnded = false
FloorFall._heartbeatConn = nil

function FloorFall.setup(context: RoundContract.RoundContext)
	FloorFall._tiles = {}
	FloorFall._elapsed = 0
	FloorFall._nextWave = FloorConfig.dropInterval
	FloorFall._pendingDrops = {}
	FloorFall._roundEnded = false

	local offsetX = -((FloorConfig.gridCols - 1) * FloorConfig.tileSize) / 2
	local offsetZ = -((FloorConfig.gridRows - 1) * FloorConfig.tileSize) / 2

	for row = 1, FloorConfig.gridRows do
		FloorFall._tiles[row] = {}
		for col = 1, FloorConfig.gridCols do
			local part = Instance.new("Part")
			part.Size = Vector3.new(FloorConfig.tileSize, FloorConfig.tileThickness, FloorConfig.tileSize)
			part.Position = Vector3.new(
				offsetX + (col - 1) * FloorConfig.tileSize,
				FloorConfig.startY,
				offsetZ + (row - 1) * FloorConfig.tileSize
			)
			part.BrickColor = FloorConfig.colors.safe
			part.Anchored = true
			part.Name = "FloorTile"
			part.Parent = Workspace
			FloorFall._tiles[row][col] = {
				part = part,
				state = "safe",
			}
		end
	end

	-- Place participants on grid tiles (above yThreshold, standing headroom)
	local placed = 0
	for i, player in ipairs(context.players) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				placed += 1
				local row = ((i - 1) % FloorConfig.gridRows) + 1
				local col = ((i - 1) % FloorConfig.gridCols) + 1
				local tile = FloorFall._tiles[row] and FloorFall._tiles[row][col]
				if tile and tile.part then
					local pos = tile.part.Position
					hrp.CFrame = CFrame.new(pos.X, pos.Y + FloorConfig.tileThickness + 3, pos.Z)
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end

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
		context.onRoundComplete({
			winnerUserId = winner,
			scores = {},
		})
	end

	local function pruneGhosts()
		for userId, player in pairs(living) do
			if player.Parent == nil or player.Character == nil then
				living[userId] = nil
			end
		end
	end

	local function checkEliminations()
		for userId, player in pairs(living) do
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Position.Y < FloorConfig.yThreshold then
				living[userId] = nil
				print("[PartyPanic] FloorFall: " .. player.Name .. " eliminated")
			end
		end
	end

	local function getAliveCount()
		local count = 0
		for _ in pairs(living) do
			count += 1
		end
		return count
	end

	local function dropWave()
		local safeTiles = {}
		for row = 1, FloorConfig.gridRows do
			for col = 1, FloorConfig.gridCols do
				local tile = FloorFall._tiles[row] and FloorFall._tiles[row][col]
				if tile and tile.state == "safe" then
					table.insert(safeTiles, { row = row, col = col })
				end
			end
		end
		local count = math.min(FloorConfig.tilesPerWave, #safeTiles)
		for _ = 1, count do
			local idx = math.random(#safeTiles)
			local picked = table.remove(safeTiles, idx)
			if picked then
				local tile = FloorFall._tiles[picked.row] and FloorFall._tiles[picked.row][picked.col]
				if tile then
					tile.state = "warning"
					tile.part.BrickColor = FloorConfig.colors.warning
					table.insert(FloorFall._pendingDrops, {
						row = picked.row,
						col = picked.col,
						time = FloorFall._elapsed + FloorConfig.warningDuration,
					})
				end
			end
		end
	end

	FloorFall._heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		FloorFall._elapsed += dt

		-- Prune ghosts (disconnected or missing character) before any checks
		pruneGhosts()

		-- Timeout fallback (PRD §4: 60-90s cap)
		if FloorFall._elapsed >= roundDuration then
			local bestUserId = nil
			local bestY = -math.huge
			for userId, player in pairs(living) do
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if hrp and hrp.Position.Y > bestY then
					bestY = hrp.Position.Y
					bestUserId = userId
				end
			end
			endRound(bestUserId)
			return
		end

		-- Wave drops (solo-safe: only when >1 player alive)
		if getAliveCount() > 1 and FloorFall._elapsed >= FloorFall._nextWave then
			FloorFall._nextWave += FloorConfig.dropInterval
			dropWave()
		end

		-- Process pending tile destructions
		for i = #FloorFall._pendingDrops, 1, -1 do
			local drop = FloorFall._pendingDrops[i]
			if FloorFall._elapsed >= drop.time then
				local tile = FloorFall._tiles[drop.row] and FloorFall._tiles[drop.row][drop.col]
				if tile then
					tile.state = "gone"
					tile.part:Destroy()
					FloorFall._tiles[drop.row][drop.col] = nil
				end
				table.remove(FloorFall._pendingDrops, i)
			end
		end

		-- Eliminate fallen players
		checkEliminations()

		-- Last standing wins (solo-safe: skip for single-player, runs to timeout)
		if startingCount > 1 and getAliveCount() <= 1 then
			local winner = nil
			for userId, _ in pairs(living) do
				winner = userId
				break
			end
			endRound(winner)
		end
	end)
end

function FloorFall.cleanup(context: RoundContract.RoundContext)
	if FloorFall._heartbeatConn then
		FloorFall._heartbeatConn:Disconnect()
		FloorFall._heartbeatConn = nil
	end
	if FloorFall._tiles then
		for _, rowTiles in pairs(FloorFall._tiles) do
			for _, tile in pairs(rowTiles) do
				if tile and tile.part and tile.part.Parent then
					tile.part:Destroy()
				end
			end
		end
	end
	FloorFall._tiles = {}
	FloorFall._pendingDrops = {}
	FloorFall._roundEnded = false
	print("[PartyPanic] FloorFall cleanup — " .. #context.players .. " players")
end

return FloorFall
