-- HotPotato config: pure data table for the pass-the-potato elimination round.
-- Tuning edits this file, never code.
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

return HotConfig
