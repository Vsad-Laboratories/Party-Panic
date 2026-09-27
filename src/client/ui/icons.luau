--!strict
-- icons.luau — single fill-in point for HUD icon asset IDs.
-- Icon ATLAS (UI): id 104056199975187 (410x328, 82x82 trimmed square slots, 5 cols).
-- Each entry is a 3-tuple { atlasId, ImageRectOffset, ImageRectSize } so icons.apply()
-- sets the three atlas properties at once — that is what pixel-perfect-centers every
-- icon in its square hitbox with zero letterbox (ScaleType Fit + trimmed slots).
-- Source of truth: assets/atlas.txt (keep in sync; never hand-edit offsets alone).
-- 19 shipped icons have slots; 5 pending (Level, Sell, Equip, Unequip, Gift) render
-- rbxassetid://0 (stable blank) until their PNGs land via PR #22. assets/IDs.txt is
-- NOT consumed by this file.
-- Skills: roblox-gui (ImageLabel/ImageButton atlas wiring), roblox-ui-design.

local ATLAS_ID = "rbxassetid://104056199975187"
local SLOT_SIZE = Vector2.new(82, 82)
local ZERO = "rbxassetid://0"

local function entry(x: number, y: number)
	return { ATLAS_ID, Vector2.new(x, y), SLOT_SIZE }
end

local icons: { [string]: any } = {}

-- shipped HUD icons (offset per assets/atlas.txt)
icons.Back = entry(0, 0)
icons.Buy = entry(82, 0)
icons.Claim = entry(164, 0)
icons.Close = entry(246, 0)
icons.Coin = entry(328, 0)
icons.Confirm = entry(0, 82)
icons.Inventory = entry(82, 82)
icons.Lock = entry(164, 82)
icons.MiniGames = entry(246, 82)
icons.Packs = entry(328, 82)
icons.PartyPass = entry(0, 164)
icons.Perk = entry(82, 164)
icons.Play = entry(164, 164)
icons.Players = entry(246, 164)
icons.Settings = entry(328, 164)
icons.Shop = entry(0, 246)
icons.Stats = entry(82, 246)
icons.VoteMap = entry(164, 246)
icons.WorldMap = entry(246, 246)

-- pending: no atlas slot yet — rbxassetid://0 sentinel so an absent icon renders blank
-- instead of leaking last frame or a stray texture.
icons.Level = entry(0, 0) -- placeholder offset; Image is ZERO so it renders nothing
icons.Sell = entry(0, 0)
icons.Equip = entry(0, 0)
icons.Unequip = entry(0, 0)
icons.Gift = entry(0, 0)
do
	for k in pairs({ Level = true, Sell = true, Equip = true, Unequip = true, Gift = true }) do
		icons[k][1] = ZERO
	end
end

icons.ATLAS_ID = ATLAS_ID
icons.SLOT_SIZE = SLOT_SIZE

-- Apply an icon entry to any GuiObject with an Image property (ImageButton/ImageLabel).
-- Sets Image + ImageRectOffset + ImageRectSize + ScaleType Fit in one call so the icon
-- always fills its square box with zero letterbox (trimmed atlas slots + AnchorPoint 0.5).
function icons.apply(target: Instance, name: string): ()
	local iconEntry = icons[name]
	if iconEntry then
		target.Image = iconEntry[1]
		target.ImageRectOffset = iconEntry[2]
		target.ImageRectSize = iconEntry[3]
		target.ScaleType = Enum.ScaleType.Fit
	else
		target.Image = ZERO
		target.ImageRectOffset = Vector2.new(0, 0)
		target.ImageRectSize = Vector2.new(0, 0)
	end
end

return icons
