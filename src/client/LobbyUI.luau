-- LobbyUI: mobile-first lobby surface driven by the server lobby-state feed.
-- Vote and coin controls remain shell surfaces until their protocols land.
-- Layout: thumb-reach bottom vote buttons, top status, center crown area.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local LobbyState = require(ReplicatedStorage.Shared.LobbyState)

type LobbyStatePayload = LobbyState.LobbyStatePayload

local BOTTOM_MARGIN = 80
local BUTTON_SIZE = UDim2.fromOffset(280, 96)
local BUTTON_SPACING = 24
local MAX_PLAYERS = 12

local function createCorner(radius: number?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	return corner
end

local function createStroke(color: Color3, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	return stroke
end

local function createTextLabel(
	name: string,
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	textSize: number,
	anchorPoint: Vector2?,
	visible: boolean?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Parent = parent
	label.Position = position
	label.Size = size
	label.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.7
	label.TextWrapped = true
	label.Visible = visible ~= false
	return label
end

local function createButton(parent: Instance, text: string, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = "VoteButton"
	button.Parent = parent
	button.Position = position
	button.Size = BUTTON_SIZE
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = 0.1
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.TextScaled = true
	button.TextSize = 36
	button.TextColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = true

	createCorner(12).Parent = button
	createStroke(Color3.fromRGB(255, 200, 0), 2).Parent = button

	return button
end

local function createPlayerSlot(parent: Instance, index: number): (Frame, TextLabel)
	local slot = Instance.new("Frame")
	slot.Name = "PlayerSlot_" .. index
	slot.Parent = parent
	slot.Size = UDim2.new(1, -20, 0, 56)
	slot.BackgroundTransparency = 1

	createCorner(8).Parent = slot
	createStroke(Color3.fromRGB(100, 100, 100), 1).Parent = slot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Parent = slot
	nameLabel.Position = UDim2.new(0, 8, 0.5, 0)
	nameLabel.Size = UDim2.new(1, -16, 1, 0)
	nameLabel.AnchorPoint = Vector2.new(0, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "..."
	nameLabel.TextScaled = true
	nameLabel.TextSize = 20
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true

	return slot, nameLabel
end

local LobbyUI = {}

function LobbyUI.new()
	local self = setmetatable({}, { __index = LobbyUI })

	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "LobbyUI"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.IgnoreGuiInset = true
	self._screenGui.Parent = PlayerGui

	self._payload = nil

	self:_build()
	self:_render()

	return self
end

function LobbyUI:_build()
	local root = self._screenGui
	root.Size = UDim2.fromScale(1, 1)

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Parent = root
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(15, 20, 40)

	createTextLabel("Title", root, "PARTY PANIC", UDim2.new(0.5, 0, 0, 40), UDim2.fromOffset(400, 60), 36, nil, true)

	self._playerCountLabel = createTextLabel(
		"PlayerCount",
		root,
		"Players: 0 / " .. MAX_PLAYERS,
		UDim2.new(0.02, 0, 0, 96),
		UDim2.fromOffset(240, 48),
		24,
		nil,
		true
	)

	local playerListContainer = Instance.new("Frame")
	playerListContainer.Name = "PlayerList"
	playerListContainer.Parent = root
	playerListContainer.Position = UDim2.new(0.02, 0, 0, 156)
	playerListContainer.Size = UDim2.fromOffset(280, 320)
	playerListContainer.BackgroundTransparency = 1

	createCorner(12).Parent = playerListContainer

	local listBackground = Instance.new("Frame")
	listBackground.Name = "ListBackground"
	listBackground.Parent = playerListContainer
	listBackground.Size = UDim2.fromScale(1, 1)
	listBackground.BackgroundColor3 = Color3.fromRGB(30, 35, 60)
	listBackground.BorderSizePixel = 0
	createCorner(12).Parent = listBackground

	self._playerSlots = {}
	for i = 1, MAX_PLAYERS do
		local slot, nameLabel = createPlayerSlot(playerListContainer, i)
		slot.Position = UDim2.fromOffset(10, 8 + (i - 1) * 60)
		self._playerSlots[i] = { frame = slot, nameLabel = nameLabel }
	end

	self._countdownLabel = createTextLabel(
		"CountdownLabel",
		root,
		"Starting in 10s",
		UDim2.new(0.5, 0, 0, 540),
		UDim2.fromOffset(360, 56),
		32,
		nil,
		true
	)

	local crownArea = Instance.new("Frame")
	crownArea.Name = "CrownArea"
	crownArea.Parent = root
	crownArea.Position = UDim2.new(0.5, 0, 0.5, -20)
	crownArea.Size = UDim2.fromOffset(160, 160)
	crownArea.AnchorPoint = Vector2.new(0.5, 0.5)
	crownArea.BackgroundTransparency = 0.8
	crownArea.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	crownArea.BorderSizePixel = 0
	createCorner(80).Parent = crownArea

	self._crownLabel = createTextLabel(
		"CrownLabel",
		crownArea,
		"Winner",
		UDim2.new(0.5, 0, 1, 12),
		UDim2.fromOffset(160, 36),
		20,
		nil,
		true
	)

	local coinContainer = Instance.new("Frame")
	coinContainer.Name = "CoinContainer"
	coinContainer.Parent = root
	coinContainer.Position = UDim2.new(0.98, 0, 0, 12)
	coinContainer.Size = UDim2.fromOffset(200, 56)
	coinContainer.AnchorPoint = Vector2.new(1, 0)
	coinContainer.BackgroundTransparency = 0.2
	coinContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	createCorner(12).Parent = coinContainer

	createStroke(Color3.fromRGB(255, 200, 0), 2).Parent = coinContainer

	self._coinLabel = createTextLabel(
		"CoinLabel",
		coinContainer,
		"0",
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromOffset(180, 48),
		36,
		nil,
		true
	)

	local voteButtonContainer = Instance.new("Frame")
	voteButtonContainer.Name = "VoteButtons"
	voteButtonContainer.Parent = root
	voteButtonContainer.Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
	voteButtonContainer.Size =
		UDim2.fromOffset(3 * (BUTTON_SIZE.X.Offset + BUTTON_SPACING) - BUTTON_SPACING, BUTTON_SIZE.Y.Offset)
	voteButtonContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	voteButtonContainer.BackgroundTransparency = 1

	for i = 1, 3 do
		local button = createButton(
			voteButtonContainer,
			"Map " .. i,
			UDim2.fromOffset((i - 1) * (BUTTON_SIZE.X.Offset + BUTTON_SPACING), 0)
		)
		button.Name = "VoteButton" .. i
	end
end

function LobbyUI:update(payload: LobbyStatePayload)
	self._payload = payload
	self:_render()
end

function LobbyUI:_render()
	if not self._screenGui or not self._screenGui.Parent then
		return
	end

	local p = self._payload
	if not p then
		self:_renderNeutral()
		return
	end

	self._playerCountLabel.Text = "Players: " .. #p.players .. " / " .. MAX_PLAYERS

	for i, entry in ipairs(self._playerSlots) do
		local player = p.players[i]
		if player then
			entry.frame.Visible = true
			entry.nameLabel.Text = player.name
		else
			entry.frame.Visible = false
		end
	end

	local state = p.state
	if state == "Countdown" then
		self._countdownLabel.Text = "Starting in " .. math.max(0, p.countdown) .. "s"
	elseif state == "InRound" then
		self._countdownLabel.Text = p.roundName
	elseif state == "Results" then
		self._countdownLabel.Text = "Results"
	else
		self._countdownLabel.Text = "Waiting for players"
	end

	self._coinLabel.Text = "—"

	self:_renderWinner(p)
end

function LobbyUI:_renderNeutral()
	self._playerCountLabel.Text = "Players: — / " .. MAX_PLAYERS
	for _, entry in ipairs(self._playerSlots) do
		entry.frame.Visible = false
	end
	self._countdownLabel.Text = "—"
	self._coinLabel.Text = "—"
	self._crownLabel.Text = "—"
end

function LobbyUI:_renderWinner(p: LobbyStatePayload)
	local winnerUserId = p.lastResult and p.lastResult.winnerUserId
	if not winnerUserId then
		self._crownLabel.Text = "—"
		return
	end
	for _, player in ipairs(p.players) do
		if player.userId == winnerUserId then
			self._crownLabel.Text = player.name
			return
		end
	end
	self._crownLabel.Text = tostring(winnerUserId)
end

return LobbyUI
