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
			position = Vector3.new(30, 0, 0),
			size = Vector3.new(10, 2, 10),
			material = Enum.Material.Concrete,
			color = BrickColor.new("Medium stone grey"),
		},
		{
			position = Vector3.new(-15, 0, 26),
			size = Vector3.new(10, 2, 10),
			material = Enum.Material.Concrete,
			color = BrickColor.new("Medium stone grey"),
		},
		{
			position = Vector3.new(-15, 0, -26),
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
	lobbySpawn = CFrame.new(0, 3, 0),
	spawnPoints = {
		Vector3.new(0, 3, 0),
		Vector3.new(10, 3, 0),
		Vector3.new(-10, 3, 0),
		Vector3.new(0, 3, 10),
		Vector3.new(0, 3, -10),
	},
}
return LobbyHubConfig
