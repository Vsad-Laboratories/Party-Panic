-- Lobby Hub map init: Lobby base v3 builder/cleaner (footprint x2, heights unchanged).
-- Spawn: ONE center SpawnLocation on the platform (deterministic).
-- 12 perimeter pads are plain anchored Parts (round-placement contract data only).
-- Dressing assets loaded via InsertService (scripts stripped per ASSETS.md).
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")

local config = require(script.config)

local LobbyHub = {}
LobbyHub._parts = {} -- every part created here is owned + destroyed by cleanup()
LobbyHub._assets = {} -- loaded asset models for cleanup

-- Flat cylinder: axis rotated to vertical so the circular face is in the X-Z plane
-- (Y == Z kept equal on purpose; unequal-cylinder rendering is engine-contested).
local function createDisc(description)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(description.thickness, description.diameter, description.diameter)
	part.CFrame = CFrame.new(description.position) * CFrame.Angles(0, 0, math.rad(90))
	part.Material = description.material
	part.Color = description.color
	part.Anchored = true
	part.Name = description.name
	part.Parent = Workspace
	table.insert(LobbyHub._parts, part)
	return part
end

-- Elliptical band of tangent-aligned boxes (wall, rim, ring, edge line share this).
-- Segment length = arc approximation chord*(1+step^2/6): the resulting ~0.04-stud
-- joint overlap hides hairline gaps at the outer face (same ratio the shipped
-- circular LobbyHub walls used). Coplanar overlap there is sub-cm and invisible.
local function createEllipseBand(spec)
	local step = (2 * math.pi) / spec.count
	local arcFactor = 1 + (step * step) / 6
	for i = 1, spec.count do
		local t0 = (i - 1) * step
		local t1 = i * step
		local p0 = Vector3.new(spec.a * math.cos(t0), 0, spec.b * math.sin(t0))
		local p1 = Vector3.new(spec.a * math.cos(t1), 0, spec.b * math.sin(t1))
		local mid = (p0 + p1) / 2
		local chord = p1 - p0
		local part = Instance.new("Part")
		part.Size = Vector3.new(spec.radialWidth, spec.height, chord.Magnitude * arcFactor)
		-- yaw so local Z follows the chord; local X ends up perpendicular (band width).
		part.CFrame = CFrame.new(mid.X, spec.y, mid.Z) * CFrame.Angles(0, math.atan2(chord.X, chord.Z), 0)
		part.Material = spec.material
		part.Color = spec.color
		part.Anchored = true
		part.Name = spec.name .. i
		part.Parent = Workspace
		table.insert(LobbyHub._parts, part)
	end
end

-- Load an asset, strip scripts, and place it at the given position.
local function loadAsset(assetId, parent, position)
	local asset = InsertService:LoadAsset(assetId)
	for _, descendant in ipairs(asset:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		end
	end
	if asset.PrimaryPart then
		asset:SetPrimaryPartCFrame(CFrame.new(position))
	else
		asset:MoveTo(position)
	end
	asset.Parent = parent
	table.insert(LobbyHub._assets, asset)
	return asset
end

function LobbyHub.init()
	-- Ground disc (top y=1) and central platform (top y=3)
	createDisc(config.groundDisc)
	createDisc(config.platform)

	-- Oval stage: wall, rim, decor ring, teal edge line
	createEllipseBand(config.perimeterWall)
	createEllipseBand(config.topRim)
	createEllipseBand(config.decorRing)
	createEllipseBand(config.ringEdge)

	-- ONE center SpawnLocation: the ONLY active spawn point.
	-- Deterministic spawn on the platform center (PR#17 spawn-stay).
	local cs = config.centerSpawn
	local centerSpawn = Instance.new("SpawnLocation")
	centerSpawn.Size = cs.size
	centerSpawn.CFrame = CFrame.new(cs.position)
	centerSpawn.Material = cs.material
	centerSpawn.Color = cs.color
	centerSpawn.Anchored = true
	centerSpawn.Neutral = cs.neutral
	centerSpawn.AllowTeamChangeOnTouch = cs.allowTeamChangeOnTouch
	centerSpawn.CanCollide = cs.canCollide
	centerSpawn.Transparency = cs.transparency
	centerSpawn.Name = cs.name
	centerSpawn.Parent = Workspace
	table.insert(LobbyHub._parts, centerSpawn)

	-- 12 perimeter pads: PLAIN ANCHORED PARTS (NOT SpawnLocations).
	-- Round-placement contract data for Placements; must NOT be where
	-- a joining player spawns (PR#17 spawn-stay).
	local ring = config.spawnRing
	for i = 1, ring.count do
		local theta = (i - 1) * (2 * math.pi) / ring.count
		local pos = Vector3.new(ring.a * math.cos(theta), ring.y, ring.b * math.sin(theta))
		local pad = Instance.new("Part")
		pad.Size = config.spawn.size
		pad.CFrame = CFrame.lookAt(pos, Vector3.new(0, ring.y, 0))
		pad.Material = config.spawn.material
		pad.Color = config.spawn.color
		pad.Anchored = true
		pad.CanCollide = false
		pad.Transparency = 0.7
		pad.Name = "PerimeterPad_" .. i
		pad.Parent = Workspace
		table.insert(LobbyHub._parts, pad)
	end

	-- Dressing assets (Batch 2, ASSETS.md). Scripts stripped on ingest.
	for _, category in pairs(config.dressingAssets) do
		for _, assetDesc in ipairs(category) do
			loadAsset(assetDesc.id, Workspace, assetDesc.position)
		end
	end

	-- Lighting setup (cozy low-poly daylight) and store original values
	LobbyHub._originalLighting = {
		Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		TimeOfDay = Lighting.TimeOfDay,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		GlobalShadows = Lighting.GlobalShadows,
		ShadowSoftness = Lighting.ShadowSoftness,
	}
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 200)
	Lighting.TimeOfDay = "14:00:00"
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.5

	local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not Atmosphere then
		Atmosphere = Instance.new("Atmosphere")
		Atmosphere.Parent = Lighting
	end
	LobbyHub._originalAtmosphere = {
		Density = Atmosphere.Density,
		Offset = Atmosphere.Offset,
		Color = Atmosphere.Color,
		Glare = Atmosphere.Glare,
		Haze = Atmosphere.Haze,
	}
	Atmosphere.Density = 0.3
	Atmosphere.Offset = 0.25
	Atmosphere.Color = Color3.fromRGB(190, 200, 255)
	Atmosphere.Glare = 0.2
	Atmosphere.Haze = 0.5
end

function LobbyHub.cleanup()
	-- Destroy all tracked parts
	for _, part in ipairs(LobbyHub._parts) do
		if part.Parent then
			part:Destroy()
		end
	end
	LobbyHub._parts = {}
	-- Destroy loaded assets
	for _, asset in ipairs(LobbyHub._assets) do
		if asset.Parent then
			asset:Destroy()
		end
	end
	LobbyHub._assets = {}
	-- Restore original lighting
	if LobbyHub._originalLighting then
		for k, v in pairs(LobbyHub._originalLighting) do
			Lighting[k] = v
		end
	end
	if LobbyHub._originalAtmosphere then
		local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if Atmosphere then
			for k, v in pairs(LobbyHub._originalAtmosphere) do
				Atmosphere[k] = v
			end
		end
	end
end

return LobbyHub
