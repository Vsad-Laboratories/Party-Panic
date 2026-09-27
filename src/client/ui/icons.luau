--!strict
-- icons.luau — the single fill-in point for UI icon asset IDs.
-- 24 icons total: 19 ship as PNGs in assets/Icons/ (NOT synced into the place by
-- Rojo) + 5 pending (Level, Sell, Equip, Unequip, Gift). PNGs are uploaded through
-- Studio (View -> Asset Manager -> Bulk Import); the Operator lands the real IDs by
-- editing the values below. Defaults are rbxassetid://0 placeholders so the layout
-- resolves before IDs arrive. Source: docs/agents/UI.md, assets/README.md.

local icons: { [string]: string } = {
	-- nav column (tier 1)
	Inventory = "rbxassetid://0",
	Shop = "rbxassetid://0",
	Settings = "rbxassetid://0",
	PartyPass = "rbxassetid://0",
	Packs = "rbxassetid://0",
	MiniGames = "rbxassetid://0",
	WorldMap = "rbxassetid://0",
	Stats = "rbxassetid://0",

	-- HUD (tier 2) — Level is pending; placeholder drives the level badge (Finding 3)
	Coin = "rbxassetid://0",
	Perk = "rbxassetid://0",
	Players = "rbxassetid://0",
	Level = "rbxassetid://0",

	-- controls (tier 3)
	Close = "rbxassetid://0",
	Back = "rbxassetid://0",
	Confirm = "rbxassetid://0",
	Claim = "rbxassetid://0",
	Lock = "rbxassetid://0",
	VoteMap = "rbxassetid://0",
	Play = "rbxassetid://0",

	-- round-2 controls (tier 4) — pending
	Buy = "rbxassetid://0",
	Sell = "rbxassetid://0",
	Equip = "rbxassetid://0",
	Unequip = "rbxassetid://0",
	Gift = "rbxassetid://0",
}

return icons
