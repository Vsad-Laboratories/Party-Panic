--!strict
-- lobby.luau — self-contained, self-connecting lobby HUD (Astro-Arcade Punk).
-- Builds ONE ScreenGui and connects to the server LobbyStateEvent feed; re-renders
-- on state signals only (no per-frame loops). Foundation skeleton: no vote UI,
-- no countdown UI — rounds start by player action (future task).
-- Source of truth: docs/DESIGN.md + docs/agents/UI.md.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tokens = require(script.Parent.tokens)

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

type Lobby = {
	_screenGui: ScreenGui,
	_uiScale: UIScale,
	_playerCountLabel: TextLabel,
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
	playerPill.Position = UDim2.fromScale(0.04, 0.06)
	playerPill.Size = UDim2.fromScale(0.2, 0.07)
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

	-- Coin counter placeholder (top-right)
	local coinPill = Instance.new("Frame")
	coinPill.Name = "Coins"
	coinPill.Parent = root
	coinPill.Position = UDim2.fromScale(0.96, 0.06)
	coinPill.Size = UDim2.fromScale(0.2, 0.07)
	coinPill.AnchorPoint = Vector2.new(1, 0)
	coinPill.BackgroundColor3 = p.base
	coinPill.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = coinPill
	newStroke(p.accent, 1, 0.55).Parent = coinPill

	newLabel(
		"Label",
		coinPill,
		"0",
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromScale(0.9, 0.8),
		tokens.textSizes.pill,
		p.accent,
		Vector2.new(0.5, 0.5)
	)

	-- Bottom thumb-zone (reserved, empty — future buttons)
	local thumbZone = Instance.new("Frame")
	thumbZone.Name = "ThumbZone"
	thumbZone.Parent = root
	thumbZone.Position = UDim2.fromScale(0.5, 0.93)
	thumbZone.Size = UDim2.fromScale(0.9, 0.12)
	thumbZone.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbZone.BackgroundColor3 = p.base
	thumbZone.BorderSizePixel = 0
	thumbZone.BackgroundTransparency = 0.55
	newUICorner(tokens.radii.lg).Parent = thumbZone
	newStroke(p.accent, 1, 0.65).Parent = thumbZone
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
	local playerCount = #payload.players
	self._playerCountLabel.Text = playerCount .. " / " .. MAX_PLAYERS
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
