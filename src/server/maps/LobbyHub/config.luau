-- Lobby Hub map config: Astro-Arcade Punk theme following LobbyMap Reference.jpg.
-- Layout: floor top y=1; wall ring r[18,20]; north = +Z (status screen), south = -Z (obby).
-- All zone boxes verified pairwise-disjoint, max corner r<=18, on-floor, <=40 studs from spawn.
local LobbyHubConfig = {
	-- Grass floor (square block under the circular wall ring)
	centralDisc = {
		position = Vector3.new(0, 0, 0),
		size = Vector3.new(40, 2, 40),
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green
		name = "CentralDisc",
	},
	-- SpawnLocation properties (used in init)
	spawn = {
		size = Vector3.new(4, 1, 4),
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(95, 227, 211), -- accent soft teal/cyan
	},
	-- Lobby spawn CFrame (on floor top; identity rotation — facing is a Pass B observable)
	lobbySpawn = CFrame.new(0, 1.5, 0),
	-- Walkable spawn points (4x4 character footprint checked against every zone)
	spawnPoints = {
		Vector3.new(0, 1.5, 0),
		Vector3.new(8, 1.5, 0),
		Vector3.new(-8, 1.5, 0),
		Vector3.new(0, 1.5, 8),
		Vector3.new(0, 1.5, -8),
	},
	-- Slate-blue perimeter wall, 16 segments; height 7 so the status screen mounts on it
	perimeterWall = {
		count = 16,
		innerRadius = 18,
		thickness = 2,
		height = 7,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(46, 58, 89), -- slate-blue
	},
	-- Green top rim on the wall (init places it at 1 + wall.height + rim height/2)
	topRim = {
		count = 16,
		innerRadius = 18,
		thickness = 2,
		height = 0.5,
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green (same as floor)
	},
	-- Storefront Avenue: 3 stalls stepping along the west wall (upper-left sector of the image)
	storefrontAvenue = {
		{
			position = Vector3.new(-13.5, 4.0, 4.5), -- size (5,6,4): y = 1 + 6/2 = 4 (seated on floor)
			size = Vector3.new(5, 6, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(95, 227, 211), -- teal
			name = "StorefrontBooth1",
		},
		{
			position = Vector3.new(-11.0, 4.0, 9.0),
			size = Vector3.new(5, 6, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77), -- canary
			name = "StorefrontBooth2",
		},
		{
			position = Vector3.new(-5.5, 4.0, 12.0),
			size = Vector3.new(5, 6, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77), -- canary
			name = "StorefrontBooth3",
		},
	},
	-- Party Pass Grotto: raised stone terrace on the east wall with gate + neon sign on the wall
	partyPassGrotto = {
		alcove = {
			position = Vector3.new(11.5, 3.0, 6.0), -- terrace: y = 1 + 4/2 = 3, top at y=5
			size = Vector3.new(8, 4, 6),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(163, 168, 178), -- light stone (reference image terrace)
			name = "PartyPassTerrace",
		},
		pedestal = {
			position = Vector3.new(11.5, 6.0, 6.0), -- sits on terrace top (y=5)
			size = Vector3.new(3, 2, 3),
			material = Enum.Material.Metal,
			color = Color3.fromRGB(255, 225, 77), -- gold (crown stand)
			name = "TrophyPedestal",
		},
		gate = {
			position = Vector3.new(16.35, 3.0, 6.0), -- chord-flat against curved wall, corners r<=18
			size = Vector3.new(0.5, 4, 1.5),
			material = Enum.Material.Metal,
			color = Color3.fromRGB(60, 65, 75), -- dark iron
			name = "PartyPassGate",
		},
		gateSign = {
			position = Vector3.new(17.6, 6.0, 2.0), -- neon sign on the wall next to the gate
			size = Vector3.new(0.2, 1.5, 2.5),
			material = Enum.Material.Metal,
			color = Color3.fromRGB(255, 225, 77), -- canary neon
			name = "PartyPassGateSign",
		},
	},
	-- Map Voting Circle: 3 ring pads ON the spawn disc (north-pointing triangle, image center)
	mapVotingCircle = {
		pads = {
			{
				position = Vector3.new(0, 1.1, 4.3), -- north pad, r=4.3 from center; y = 1 + 0.1
				size = Vector3.new(3, 0.2, 3),
				material = Enum.Material.Neon,
				color = Color3.fromRGB(95, 227, 211), -- teal
				name = "VotePad1",
			},
			{
				position = Vector3.new(-3.724, 1.1, -2.15), -- southwest pad, r=4.3
				size = Vector3.new(3, 0.2, 3),
				material = Enum.Material.Neon,
				color = Color3.new(1, 1, 1), -- white
				name = "VotePad2",
			},
			{
				position = Vector3.new(3.724, 1.1, -2.15), -- southeast pad, r=4.3
				size = Vector3.new(3, 0.2, 3),
				material = Enum.Material.Neon,
				color = Color3.fromRGB(255, 225, 77), -- yellow
				name = "VotePad3",
			},
		},
		statusScreen = {
			position = Vector3.new(0, 5.5, 17.38), -- mounted on the north wall, chord-flat (corners r<=18)
			size = Vector3.new(8, 5, 0.3),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(35, 43, 69), -- deep cosmic navy
			name = "StatusScreen",
		},
	},
	-- Winner Podium: small 3-tier stack north-east, flanking the vote circle's back (not in image)
	winnerPodium = {
		base = {
			position = Vector3.new(7.0, 2.0, 13.0),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75), -- grass green
			name = "PodiumBase",
		},
		mid = {
			position = Vector3.new(7.0, 4.0, 13.0),
			size = Vector3.new(3, 2, 3),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75),
			name = "PodiumMid",
		},
		top = {
			position = Vector3.new(7.0, 6.0, 13.0),
			size = Vector3.new(2, 2, 2),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75),
			name = "PodiumTop",
		},
	},
	-- AFK & Coin Obby Arena: 4 colorful tiles across the south (front/at-feet sector of the image)
	afkCoinObbyArena = {
		{
			position = Vector3.new(-11.0, 2.0, -6.0), -- y = 1 + 2/2 = 2
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 63, 164), -- pink (DESIGN: pink/yellow/cyan/purple)
			name = "ObbyStripWest",
		},
		{
			position = Vector3.new(-5.0, 2.0, -6.0),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77), -- yellow
			name = "ObbyStripMidWest",
		},
		{
			position = Vector3.new(5.0, 2.0, -6.0),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(95, 227, 211), -- cyan
			name = "ObbyStripMidEast",
		},
		{
			position = Vector3.new(11.0, 2.0, -6.0),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(155, 89, 182), -- purple (DESIGN word; no RGB bound)
			name = "ObbyStripEast",
		},
	},
	-- Existing landmark re-skinned: outside the wall ring by design (visible above the rim)
	landmark = {
		position = Vector3.new(0, 5, 40),
		size = Vector3.new(5, 10, 5),
		material = Enum.Material.Metal,
		color = Color3.fromRGB(255, 63, 164), -- neon pink accent
		name = "Landmark",
	},
	-- Decorative assets from ASSETS.md; footprints assumed <=4x4 (Pass B visual check)
	decorAssets = {
		planter1 = {
			id = 16206527053, -- Rectangle planter 1
			position = Vector3.new(-15.5, 2, 0),
		},
		lamp1 = {
			id = 5036801877, -- Medieval lamp 1
			position = Vector3.new(15, 2, -6),
		},
	},
}
return LobbyHubConfig
