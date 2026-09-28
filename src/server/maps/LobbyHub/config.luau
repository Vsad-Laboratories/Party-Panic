-- Lobby Hub map config: Lobby base redesign to match assets/Reference/Lobby.jpg.
-- Scale: ~140x80 studs oval (down from 280x210).
-- Ground: circular disc D140 (top y=1) - grass apron beyond the wall.
-- Playable oval: wall ring on ellipse a=60 b=40 (outer 120x80), height 15, Slate material.
-- Layers: wall [radial 58..64] -> top rim -> walkable interior.
-- Central platform: circle D24, raised (y 1..4, top y=4), glowing Neon.
-- Spawn: ONLY the mythical spawn plate asset (110144096035671) at center.
-- Dressing: stalls 1.2x, trees/rocks on grass apron (Z > 40 / Z < -40).
local LobbyHubConfig = {
	-- Ground disc (flat cylinder; circular face, top surface y=1)
	groundDisc = {
		position = Vector3.new(0, 0, 0),
		diameter = 140,
		thickness = 2,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green
		name = "GroundDisc",
	},
	-- SpawnLocation properties (center mythical plate spawn)
	spawn = {
		size = Vector3.new(8, 1, 8),
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(95, 227, 211), -- accent soft teal/cyan
	},
	-- Fallback anchor: central platform top where mythical plate sits
	lobbySpawn = CFrame.new(0, 4, 0),
	-- Perimeter spawn points, y=1.5 (bottom flush floor top y=1); Placements reads this
	spawnPoints = {
		Vector3.new(50, 1.5, 0),
		Vector3.new(43.3, 1.5, 16.5),
		Vector3.new(25, 1.5, 28.6),
		Vector3.new(0, 1.5, 33),
		Vector3.new(-25, 1.5, 28.6),
		Vector3.new(-43.3, 1.5, 16.5),
		Vector3.new(-50, 1.5, 0),
		Vector3.new(-43.3, 1.5, -16.5),
		Vector3.new(-25, 1.5, -28.6),
		Vector3.new(0, 1.5, -33),
		Vector3.new(25, 1.5, -28.6),
		Vector3.new(43.3, 1.5, -16.5),
	},
	-- Slate-blue perimeter wall: 32 tangent-aligned segments, y 0.5..15.5
	perimeterWall = {
		count = 32,
		a = 60,
		b = 40,
		radialWidth = 4,
		height = 15,
		y = 8,
		material = Enum.Material.Slate,
		color = Color3.fromRGB(40, 60, 120), -- blue stone
		name = "PerimeterWall_",
	},
	-- Grass-green top rim on the wall (y 15.5..16)
	topRim = {
		count = 32,
		a = 60,
		b = 40,
		radialWidth = 4,
		height = 0.5,
		y = 15.75,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green (same as ground)
		name = "TopRim_",
	},
	-- Central platform: circle D24, raised 1 above grass (y 1..4, top y=4)
	-- Glowing Neon material for mythical spawn plate emphasis
	platform = {
		position = Vector3.new(0, 2.5, 0),
		diameter = 24,
		thickness = 3,
		material = Enum.Material.Neon,
		color = Color3.fromRGB(0, 200, 255), -- bright cyan glow
		name = "CentralPlatform",
	},
	-- Perimeter spawn ring: init builds 12 PLAIN ANCHORED PARTS here (NOT
	-- SpawnLocations). They serve as round-placement contract data for Placements
	-- but must NOT be where a joining player spawns (PR#17 spawn-stay).
	-- Smaller ellipse a=50 b=33 for the redesigned footprint.
	spawnRing = {
		count = 12,
		a = 50,
		b = 33,
		y = 1.5,
	},
	-- Dressing assets (Batch 2, ASSETS.md). Positions chosen to match
	-- assets/Reference/Lobby.jpg composition: stalls along west wall,
	-- greenery on grass apron, mythical plate at center, leaderboard east.
	-- All positions are anchored, no overlap with wall/band/platform.
	dressingAssets = {
		-- Storefront stalls along the west wall (asset 16263631766)
		-- 1.2x bigger than default asset scale (5,6,4) -> (6,7,5)
		stalls = {
			{ id = 16263631766, position = Vector3.new(-40, 4, 20), size = Vector3.new(6, 7, 5), name = "StallWest1" },
			{ id = 16263631766, position = Vector3.new(-40, 4, 45), size = Vector3.new(6, 7, 5), name = "StallWest2" },
			{ id = 16263631766, position = Vector3.new(-40, 4, -10), size = Vector3.new(6, 7, 5), name = "StallWest3" },
		},
		-- Trees on the grass apron (asset 12549617200)
		-- Placed at Z > 40 / Z < -40 where wall doesn't extend, inside D140 disc.
		trees = {
			{ id = 12549617200, position = Vector3.new(0, 2, 55), size = Vector3.new(4, 8, 4), name = "TreeNorth1" },
			{ id = 12549617200, position = Vector3.new(0, 2, -55), size = Vector3.new(4, 8, 4), name = "TreeSouth1" },
			{ id = 12549617200, position = Vector3.new(0, 2, 65), size = Vector3.new(4, 8, 4), name = "TreeNorth2" },
			{ id = 12549617200, position = Vector3.new(0, 2, -65), size = Vector3.new(4, 8, 4), name = "TreeSouth2" },
			{ id = 12549617200, position = Vector3.new(0, 2, 45), size = Vector3.new(4, 8, 4), name = "TreeEast1" },
			{ id = 12549617200, position = Vector3.new(0, 2, -45), size = Vector3.new(4, 8, 4), name = "TreeEast2" },
		},
		-- Rocks scattered on the grass apron (assets 16933634812, 10355509588, 13471036173)
		-- Placed at Z > 40 / Z < -40, inside the disc.
		rocks = {
			{
				id = 16933634812,
				position = Vector3.new(15, 1, 48),
				size = Vector3.new(3, 2, 3),
				name = "RockNorthEast",
			},
			{
				id = 10355509588,
				position = Vector3.new(-15, 1, -48),
				size = Vector3.new(4, 2, 4),
				name = "RockSouthWest",
			},
			{ id = 13471036173, position = Vector3.new(20, 1, 58), size = Vector3.new(3, 2, 3), name = "RockNorth2" },
		},
		-- Mythical spawn plate ON the central platform (asset 110144096035671)
		-- At platform center top (0, 4, 0) - the ONLY deterministic spawn point.
		mythicalPlate = {
			{
				id = 110144096035671,
				position = Vector3.new(0, 4.5, 0),
				size = Vector3.new(6, 1, 6),
				name = "MythicalPlate",
			},
		},
		-- TOP Playtime Leaderboard east of platform (asset 5352156968)
		-- Contains scripts → stripped on ingest (ASSETS.md rule).
		leaderboard = {
			{ id = 5352156968, position = Vector3.new(45, 5, 35), size = Vector3.new(2, 4, 1), name = "Leaderboard" },
		},
	},
}
return LobbyHubConfig
