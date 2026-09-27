--!strict
-- icons.luau — the single fill-in point for UI icon asset IDs.
-- 24 icons total: 19 ship as PNGs in assets/Icons/ (NOT synced into the place by
-- Rojo) + 5 pending (Level, Sell, Equip, Unequip, Gift). The 19 shipped PNGs went up
-- via Open Cloud as Image-type assets (decal ids do not render in ImageLabel)
-- into assets/IDs.txt (name=id, source of truth for this table); the
-- 5 pending keep rbxassetid://0 placeholders until their IDs arrive.
-- Source: docs/agents/UI.md, assets/README.md.

local icons: { [string]: string } = {
	-- nav column (tier 1)
	Inventory = "rbxassetid://87418317685793",
	Shop = "rbxassetid://77812172502851",
	Settings = "rbxassetid://109081341872868",
	PartyPass = "rbxassetid://124560866060929",
	Packs = "rbxassetid://104152505679273",
	MiniGames = "rbxassetid://138123222145231",
	WorldMap = "rbxassetid://87241534410327",
	Stats = "rbxassetid://99572193244124",

	-- HUD (tier 2) — Level is pending; placeholder drives the level badge (Finding 3)
	Coin = "rbxassetid://133742676115554",
	Perk = "rbxassetid://139095467640310",
	Players = "rbxassetid://77101408397728",
	Level = "rbxassetid://0",

	-- controls (tier 3)
	Close = "rbxassetid://117461692631689",
	Back = "rbxassetid://140104471059692",
	Confirm = "rbxassetid://110846396902043",
	Claim = "rbxassetid://95530776349868",
	Lock = "rbxassetid://107786625530801",
	VoteMap = "rbxassetid://97702581163607",
	Play = "rbxassetid://99845151387677",

	-- round-2 controls (tier 4) — pending
	Buy = "rbxassetid://128715344465124",
	Sell = "rbxassetid://0",
	Equip = "rbxassetid://0",
	Unequip = "rbxassetid://0",
	Gift = "rbxassetid://0",
}

return icons
