-- Lobby Hub map init: builder/cleaner for lobby geometry and spawn.
local Workspace = game:GetService("Workspace")

local config = require(script.config)

local LobbyHub = {}
LobbyHub._parts = {} -- tracks created parts for cleanup
LobbyHub._spawnLocation = nil

function LobbyHub.init()
	-- central disc
	local disc = Instance.new("Part")
	disc.Size = config.centralDisc.size
	disc.Position = config.centralDisc.position
	disc.Material = config.centralDisc.material
	disc.BrickColor = config.centralDisc.color
	disc.Anchored = true
	disc.Name = "LobbyCentralDisc"
	disc.Parent = Workspace
	table.insert(LobbyHub._parts, disc)

	-- satellite pads
	for i, padCfg in ipairs(config.satellitePads) do
		local pad = Instance.new("Part")
		pad.Size = padCfg.size
		pad.Position = padCfg.position
		pad.Material = padCfg.material
		pad.BrickColor = padCfg.color
		pad.Anchored = true
		pad.Name = "LobbySatellitePad_" .. i
		pad.Parent = Workspace
		table.insert(LobbyHub._parts, pad)
	end

	-- landmark
	local landmark = Instance.new("Part")
	landmark.Size = config.landmark.size
	landmark.Position = config.landmark.position
	landmark.Material = config.landmark.material
	landmark.BrickColor = config.landmark.color
	landmark.Anchored = true
	landmark.Name = "LobbyLandmark"
	landmark.Parent = Workspace
	table.insert(LobbyHub._parts, landmark)

	-- SpawnLocation for players
	local spawn = Instance.new("SpawnLocation")
	spawn.CFrame = config.lobbySpawn
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.Material = Enum.Material.Grass
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright green")
	spawn.Name = "LobbySpawn"
	spawn.Parent = Workspace
	LobbyHub._spawnLocation = spawn
end

function LobbyHub.cleanup()
	for _, part in ipairs(LobbyHub._parts) do
		if part.Parent then
			part:Destroy()
		end
	end
	LobbyHub._parts = {}

	if LobbyHub._spawnLocation and LobbyHub._spawnLocation.Parent then
		LobbyHub._spawnLocation:Destroy()
	end
	LobbyHub._spawnLocation = nil
end
return LobbyHub
