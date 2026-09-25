--!strict
-- lobby.luau — self-contained, self-connecting lobby HUD (Astro-Arcade Punk).
-- Builds ONE ScreenGui, connects to the server LobbyStateEvent feed, re-renders on
-- state signals only (no per-frame loops). Implements the lobby screen layout from
-- docs/DESIGN.md (LEFT/RIGHT nav columns + bottom level bar). No vote UI, no
-- countdown UI — rounds start by player action (future task). Source: DESIGN.md +
-- docs/agents/UI.md.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tokens = require(script.Parent.tokens)
local router = require(script.Parent.router)

type PlayerInfo = {
	userId: number,
	name: string,
}

type LobbyPayload = {
	state: string,
	countdown: number,
	players: { PlayerInfo },
	roundName: string,
	lastResult: { winnerUserId: number }?,
}

local MAX_PLAYERS = 12

type ButtonSpec = {
	name: string,
	label: string,
	accent: Color3,
}

type Lobby = {
	_screenGui: ScreenGui,
	_uiScale: UIScale,
	_playerCountLabel: TextLabel,
	_coinCountLabel: TextLabel,
	_levelFill: Frame,
	_eventConn: RBXScriptConnection?,
	_resizeConn: RBXScriptConnection?,
	_build: (Lobby) -> (),
	_connect: (Lobby) -> (),
	_onPayload: (Lobby, LobbyPayload) -> (),
	_refreshScale: (Lobby) -> (),
}

-- UI helpers --------------------------------------------------------------

local function newUICorner(radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	return corner
end

local function newStroke(color: Color3, thickness: number, transparency: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	return stroke
end

local function newLabel(
	name: string,
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	textSize: number,
	color: Color3,
	anchorPoint: Vector2?,
	strokeTransparency: number?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Parent = parent
	label.Position = position
	label.Size = size
	label.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = tokens.fonts.body
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.TextStrokeTransparency = strokeTransparency or 1
	return label
end

local function newButton(
	name: string,
	parent: Instance,
	label: string,
	position: UDim2,
	size: UDim2,
	accent: Color3
): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Parent = parent
	button.Position = position
	button.Size = size
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = tokens.palette.navy
	button.BorderSizePixel = 0
	button.Font = tokens.fonts.body
	button.Text = label
	button.TextSize = tokens.textSizes.pill
	button.TextColor3 = accent
	button.TextScaled = true
	button.TextWrapped = true
	button.AutoButtonColor = true
	newUICorner(tokens.radii.lg).Parent = button
	newStroke(accent, 1, 0.55).Parent = button
	return button
end

-- Lobby nav buttons (palette-safe: navy panels, teal/pink/canary accents) --------

local LEFT_BUTTONS: { ButtonSpec } = {
	{ name = "Inventory", label = "INVENTORY", accent = tokens.palette.accent },
	{ name = "Shop", label = "SHOP", accent = tokens.palette.pink },
	{ name = "Settings", label = "SETTINGS", accent = tokens.palette.canary },
	{ name = "PartyPass", label = "PARTY PASS", accent = tokens.palette.accent },
	{ name = "Packs", label = "PACKS", accent = tokens.palette.pink },
}

local RIGHT_BUTTONS: { ButtonSpec } = {
	{ name = "MiniGames", label = "MINIGAMES", accent = tokens.palette.canary },
	{ name = "Maps", label = "MAPS", accent = tokens.palette.accent },
	{ name = "Stats", label = "STATS", accent = tokens.palette.pink },
}

local function buildColumn(
	parent: Instance,
	buttons: { ButtonSpec },
	xCenter: number,
	startY: number,
	spacing: number,
	size: UDim2
)
	for i, button in ipairs(buttons) do
		local btn = newButton(
			button.name .. "Button",
			parent,
			button.label,
			UDim2.fromScale(xCenter, startY + (i - 1) * spacing),
			size,
			button.accent
		)
		btn.Activated:Connect(function()
			router.open(button.name)
		end)
	end
end

-- Lobby HUD ----------------------------------------------------------------

local Lobby = {}
Lobby.__index = Lobby

function Lobby.new(): Lobby
	local self = {} :: Lobby
	setmetatable(self, Lobby)

	local player = assert(Players.LocalPlayer, "LocalPlayer is not available")
	local playerGui = player:WaitForChild("PlayerGui")

	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "PartyPanicLobby"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.IgnoreGuiInset = true
	self._screenGui.DisplayOrder = 0
	self._screenGui.Size = UDim2.fromScale(1, 1)
	self._screenGui.Parent = playerGui

	self._uiScale = Instance.new("UIScale")
	self._uiScale.Name = "ResponsiveScale"
	self._uiScale.Scale = 1
	self._uiScale.Parent = self._screenGui

	self:_build()
	self:_connect()

	self._resizeConn = self._screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_refreshScale()
	end)
	self:_refreshScale()

	return self
end

function Lobby._build(self: Lobby)
	local root = self._screenGui
	local p = tokens.palette

	-- Full-bleed background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Parent = root
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = p.navy
	background.BorderSizePixel = 0

	-- Title + status (top-center)
	newLabel(
		"Title",
		root,
		"PARTY PANIC",
		UDim2.fromScale(0.5, 0.05),
		UDim2.fromScale(0.8, 0.1),
		tokens.textSizes.title,
		p.accent,
		Vector2.new(0.5, 0.5)
	)
	newLabel(
		"Status",
		root,
		"Lobby — explore the hub!",
		UDim2.fromScale(0.5, 0.16),
		UDim2.fromScale(0.8, 0.045),
		tokens.textSizes.body,
		tokens.palette.text,
		Vector2.new(0.5, 0.5)
	)

	-- Player-count pill (top-left)
	local playerPill = Instance.new("Frame")
	playerPill.Name = "PlayerCount"
	playerPill.Parent = root
	playerPill.Position = UDim2.fromScale(0.04, 0.055)
	playerPill.Size = UDim2.fromScale(0.14, 0.06)
	playerPill.AnchorPoint = Vector2.new(0, 0)
	playerPill.BackgroundColor3 = p.base
	playerPill.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = playerPill
	newStroke(p.accent, 1, 0.55).Parent = playerPill

	self._playerCountLabel = newLabel(
		"Label",
		playerPill,
		"0 / " .. MAX_PLAYERS,
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromScale(0.9, 0.8),
		tokens.textSizes.pill,
		p.accent,
		Vector2.new(0.5, 0.5)
	)

	-- LEFT nav column
	buildColumn(root, LEFT_BUTTONS, 0.1, 0.18, 0.15, UDim2.fromScale(0.13, 0.13))

	-- RIGHT nav column
	buildColumn(root, RIGHT_BUTTONS, 0.9, 0.2, 0.18, UDim2.fromScale(0.13, 0.13))

	-- Bottom bar: coin (left) + level progress (center) + perk chip (right)
	local coinIcon = Instance.new("Frame")
	coinIcon.Name = "CoinIcon"
	coinIcon.Parent = root
	coinIcon.Position = UDim2.fromScale(0.235, 0.86)
	coinIcon.Size = UDim2.fromScale(0.034, 0.034)
	coinIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	coinIcon.BackgroundColor3 = tokens.palette.canary
	coinIcon.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = coinIcon

	self._coinCountLabel = newLabel(
		"CoinCount",
		root,
		"0",
		UDim2.fromScale(0.29, 0.86),
		UDim2.fromScale(0.08, 0.034),
		tokens.textSizes.caption,
		tokens.palette.text,
		Vector2.new(0, 0.5)
	)

	local levelTrack = Instance.new("Frame")
	levelTrack.Name = "LevelTrack"
	levelTrack.Parent = root
	levelTrack.Position = UDim2.fromScale(0.5, 0.91)
	levelTrack.Size = UDim2.fromScale(0.52, 0.04)
	levelTrack.AnchorPoint = Vector2.new(0.5, 0.5)
	levelTrack.BackgroundColor3 = p.base
	levelTrack.BorderSizePixel = 0
	newUICorner(tokens.radii.lg).Parent = levelTrack
	newStroke(p.accent, 1, 0.6).Parent = levelTrack

	self._levelFill = Instance.new("Frame")
	self._levelFill.Name = "LevelFill"
	self._levelFill.Parent = levelTrack
	self._levelFill.Size = UDim2.fromScale(0, 1)
	self._levelFill.Position = UDim2.fromScale(0, 0.5)
	self._levelFill.AnchorPoint = Vector2.new(0, 0.5)
	self._levelFill.BackgroundColor3 = p.accent
	self._levelFill.BorderSizePixel = 0
	newUICorner(tokens.radii.lg).Parent = self._levelFill

	local perkChip = Instance.new("Frame")
	perkChip.Name = "PerkChip"
	perkChip.Parent = root
	perkChip.Position = UDim2.fromScale(0.765, 0.86)
	perkChip.Size = UDim2.fromScale(0.22, 0.036)
	perkChip.AnchorPoint = Vector2.new(0.5, 0.5)
	perkChip.BackgroundColor3 = tokens.palette.pink
	perkChip.BorderSizePixel = 0
	newUICorner(tokens.radii.md).Parent = perkChip

	newLabel(
		"Label",
		perkChip,
		"Bloody Aura: 5x Coins",
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromScale(0.92, 0.85),
		tokens.textSizes.caption,
		tokens.palette.navy,
		Vector2.new(0.5, 0.5)
	)
end

function Lobby._connect(self: Lobby)
	local function bind(event: RemoteEvent)
		self._eventConn = event.OnClientEvent:Connect(function(payload: LobbyPayload)
			self:_onPayload(payload)
		end)
	end

	local existing = ReplicatedStorage:FindFirstChild("LobbyStateEvent")
	if existing ~= nil and existing:IsA("RemoteEvent") then
		bind(existing)
	else
		ReplicatedStorage.ChildAdded:Connect(function(child: Instance)
			if child.Name == "LobbyStateEvent" and child:IsA("RemoteEvent") then
				bind(child)
			end
		end)
	end
end

function Lobby._onPayload(self: Lobby, payload: LobbyPayload)
	self._playerCountLabel.Text = #payload.players .. " / " .. MAX_PLAYERS
end

local function computeScale(screenHeight: number): number
	if screenHeight <= 0 then
		return 1
	end
	return math.clamp(screenHeight / 840, 0.55, 1)
end

function Lobby._refreshScale(self: Lobby)
	self._uiScale.Scale = computeScale(self._screenGui.AbsoluteSize.Y)
end

local active: Lobby? = nil

function Lobby.start(): Lobby
	if active then
		return active
	end
	active = Lobby.new()
	return active
end

return Lobby
