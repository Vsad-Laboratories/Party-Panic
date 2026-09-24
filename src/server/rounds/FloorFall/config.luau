-- FloorFall config: pure data table for the tile-vanish elimination round.
-- Tuning edits this file, never code.
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

return FloorConfig
