-- FloorFall floor subsystem: grid builder + warn/drop scheduler.
-- Creates the tile grid and manages wave-based tile disappearance.
local Workspace = game:GetService("Workspace")

local config = require(script.Parent.config)

local floor = {
	tiles = {},
	elapsed = 0,
	nextWave = 0,
	pendingDrops = {},
	heartbeatConn = nil,
}

function floor.build()
	floor.tiles = {}
	floor.elapsed = 0
	floor.nextWave = config.dropInterval
	floor.pendingDrops = {}

	local offsetX = -((config.gridCols - 1) * config.tileSize) / 2
	local offsetZ = -((config.gridRows - 1) * config.tileSize) / 2

	for row = 1, config.gridRows do
		floor.tiles[row] = {}
		for col = 1, config.gridCols do
			local part = Instance.new("Part")
			part.Size = Vector3.new(config.tileSize, config.tileThickness, config.tileSize)
			part.Position =
				Vector3.new(offsetX + (col - 1) * config.tileSize, config.startY, offsetZ + (row - 1) * config.tileSize)
			part.BrickColor = config.colors.safe
			part.Anchored = true
			part.Name = "FloorTile"
			part.Parent = Workspace
			floor.tiles[row][col] = {
				part = part,
				state = "safe",
			}
		end
	end
end

function floor.dropWave()
	local safeTiles = {}
	for row = 1, config.gridRows do
		for col = 1, config.gridCols do
			local tile = floor.tiles[row] and floor.tiles[row][col]
			if tile and tile.state == "safe" then
				table.insert(safeTiles, { row = row, col = col })
			end
		end
	end
	local count = math.min(config.tilesPerWave, #safeTiles)
	for _ = 1, count do
		local idx = math.random(#safeTiles)
		local picked = table.remove(safeTiles, idx)
		if picked then
			local tile = floor.tiles[picked.row] and floor.tiles[picked.row][picked.col]
			if tile then
				tile.state = "warning"
				tile.part.BrickColor = config.colors.warning
				table.insert(floor.pendingDrops, {
					row = picked.row,
					col = picked.col,
					time = floor.elapsed + config.warningDuration,
				})
			end
		end
	end
end

function floor.processPendingDrops()
	for i = #floor.pendingDrops, 1, -1 do
		local drop = floor.pendingDrops[i]
		if floor.elapsed >= drop.time then
			local tile = floor.tiles[drop.row] and floor.tiles[drop.row][drop.col]
			if tile then
				tile.state = "gone"
				tile.part:Destroy()
				floor.tiles[drop.row][drop.col] = nil
			end
			table.remove(floor.pendingDrops, i)
		end
	end
end

function floor.advance(dt)
	floor.elapsed += dt
	floor.processPendingDrops()
end

function floor.cleanup()
	if floor.heartbeatConn then
		floor.heartbeatConn:Disconnect()
		floor.heartbeatConn = nil
	end
	for _, rowTiles in pairs(floor.tiles) do
		for _, tile in pairs(rowTiles) do
			if tile and tile.part and tile.part.Parent then
				tile.part:Destroy()
			end
		end
	end
	floor.tiles = {}
	floor.pendingDrops = {}
end

return floor
