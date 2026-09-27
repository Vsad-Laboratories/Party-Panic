--!strict
-- lobby.luau — self-contained, self-connecting lobby HUD (Astro-Arcade Punk).
-- One ScreenGui that FLOATS over the live 3D lobby scene as a true HUD overlay:
-- no opaque full-screen fill (docs/UX.md anti-pattern #2 / rule #20). Readable via
-- small semi-transparent navy panels + accent strokes. State-driven only (no loops).
--
-- Skills applied: roblox-gui (ScreenGui/Scale/ScaleType/ResetOnSpawn), roblox-ui-design
-- (visual system, hierarchy, touch targets), roblox-luau-core (if-expr, 1-based),
-- roblox-luau-patterns (module ownership/cleanup, task.*), roblox-animations (tweens).
-- UX law: docs/UX.md (BuilderSans FontFace, TextScaled+UITextSizeConstraint, 150ms
-- tooltips, no mock data, no opaque overlay). Operator playtest report = spec.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local tokens = require(script.Parent.tokens)
local router = require(script.Parent.router)
local icons = require(script.Parent.icons)
local sounds = require(script.Parent.sounds)

type PlayerInfo = {
	userId: number,
	name: string,
}

-- Client view of the server LobbyStatePayload (src/shared/LobbyState.luau).
-- level/xp/xpForNext/coinCount are optional (backend wires them later); the HUD shows
-- an honest zero state (LV 1, 0 / 100, 0 coins) until real data lands.
type LobbyPayload = {
	state: string,
	countdown: number,
	players: { PlayerInfo },
	roundName: string,
	lastResult: { winnerUserId: number }?,
	level: number?,
	xp: number?,
	xpForNext: number?,
	coinCount: number?,
}

local MAX_PLAYERS = 12

-- Tooltip (GOAL b / docs/UX.md #24): 0.12s delay, 0.1s fade-in, instant hide on leave.
local TOOLTIP_DELAY = 0.12
local TOOLTIP_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

type ButtonSpec = {
	name: string,
	icon: string,
	label: string,
	accent: Color3,
}

type Lobby = {
	_screenGui: ScreenGui,
	_uiScale: UIScale,
	_background: Frame,
	_playerCountLabel: TextLabel,
	_levelNumberLabel: TextLabel,
	_levelFill: Frame,
	_progressLabel: TextLabel,
	_coinCountLabel: TextLabel,
	_tooltip: TextLabel,
	_tooltipTween: Tween?,
	_tooltipTask: thread?,
	_eventConn: RBXScriptConnection?,
	_resizeConn: RBXScriptConnection?,
	_build: (Lobby) -> (),
	_connect: (Lobby) -> (),
	_onPayload: (Lobby, LobbyPayload) -> (),
	_scheduleTooltip: (Lobby, text: string, xScale: number, yScale: number) -> (),
	_showTooltip: (Lobby, text: string, xScale: number, yScale: number) -> (),
	_hideTooltip: (Lobby) -> (),
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

local function newTextSizeConstraint(minSize: number, label: TextLabel): UITextSizeConstraint
	local tsc = Instance.new("UITextSizeConstraint")
	tsc.MinTextSize = minSize
	tsc.MaxTextSize = 32
	tsc.Parent = label
	return tsc
end

-- label: 1=heading, 2=panel text, 3=status over scene, 4=tooltip caption
local function newLabel(
	name: string,
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	textSize: number,
	color: Color3,
	anchorPoint: Vector2?,
	strokeTransparency: number?,
	font: Font?,
	minTextSize: number?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Parent = parent
	label.Position = position
	label.Size = size
	label.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.FontFace = font or tokens.fonts.body
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	-- dark navy stroke improves legibility over the live 3D scene (palette token)
	label.TextStrokeColor3 = tokens.palette.navy
	label.TextStrokeTransparency = strokeTransparency or 1
	newTextSizeConstraint(minTextSize or 14, label)
	return label
end

-- Icon button factory: 1:1 square ImageButton, ScaleType Fit, hover tint + hover sound,
-- press tint + click sound, and a scheduled tooltip. Wired through sounds.luau so no
-- button can miss feedback (GOAL a/f, Finding 5). Icon-only per docs/UX.md #30/#4
-- (the tooltip carries the friendly name, satisfying #30 without caption clutter).
local function newButton(
	name: string,
	parent: Instance,
	iconName: string,
	label: string,
	xScale: number,
	yScale: number,
	scale: number,
	accent: Color3,
	lobby: Lobby
): ImageButton
	local button = Instance.new("ImageButton")
	button.Name = name
	button.Parent = parent
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(xScale, yScale)
	button.Size = UDim2.fromScale(scale, scale)
	button.BackgroundColor3 = tokens.palette.navy
	button.BackgroundTransparency = 0.15
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Image = icons[iconName] or ""
	button.ScaleType = Enum.ScaleType.Fit
	button.ImageColor3 = tokens.palette.text
	newUICorner(tokens.radii.lg).Parent = button
	newStroke(accent, 1, 0.45).Parent = button

	button.MouseEnter:Connect(function()
		button.ImageColor3 = tokens.palette.canary
		sounds.playHover()
		lobby:_scheduleTooltip(label, xScale, yScale)
	end)
	button.MouseLeave:Connect(function()
		button.ImageColor3 = tokens.palette.text
		lobby:_hideTooltip()
	end)
	button.Activated:Connect(function()
		button.ImageColor3 = tokens.palette.pink
		sounds.playClick()
		lobby:_hideTooltip()
		-- restore icon tint after the pop click
		task.delay(0.1, function()
			if button and button.Parent then
				button.ImageColor3 = tokens.palette.text
			end
		end)
	end)

	return button
end

-- Lobby nav buttons (palette-safe: navy panels, teal/pink/canary accents) --------
-- Icons resolve via src/client/ui/icons.luau (placeholder IDs until Operator lands them).

local LEFT_BUTTONS: { ButtonSpec } = {
	{ name = "Inventory", icon = "Inventory", label = "Inventory", accent = tokens.palette.accent },
	{ name = "Shop", icon = "Shop", label = "Shop", accent = tokens.palette.pink },
	{ name = "Settings", icon = "Settings", label = "Settings", accent = tokens.palette.canary },
	{ name = "PartyPass", icon = "PartyPass", label = "Party Pass", accent = tokens.palette.accent },
	{ name = "Packs", icon = "Packs", label = "Packs", accent = tokens.palette.pink },
}

local RIGHT_BUTTONS: { ButtonSpec } = {
	{ name = "MiniGames", icon = "MiniGames", label = "Mini-Games", accent = tokens.palette.canary },
	{ name = "Maps", icon = "WorldMap", label = "Maps", accent = tokens.palette.accent },
	{ name = "Stats", icon = "Stats", label = "Stats", accent = tokens.palette.pink },
}

local function buildColumn(
	parent: Instance,
	buttons: { ButtonSpec },
	xCenter: number,
	startY: number,
	spacing: number,
	scale: number,
	lobby: Lobby
)
	for i, button in ipairs(buttons) do
		local btn = newButton(
			button.name .. "Button",
			parent,
			button.icon,
			button.label,
			xCenter,
			startY + (i - 1) * spacing,
			scale,
			button.accent,
			lobby
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
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.Parent = playerGui

	self._uiScale = Instance.new("UIScale")
	self._uiScale.Name = "ResponsiveScale"
	self._uiScale.Scale = 1
	self._uiScale.Parent = self._screenGui

	self:_build()
	self:_connect()

	-- Responsive scale: read AbsoluteSize after first layout (docs/UX.md #33 — never on
	-- the very first frame). The transparent _background is the resize sensor.
	self._resizeConn = self._background:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_refreshScale()
	end)
	task.defer(function()
		self:_refreshScale()
	end)

	return self
end

function Lobby._build(self: Lobby)
	local root = self._screenGui
	local p = tokens.palette

	-- Transparent HUD container: NO opaque fill (GOAL c). Lets the LobbyHub scene show
	-- through; panels/chips own their navy backdrops. Doubles as the AbsoluteSize sensor
	-- for UIScale (ScreenGui is not a GuiObject).
	self._background = Instance.new("Frame")
	self._background.Name = "Overlay"
	self._background.Parent = root
	self._background.Size = UDim2.fromScale(1, 1)
	self._background.BackgroundTransparency = 1
	self._background.BorderSizePixel = 0

	-- Title + status (top-center). BuilderSans heading/body (docs/UX.md #1/#5).
	newLabel(
		"Title",
		root,
		"PARTY PANIC",
		UDim2.fromScale(0.5, 0.04),
		UDim2.fromScale(0.6, 0.08),
		tokens.textSizes.title,
		p.accent,
		Vector2.new(0.5, 0.5),
		0.6,
		tokens.fonts.heading
	)
	newLabel(
		"Status",
		root,
		"Lobby — explore the hub!",
		UDim2.fromScale(0.5, 0.11),
		UDim2.fromScale(0.6, 0.045),
		tokens.textSizes.body,
		tokens.palette.text,
		Vector2.new(0.5, 0.5),
		0.6
	)

	-- Player-count pill (top-left)
	local playerPill = Instance.new("Frame")
	playerPill.Name = "PlayerCount"
	playerPill.Parent = root
	playerPill.Position = UDim2.fromScale(0.04, 0.05)
	playerPill.Size = UDim2.fromScale(0.13, 0.06)
	playerPill.BackgroundColor3 = p.base
	playerPill.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = playerPill
	newStroke(p.accent, 1, 0.55).Parent = playerPill

	self._playerCountLabel = newLabel(
		"Label",
		playerPill,
		"0 / " .. MAX_PLAYERS,
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromScale(0.9, 0.82),
		tokens.textSizes.pill,
		p.accent,
		Vector2.new(0.5, 0.5)
	)

	-- LEFT nav column — icon-only ImageButtons (icons.luau)
	buildColumn(root, LEFT_BUTTONS, 0.11, 0.18, 0.17, 0.11, self)
	-- RIGHT nav column
	buildColumn(root, RIGHT_BUTTONS, 0.89, 0.18, 0.18, 0.11, self)

	-- Bottom bar (compact, bottom thumb-zone): LV badge | level track | 0 / 100 | coins
	local barY = 0.91

	-- Level badge: Level icon + "LV 1"
	local levelBadge = Instance.new("Frame")
	levelBadge.Name = "LevelBadge"
	levelBadge.Parent = root
	levelBadge.Position = UDim2.fromScale(0.11, barY)
	levelBadge.Size = UDim2.fromScale(0.082, 0.044)
	levelBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	levelBadge.BackgroundColor3 = p.base
	levelBadge.BackgroundTransparency = 0.15
	levelBadge.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = levelBadge
	newStroke(p.accent, 1, 0.5).Parent = levelBadge

	local levelIcon = Instance.new("ImageLabel")
	levelIcon.Name = "LevelIcon"
	levelIcon.Parent = levelBadge
	levelIcon.AnchorPoint = Vector2.new(0, 0.5)
	levelIcon.Position = UDim2.fromScale(0.1, 0.5)
	levelIcon.Size = UDim2.fromScale(0.44, 0.7)
	levelIcon.BackgroundTransparency = 1
	levelIcon.BorderSizePixel = 0
	levelIcon.Image = icons["Level"] or ""
	levelIcon.ScaleType = Enum.ScaleType.Fit
	levelIcon.ImageColor3 = p.accent

	self._levelNumberLabel = newLabel(
		"LevelNumber",
		levelBadge,
		"LV 1",
		UDim2.fromScale(0.6, 0.5),
		UDim2.fromScale(0.38, 0.72),
		tokens.textSizes.caption,
		tokens.palette.text,
		Vector2.new(0, 0.5)
	)

	-- Level progress track + fill (compact, palette teal fill)
	local levelTrack = Instance.new("Frame")
	levelTrack.Name = "LevelTrack"
	levelTrack.Parent = root
	levelTrack.Position = UDim2.fromScale(0.33, barY)
	levelTrack.Size = UDim2.fromScale(0.28, 0.036)
	levelTrack.AnchorPoint = Vector2.new(0.5, 0.5)
	levelTrack.BackgroundColor3 = p.base
	levelTrack.BackgroundTransparency = 0.15
	levelTrack.BorderSizePixel = 0
	newUICorner(tokens.radii.sm).Parent = levelTrack
	newStroke(p.accent, 1, 0.55).Parent = levelTrack

	self._levelFill = Instance.new("Frame")
	self._levelFill.Name = "LevelFill"
	self._levelFill.Parent = levelTrack
	self._levelFill.Size = UDim2.fromScale(0, 1)
	self._levelFill.Position = UDim2.fromScale(0, 0.5)
	self._levelFill.AnchorPoint = Vector2.new(0, 0.5)
	self._levelFill.BackgroundColor3 = p.accent
	self._levelFill.BorderSizePixel = 0
	newUICorner(tokens.radii.sm).Parent = self._levelFill

	-- Progress text "0 / 100"
	local progressPill = Instance.new("Frame")
	progressPill.Name = "ProgressPill"
	progressPill.Parent = root
	progressPill.Position = UDim2.fromScale(0.52, barY)
	progressPill.Size = UDim2.fromScale(0.1, 0.04)
	progressPill.AnchorPoint = Vector2.new(0.5, 0.5)
	progressPill.BackgroundColor3 = p.base
	progressPill.BackgroundTransparency = 0.15
	progressPill.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = progressPill
	newStroke(p.accent, 1, 0.55).Parent = progressPill

	self._progressLabel = newLabel(
		"Progress",
		progressPill,
		"0 / 100",
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromScale(0.9, 0.8),
		tokens.textSizes.caption,
		tokens.palette.text,
		Vector2.new(0.5, 0.5)
	)

	-- Compact coin count: Coin icon (icons.luau) + number
	local coinFrame = Instance.new("Frame")
	coinFrame.Name = "CoinCount"
	coinFrame.Parent = root
	coinFrame.Position = UDim2.fromScale(0.7, barY)
	coinFrame.Size = UDim2.fromScale(0.11, 0.044)
	coinFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	coinFrame.BackgroundColor3 = p.base
	coinFrame.BackgroundTransparency = 0.15
	coinFrame.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = coinFrame
	newStroke(p.accent, 1, 0.55).Parent = coinFrame

	local coinIcon = Instance.new("ImageLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.Parent = coinFrame
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.Position = UDim2.fromScale(0.08, 0.5)
	coinIcon.Size = UDim2.fromScale(0.42, 0.7)
	coinIcon.BackgroundTransparency = 1
	coinIcon.BorderSizePixel = 0
	coinIcon.Image = icons["Coin"] or ""
	coinIcon.ScaleType = Enum.ScaleType.Fit
	coinIcon.ImageColor3 = tokens.palette.canary

	self._coinCountLabel = newLabel(
		"Count",
		coinFrame,
		"0",
		UDim2.fromScale(0.6, 0.5),
		UDim2.fromScale(0.38, 0.72),
		tokens.textSizes.caption,
		tokens.palette.text,
		Vector2.new(0, 0.5)
	)

	-- No perk chip: the perk system does not exist yet (Operator playtest report). It is
	-- re-added only when the backend ships real perk data — no mock chip anywhere.

	-- Hover tooltip (GOAL b): reused single label, non-blocking, ZIndex above all HUD.
	self._tooltip = Instance.new("TextLabel")
	self._tooltip.Name = "Tooltip"
	self._tooltip.Parent = root
	self._tooltip.BackgroundTransparency = 0.25
	self._tooltip.BackgroundColor3 = p.navy
	self._tooltip.BorderSizePixel = 0
	self._tooltip.Size = UDim2.fromOffset(200, 50)
	self._tooltip.TextColor3 = tokens.palette.text
	self._tooltip.TextStrokeColor3 = p.navy
	self._tooltip.TextStrokeTransparency = 0.55
	self._tooltip.FontFace = tokens.fonts.body
	self._tooltip.TextSize = tokens.textSizes.caption
	self._tooltip.TextScaled = true
	self._tooltip.TextWrapped = true
	self._tooltip.TextTransparency = 1
	self._tooltip.Visible = false
	self._tooltip.ZIndex = 100
	newUICorner(tokens.radii.md).Parent = self._tooltip
	newStroke(tokens.palette.canary, 1, 0.6).Parent = self._tooltip
	newTextSizeConstraint(12, self._tooltip)
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

	if payload.level then
		self._levelNumberLabel.Text = "LV " .. tostring(payload.level)
	end
	if payload.xp and payload.xpForNext then
		local nextThreshold = payload.xpForNext
		local pct = if nextThreshold > 0 then payload.xp / nextThreshold else 0
		self._levelFill.Size = UDim2.fromScale(math.clamp(pct, 0, 1), 1)
		self._progressLabel.Text = tostring(payload.xp) .. " / " .. tostring(payload.xpForNext)
	end
	if payload.coinCount then
		self._coinCountLabel.Text = tostring(payload.coinCount)
	end
end

-- Tooltip lifecycle (GOAL b): show after a 0.12s delay; hide instantly on leave. PC
-- hover only — MouseEnter/MouseLeave don't fire on touch. The tooltip sits beside the
-- button (never over it) so it cannot block clicks (docs/UX.md anti-pattern #2).
function Lobby._scheduleTooltip(self: Lobby, text: string, xScale: number, yScale: number)
	if self._tooltipTask then
		task.cancel(self._tooltipTask)
	end
	self._tooltipTask = task.delay(TOOLTIP_DELAY, function()
		self:_showTooltip(text, xScale, yScale)
	end)
end

function Lobby._showTooltip(self: Lobby, text: string, xScale: number, yScale: number)
	self._tooltip.Text = text
	-- Place to the side away from the screen edge so it never covers the button.
	if xScale < 0.5 then
		self._tooltip.Position = UDim2.fromScale(xScale + 0.11, yScale)
		self._tooltip.AnchorPoint = Vector2.new(0, 0.5)
	else
		self._tooltip.Position = UDim2.fromScale(xScale - 0.11, yScale)
		self._tooltip.AnchorPoint = Vector2.new(1, 0.5)
	end
	self._tooltip.Visible = true
	self._tooltip.TextTransparency = 1
	if self._tooltipTween then
		self._tooltipTween:Cancel()
	end
	self._tooltipTween = TweenService:Create(self._tooltip, TOOLTIP_TWEEN, { TextTransparency = 0 })
	self._tooltipTween:Play()
end

function Lobby._hideTooltip(self: Lobby)
	if self._tooltipTask then
		task.cancel(self._tooltipTask)
		self._tooltipTask = nil
	end
	if self._tooltipTween then
		self._tooltipTween:Cancel()
		self._tooltipTween = nil
	end
	self._tooltip.TextTransparency = 1
	self._tooltip.Visible = false
end

local function computeScale(screenHeight: number): number
	if screenHeight <= 0 then
		return 1
	end
	return math.clamp(screenHeight / 840, 0.55, 1)
end

function Lobby._refreshScale(self: Lobby)
	self._uiScale.Scale = computeScale(self._background.AbsoluteSize.Y)
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
