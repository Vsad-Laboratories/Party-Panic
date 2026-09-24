-- FloorFall players subsystem: placement, ghost pruning, elimination, win/timeout checks.
local config = require(script.Parent.config)

local players = {}

function players.placeOnGrid(context_players, tiles)
	local placed = 0
	for i, player in ipairs(context_players) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				placed += 1
				local row = ((i - 1) % config.gridRows) + 1
				local col = ((i - 1) % config.gridCols) + 1
				local tile = tiles[row] and tiles[row][col]
				if tile and tile.part then
					local pos = tile.part.Position
					hrp.CFrame = CFrame.new(pos.X, pos.Y + config.tileThickness + 3, pos.Z)
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end
	return placed
end

function players.pruneGhosts(living)
	for userId, player in pairs(living) do
		if player.Parent == nil or player.Character == nil then
			living[userId] = nil
		end
	end
end

function players.checkEliminations(living)
	for userId, player in pairs(living) do
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp.Position.Y < config.yThreshold then
			living[userId] = nil
			print("[PartyPanic] FloorFall: " .. player.Name .. " eliminated")
		end
	end
end

function players.getAliveCount(living)
	local count = 0
	for _ in pairs(living) do
		count += 1
	end
	return count
end

function players.timeoutAward(living)
	local bestUserId = nil
	local bestY = -math.huge
	for userId, player in pairs(living) do
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp.Position.Y > bestY then
			bestY = hrp.Position.Y
			bestUserId = userId
		end
	end
	return bestUserId
end

function players.lastStanding(living)
	local winner = nil
	for userId, _ in pairs(living) do
		winner = userId
		break
	end
	return winner
end

return players
