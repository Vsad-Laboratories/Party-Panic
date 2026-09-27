--!strict
-- icons.luau — the single fill-in point for UI icon asset IDs.
-- 24 icons total: 19 ship as PNGs in assets/Icons/ (NOT synced into the place by
-- Rojo) + 5 pending (Level, Sell, Equip, Unequip, Gift). The 19 shipped PNGs went up
-- via Open Cloud into assets/IDs.txt (name=id, source of truth for this table); the
-- 5 pending keep rbxassetid://0 placeholders until their IDs arrive.
-- Source: docs/agents/UI.md, assets/README.md.

local icons: { [string]: string } = {
	-- nav column (tier 1)
	Inventory = "rbxassetid://106995180936545",
	Shop = "rbxassetid://78224747604287",
	Settings = "rbxassetid://119258081930586",
	PartyPass = "rbxassetid://100590700972459",
	Packs = "rbxassetid://88417644287112",
	MiniGames = "rbxassetid://82084761117586",
	WorldMap = "rbxassetid://81383186031554",
	Stats = "rbxassetid://79945290766853",

	-- HUD (tier 2) — Level is pending; placeholder drives the level badge (Finding 3)
	Coin = "rbxassetid://103338430195183",
	Perk = "rbxassetid://75756605679684",
	Players = "rbxassetid://104066424169322",
	Level = "rbxassetid://0",

	-- controls (tier 3)
	Close = "rbxassetid://83118632374865",
	Back = "rbxassetid://97317144586105",
	Confirm = "rbxassetid://96488002114048",
	Claim = "rbxassetid://88741285648569",
	Lock = "rbxassetid://107539694824608",
	VoteMap = "rbxassetid://131897868456893",
	Play = "rbxassetid://98456158998886",

	-- round-2 controls (tier 4) — pending
	Buy = "rbxassetid://105402032582168",
	Sell = "rbxassetid://0",
	Equip = "rbxassetid://0",
	Unequip = "rbxassetid://0",
	Gift = "rbxassetid://0",
}

return icons
