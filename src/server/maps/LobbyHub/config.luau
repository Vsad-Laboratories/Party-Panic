-- Lobby Hub map config: Lobby base v2 (Operator oval spec, DESIGN "Lobby base v2").
-- Ground: circular disc D140 (top y=1) - apron of grass beyond the wall, as in the reference image.
-- Playable oval: wall ring on ellipse a=69 b=51.5 (outer 140x105), full 360 degrees, height 16.
-- Layers inward: wall [radial 68..70] -> decor ring width 9 [59..68] -> teal edge line -> walkable.
-- Central platform: circle D26, raised (y 1..3, top y=3). Spawns: 12 on ellipse a=57 b=39.5.
-- Zones/props/stalls = dressing PR (previous geometry kept in git history).
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
	-- SpawnLocation properties (all 12 perimeter spawns)
	spawn = {
		size = Vector3.new(4, 1, 4),
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(95, 227, 211), -- accent soft teal/cyan
	},
	-- Fallback anchor (Placements pre-#17): central platform top
	lobbySpawn = CFrame.new(0, 3.5, 0),
	-- Perimeter spawn points, y=1.5 (bottom flush floor top y=1); Placements reads this
	spawnPoints = {
		Vector3.new(54.5, 1.5, 0),
		Vector3.new(47.2, 1.5, 18.5),
		Vector3.new(27.25, 1.5, 32.04),
		Vector3.new(0, 1.5, 37),
		Vector3.new(-27.25, 1.5, 32.04),
		Vector3.new(-47.2, 1.5, 18.5),
		Vector3.new(-54.5, 1.5, 0),
		Vector3.new(-47.2, 1.5, -18.5),
		Vector3.new(-27.25, 1.5, -32.04),
		Vector3.new(0, 1.5, -37),
		Vector3.new(27.25, 1.5, -32.04),
		Vector3.new(47.2, 1.5, -18.5),
	},
	-- Slate-blue perimeter wall: 32 tangent-aligned segments, y 1..17
	perimeterWall = {
		count = 32,
		a = 69,
		b = 51.5,
		radialWidth = 2,
		height = 16,
		y = 9,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(46, 58, 89), -- slate-blue
		name = "PerimeterWall_",
	},
	-- Grass-green top rim on the wall (y 17..17.5)
	topRim = {
		count = 32,
		a = 69,
		b = 51.5,
		radialWidth = 2,
		height = 0.5,
		y = 17.25,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green (same as ground)
		name = "TopRim_",
	},
	-- Decorative ring path: cosmic navy band width 9 (y 1..1.3), kept clear of props
	decorRing = {
		count = 32,
		a = 63.5,
		b = 46,
		radialWidth = 9,
		height = 0.2,
		y = 1.1,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(35, 43, 69), -- cosmic navy
		name = "DecorRing_",
	},
	-- Teal edge line raised on the ring's inner side (y 1.3..1.42); a/b chosen so
	-- the line stays >=0.05 inside the band at every angle (band edge = offset curve,
	-- not an ellipse - exact match impossible, ~0.7 wander is invisible on a 9-wide band)
	ringEdge = {
		count = 32,
		a = 59.3,
		b = 41.8,
		radialWidth = 0.5,
		height = 0.12,
		y = 1.36,
		material = Enum.Material.Neon,
		color = Color3.fromRGB(95, 227, 211), -- accent teal-cyan
		name = "RingEdge_",
	},
	-- Central platform: circle D26, raised 2 above grass (y 1..3, top y=3)
	platform = {
		position = Vector3.new(0, 2, 0),
		diameter = 26,
		thickness = 2,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(163, 168, 178), -- light stone (reference hub)
		name = "CentralPlatform",
	},
	-- Perimeter spawn ring: init builds 12 SpawnLocations here, facing center.
	-- a/b give pad edges (half-size 2) >=1.5 clear of the band's BUILT inner
	-- boundary (chord boxes sag up to ~0.3 inside the smooth offset curve).
	spawnRing = {
		count = 12,
		a = 54.5,
		b = 37,
		y = 1.5,
	},
}
return LobbyHubConfig
