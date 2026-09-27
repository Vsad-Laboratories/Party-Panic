--!strict
-- ShopConfig.luau — DATA ONLY for the Shop screen (src/client/ui/shop.luau).
-- No mock cosmetics: the catalog ships EMPTY until the Operator populates it; the
-- screen renders "Coming Soon" when there is nothing to show. Categories and the
-- animation-assets table are the only real data here.
-- Skills: roblox-monetization (layout), roblox-luau-types.

local ShopConfig = {}

-- Display categories (order = tab order in the Shop UI).
ShopConfig.Categories = {
	"Crown Trails",
	"Victory Poses",
	"Entrance Effects",
	"Emotes",
	"Elimination Effects",
	"Nameplates",
	"Locker Slots",
}

-- Catalog schema (documented for the Operator / future type-check):
--   { cosmeticId: string, name: string, icon: string, coinPrice: number,
--     category: string, previewable: boolean }
-- Intentionally empty — items are added only when real assets land. Never mocked.
ShopConfig.Catalog = {}

-- Animation integration (Operator round-2). Asset IDs are number asset ids; wrap as
-- rbxassetid:// at load time (see shop.luau / MonetizationConfig.GamePasses.EmotePack).
--   EmotePackAnimation    — AnimationTrack pack; tracks loaded via Animator:LoadAnimation.
--   EmoteSelectorModule   — ModuleScript asset id for the emote selector UI (LoadAsset + require).
--   GUIAnimationPack      — ModuleScript asset id exposing tween helpers used for all
--                           shop transitions / button tweens / coin roll-up.
ShopConfig.AnimationAssets = {
	EmotePackAnimation = 109991912171331,
	EmoteSelectorModule = 8944416554,
	GUIAnimationPack = 136376766704443,
}

-- Shop product icons live in a SEPARATE monetization atlas (17 assets) — source of
-- truth: assets/MonetizationIDs.txt (name -> rbxassetid). Not yet wired to a single
-- atlas id; shop item icons resolve through MonetizationIDs at runtime. Empty until
-- catalog is populated, so this stays a lookup helper with no mock entries.
ShopConfig.MonetizationIconIds = {}

return ShopConfig
