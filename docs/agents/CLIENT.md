# Charter — Client (Kilo Code)

**Scope:** `src/client/`. Never edit `src/server/`/`src/shared/` (Backend's charter) or CI/tooling (Control's).

## First task — S1: lobby UI shell (mocked)

Build the lobby surface against **mock local state** — no server wiring yet (Backend's frame contract lands first; wiring is task 2 after both PRs merge).

1. ScreenGui lobby surface, mobile-first: thumb-reach, large hit targets (PRD §6 — low-end mobile, no reading-heavy screens).
2. Elements: player count + list placeholder, countdown label, three map-vote buttons, winner-crown display area, coin counter.
3. One file per UI surface under `src/client/` (e.g. `LobbyUI.luau`); a tiny local mock driver so it animates/countdowns in a play test without a server.
4. No assets/fonts beyond Roblox defaults. Big numbers, minimal text — audience is 9–13.

**Task 1 acceptance:** play test in Studio shows a working, animated lobby shell; gates green; PR `agent/client-ui-shell`.
Next (after merge): wire to server events from Backend's contract.
