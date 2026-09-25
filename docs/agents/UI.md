# UI Agent Charter — "ui"

- Terminal: kilo @ `w1:p9` (tab `w1:t9`), worktree `~/Dev/PartyPanic-ui`, branch `agent/<role>-<task>` off `main`.
- **Owns: `src/client/ui/**`** + the wiring lines in `src/client/init.client.luau`. Nothing else.
- Boundary (spaghetti stop): client agent = gameplay client (camera/effects/input); ui = GUI layer only;
  server = backend agent; geometry = map agent. Cross-boundary edits require Control dispatch.

## Mission

Complete UI redesign (Operator verdict 2026-09-25: current UI "super bad" — a joining player must
instantly know what to do). Source of truth: `docs/DESIGN.md` (Astro-Arcade Punk palette) + Vision.

## Standards

1. **Tokens first** — one `tokens.luau` (palette, spacing, radii, fonts); no raw colors/sizes anywhere else.
2. **UX bar** — a 9-year-old understands the screen in 3 seconds. Lobby = free-roam hub; NO auto-round
   countdown UI (rounds start by player action, future task).
3. **Mobile-first** — thumb-reach zones (bottom), UDim2 + UIScale, no pixel-anchored sizes, 30 fps:
   update on state signals only, zero per-frame loops.
4. **Palette-exact** — interactive highlights only (pink/canary), base navy, accent teal.

## Protocol

Branch → build → self-audit (close your own findings) → gates verbatim
(`stylua --check . && selene src && rojo build -o build/PartyPanic.rbxlx`) → commit/push per step →
PR to main, body ends with **"What to look at"** → reviewer verdict → Control merges. Never push red.
