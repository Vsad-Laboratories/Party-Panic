--!strict
-- Design tokens: single source of truth for color, spacing, radii, fonts.
-- Palette via docs/DESIGN.md (Astro-Arcade Punk, theme locked 2026-09-25).
-- pink + canary are interactive-only highlights; no raw color/size elsewhere.

type Palette = {
	base: Color3, -- slate blue (surfaces)
	navy: Color3, -- cosmic navy (background)
	accent: Color3, -- teal-cyan (primary text / headings)
	pink: Color3, -- neon pink (interactive)
	canary: Color3, -- canary (interactive)
	text: Color3, -- readability neutral on dark
}

type Spacing = {
	xs: number,
	sm: number,
	md: number,
	lg: number,
	xl: number,
	xxl: number,
}

type Radii = {
	sm: number,
	md: number,
	lg: number,
	full: number,
}

type Fonts = {
	heading: Enum.Font,
	body: Enum.Font,
	mono: Enum.Font,
}

type TextSizes = {
	display: number,
	title: number,
	pill: number,
	body: number,
	caption: number,
}

local tokens: {
	palette: Palette,
	spacing: Spacing,
	radii: Radii,
	fonts: Fonts,
	textSizes: TextSizes,
} = {
	palette = {
		base = Color3.fromRGB(46, 58, 89),
		navy = Color3.fromRGB(35, 43, 69),
		accent = Color3.fromRGB(95, 227, 211),
		pink = Color3.fromRGB(255, 63, 164),
		canary = Color3.fromRGB(255, 225, 77),
		text = Color3.fromRGB(235, 242, 250),
	},
	spacing = {
		xs = 4,
		sm = 8,
		md = 16,
		lg = 24,
		xl = 32,
		xxl = 48,
	},
	radii = {
		sm = 6,
		md = 12,
		lg = 16,
		full = 999,
	},
	fonts = {
		heading = Enum.Font.GothamBold,
		body = Enum.Font.Gotham,
		mono = Enum.Font.Code,
	},
	textSizes = {
		display = 48,
		title = 36,
		pill = 24,
		body = 20,
		caption = 14,
	},
}

return tokens
