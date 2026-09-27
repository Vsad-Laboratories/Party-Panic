-- Lobby Hub map config: Lobby base v3 = v2 footprint x2 (Operator goal "2x bigger";
-- ALL plan dimensions doubled, ALL heights/y unchanged).
-- Ground: circular disc D280 (top y=1) - apron of grass beyond the wall, as in the reference image.
-- Playable oval: wall ring on ellipse a=138 b=103 (outer 280x210), full 360 degrees, height 16.
-- Layers inward: wall [radial 136..140] -> decor ring width 18 [117.5..135.5] -> teal edge line -> walkable.
-- Central platform: circle D52, raised (y 1..3, top y=3). Spawns: 12 on ellipse a=109 b=74.
-- Zones/props/stalls = dressing PR (previous geometry kept in git history).
local LobbyHubConfig = {
	-- Ground disc (flat cylinder; circular face, top surface y=1)
	groundDisc = {
		position = Vector3.new(0, 0, 0),
		diameter = 280,
		thickness = 2,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green
		name = "GroundDisc",
	},
	-- SpawnLocation properties (all 12 perimeter spawns)
	spawn = {
		size = Vector3.new(8, 1, 8),
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(95, 227, 211), -- accent soft teal/cyan
	},
	-- Fallback anchor (Placements pre-#17): central platform top
	lobbySpawn = CFrame.new(0, 3.5, 0),
	-- Perimeter spawn points, y=1.5 (bottom flush floor top y=1); Placements reads this
	spawnPoints = {
		Vector3.new(109, 1.5, 0),
		Vector3.new(94.4, 1.5, 37),
		Vector3.new(54.5, 1.5, 64.08),
		Vector3.new(0, 1.5, 74),
		Vector3.new(-54.5, 1.5, 64.08),
		Vector3.new(-94.4, 1.5, 37),
		Vector3.new(-109, 1.5, 0),
		Vector3.new(-94.4, 1.5, -37),
		Vector3.new(-54.5, 1.5, -64.08),
		Vector3.new(0, 1.5, -74),
		Vector3.new(54.5, 1.5, -64.08),
		Vector3.new(94.4, 1.5, -37),
	},
	-- Slate-blue perimeter wall: 32 tangent-aligned segments, y 1..17
	perimeterWall = {
		count = 32,
		a = 138,
		b = 103,
		radialWidth = 4,
		height = 16,
		y = 9,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(46, 58, 89), -- slate-blue
		name = "PerimeterWall_",
	},
	-- Grass-green top rim on the wall (y 17..17.5)
	topRim = {
		count = 32,
		a = 138,
		b = 103,
		radialWidth = 4,
		height = 0.5,
		y = 17.25,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green (same as ground)
		name = "TopRim_",
	},
	-- Decorative ring path: cosmic navy band width 18 (y 1..1.3), kept clear of props
	decorRing = {
		count = 32,
		a = 126.5,
		b = 91.5,
		radialWidth = 18,
		height = 0.2,
		y = 1.1,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(35, 43, 69), -- cosmic navy
		name = "DecorRing_",
	},
	-- Teal edge line raised on the ring's inner side (y 1.3..1.42); a/b chosen so
	-- the line stays inside the band at every angle (band edge = offset curve, not an
	-- ellipse - exact match impossible; every plan dimension x2 keeps the same
	-- proportional margins the v2 design passed review with, on a 18-wide band)
	ringEdge = {
		count = 32,
		a = 118.6,
		b = 83.6,
		radialWidth = 1,
		height = 0.12,
		y = 1.36,
		material = Enum.Material.Neon,
		color = Color3.fromRGB(95, 227, 211), -- accent teal-cyan
		name = "RingEdge_",
	},
	-- Central platform: circle D52, raised 2 above grass (y 1..3, top y=3)
	platform = {
		position = Vector3.new(0, 2, 0),
		diameter = 52,
		thickness = 2,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(163, 168, 178), -- light stone (reference hub)
		name = "CentralPlatform",
	},
	-- Perimeter spawn ring: init builds 12 SpawnLocations here, facing center.
	-- a/b give pad edges (half-size 4) clear of the band's BUILT inner boundary
	-- (chord boxes sag inside the smooth offset curve); margins measured by the
	-- geometry checker and pasted in the PR body.
	spawnRing = {
		count = 12,
		a = 109,
		b = 74,
		y = 1.5,
	},
}
return LobbyHubConfig
