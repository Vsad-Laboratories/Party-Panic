-- Lobby Hub map config: pure data for Astro-Arcade Punk theme with Operator's layout.
-- Central disc (grass green) + perimeter wall (slate-blue) + top rim (green) + zones.
local LobbyHubConfig = {
	-- Base floor (central disc) - grass green block
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
	-- Lobby spawn CFrame (position on central disc top)
	lobbySpawn = CFrame.new(0, 1.5, 0), -- half thickness above disc center (disc top at y=1) + half spawn height
	-- Walkable spawn points (on central disc top, inset from edge)
	spawnPoints = {
		Vector3.new(0, 1.5, 0),
		Vector3.new(8, 1.5, 0),
		Vector3.new(-8, 1.5, 0),
		Vector3.new(0, 1.5, 8),
		Vector3.new(0, 1.5, -8),
	},
	-- Perimeter wall (slate-blue) - approximated by 16 parts
	perimeterWall = {
		count = 16,
		innerRadius = 18, -- radius of the central disc (inner edge of wall)
		thickness = 2, -- wall thickness
		height = 3, -- wall height
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(46, 58, 89), -- slate-blue
	},
	-- Top rim (green) - approximated by 16 parts on top of the wall
	topRim = {
		count = 16,
		innerRadius = 18, -- same as wall inner radius
		thickness = 2, -- same thickness as wall
		height = 0.5, -- rim height
		material = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(106, 190, 75), -- grass green (same as floor)
	},
	-- Zones
	-- Storefront Avenue (left flank): 3 booths at left 45° (north-west) - actually angles -60, -45, -30 degrees west of north
	storefrontAvenue = {
		{
			-- Booth 1: angle 60 deg west of north
			position = Vector3.new(-10.392, 4.0, 6.000), -- x = -R*sin(60), z = R*cos(60), R=12, y = 1 + size.Y/2 = 1+3=4
			size = Vector3.new(8, 6, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(95, 227, 211), -- teal (interactive)
			name = "StorefrontBooth1",
		},
		{
			-- Booth 2: angle 45 deg west of north
			position = Vector3.new(-8.485, 4.0, 8.485), -- x = -R*sin(45), z = R*cos(45), R=12
			size = Vector3.new(8, 6, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(95, 227, 211), -- teal
			name = "StorefrontBooth2",
		},
		{
			-- Booth 3: angle 30 deg west of north
			position = Vector3.new(-6.000, 4.0, 10.392), -- x = -R*sin(30), z = R*cos(30), R=12
			size = Vector3.new(8, 6, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(95, 227, 211), -- teal
			name = "StorefrontBooth3",
		},
	},
	-- Party Pass Grotto (right flank): elevated rocky alcove + trophy pedestal + gate sign at right 45° (north-east) -- actually angle +30 deg east of north
	partyPassGrotto = {
		alcove = {
			-- Base at angle 30 deg east of north (theta = -30 deg west of north)
			position = Vector3.new(4.500, 6.0, 7.794), -- x = R*sin(30)?? Wait we used x = -R*sin(theta) with theta negative? Let's recompute: we want x positive, z positive. Using formula x = -R*sin(theta) where theta is degrees west of north. For east of north, theta = -30. So x = -R*sin(-30) = -R*(-0.5) = +R*0.5 = 4.5. z = R*cos(-30) = R*0.8660 = 7.794. y = 1 + size.Y/2 = 1+5=6.
			size = Vector3.new(12, 10, 12),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(35, 43, 69), -- deep cosmic navy
			name = "PartyPassAlcove",
		},
		pedestal = {
			-- On top of alcove
			position = Vector3.new(4.500, 12.0, 7.794), -- x same as alcove, z same, y = alcove top (y=1+10=11) + half pedestal height (1) = 12
			size = Vector3.new(6, 2, 6),
			material = Enum.Material.Metal,
			color = Color3.fromRGB(95, 227, 211), -- accent soft teal/cyan
			name = "TrophyPedestal",
		},
		gateSign = {
			-- On the front face of the alcove (negative Z side), slightly outside
			position = Vector3.new(4.500, 6.0, 1.594), -- x = alcove center x, y = alcove center y, z = alcove front face z (alcove center z - alcove size.Z/2) - 0.2? alcove front face z = 7.794 - 6 = 1.794, we place at 1.594 (0.2 outside)
			size = Vector3.new(4, 2, 0.2),
			material = Enum.Material.Metal,
			color = Color3.fromRGB(255, 225, 77), -- canary yellow (interactive)
			name = "PartyPassGateSign",
		},
	},
	-- Map Voting circle center: 3 glowing floor pads + STATUS screen above (dead ahead, north)
	mapVotingCircle = {
		pads = {
			{
				-- Pad 1: west of north (angle 60 deg west of north)
				position = Vector3.new(-8.660, 1.1, 5.000), -- x = -R*sin(60), z = R*cos(60), R=10, y = 1 + size.Y/2 = 1+0.1=1.1
				size = Vector3.new(4, 0.2, 4),
				material = Enum.Material.Neon,
				color = Color3.fromRGB(95, 227, 211), -- teal (interactive)
				name = "VotePad1",
			},
			{
				-- Pad 2: due north (angle 0 deg)
				position = Vector3.new(0.000, 1.1, 10.000),
				size = Vector3.new(4, 0.2, 4),
				material = Enum.Material.Neon,
				color = Color3.new(1, 1, 1), -- white (interactive)
				name = "VotePad2",
			},
			{
				-- Pad 3: east of north (angle 60 deg east of north, i.e., -60 deg west of north)
				position = Vector3.new(8.660, 1.1, 5.000), -- x = -R*sin(-60) = -R*(-0.866)= +R*0.866, z = R*cos(-60)= R*0.5
				size = Vector3.new(4, 0.2, 4),
				material = Enum.Material.Neon,
				color = Color3.fromRGB(255, 225, 77), -- yellow (interactive)
				name = "VotePad3",
			},
		},
		statusScreen = {
			position = Vector3.new(0.000, 5.0, 10.000), -- above the voting circle
			size = Vector3.new(8, 4, 0.2),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(35, 43, 69), -- deep cosmic navy
			name = "StatusScreen",
		},
	},
	-- Winner Podium center: tiered podium (rear 180° = south)
	winnerPodium = {
		base = {
			position = Vector3.new(0.000, 2.0, -14.000), -- due south, radius 14
			size = Vector3.new(12, 2, 12),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75), -- grass green (same as floor)
			name = "PodiumBase",
		},
		mid = {
			position = Vector3.new(0.000, 4.0, -14.000), -- on top of base
			size = Vector3.new(8, 2, 8),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75),
			name = "PodiumMid",
		},
		top = {
			position = Vector3.new(0.000, 6.0, -14.000), -- on top of mid
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(106, 190, 75),
			name = "PodiumTop",
		},
	},
	-- AFK & Coin Obby Arena front strip: decorative parkour strip (flanking the Winner Podium at the player's feet)
	afkCoinObbyArena = {
		-- We'll make a strip from west to east at the south, just in front of the Winner Podium (so north of the Winner Podium? but still south of spawn)
		-- We'll put it at z = -6 (so 8 studs north of the Winner Podium which is at z=-14)
		-- and from x = -10 to x = 10 in steps? We'll make three parts for simplicity.
		{
			position = Vector3.new(-10.000, 2.0, -6.000),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77), -- canary yellow (interactive)
			name = "ObbyStripWest",
		},
		{
			position = Vector3.new(0.000, 2.0, -6.000),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77),
			name = "ObbyStripCenter",
		},
		{
			position = Vector3.new(10.000, 2.0, -6.000),
			size = Vector3.new(4, 2, 4),
			material = Enum.Material.SmoothPlastic,
			color = Color3.fromRGB(255, 225, 77),
			name = "ObbyStripEast",
		},
	},
	-- Existing landmark (re-skinned)
	tlandmark = {
		position = Vector3.new(0, 11, 40),
		size = Vector3.new(5, 20, 5),
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
