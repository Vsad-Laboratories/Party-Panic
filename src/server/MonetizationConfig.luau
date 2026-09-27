-- MonetizationConfig: data-only tables for ALL prices, IDs, and grants.
-- NO logic in this file — MonetizationService reads these tables.
-- Operator will replace placeholder IDs (0) with real Roblox asset IDs.
-- Skills applied: roblox-monetization (product type separation),
--   roblox-security (server-authoritative config).

local MonetizationConfig = {}

-- GamePasses: durable ownership. placeholder IDs = 0; Operator replaces.
MonetizationConfig.GamePasses = {
	GP_VIP = {
		id = 0,
		price = 199,
		name = "VIP",
		description = "2x coin earnings. Capped at +100% total (see VIPBonusCap).",
		category = "perks",
	},
	GP_EmotePack = {
		id = 0,
		price = 99,
		name = "Emote Pack",
		description = "5 expressive emotes for your avatar.",
		category = "cosmetics",
		animationAssetId = 109991912171331,
		selectorAssetId = 8944416554,
	},
	GP_LockerSlots = {
		id = 0,
		price = 79,
		name = "Extra Locker Slots",
		description = "Expand your cosmetic locker by 12 slots.",
		category = "cosmetics",
	},
}

-- Developer Products: repeatable consumables. placeholder IDs = 0; Operator replaces.
MonetizationConfig.Products = {
	DP_Starter = {
		id = 0,
		price = 49,
		name = "Starter Coins",
		description = "500 coins. Previewable - exact amount granted on purchase.",
		grants = { coins = 500 },
		category = "coins",
	},
	DP_Standard = {
		id = 0,
		price = 199,
		name = "Standard Coins",
		description = "1,800 coins. Previewable - exact amount granted on purchase.",
		grants = { coins = 1800 },
		category = "coins",
	},
	DP_Premium = {
		id = 0,
		price = 499,
		name = "Premium Coins",
		description = "5,500 coins. Previewable - exact amount granted on purchase.",
		grants = { coins = 5500 },
		category = "coins",
	},
	DP_StarterBundle = {
		id = 0,
		price = 399,
		name = "Starter Bundle",
		description = '10,000 coins + exclusive "Blazing Trail" aura. All contents shown before purchase.',
		grants = { coins = 10000, cosmeticId = "aura_blazing_trail" },
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

-- Currency formatter ladder: K / 10K / 100K / 1M / 10M / 100M / 1B / 10B / 100B / 1T / 10T / 100T.
-- Data-only table; formatting logic lives in MonetizationService.formatCurrency.
MonetizationConfig.CurrencyFormatter = {
	thresholds = {
		{ value = 1000, suffix = "K" },
		{ value = 10000, suffix = "10K" },
		{ value = 100000, suffix = "100K" },
		{ value = 1000000, suffix = "M" },
		{ value = 10000000, suffix = "10M" },
		{ value = 100000000, suffix = "100M" },
		{ value = 1000000000, suffix = "B" },
		{ value = 10000000000, suffix = "10B" },
		{ value = 100000000000, suffix = "100B" },
		{ value = 1000000000000, suffix = "T" },
		{ value = 10000000000000, suffix = "10T" },
		{ value = 100000000000000, suffix = "100T" },
	},
}

return MonetizationConfig
