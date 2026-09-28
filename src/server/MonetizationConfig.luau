-- MonetizationConfig: data-only tables for ALL prices, IDs, and grants.
-- NO logic in this file — MonetizationService reads these tables.
-- Operator will replace placeholder IDs (0) with real Roblox asset IDs.
-- Skills applied: roblox-monetization (product type separation),
--   roblox-security (server-authoritative config).

local MonetizationConfig = {}

-- GamePasses: durable ownership. Operator-provided IDs below.
MonetizationConfig.GamePasses = {
	GP_VIP = {
		id = 1998699067,
		price = 199,
		name = "VIP Supporter",
		description = "VIP crown trail, Supporter nameplate, golden lobby crown, +50% coins (capped +100% total).",
		category = "perks",
	},
	GP_EmotePack = {
		id = 1998153066,
		price = 99,
		name = "Emote Pack",
		description = "6 expressive emotes: Dance, Taunt, Wave, Sit, Point, Cheer.",
		category = "cosmetics",
		animationAssetId = 109991912171331,
		selectorAssetId = 8944416554,
	},
	GP_LockerSlots = {
		id = 0, -- Operator to provide
		price = 79,
		name = "Extra Locker Slots",
		description = "Expand your cosmetic locker by 12 slots.",
		category = "cosmetics",
	},
}

-- Developer Products: repeatable consumables. Operator-provided IDs below.
MonetizationConfig.Products = {
	DP_Starter = {
		id = 1998099063,
		price = 49,
		name = "Coin Starter Pack",
		description = "500 coins. Previewable - exact amount granted on purchase.",
		grants = { coins = 500 },
		category = "coins",
	},
	DP_Standard = {
		id = 1999245084,
		price = 199,
		name = "Standard Coin Pack",
		description = "1,800 coins. Previewable - exact amount granted on purchase.",
		grants = { coins = 1800 },
		category = "coins",
	},
	DP_Premium = {
		id = 1998567062,
		price = 499,
		name = "Premium Coin Pack",
		description = "5,500 coins. Previewable - exact amount granted on purchase.",
		grants = { coins = 5500 },
		category = "coins",
	},
	DP_StarterBundle = {
		id = 1999437069,
		price = 399,
		name = "Starter Bundle",
		description = '10,000 coins + exclusive "Blazing Trail" aura + exclusive emote. All contents shown before purchase.',
		grants = { coins = 10000, cosmeticId = "aura_blazing_trail", emoteId = "emote_starter_burst" },
		category = "bundle",
	},
}

-- Coin earn table by round placement (1st through 6th).
-- All values are base coins; VIP multiplier applied separately (capped).
MonetizationConfig.CoinEarnByPlacement = {
	[1] = 100,
	[2] = 70,
	[3] = 50,
	[4] = 30,
	[5] = 20,
	[6] = 10,
}

-- VIP bonus: multiplicative on coin earnings, capped at 0.5 (max +100% total).
-- GP_VIP grants 0.5 multiplier. No stacking beyond 0.5.
MonetizationConfig.VIPBonusCap = 0.5

-- Animation/Game assets provided by Operator for emotes and GUI.
-- These are real Roblox asset IDs (not gamepass/product IDs).
MonetizationConfig.AnimationAssets = {
	EmotePack = 109991912171331, -- animation pack: contains emote tracks
	EmoteSelector = 8944416554, -- emote selector UI module
	GUIAnimationPack = 136376766704443, -- GUI/UI animation pack (tweens, transitions)
}

-- Monetization asset Image IDs (uploaded via Open Cloud, all Approved).
-- Used for GamePass icons, Product icons, and reward previews in shop.
MonetizationConfig.AssetImages = {
	-- GamePass icons
	GP_VIP = 73703813474838,
	GP_EmotePack = 138461984056045,
	GP_LockerSlots = 0, -- placeholder

	-- Product icons
	DP_Starter = 84995738507820,
	DP_Standard = 120448396679309,
	DP_Premium = 84671549405033,
	DP_StarterBundle = 82020605779904,

	-- Reward previews
	Reward_VIPCrownTrail = 136308570690152,
	Reward_VIPNameplate = 110262811785349,
	Reward_VIPLobbyCrown = 114134285767791,
	Reward_Emote_Dance = 105812170122928,
	Reward_Emote_Taunt = 129997123779943,
	Reward_Emote_Wave = 81092024808655,
	Reward_Emote_Sit = 101717680487675,
	Reward_Emote_Point = 118033762175014,
	Reward_Emote_Cheer = 134244621286962,
	Reward_StarterAura = 133332792618061,
	Reward_StarterBundleEmote = 134244621286962, -- same as Celebration Emote
	Reward_CoinIcon = 0, -- use existing Coin.png from HUD atlas
	Reward_GiftBox = 75136744544530,
}

-- Party Pass config placeholder (Free-Fire-style monthly pass).
-- Gated by D7 cohort flag (PRD section 9, A2). Not active until D7 >= Minimum
-- on 2 consecutive weeks (PRD section 2).
MonetizationConfig.PartyPass = {
	enabled = false,
	price = 199,
	cycleDays = 30,
	d7CohortGate = true,
	dailyFreeRewards = {
		{ season = 1, day = 1, reward = { coins = 200 } },
		{ season = 1, day = 2, reward = { cosmeticId = "emoji_party" } },
		{ season = 1, day = 3, reward = { coins = 100 } },
	},
	premiumTierRewards = {
		{ season = 1, day = 1, reward = { coins = 500 } },
		{ season = 1, day = 2, reward = { cosmeticId = "emote_dance_flair" } },
		{ season = 1, day = 3, reward = { coins = 300 } },
	},
}

-- Currency formatter ladder: K / M / B / T (matches client formatCoins).
-- Data-only table; formatting logic lives in MonetizationService.formatCurrency.
MonetizationConfig.CurrencyFormatter = {
	thresholds = {
		{ value = 1000, suffix = "K" },
		{ value = 1000000, suffix = "M" },
		{ value = 1000000000, suffix = "B" },
		{ value = 1000000000000, suffix = "T" },
	},
}

return MonetizationConfig
