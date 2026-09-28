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
	heading: Font,
	body: Font,
	mono: Enum.Font,
}

type TextSizes = {
	display: number,
	title: number,
	pill: number,
	body: number,
	caption: number,
}

-- Control sizing scale. One square edge for every nav button, one chip height, one gap
-- unit, one screen-edge margin: the HUD sizes in px under a single UIScale instead of
-- per-axis scale fractions, which stretched every control differently on 16:9.
type Controls = {
	button: number, -- square nav button edge == the icon rect (1:1 hitbox)
	buttonGap: number, -- vertical gap between rail buttons
	edge: number, -- symmetric margin from the screen edge
	chipHeight: number, -- status / bottom-bar chip height
	chipGap: number, -- horizontal gap between bar chips
	chipIcon: number, -- square icon slot inside a chip
	tipGap: number, -- gap between a button and its tooltip
}

type Tokens = {
	palette: Palette,
	spacing: Spacing,
	radii: Radii,
	fonts: Fonts,
	textSizes: TextSizes,
	controls: Controls,
}

local tokens: Tokens = {
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
		heading = Font.fromName("BuilderSans", Enum.FontWeight.ExtraBold),
		body = Font.fromName("BuilderSans", Enum.FontWeight.Regular),
		mono = Enum.Font.Code,
	},
	textSizes = {
		display = 48,
		title = 36,
		pill = 24,
		body = 20,
		caption = 14,
	},
	controls = {
		button = 60,
		buttonGap = 12,
		edge = 24,
		chipHeight = 44,
		chipGap = 12,
		chipIcon = 24,
		tipGap = 8,
	},
}

return tokens
