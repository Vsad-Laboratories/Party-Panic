-- Lobby Hub map config: pure data for lobby geometry and spawns.
-- Central disc + satellite pads + accent landmark.
local LobbyHubConfig = {
	centralDisc = {
		position = Vector3.new(0, 0, 0),
		size = Vector3.new(20, 2, 20),
		material = Enum.Material.Concrete,
		color = BrickColor.new("Medium stone grey"),
	},
	satellitePads = {
		{
			position = Vector3.new(17, 0, 0),
			size = Vector3.new(10, 2, 10),
			material = Enum.Material.Concrete,
			color = BrickColor.new("Medium stone grey"),
		},
		{
			position = Vector3.new(-17, 0, 0),
			size = Vector3.new(10, 2, 10),
			material = Enum.Material.Concrete,
			color = BrickColor.new("Medium stone grey"),
		},
		{
			position = Vector3.new(0, 0, 17),
			size = Vector3.new(10, 2, 10),
			material = Enum.Material.Concrete,
			color = BrickColor.new("Medium stone grey"),
		},
	},
	landmark = {
		position = Vector3.new(0, 5, 40),
		size = Vector3.new(5, 10, 5),
		material = Enum.Material.Metal,
		color = BrickColor.new("Bright blue"),
	},
	spawn = {
		size = Vector3.new(4, 1, 4),
		material = Enum.Material.Grass,
		color = BrickColor.new("Bright green"),
	},
	lobbySpawn = CFrame.new(0, 1.5, 0),
	spawnPoints = {
		Vector3.new(0, 1.5, 0),
		Vector3.new(6, 1.5, 0),
		Vector3.new(-6, 1.5, 0),
		Vector3.new(0, 1.5, 6),
		Vector3.new(0, 1.5, -6),
	},
}
return LobbyHubConfig
