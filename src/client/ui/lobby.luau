--!strict
-- lobby.luau — self-contained, self-connecting lobby HUD (Astro-Arcade Punk).
-- One ScreenGui FLOATS over the live 3D lobby scene as a true HUD overlay: no opaque
-- full-screen fill (docs/UX.md anti-pattern #2). Readable via semi-transparent navy
-- panels + strokes. State-driven only (no loops).
--
-- Bottom status group: a CENTERED, doubled-height level bar with the level counter,
-- XP track and 0/100 inside it; a coin pill above-LEFT (auto-width, never truncates);
-- an equipped-auras/effects list above-RIGHT (hidden when empty).
--
-- Icons come from the 104056199975187 HUD atlas via icons.apply (ImageRectOffset/Size,
-- ScaleType Fit) so every icon is pixel-centered in its square hitbox with zero letterbox.
-- At init the atlas + both pop sounds are ContentProvider-preloaded.
-- Skills: roblox-gui (ScreenGui/reset/scale/atlas), roblox-ui-design (hierarchy,
-- touch targets, legibility), roblox-luau-core (if-expr), roblox-animations (fade tween),
-- roblox-datastores/roblox-monetization (replicated profile state).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local tokens = require(script.Parent.tokens)
local router = require(script.Parent.router)
local icons = require(script.Parent.icons)
local sounds = require(script.Parent.sounds)
local MonetizationConfig = require(script.Parent.MonetizationConfig)
local Profile = require(script.Parent.Profile)

type PlayerInfo = {
	userId: number,
	name: string,
}

-- Client view of the server LobbyStatePayload (src/shared/LobbyState.luau). level/xp
-- are optional; coinCount/ownedPasses/equipped are replicated by the server and drive
-- the HUD. Honest zero state (LV 1, 0 / 100, 0 coins) until real data lands.
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
	ownedPasses: { number }?,
	equipped: { crown: string?, title: string?, trail: string?, auras: { string } }?,
}

local MAX_PLAYERS = 12

-- Tooltip (0.12s delay, 0.1s fade, instant hide): per Operator spec. Untouched by the
-- bottom-bar redesign.
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
	_levelBar: Frame,
	_levelNumberLabel: TextLabel,
	_levelFill: Frame,
	_progressLabel: TextLabel,
	_coinPill: Frame,
	_coinCountLabel: TextLabel,
	_effectList: Frame,
	_effectLayout: UIListLayout,
	_tooltip: TextLabel,
	_tooltipTween: Tween?,
	_tooltipTask: thread?,
	_eventConn: RBXScriptConnection?,
	_resizeConn: RBXScriptConnection?,
	_build: (Lobby) -> (),
	_connect: (Lobby) -> (),
	_onPayload: (Lobby, LobbyPayload) -> (),
	_refreshEffectList: (Lobby) -> (),
	_scheduleTooltip: (Lobby, text: string, xScale: number, yScale: number) -> (),
	_showTooltip: (Lobby, text: string, xScale: number, yScale: number) -> (),
	_hideTooltip: (Lobby) -> (),
	_refreshScale: (Lobby) -> (),
}

-- UI helpers --------------------------------------------------------------

local function newUICorner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function newStroke(parent: Instance, color: Color3, thickness: number, transparency: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.Parent = parent
	return stroke
end

local function newTextSizeConstraint(minSize: number, label: TextLabel): UITextSizeConstraint
	local tsc = Instance.new("UITextSizeConstraint")
	tsc.MinTextSize = minSize
	tsc.MaxTextSize = 26
	tsc.Parent = label
	return tsc
end

-- newLabel: a readable TextLabel (BuilderSans via tokens.fonts). stroke helps over the
-- live 3D scene; TextScaled + TextSizeConstraint keeps it legible at mobile scale.
local function newLabel(
	name: string,
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	textSize: number,
	color: Color3,
	anchorPoint: Vector2?,
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
	label.TextStrokeColor3 = tokens.palette.navy
	label.TextStrokeTransparency = 0.6
	newTextSizeConstraint(minTextSize or 12, label)
	return label
end

-- Icon button factory: 1:1 square ImageButton using the atlas (icons.apply sets
-- Image + ImageRectOffset + ImageRectSize + ScaleType Fit -> pixel-centered, zero
-- letterbox). Navy panel + transparency + UICorner = uniform clean box, NO per-button
-- accent stroke. Hover tint + hover sound, press tint + click sound, scheduled tooltip.
-- Wired through sounds.luau so no button can miss feedback.
local function newButton(
	name: string,
	parent: Instance,
	iconName: string,
	label: string,
	xScale: number,
	yScale: number,
	scale: number,
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
	icons.apply(button, iconName)
	button.ImageColor3 = tokens.palette.text
	newUICorner(button, tokens.radii.lg)

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
		task.delay(0.1, function()
			if button and button.Parent then
				button.ImageColor3 = tokens.palette.text
			end
		end)
	end)

	return button
end

-- Lobby nav columns (icon-only, uniform boxes). ---------------------------------
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

local function buildColumn(
	parent: Instance,
	buttons: { ButtonSpec },
	xCenter: number,
	startY: number,
	spacing: number,
	size: number,
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
			size,
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

	-- Preload the HUD atlas + pop sounds so they are ready at first paint
	-- (Operator: launch slow, icons/sfx took 10+ seconds). Safe no-ops if the
	-- content provider can't resolve yet.
	pcall(function()
		ContentProvider:PreloadAsync({ icons.ATLAS_ID })
	end)
	sounds.preload()

	-- Resize sensor: ScreenGui isn't a GuiObject, so the transparent _background
	-- Frame carries the AbsoluteSize signal. Defer until after first layout.
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

	-- Transparent overlay: NO opaque fill (lets the LobbyHub scene show through). Also
	-- the AbsoluteSize resize sensor for UIScale.
	self._background = Instance.new("Frame")
	self._background.Name = "Overlay"
	self._background.Parent = root
	self._background.Size = UDim2.fromScale(1, 1)
	self._background.BackgroundTransparency = 1
	self._background.BorderSizePixel = 0

	-- Title + status (top-center). BuilderSans heading/body.
	newLabel(
		"Title",
		root,
		"PARTY PANIC",
		UDim2.fromScale(0.5, 0.04),
		UDim2.fromScale(0.6, 0.08),
		tokens.textSizes.title,
		p.accent,
		Vector2.new(0.5, 0.5),
		tokens.fonts.heading
	)
	newLabel(
		"Status",
		root,
		"Lobby — explore the hub!",
		UDim2.fromScale(0.5, 0.11),
		UDim2.fromScale(0.6, 0.045),
		tokens.textSizes.body,
		p.text,
		Vector2.new(0.5, 0.5)
	)

	-- Player-count pill (top-left).
	local playerPill = Instance.new("Frame")
	playerPill.Name = "PlayerCount"
	playerPill.Parent = root
	playerPill.Position = UDim2.fromScale(0.04, 0.05)
	playerPill.Size = UDim2.fromScale(0.13, 0.06)
	playerPill.BackgroundColor3 = p.base
	playerPill.BorderSizePixel = 0
	newUICorner(playerPill, tokens.radii.full)
	newStroke(playerPill, p.accent, 1, 0.55)

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

	-- LEFT/RIGHT nav columns — uniform icon boxes.
	buildColumn(root, LEFT_BUTTONS, 0.11, 0.18, 0.16, 0.11, self)
	buildColumn(root, RIGHT_BUTTONS, 0.89, 0.18, 0.18, 0.11, self)

	-- Bottom status group -----------------------------------------------------
	-- Centered taller level bar with LV / track / 0-100 inside; coin pill upper-left
	-- (auto-width); equipped-auras list upper-right (hidden when empty).
	local barY = 0.90
	local barW = 0.34
	local barH = 0.088 -- doubled vs the prior 0.044 cluster (Operator: "noticeably taller")
	local barLeft = 0.5 - barW / 2
	local barRight = 0.5 + barW / 2
	local aboveY = barY - barH / 2 - 0.025 -- row holding coin pill + effect list

	-- Level bar (container). Anchored center so the whole bar is one centered group.
	self._levelBar = Instance.new("Frame")
	self._levelBar.Name = "LevelBar"
	self._levelBar.Parent = root
	self._levelBar.Position = UDim2.fromScale(0.5, barY)
	self._levelBar.Size = UDim2.fromScale(barW, barH)
	self._levelBar.AnchorPoint = Vector2.new(0.5, 0.5)
	self._levelBar.BackgroundColor3 = p.base
	self._levelBar.BackgroundTransparency = 0.18
	self._levelBar.BorderSizePixel = 0
	newUICorner(self._levelBar, tokens.radii.full)
	newStroke(self._levelBar, p.accent, 1, 0.5)

	-- LV counter — left side, inside the bar.
	self._levelNumberLabel = newLabel(
		"LevelNumber",
		self._levelBar,
		"LV 1",
		UDim2.fromScale(0.04, 0.5),
		UDim2.fromScale(0.15, 0.48),
		tokens.textSizes.caption,
		p.accent,
		Vector2.new(0, 0.5)
	)

	-- Progress track + fill — centered, inside the bar.
	local levelTrack = Instance.new("Frame")
	levelTrack.Name = "LevelTrack"
	levelTrack.Parent = self._levelBar
	levelTrack.AnchorPoint = Vector2.new(0.5, 0.5)
	levelTrack.Position = UDim2.fromScale(0.5, 0.5)
	levelTrack.Size = UDim2.fromScale(0.50, 0.24)
	levelTrack.BackgroundColor3 = p.base
	levelTrack.BackgroundTransparency = 0.15
	levelTrack.BorderSizePixel = 0
	newUICorner(levelTrack, tokens.radii.sm)
	newStroke(levelTrack, p.accent, 1, 0.55)

	self._levelFill = Instance.new("Frame")
	self._levelFill.Name = "LevelFill"
	self._levelFill.Parent = levelTrack
	self._levelFill.AnchorPoint = Vector2.new(0, 0.5)
	self._levelFill.Position = UDim2.fromScale(0, 0.5)
	self._levelFill.Size = UDim2.fromScale(0, 1)
	self._levelFill.BackgroundColor3 = p.accent
	self._levelFill.BorderSizePixel = 0
	newUICorner(self._levelFill, tokens.radii.sm)

	-- 0/100 text — right side, inside the bar.
	self._progressLabel = newLabel(
		"Progress",
		self._levelBar,
		"0 / 100",
		UDim2.fromScale(0.97, 0.5),
		UDim2.fromScale(0.26, 0.48),
		tokens.textSizes.caption,
		p.text,
		Vector2.new(1, 0.5)
	)

	-- Coin pill — upper-left of the bar, auto-width (never truncates). Grows left from
	-- the bar's left edge + gap. Height in scale so the global UIScale (computeScale)
	-- shrinks it at mobile.
	self._coinPill = Instance.new("Frame")
	self._coinPill.Name = "CoinPill"
	self._coinPill.Parent = root
	self._coinPill.AnchorPoint = Vector2.new(1, 0.5)
	self._coinPill.Position = UDim2.fromScale(barLeft - 0.03, aboveY)
	self._coinPill.Size = UDim2.fromScale(0, 0.06)
	self._coinPill.AutomaticSize = Enum.AutomaticSize.X
	self._coinPill.BackgroundColor3 = p.base
	self._coinPill.BackgroundTransparency = 0.15
	self._coinPill.BorderSizePixel = 0
	newUICorner(self._coinPill, tokens.radii.full)
	newStroke(self._coinPill, p.accent, 1, 0.55)
	local coinLayout = Instance.new("UIListLayout")
	coinLayout.FillDirection = Enum.FillDirection.Horizontal
	coinLayout.Padding = 6
	coinLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	coinLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	coinLayout.Parent = self._coinPill

	local coinIconL = Instance.new("ImageLabel")
	coinIconL.Name = "CoinIcon"
	coinIconL.Parent = self._coinPill
	coinIconL.Size = UDim2.fromScale(0, 0.65)
	local coinAspect = Instance.new("UIAspectRatioConstraint")
	coinAspect.AspectRatio = 1
	coinAspect.Parent = coinIconL
	coinIconL.BackgroundTransparency = 1
	coinIconL.BorderSizePixel = 0
	icons.apply(coinIconL, "Coin")
	coinIconL.ImageColor3 = tokens.palette.canary

	self._coinCountLabel = Instance.new("TextLabel")
	self._coinCountLabel.Name = "Count"
	self._coinCountLabel.Parent = self._coinPill
	self._coinCountLabel.AutomaticSize = Enum.AutomaticSize.X
	self._coinCountLabel.Size = UDim2.fromScale(0, 0.7)
	self._coinCountLabel.BackgroundTransparency = 1
	self._coinCountLabel.FontFace = tokens.fonts.body
	self._coinCountLabel.TextSize = tokens.textSizes.caption
	self._coinCountLabel.TextColor3 = p.text
	self._coinCountLabel.TextScaled = true
	self._coinCountLabel.Text = MonetizationConfig.formatCoins(0)
	self._coinCountLabel.TextStrokeColor3 = tokens.palette.navy
	self._coinCountLabel.TextStrokeTransparency = 0.6
	local coinTsc = Instance.new("UITextSizeConstraint")
	coinTsc.MinTextSize = 10
	coinTsc.MaxTextSize = 24
	coinTsc.Parent = self._coinCountLabel
	-- right padding so text never kisses the pill's right corner
	local coinPad = Instance.new("Frame")
	coinPad.Size = UDim2.fromOffset(6, 1)
	coinPad.BackgroundTransparency = 1
	coinPad.Parent = self._coinPill

	-- Equipped-auras/effects list — upper-right of the bar, hidden when empty.
	-- This is the lobby status row (equipped crown/title/trail/auras). Read from the
	-- server-replicated profile (Profile.luau), never mocked.
	self._effectList = Instance.new("Frame")
	self._effectList.Name = "EffectList"
	self._effectList.Parent = root
	self._effectList.AnchorPoint = Vector2.new(0, 0.5)
	self._effectList.Position = UDim2.fromScale(barRight + 0.03, aboveY)
	self._effectList.Size = UDim2.fromScale(0, 0.06)
	self._effectList.AutomaticSize = Enum.AutomaticSize.X
	self._effectList.BackgroundTransparency = 0.15
	self._effectList.BackgroundColor3 = p.base
	self._effectList.BorderSizePixel = 0
	self._effectList.Visible = false
	newUICorner(self._effectList, tokens.radii.full)
	newStroke(self._effectList, p.accent, 1, 0.5)
	self._effectLayout = Instance.new("UIListLayout")
	self._effectLayout.FillDirection = Enum.FillDirection.Horizontal
	self._effectLayout.Padding = 6
	self._effectLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	self._effectLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	self._effectLayout.Parent = self._effectList

	self:_refreshEffectList()

	-- Hover tooltip (reused single label, ZIndex above all HUD).
	self._tooltip = Instance.new("TextLabel")
	self._tooltip.Name = "Tooltip"
	self._tooltip.Parent = root
	self._tooltip.BackgroundTransparency = 0.25
	self._tooltip.BackgroundColor3 = p.navy
	self._tooltip.BorderSizePixel = 0
	self._tooltip.Size = UDim2.fromOffset(100, 25) -- 2x smaller (Operator round-1)
	self._tooltip.TextColor3 = p.text
	self._tooltip.TextStrokeColor3 = p.navy
	self._tooltip.TextStrokeTransparency = 0.55
	self._tooltip.FontFace = tokens.fonts.body
	self._tooltip.TextSize = tokens.textSizes.caption
	self._tooltip.TextScaled = true
	self._tooltip.TextWrapped = true
	self._tooltip.TextTransparency = 1
	self._tooltip.Visible = false
	self._tooltip.ZIndex = 100
	newUICorner(self._tooltip, tokens.radii.md)
	newStroke(self._tooltip, tokens.palette.canary, 1, 0.6)
	newTextSizeConstraint(6, self._tooltip)
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
	if payload.coinCount ~= nil then
		self._coinCountLabel.Text = MonetizationConfig.formatCoins(payload.coinCount)
	end
	if payload.ownedPasses then
		Profile.setOwnedPasses(payload.ownedPasses)
	end
	if payload.equipped then
		Profile.setEquipped(payload.equipped)
		self:_refreshEffectList()
	end
end

function Lobby._refreshEffectList(self: Lobby)
	-- Clear existing tags.
	for _, tag in ipairs(self._effectList:GetChildren()) do
		if tag:IsA("TextLabel") and tag.Name == "Tag" then
			tag:Destroy()
		end
	end
	local tags = Profile.getEquippedTags()
	for _, tag in ipairs(tags) do
		local label = Instance.new("TextLabel")
		label.Name = "Tag"
		label.Parent = self._effectList
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromScale(0, 0.7)
		label.BackgroundTransparency = 0.35
		label.BackgroundColor3 = tokens.palette.navy
		label.BorderSizePixel = 0
		label.FontFace = tokens.fonts.body
		label.TextSize = tokens.textSizes.caption
		label.TextColor3 = tokens.palette.text
		label.TextStrokeColor3 = tokens.palette.navy
		label.TextStrokeTransparency = 0.6
		label.TextScaled = true
		label.Text = " " .. tag .. " "
		newUICorner(label, tokens.radii.sm)
	end
	self._effectList.Visible = #tags > 0
end

-- Tooltip lifecycle: show after 0.12s; hide instantly on leave. PC hover only.
function Lobby._scheduleTooltip(self: Lobby, text: string, xScale: number, yScale: number)
	if self._tooltipTask then
		task.cancel(self._tooltipTask)
	end
	self._tooltipTask = task.delay(TOOLTIP_DELAY, function()
		self._tooltipTask = nil
		self:_showTooltip(text, xScale, yScale)
	end)
end

function Lobby._showTooltip(self: Lobby, text: string, xScale: number, yScale: number)
	self._tooltip.Text = text
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
