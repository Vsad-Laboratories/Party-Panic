-- Lobby Hub map init: builder/cleaner for Astro-Arcade Punk theme.
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

local config = require(script.config)

local LobbyHub = {}
LobbyHub._parts = {} -- tracks all BaseParts created for cleanup
LobbyHub._guis = {} -- tracks GUI objects for cleanup
LobbyHub._spawnLocation = nil

-- Helper to create a part from a config description
local function createPart(description)
	local part = Instance.new("Part")
	part.Size = description.size
	part.Position = description.position
	part.Material = description.material or Enum.Material.SmoothPlastic
	part.BrickColor = description.color
			and BrickColor.new(description.color.R * 255, description.color.G * 255, description.color.B * 255)
		or BrickColor.new("Medium stone grey")
	part.Anchored = true
	part.Name = description.name or "Part"
	if description.shape then
		part.Shape = description.shape
	end
	part.Parent = Workspace
	table.insert(LobbyHub._parts, part)
	return part
end

-- Helper to load and clean an asset
local function loadAsset(assetId, parent)
	local asset = InsertService:LoadAsset(assetId)
	-- Remove any Script, LocalScript, ModuleScript descendants
	for _, descendant in ipairs(asset:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		end
	end
	-- Parent the asset
	asset.Parent = parent
	return asset
end

function LobbyHub.init()
	-- Central disc
	createPart(config.centralDisc)

	-- SpawnLocation for players
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = config.spawn.size
	spawn.Position = config.lobbySpawn.Position
	spawn.CFrame = config.lobbySpawn
	spawn.Material = config.spawn.material
	spawn.BrickColor =
		BrickColor.new(config.spawn.color.R * 255, config.spawn.color.G * 255, config.spawn.color.B * 255)
	spawn.Anchored = true
	spawn.Name = "LobbySpawn"
	spawn.Parent = Workspace
	LobbyHub._spawnLocation = spawn
	table.insert(LobbyHub._parts, spawn)

	-- Perimeter wall (approximated by multiple parts)
	local wall = config.perimeterWall
	local count = wall.count
	local innerRadius = wall.innerRadius
	local thickness = wall.thickness
	local height = wall.height
	-- We'll create the wall as a series of parts, each covering an arc of 360/count degrees
	-- Each part will be a rectangular box that approximates a section of the wall.
	-- We'll place each part so that its outer face is at radius innerRadius + thickness/2? Actually, we want the wall to be a hollow cylinder.
	-- We'll make each part a box that is thick in the radial direction, tall, and wide in the tangential direction.
	-- The width (tangential) of each part at the outer radius is approximately: (2 * pi * (innerRadius + thickness)) / count
	-- But we'll use the average radius for simplicity.
	local avgRadius = innerRadius + thickness / 2
	local arcLength = (2 * math.pi * avgRadius) / count
	for i = 1, count do
		local angle = (i - 1) * (2 * math.pi) / count
		-- Position of the center of this wall section (at the average radius)
		local x = avgRadius * math.cos(angle)
		local z = avgRadius * math.sin(angle)
		-- The part's size: radial thickness, height, and tangential width (arcLength)
		local partSize = Vector3.new(thickness, height, arcLength)
		-- The part's CFrame: we want it to be facing radially outward? Actually, we want the part to be oriented so that its width is tangential.
		-- We'll create the part at (x, height/2, z) and then rotate it so that its local X axis points radially outward?
		-- But we are setting Position and Size, and the part is axis-aligned. We need to rotate it.
		-- We'll set the part's CFrame to: CFrame.new(x, height/2, z) * CFrame.fromEulerAnglesYXZ(0, angle, 0) * CFrame.new(0, 0, -arcLength/2)
		-- Wait, we want the part to be tangential, so its length should be in the tangential direction.
		-- We'll set the part's Size to (thickness, height, arcLength) and then rotate it so that its local Z axis points tangential?
		-- Actually, we can set the part's CFrame to: CFrame.new(x, height/2, z) * CFrame.Angles(0, angle, 0)
		-- Then the part's local X is radial, local Y is up, local Z is tangential.
		-- So we set Size = Vector3.new(thickness, height, arcLength) and then the part will extend:
		--   in X: -thickness/2 to thickness/2 (radial)
		--   in Y: -height/2 to height/2 (vertical)
		--   in Z: -arcLength/2 to arcLength/2 (tangential)
		-- This will give us a box that is tangential.
		local part = Instance.new("Part")
		part.Size = partSize
		part.Position = Vector3.new(x, height / 2, z)
		part.Material = wall.material
		part.BrickColor = BrickColor.new(wall.color.R * 255, wall.color.G * 255, wall.color.B * 255)
		part.Anchored = true
		part.Name = "PerimeterWall_" .. i
		part.CFrame = part.CFrame * CFrame.Angles(0, angle, 0)
		part.Parent = Workspace
		table.insert(LobbyHub._parts, part)
	end

	-- Top rim (approximated by multiple parts)
	local rim = config.topRim
	count = rim.count
	innerRadius = rim.innerRadius
	thickness = rim.thickness
	height = rim.height
	avgRadius = innerRadius + thickness / 2
	arcLength = (2 * math.pi * avgRadius) / count
	for i = 1, count do
		local angle = (i - 1) * (2 * math.pi) / count
		local x = avgRadius * math.cos(angle)
		local z = avgRadius * math.sin(angle)
		local partSize = Vector3.new(thickness, height, arcLength)
		local part = Instance.new("Part")
		part.Size = partSize
		part.Position = Vector3.new(x, wall.height + height / 2, z) -- on top of the wall
		part.Material = rim.material
		part.BrickColor = BrickColor.new(rim.color.R * 255, rim.color.G * 255, rim.color.B * 255)
		part.Anchored = true
		part.Name = "TopRim_" .. i
		part.CFrame = part.CFrame * CFrame.Angles(0, angle, 0)
		part.Parent = Workspace
		table.insert(LobbyHub._parts, part)
	end

	-- Storefront Avenue booths
	for _, boothDesc in ipairs(config.storefrontAvenue) do
		createPart(boothDesc)
	end

	-- Battle Pass Grotto
	createPart(config.battlePassGrotto.alcove)
	createPart(config.battlePassGrotto.pedestal)

	-- Map Voting Circle
	-- Glowing floor pads
	for _, padDesc in ipairs(config.mapVotingCircle.pads) do
		createPart(padDesc)
	end
	-- Status screen part
	local statusScreenPart = createPart(config.mapVotingCircle.statusScreen)
	-- Add SurfaceGui for text display
	local statusGui = Instance.new("SurfaceGui")
	statusGui.Face = Enum.NormalId.Top
	statusGui.Adornee = statusScreenPart
	statusGui.Parent = statusScreenPart
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "STATUS"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextScaled = true
	textLabel.Parent = statusGui
	table.insert(LobbyHub._guis, statusGui)

	-- Winner Podium
	createPart(config.winnerPodium.base)
	createPart(config.winnerPodium.mid)
	createPart(config.winnerPodium.top)

	-- AFK & Coin Obby Arena
	for _, stripDesc in ipairs(config.afkCoinObbyArena) do
		createPart(stripDesc)
	end

	-- Landmark (re-skinned)
	createPart(config.landmark)

	-- Decorative assets (load and place)
	for _, assetDesc in pairs(config.decorAssets) do
		if assetDesc.id then
			local asset = loadAsset(assetDesc.id, Workspace)
			-- Set position if provided
			if assetDesc.position then
				-- Assume the asset has a PrimaryPart; if not, we set the asset's root position
				if asset.PrimaryPart then
					asset:SetPrimaryPartCFrame(CFrame.new(assetDesc.position))
				else
					asset:MoveTo(assetDesc.position)
				end
			end
			-- Add to parts for cleanup
			table.insert(LobbyHub._parts, asset)
		end
	end
end

function LobbyHub.cleanup()
	-- Destroy all tracked parts
	for _, part in ipairs(LobbyHub._parts) do
		if part.Parent then
			part:Destroy()
		end
	end
	LobbyHub._parts = {}
	-- Destroy tracked GUIs
	for _, gui in ipairs(LobbyHub._guis) do
		if gui.Parent then
			gui:Destroy()
		end
	end
	LobbyHub._guis = {}
	-- Destroy spawn location
	if LobbyHub._spawnLocation and LobbyHub._spawnLocation.Parent then
		LobbyHub._spawnLocation:Destroy()
	end
	LobbyHub._spawnLocation = nil
end

return LobbyHub
