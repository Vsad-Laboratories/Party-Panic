--!strict
-- lobby.luau — self-contained, self-connecting lobby HUD (Astro-Arcade Punk).
-- One ScreenGui that FLOATS over the live 3D lobby scene as a true HUD overlay:
-- no opaque full-screen fill (docs/UX.md anti-pattern #2 / rule #20). Readable via
-- small semi-transparent navy panels + accent strokes. State-driven only (no loops).
--
-- Skills applied: roblox-gui (ScreenGui/Scale/ScaleType/ResetOnSpawn), roblox-ui-design
-- (visual system, hierarchy, touch targets), roblox-luau-core (if-expr, 1-based),
-- roblox-luau-patterns (module ownership/cleanup, task.*), roblox-animations (tweens).
-- UX law: docs/UX.md (BuilderSans FontFace, TextScaled+UITextSizeConstraint, 120ms
-- tooltips per Operator spec, no mock data, no opaque overlay). Operator playtest
-- report = spec.
--
-- Geometry: every control is sized in px from tokens.controls and scaled by the single
-- ScreenGui UIScale. Never size a control with fromScale(w, w) — that makes a "square"
-- button rectangular on any non-square viewport, which is what left the icons floating
-- inside dead hitboxes.

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
	coinCount: number?,
}

-- Client view of the server LobbyStatePayload (src/shared/LobbyState.luau).
-- level/xp/xpForNext are optional (backend wires them later); the HUD shows an honest
-- zero state (LV 1, 0 / 100) until real data lands. Coins are NOT here: the state sync
-- is one FireAllClients broadcast, so coins ride on our own players[] entry.
type LobbyPayload = {
	state: string,
	countdown: number,
	players: { PlayerInfo },
	roundName: string,
	lastResult: { winnerUserId: number }?,
	level: number?,
	xp: number?,
	xpForNext: number?,
}

local MAX_PLAYERS = 12

-- Tooltip (GOAL b / Operator spec 0.12s, overrides docs/UX.md #23 150-200ms): 0.12s
-- delay, 0.1s fade-in, instant hide on leave.
local TOOLTIP_DELAY = 0.12
local TOOLTIP_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

type ButtonSpec = {
	name: string,
	icon: string,
	label: string,
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
	_childAddedConn: RBXScriptConnection?,
	_resizeConn: RBXScriptConnection?,
	_build: (Lobby) -> (),
	_connect: (Lobby) -> (),
	_onPayload: (Lobby, LobbyPayload) -> (),
	_scheduleTooltip: (Lobby, text: string, x: number, y: number, onLeft: boolean) -> (),
	_showTooltip: (Lobby, text: string, x: number, y: number, onLeft: boolean) -> (),
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

-- Icon button factory: the button rect IS the icon rect — one square px box under the
-- single UIScale, ScaleType Fit, so the clickable area and the visible glyph can never
-- drift apart (Operator: "the Icon and hitbox of buttons are not the same size"). Hover
-- tint + hover sound, press tint + click sound, and a scheduled tooltip. Wired through
-- sounds.luau so no button can miss feedback (GOAL a/f, Finding 5). Icon-only per
-- docs/UX.md #30/#4 (the tooltip carries the friendly name, satisfying #30 without
-- caption clutter). Uniform clean box: navy panel + transparency + UICorner, no
-- per-button stroke (Operator: buttons were "plain uniform boxes" with coloured accents
-- — now every button is the same rounded navy box with only the icon inside).
local function newButton(
	name: string,
	parent: Instance,
	iconName: string,
	label: string,
	position: UDim2,
	tooltipX: number,
	tooltipOnLeft: boolean,
	lobby: Lobby
): ImageButton
	local button = Instance.new("ImageButton")
	button.Name = name
	button.Parent = parent
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = position
	button.Size = UDim2.fromOffset(tokens.controls.button, tokens.controls.button)
	button.BackgroundColor3 = tokens.palette.navy
	button.BackgroundTransparency = 0.15
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Image = icons[iconName] or ""
	button.ScaleType = Enum.ScaleType.Fit
	button.ImageColor3 = tokens.palette.text
	newUICorner(tokens.radii.lg).Parent = button

	button.MouseEnter:Connect(function()
		button.ImageColor3 = tokens.palette.canary
		sounds.playHover()
		-- Rails anchor buttons at RAIL_CENTRE_Y, so position.Y.Offset is the button's
		-- own vertical offset from that line — the tooltip lines up with its button.
		lobby:_scheduleTooltip(label, tooltipX, position.Y.Offset, tooltipOnLeft)
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
	{ name = "Inventory", icon = "Inventory", label = "Inventory" },
	{ name = "Shop", icon = "Shop", label = "Shop" },
	{ name = "Settings", icon = "Settings", label = "Settings" },
	{ name = "PartyPass", icon = "PartyPass", label = "Party Pass" },
	{ name = "Packs", icon = "Packs", label = "Packs" },
}

local RIGHT_BUTTONS: { ButtonSpec } = {
	{ name = "MiniGames", icon = "MiniGames", label = "Mini-Games" },
	{ name = "Maps", icon = "WorldMap", label = "Maps" },
	{ name = "Stats", icon = "Stats", label = "Stats" },
}

-- Vertical rail: one pitch for every button, centred in the free band between the header
-- and the bottom bar, and mirrored edge margins (tokens.controls.edge). The old columns
-- each hardcoded their own start Y and their own spacing (0.16 left vs 0.18 right in
-- screen fractions), so the two rails disagreed and drifted with the aspect ratio.
--
-- 0.57 (not 0.5): a 5-button rail is 348px tall before scaling, so on a short viewport
-- (landscape phone, UIScale 0.57) a screen-centred rail ran its first button into the
-- top-left player pill. 0.57 centres it in the gap the header and bottom bar leave.
local RAIL_CENTRE_Y = 0.57

local function buildColumn(parent: Instance, buttons: { ButtonSpec }, fromRight: boolean, lobby: Lobby)
	local c = tokens.controls
	local pitch = c.button + c.buttonGap
	local centreX = c.edge + c.button / 2
	-- Tooltip sits just outside the rail, measured from the SCREEN edge: rail outer edge
	-- (edge + button) + gap. Never over the button, so it cannot eat clicks.
	local tooltipX = c.edge + c.button + c.tipGap
	-- Centre the whole column so a 5-button rail and a 3-button rail both look deliberate.
	local firstCentreY = -((#buttons - 1) * pitch + c.button) / 2

	for i, button in ipairs(buttons) do
		local y = firstCentreY + (i - 1) * pitch
		local x
		if fromRight then
			x = UDim2.new(1, -centreX, RAIL_CENTRE_Y, y)
		else
			x = UDim2.new(0, centreX, RAIL_CENTRE_Y, y)
		end
		local btn = newButton(
			button.name .. "Button",
			parent,
			button.icon,
			button.label,
			x,
			tooltipX,
			fromRight, -- left rail tooltips open rightwards, right rail leftwards
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
	-- Core UI safe insets (only honoured with IgnoreGuiInset): keeps the top-left player
	-- pill clear of the Roblox topbar and the bottom bar clear of the phone home bar
	-- (docs/UX.md #9 — thumb-zone safe area).
	self._screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
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
	local c = tokens.controls

	-- Transparent HUD container: NO opaque fill (GOAL c). Lets the LobbyHub scene show
	-- through; panels/chips own their navy backdrops. Doubles as the AbsoluteSize sensor
	-- for UIScale (ScreenGui is not a GuiObject).
	self._background = Instance.new("Frame")
	self._background.Name = "Overlay"
	self._background.Parent = root
	self._background.Size = UDim2.fromScale(1, 1)
	self._background.BackgroundTransparency = 1
	self._background.BorderSizePixel = 0

	-- Top band. Screen-inset safe (ScreenGui.ScreenInsets below) plus a symmetric
	-- tokens.controls.edge margin, so the player pill never lands under the Roblox
	-- topbar and the title/status never collide with it at 480x800. The two centred
	-- labels span the width between the margins and sit in their own band BELOW the pill.
	local topY = c.edge
	local bandW = 1
	local bandOff = -c.edge * 2

	-- Title + status (top-center). BuilderSans heading/body (docs/UX.md #1/#5).
	newLabel(
		"Title",
		root,
		"PARTY PANIC",
		UDim2.new(0.5, 0, 0, topY + 56),
		UDim2.new(bandW, bandOff, 0, 44),
		tokens.textSizes.title,
		p.accent,
		Vector2.new(0.5, 0),
		0.6,
		tokens.fonts.heading
	)
	newLabel(
		"Status",
		root,
		"Lobby — explore the hub!",
		UDim2.new(0.5, 0, 0, topY + 124),
		UDim2.new(bandW, bandOff, 0, 26),
		tokens.textSizes.body,
		tokens.palette.text,
		Vector2.new(0.5, 0),
		0.6
	)

	-- Player-count pill (top-left)
	local playerPill = Instance.new("Frame")
	playerPill.Name = "PlayerCount"
	playerPill.Parent = root
	playerPill.Position = UDim2.fromOffset(c.edge, topY)
	playerPill.Size = UDim2.fromOffset(88, c.chipHeight)
	playerPill.BackgroundColor3 = p.base
	playerPill.BorderSizePixel = 0
	newUICorner(tokens.radii.full).Parent = playerPill
	newStroke(p.accent, 1, 0.55).Parent = playerPill

	self._playerCountLabel = newLabel(
		"Label",
		playerPill,
		"0 / " .. MAX_PLAYERS,
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromOffset(88 - tokens.spacing.sm * 2, c.chipHeight - tokens.spacing.sm * 2),
		tokens.textSizes.body,
		p.accent,
		Vector2.new(0.5, 0.5)
	)

	-- LEFT nav column — icon-only ImageButtons (icons.luau)
	buildColumn(root, LEFT_BUTTONS, false, self)
	-- RIGHT nav column
	buildColumn(root, RIGHT_BUTTONS, true, self)

	-- Bottom bar: LV badge | progress track | 0/100 pill | coin pill. ONE owner for the
	-- row: a UIListLayout inside a bottom-anchored bar that auto-sizes to its content, so
	-- the gaps are uniform by construction and the group stays centred at any width.
	-- The old build hand-computed four centre offsets from a comment (0.225 / 0.426 /
	-- 0.636 / 0.761) in screen fractions: the group was ~250px wide on a phone but ~540px
	-- on 16:9 desktop, and any text change moved chips independently.
	local bar = Instance.new("Frame")
	bar.Name = "BottomBar"
	bar.Parent = root
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -c.edge)
	bar.Size = UDim2.fromOffset(0, c.chipHeight)
	bar.AutomaticSize = Enum.AutomaticSize.X -- content owns the width
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0

	local barFlow = Instance.new("UIListLayout")
	barFlow.FillDirection = Enum.FillDirection.Horizontal
	barFlow.HorizontalAlignment = Enum.HorizontalAlignment.Center
	barFlow.SortOrder = Enum.SortOrder.LayoutOrder -- visual order, not alphabetical
	barFlow.Padding = UDim.new(0, c.chipGap)
	barFlow.Parent = bar

	-- Icon slot inside a chip: square, or the art letterboxes (the old 0.42 x 0.7 slot
	-- squeezed a square PNG into a wide gap and left dead space before the text).
	local function newChipIcon(chip: Frame, iconName: string, tint: Color3): ImageLabel
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Parent = chip
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.fromOffset(tokens.spacing.sm, 0)
		icon.Size = UDim2.fromOffset(c.chipIcon, c.chipIcon)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.Image = icons[iconName] or ""
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ImageColor3 = tint
		return icon
	end

	-- Chip chrome: one height, one padding, one icon+label rhythm for all four chips.
	-- Width is the only content-shaped value (it follows the text the chip holds).
	local function newChip(name: string, width: number, order: number, iconName: string?, tint: Color3?): Frame
		local chip = Instance.new("Frame")
		chip.Name = name
		chip.LayoutOrder = order
		chip.Parent = bar
		chip.Size = UDim2.fromOffset(width, c.chipHeight)
		chip.BackgroundColor3 = p.base
		chip.BackgroundTransparency = 0.15
		chip.BorderSizePixel = 0
		newUICorner(tokens.radii.full).Parent = chip
		newStroke(p.accent, 1, 0.55).Parent = chip
		if iconName then
			newChipIcon(chip, iconName, tint or p.accent)
		end
		return chip
	end

	-- Label box after the icon slot: pad + icon + gap, mirrored on the right.
	local chipLabelX = tokens.spacing.sm + c.chipIcon + tokens.spacing.sm
	local chipLabelH = 28

	-- Level badge: Level icon + "LV 1"
	local levelBadge = newChip("LevelBadge", 96, 1, "Level", p.accent)

	self._levelNumberLabel = newLabel(
		"LevelNumber",
		levelBadge,
		"LV 1",
		UDim2.fromOffset(chipLabelX, 0),
		UDim2.fromOffset(96 - chipLabelX - tokens.spacing.sm, chipLabelH),
		tokens.textSizes.caption,
		tokens.palette.text,
		Vector2.new(0, 0.5)
	)

	-- Level progress track + fill (compact, palette teal fill)
	local levelTrack = newChip("LevelTrack", 120, 2)

	self._levelFill = Instance.new("Frame")
	self._levelFill.Name = "LevelFill"
	self._levelFill.Parent = levelTrack
	self._levelFill.Size = UDim2.fromScale(0, 1)
	self._levelFill.Position = UDim2.fromScale(0, 0.5)
	self._levelFill.AnchorPoint = Vector2.new(0, 0.5)
	self._levelFill.BackgroundColor3 = p.accent
	self._levelFill.BorderSizePixel = 0
	-- Pill radius to match the track: a 6px-cornered fill pokes out of a full-radius track.
	newUICorner(tokens.radii.full).Parent = self._levelFill

	-- Progress text "0 / 100" (no icon: the label is the whole chip)
	local progressPill = newChip("ProgressPill", 88, 3)

	self._progressLabel = newLabel(
		"Progress",
		progressPill,
		"0 / 100",
		UDim2.fromOffset(tokens.spacing.sm, 0),
		UDim2.fromOffset(88 - tokens.spacing.sm * 2, chipLabelH),
		tokens.textSizes.caption,
		tokens.palette.text,
		Vector2.new(0, 0.5)
	)

	-- Compact coin count: Coin icon (icons.luau) + number
	local coinFrame = newChip("CoinCount", 92, 4, "Coin", tokens.palette.canary)

	self._coinCountLabel = newLabel(
		"Count",
		coinFrame,
		"0",
		UDim2.fromOffset(chipLabelX, 0),
		UDim2.fromOffset(92 - chipLabelX - tokens.spacing.sm, chipLabelH),
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
	self._tooltip.Size = UDim2.fromOffset(120, 32)
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
	-- 14px floor, not 6: the tooltip is the ONLY name an icon-only button has
	-- (docs/UX.md #5/#29), so it must clear the readable minimum.
	newTextSizeConstraint(14, self._tooltip)
end

function Lobby._connect(self: Lobby)
	local function bind(event: RemoteEvent)
		if self._eventConn then
			self._eventConn:Disconnect()
			self._eventConn = nil
		end
		self._eventConn = event.OnClientEvent:Connect(function(payload: LobbyPayload)
			self:_onPayload(payload)
		end)
	end

	local function onChildAdded(child: Instance)
		if child.Name == "LobbyStateEvent" and child:IsA("RemoteEvent") then
			bind(child)
			if self._childAddedConn then
				self._childAddedConn:Disconnect()
				self._childAddedConn = nil
			end
		end
	end

	local existing = ReplicatedStorage:FindFirstChild("LobbyStateEvent")
	if existing ~= nil and existing:IsA("RemoteEvent") then
		bind(existing)
	else
		self._childAddedConn = ReplicatedStorage.ChildAdded:Connect(onChildAdded)
	end
end

function Lobby._onPayload(self: Lobby, payload: LobbyPayload)
	if typeof(payload) ~= "table" or typeof(payload.players) ~= "table" then
		return
	end
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
	-- Coins are per player: the broadcast is identical for everyone, so read our OWN
	-- entry out of players[] (root coinCount is never sent). Honest zero while absent.
	local localUserId = Players.LocalPlayer.UserId
	local coins: number = 0
	for _, entry in payload.players do
		if entry.userId == localUserId then
			coins = entry.coinCount or 0
			break
		end
	end
	self._coinCountLabel.Text = tostring(coins)
end

-- Tooltip lifecycle (GOAL b): show after a 0.12s delay; hide instantly on leave. PC
-- hover only — MouseEnter/MouseLeave don't fire on touch. The tooltip sits beside the
-- button (never over it) so it cannot block clicks. Anchored in px from the rail edge,
-- mirroring the edge margin — the old code offset by 0.11 of screen width, a value
-- hardcoded to the old button width.
function Lobby._scheduleTooltip(self: Lobby, text: string, x: number, y: number, onLeft: boolean)
	if self._tooltipTask then
		task.cancel(self._tooltipTask)
	end
	self._tooltipTask = task.delay(TOOLTIP_DELAY, function()
		self._tooltipTask = nil -- fired; never task.cancel a completed thread (review note)
		self:_showTooltip(text, x, y, onLeft)
	end)
end

function Lobby._showTooltip(self: Lobby, text: string, x: number, y: number, onLeft: boolean)
	self._tooltip.Text = text
	if onLeft then
		self._tooltip.Position = UDim2.new(1, -x, 0.5, y)
		self._tooltip.AnchorPoint = Vector2.new(1, 0.5)
	else
		self._tooltip.Position = UDim2.fromOffset(x, y)
		self._tooltip.AnchorPoint = Vector2.new(0, 0.5)
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
