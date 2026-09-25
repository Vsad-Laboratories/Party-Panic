-- Lobby Hub map config: pure data for Astro-Arcade Punk theme with Operator's layout.
-- Central disc (grass green) + perimeter wall (slate-blue) + top rim (green) + zones.
local LobbyHubConfig = {
	-- Base floor (central disc) - grass green cylinder
	centralDisc = {
		position = Vector3.new(0, 0, 0),
		size = Vector3.new(40, 2, 40), -- diameter 40, height 2
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green
		shape = Enum.PartType.Cylinder,
		name = "CentralDisc",
	},
	-- SpawnLocation properties (used in init)
	spawn = {
		size = Vector3.new(4, 1, 4),
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(95, 227, 211), -- accent soft teal/cyan
	},
	-- Lobby spawn CFrame (position on central disc top)
	lobbySpawn = CFrame.new(0, 1, 0), -- half thickness above disc center
	-- Walkable spawn points (on central disc top, inset from edge)
	spawnPoints = {
		Vector3.new(0, 1, 0),
		Vector3.new(8, 1, 0),
		Vector3.new(-8, 1, 0),
		Vector3.new(0, 1, 8),
		Vector3.new(0, 1, -8),
	},
	-- Perimeter wall (slate-blue) - approximated by 16 parts
	perimeterWall = {
		count = 16,
		innerRadius = 20, -- radius of the central disc (inner edge of wall)
		thickness = 2, -- wall thickness
		height = 3, -- wall height
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(46, 58, 89), -- slate-blue
	},
	-- Top rim (green) - approximated by 16 parts on top of the wall
	topRim = {
		count = 16,
		innerRadius = 20, -- same as wall inner radius
		thickness = 2, -- same thickness as wall
		height = 0.5, -- rim height
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green (same as floor)
	},
	-- Zones
	-- Storefront Avenue (left flank): 3 booths at left 45° (north-west)
	storefrontAvenue = {
		{
			-- Booth 1
			position = Vector3.new(-10, 2, 17.32), -- 30 deg west of north: x = -20*sin(30)= -10, z=20*cos(30)=17.32
			size = Vector3.new(8, 6, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77), -- canary yellow (interactive)
			name = "StorefrontBooth1",
		},
		{
			-- Booth 2
			position = Vector3.new(-14.14, 2, 14.14), -- 45 deg west of north: x = -20*sin(45)= -14.14, z=20*cos(45)=14.14
			size = Vector3.new(8, 6, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77),
			name = "StorefrontBooth2",
		},
		{
			-- Booth 3
			position = Vector3.new(-17.32, 2, 10), -- 60 deg west of north: x = -20*sin(60)= -17.32, z=20*cos(60)=10
			size = Vector3.new(8, 6, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77),
			name = "StorefrontBooth3",
		},
	},
	-- Battle Pass Grotto (right flank): elevated rocky alcove + trophy pedestal at right 45° (north-east)
	battlePassGrotto = {
		alcove = {
			position = Vector3.new(10, 2, 17.32), -- 30 deg east of north: x = 20*sin(30)=10, z=20*cos(30)=17.32
			size = Vector3.new(12, 10, 12),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(35, 43, 69), -- deep cosmic navy
			name = "BattlePassAlcove",
		},
		pedestal = {
			position = Vector3.new(10, 12, 17.32), -- on top of alcove (alcove height 10, so pedestal base at y=2+10=12)
			size = Vector3.new(6, 2, 6),
			material = Enum.Material.Metal,
			color = Color3.fromRGB(95, 227, 211), -- accent soft teal/cyan
			name = "TrophyPedestal",
		},
	},
	-- Map Voting circle center: 3 glowing floor pads + STATUS screen above (dead ahead, north)
	mapVotingCircle = {
		pads = {
			{
				-- Pad 1: west of north
				position = Vector3.new(-10, 2, 17.32), -- 30 deg west of north
				size = Vector3.new(4, 0.2, 4),
				material = Enum.Material.Neon,
				color = Color3.fromRGB(255, 225, 77), -- canary yellow (interactive)
				name = "VotePad1",
			},
			{
				-- Pad 2: due north
				position = Vector3.new(0, 2, 20),
				size = Vector3.new(4, 0.2, 4),
				material = Enum.Material.Neon,
				color = Color3.fromRGB(255, 225, 77),
				name = "VotePad2",
			},
			{
				-- Pad 3: east of north
				position = Vector3.new(10, 2, 17.32), -- 30 deg east of north
				size = Vector3.new(4, 0.2, 4),
				material = Enum.Material.Neon,
				color = Color3.fromRGB(255, 225, 77),
				name = "VotePad3",
			},
		},
		statusScreen = {
			position = Vector3.new(0, 5, 20), -- above the voting circle
			size = Vector3.new(8, 4, 0.2),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(35, 43, 69), -- deep cosmic navy
			name = "StatusScreen",
		},
	},
	-- Winner Podium center: tiered podium (rear 180° = south)
	winnerPodium = {
		base = {
			position = Vector3.new(0, 2, -20), -- due south
			size = Vector3.new(12, 2, 12),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75), -- grass green (same as floor)
			name = "PodiumBase",
		},
		mid = {
			position = Vector3.new(0, 4, -20), -- on top of base
			size = Vector3.new(8, 2, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75),
			name = "PodiumMid",
		},
		top = {
			position = Vector3.new(0, 6, -20), -- on top of mid
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75),
			name = "PodiumTop",
		},
	},
	-- AFK & Coin Obby Arena front strip: decorative parkour strip (flanking the Winner Podium at the player's feet)
	afkCoinObbyArena = {
		-- We'll make a strip from west to east at the south, just in front of the Winner Podium (so north of the Winner Podium? but still south of spawn)
		-- We'll put it at z = -18 (so 2 studs north of the Winner Podium which is at z=-20)
		-- and from x = -15 to x = 15 in steps? We'll make three parts for simplicity.
		{
			position = Vector3.new(-15, 2, -18),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77), -- canary yellow (interactive)
			name = "ObbyStripWest",
		},
		{
			position = Vector3.new(0, 2, -18),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77),
			name = "ObbyStripCenter",
		},
		{
			position = Vector3.new(15, 2, -18),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77),
			name = "ObbyStripEast",
		},
	},
	-- Existing landmark (re-skinned)
	landmark = {
		position = Vector3.new(0, 5, 40),
		size = Vector3.new(5, 10, 5),
		material = Enum.Material.Metal,
		color = Color3.fromRGB(255, 63, 164), -- neon pink accent
		name = "Landmark",
	},
	-- Decorative assets from ASSETS.md
	decorAssets = {
		-- Example: planter, lamp, etc.
		planter1 = {
			id = 16206527053, -- Rectangle planter 1
			position = Vector3.new(-10, 2, 15),
		},
		lamp1 = {
			id = 5036801877, -- Medieval lamp 1
			position = Vector3.new(10, 2, -15),
		},
	},
}
return LobbyHubConfig
