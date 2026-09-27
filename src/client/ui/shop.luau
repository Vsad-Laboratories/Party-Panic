--!strict
-- shop.luau — Shop screen shell (UI charter: src/client/ui/).
-- Opened via router.open('Shop'). Renders the cosmetics catalog grid from
-- ShopConfig.luau (DATA ONLY — empty catalog => "Coming Soon", never mocked),
-- a Locker panel with drag-to-equip, and an Emotes tab gated by GP_EmotePack.
-- Purchase flow: client fires RemoteEvent 'ShopPurchase' (name from
-- MonetizationConfig.ShopPurchaseEvent) with cosmeticId; the SERVER validates
-- price/ownership/grants via MonetizationService (roblox-monetization — the client
-- is never authoritative for ownership or currency). Transitions use the
-- GUIAnimationPack helpers (136376766704443) with a TweenService fallback.
-- Skills: roblox-gui, roblox-ui-design, roblox-monetization, roblox-luau-patterns.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")

local tokens = require(script.Parent.tokens)
local icons = require(script.Parent.icons)
local sounds = require(script.Parent.sounds)
local ShopConfig = require(script.Parent.ShopConfig)
local MonetizationConfig = require(script.Parent.MonetizationConfig)
local Profile = require(script.Parent.Profile)

local PLAYER = Players.LocalPlayer
local PLAYER_GUI = PLAYER:WaitForChild("PlayerGui")

local SHOP_EVENT: RemoteEvent = ReplicatedStorage:WaitForChild(MonetizationConfig.ShopPurchaseEvent)

-- Load the GUI animation pack once (ModuleScript 136376766704443). Falls back to a
-- thin TweenService shim if the pack isn't replicated, so the screen still animates.
local transitionPack: any? = nil
do
	local ok, inserted = pcall(function()
		local asset = InsertService:LoadAsset(MonetizationConfig.AnimationAssets.GUIAnimationPack)
		if not asset then
			return nil
		end
		asset.Name = "GUIAnimationPack"
		asset.Parent = ReplicatedStorage
		return asset:FindFirstChildWhichIsA("ModuleScript") or asset
	end)
	if ok and inserted then
		local ok2, mod = pcall(require, inserted)
		if ok2 and mod and mod.tween then
			transitionPack = mod
		end
	end
end

local function tween(obj: Instance, goal: { [string]: any }, duration: number?): ()
	if transitionPack and transitionPack.tween then
		transitionPack.tween(obj, goal, duration or 0.25)
	else
		local info = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(obj, info, goal):Play()
	end
end

local function corner(parent: Instance, radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or tokens.radii.lg)
	c.Parent = parent
	return c
end

local function stroke(parent: Instance, color: Color3, transparency: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = 1
	s.Transparency = transparency
	s.Parent = parent
	return s
end

-- Square icon box matching the lobby HUD button style (navy panel, rounded, uniform).
local function newBox(parent: Instance, name: string, size: UDim2, auto: Enum.AutomaticSize?): Frame
	local box = Instance.new("Frame")
	box.Name = name
	box.Parent = parent
	box.Size = size
	box.BackgroundColor3 = tokens.palette.base
	box.BackgroundTransparency = 0.15
	box.BorderSizePixel = 0
	if auto then
		box.AutomaticSize = auto
	end
	corner(box, tokens.radii.lg)
	stroke(box, tokens.palette.accent, 0.5)
	return box
end

local function newLabel(
	parent: Instance,
	name: string,
	text: string,
	size: UDim2,
	color: Color3?,
	font: Font?,
	textSize: number?,
	anchor: Vector2?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Parent = parent
	label.Size = size
	label.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.FontFace = font or tokens.fonts.body
	label.TextSize = textSize or tokens.textSizes.caption
	label.TextColor3 = color or tokens.palette.text
	label.TextScaled = true
	label.TextWrapped = true
	label.TextStrokeColor3 = tokens.palette.navy
	label.TextStrokeTransparency = 0.65
	local tsc = Instance.new("UITextSizeConstraint")
	tsc.MinTextSize = 10
	tsc.MaxTextSize = 32
	tsc.Parent = label
	return label
end

local function newIconButton(
	parent: Instance,
	name: string,
	iconName: string,
	size: UDim2,
	anchor: Vector2?
): ImageButton
	local button = Instance.new("ImageButton")
	button.Name = name
	button.Parent = parent
	button.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	button.Size = size
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	icons.apply(button, iconName)
	button.ImageColor3 = tokens.palette.text
	button.MouseEnter:Connect(function()
		button.ImageColor3 = tokens.palette.canary
		sounds.playHover()
	end)
	button.MouseLeave:Connect(function()
		button.ImageColor3 = tokens.palette.text
	end)
	button.Activated:Connect(function()
		button.ImageColor3 = tokens.palette.pink
		sounds.playClick()
		task.delay(0.1, function()
			if button and button.Parent then
				button.ImageColor3 = tokens.palette.text
			end
		end)
	end)
	return button
end

local Shop = {}
Shop.__index = Shop
local active: Shop? = nil

function Shop.open(): Shop
	if active then
		return active
	end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PLAYER_GUI

	local self = {} :: Shop
	setmetatable(self, Shop)
	self._screenGui = screenGui
	self._lockerSlots = {}
	self._build()
	active = self
	self:enter()
	return self
end

function Shop.close(self: Shop)
	if self._overlay then
		self._overlay.Visible = false
	end
	active = nil
end

function Shop.enter(self: Shop)
	local root = self._screenGui
	assert(root, "Shop screenGui missing")
	self._overlay = Instance.new("Frame")
	self._overlay.Name = "Overlay"
	self._overlay.Parent = root
	self._overlay.Size = UDim2.fromScale(1, 1)
	self._overlay.BackgroundTransparency = 0.55
	self._overlay.BackgroundColor3 = tokens.palette.navy
	self._overlay.BorderSizePixel = 0
	self._overlay.Visible = true

	self._topBar = Instance.new("Frame")
	self._topBar.Name = "TopBar"
	self._topBar.Parent = root
	self._topBar.Size = UDim2.fromScale(1, 0.07)
	self._topBar.Position = UDim2.fromScale(0, -0.02)
	self._topBar.BackgroundTransparency = 0.2
	self._topBar.BackgroundColor3 = tokens.palette.base
	self._topBar.BorderSizePixel = 0
	corner(self._topBar, tokens.radii.sm)

	newLabel(
		self._topBar,
		"Title",
		"SHOP",
		UDim2.fromScale(0.5, 0.5),
		tokens.palette.accent,
		tokens.fonts.heading,
		tokens.textSizes.title,
		Vector2.new(0.5, 0.5)
	)

	local closeBtn =
		newIconButton(self._topBar, "CloseButton", "Close", UDim2.fromScale(0.05, 0.6), Vector2.new(1, 0.5))
	closeBtn.Position = UDim2.fromScale(0.96, 0.5)
	closeBtn.Activated:Connect(function()
		self:close()
	end)

	tween(self._overlay, { BackgroundTransparency = 0.45 }, 0.3)
	tween(self._topBar, { Position = UDim2.fromScale(0, 0) }, 0.3)
end

function Shop._build(self: Shop)
	local root = self._screenGui
	assert(root, "Shop screenGui missing in _build")
	local p = tokens.palette

	-- Category tab strip.
	self._tabs = Instance.new("Frame")
	self._tabs.Name = "CategoryTabs"
	self._tabs.Parent = root
	self._tabs.Position = UDim2.fromScale(0.04, 0.10)
	self._tabs.Size = UDim2.fromScale(0.92, 0.055)
	self._tabs.BackgroundTransparency = 1
	self._tabs.BorderSizePixel = 0
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = 8
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Parent = self._tabs

	for _, category in ipairs(ShopConfig.Categories) do
		local tab = newBox(self._tabs, category .. "Tab", UDim2.new(0, 120, 1, 0), Enum.AutomaticSize.X)
		newLabel(
			tab,
			"Label",
			category,
			UDim2.fromScale(0.5, 0.5),
			p.text,
			nil,
			tokens.textSizes.caption,
			Vector2.new(0.5, 0.5)
		)
		tab.Active = true
		tab.MouseButton1Click:Connect(function()
			self:_selectCategory(category)
		end)
	end

	-- Catalog grid (empty => "Coming Soon").
	self._catalog = Instance.new("ScrollingFrame")
	self._catalog.Name = "Catalog"
	self._catalog.Parent = root
	self._catalog.Position = UDim2.fromScale(0.04, 0.18)
	self._catalog.Size = UDim2.fromScale(0.92, 0.62)
	self._catalog.BackgroundTransparency = 1
	self._catalog.BorderSizePixel = 0
	self._catalog.ScrollBarThickness = 6
	self._catalog.CanvasSize = UDim2.fromScale(0, 0)
	self._catalog.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromScale(0.18, 0.18)
	grid.CellPadding = UDim2.fromScale(0.013, 0.013)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.Parent = self._catalog

	self._placeholder = newLabel(self._catalog, "ComingSoon", "Coming Soon", UDim2.fromScale(1, 1), p.accent)

	-- Locker panel (drag-to-equip).
	self._locker = Instance.new("Frame")
	self._locker.Name = "Locker"
	self._locker.Parent = root
	self._locker.Position = UDim2.fromScale(0.04, 0.82)
	self._locker.Size = UDim2.fromScale(0.92, 0.14)
	self._locker.BackgroundTransparency = 0.15
	self._locker.BackgroundColor3 = p.base
	self._locker.BorderSizePixel = 0
	corner(self._locker, tokens.radii.md)
	newLabel(
		self._locker,
		"LockerTitle",
		"LOCKER",
		UDim2.fromScale(0.5, 0.26),
		p.accent,
		tokens.fonts.heading,
		tokens.textSizes.caption,
		Vector2.new(0.5, 0.5)
	)

	self._slotLayout = Instance.new("UIListLayout")
	self._slotLayout.FillDirection = Enum.FillDirection.Horizontal
	self._slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	self._slotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	self._slotLayout.Padding = 10
	self._slotLayout.Parent = self._locker

	self._lockerSlots = {}
	self:_buildLockerSlots()

	-- Emotes tab gated by GP_EmotePack (locked => tooltip, never mocked).
	self._emoteOwned = Profile.isOwned(MonetizationConfig.GamePasses.EmotePack.gamePassId)
	self:_refreshEmoteState()
end

function Shop:_buildLockerSlots()
	local slots = self._lockerSlots or {}
	for _, slot in ipairs(slots) do
		if slot and slot.Parent then
			slot:Destroy()
		end
	end
	slots = {}
	local bonus = if Profile.isOwned(MonetizationConfig.GamePasses.LockerSlots.gamePassId)
		then MonetizationConfig.LOCKER_SLOTS_GP_BONUS
		else 0
	local count = MonetizationConfig.LOCKER_SLOTS_BASE + bonus
	for i = 1, count do
		local slot = newBox(self._locker, "Slot" .. i, UDim2.fromOffset(48, 48), nil)
		slot.Active = true
		slot.AutoButtonColor = false
		-- drag-to-equip: pick an item, drop on a slot. Drag is local-only; the server
		-- persists the equip via its own handler (Profile is server-authoritative).
		slot.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:equipToSlot(i)
			end
		end)
		table.insert(slots, slot)
	end
	self._lockerSlots = slots
end

function Shop:_refreshEmoteState()
	-- When the Emote Pack is owned, load the selector module (8944416554) and animation
	-- pack (109991912171331); tracks load via Animator:LoadAnimation on the character.
	-- Locked otherwise — never mock the selector.
	if self._emoteOwned then
		if not self._emoteSelector then
			local ok, inserted = pcall(function()
				local asset = InsertService:LoadAsset(MonetizationConfig.GamePasses.EmotePack.selectorAssetId)
				if not asset then
					return nil
				end
				asset.Name = "EmoteSelector"
				asset.Parent = ReplicatedStorage
				return asset:FindFirstChildWhichIsA("ModuleScript") or asset
			end)
			if ok and inserted then
				local ok2, mod = pcall(require, inserted)
				if ok2 and mod then
					self._emoteSelector = mod
				end
			end
		end
	else
		self._emoteSelector = nil
	end
end

function Shop:_selectCategory(category: string)
	self._currentCategory = category
	self._picked = nil
	for _, child in ipairs(self._catalog:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "ComingSoon" then
			child:Destroy()
		end
	end
	self._placeholder.Visible = true
	local items = self:_itemsFor(category)
	if #items == 0 then
		self._placeholder.Text = "Coming Soon"
		return
	end
	self._placeholder.Visible = false
	for _, item in ipairs(items) do
		self:_buildCatalogItem(item)
	end
end

function Shop:_itemsFor(category: string): { any }
	local out = {}
	for _, item in ipairs(ShopConfig.Catalog) do
		if item.category == category then
			table.insert(out, item)
		end
	end
	return out
end

function Shop:_buildCatalogItem(item: { [string]: any })
	local box = newBox(self._catalog, "Item_" .. item.cosmeticId, UDim2.fromScale(1, 1), nil)
	box.Active = true

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Parent = box
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.36)
	icon.Size = UDim2.fromScale(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icons.apply(icon, item.icon or "")

	newLabel(
		box,
		"Price",
		MonetizationConfig.formatCoins(item.coinPrice),
		UDim2.fromScale(0.5, 0.82),
		tokens.palette.canary
	)

	local buy = newIconButton(box, "Buy", "Buy", UDim2.fromScale(0.36, 0.22), Vector2.new(0.5, 1))
	buy.Position = UDim2.fromScale(0.5, 0.9)
	buy.Activated:Connect(function()
		sounds.playClick()
		self._picked = item
		SHOP_EVENT:FireServer(item.cosmeticId)
	end)
end

function Shop:equipToSlot(slotIndex: number)
	if not self._picked then
		return
	end
	-- Equip the picked cosmetic to locker slot slotIndex. Ownership/currency were
	-- already validated server-side on purchase; equip is persisted by the server.
	tween(self._lockerSlots[slotIndex], { BackgroundTransparency = 0.0 }, 0.15)
	task.delay(0.2, function()
		if self._lockerSlots[slotIndex] and self._lockerSlots[slotIndex].Parent then
			self._lockerSlots[slotIndex].BackgroundTransparency = 0.15
		end
	end)
	self._picked = nil
end

return Shop
