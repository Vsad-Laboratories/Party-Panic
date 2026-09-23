# Party Panic — Vision & Session Context

> Handoff document for any AI session. Read this first, then `docs/GDD.md` (locked decisions + roadmap), then `~/RULES.md` + `~/MastersEngineer.md` (behavior + code rules).

## Vision

Build the simplest round-based party royale on Roblox that kids 9–13 replay daily and invite friends to — shipped and maintained by a solo operator with a professional AI-agent workflow, where **content updates are data-only and ship weekly**.

Success looks like: D1 retention above Roblox genre average, session length 10+ min, organic invites (referral cosmetics), and a repo where a new minigame never risks breaking the existing game.

## Pillars (every decision checks against these)

1. **Content is data** — one file per minigame in `src/rounds/`; new round/map/cosmetic = data + at most one new module, zero edits to the core loop.
2. **The frame is fixed** — lobby → vote → round state machine → rewards. Code changes are rare; data changes are weekly.
3. **Nothing merges red** — CI gate: `stylua --check` → `selene` → `rojo build`. AI PRs must pass before human review.
4. **Anti-spaghetti** — RULES.md hard rules 11/12: codebase trends toward spaghetti-fication → STOP, ask Operator; no fluff additions ever.
5. **Minimal, portable, idempotent** — every line justifies itself; `~` paths; re-runs safe.

## Architecture

```
Party Panic (Roblox place, built by Rojo from this repo)
├── src/server/      round state machine, lobby, matchmaking, persistence, economy
├── src/client/      UI, input, spectate/replay cam
├── src/shared/      round interface, configs, tables   (created when first needed)
├── src/rounds/      ONE FILE PER MINIGAME             (created sprint 3 — nothing speculative)
├── assets/          .obj meshes + textures, versioned (AI-gen, low-poly <5k tris, single palette)
├── default.project.json   Rojo: repo → place mapping
├── rokit.toml              pinned: rojo 7.7.0, selene 0.31.0, stylua 2.5.2
├── docs/GDD.md             locked decisions + roadmap
├── Vision.md               this file
└── .github/workflows/ci.yml  stylua --check → selene → rojo build → PartyPanic.rbxlx artifact
```

- **DataModel mapping:** `ServerScriptService.Server` ← `src/server` (Script), `StarterPlayer.StarterPlayerScripts.Client` ← `src/client` (LocalScript), `ReplicatedStorage.Shared` ← `src/shared` (when created).
- **Round contract (sprint 3 design, not yet written):** each round module exposes lifecycle functions the state machine calls (setup → play → cleanup); rounds never touch each other — this is what keeps AI-generated rounds safe to merge.

## Stack & workflow (locked)

| Layer | Choice | Note |
|---|---|---|
| Repo | github.com/Vsad-Laboratories/Party-Panic, `main` | git-push-driven; every push = trackable change |
| Local Studio | **Vinegar on HP Pavilion 14 SleekBook — VERIFIED 2026-09-23: Studio launches** (fix: `[studio] renderer = "Vulkan"` in Vinegar config; earlier "silicon ceiling" verdict was wrong) | Linux box; no official browser Studio exists. CI artifact `PartyPanic.rbxlx` remains the fallback + publish source |
| Agent multiplexer | herdr (v0.9.1 installed) | replaced OpenChamber — rejected 2026-09-23 |
| Feature coding | Kilo Code | works in-repo against `src/` |
| Autonomous tasks | Jules | GitHub issues → PRs; must pass CI first |
| 3D assets | Meshy / Tripo / Rodin | low-poly, <5k tris, single palette texture |
| Agent roles/skills | Operator will assign | pending |

Game loop: lobby → vote → 60–90 s round → elimination/scoring → coins → repeat; winner wears crown in lobby.

Monetization (locked): cosmetics + battle pass + power/perk gamepasses + products; ads later. Recorded warning: power gamepasses to 9–13 risk review/retention burn — cap power, lead with cosmetics.

## Current state (update on every session end)

- ✅ Repo bootstrapped and **public** → GitHub Actions free. Pushes: `eadc3c7` bootstrap → `8f4f285` Vision.md → `b80fd80` CI fix.
- ✅ **CI verified green** (run 35851129161, 9 s): `rokit install --no-trust-check` (official CI flag — trust prompts are interactive-only) → selene std → stylua --check → selene → rojo build → `PartyPanic.rbxlx` artifact uploaded. Local gates also green (0 lint errors, instances verified in place file).
- ✅ **Vinegar WORKS (2026-09-23): reinstalled 1.9.4 → Roblox Studio launches to home screen.** Fix: `~/.var/app/org.vinegarhq.Vinegar/config/vinegar/config.toml` → `[studio] renderer = "Vulkan"` (YouTube-tutorial-sourced). **My earlier "silicon ceiling" verdict was wrong** — `intel_hasvk` ICD exposes Ivy Bridge HD 4000 at Vulkan 1.3.354 (read from ICD manifests); the first-run clientcrash (RBXCRASH-Undefined, exit 67, DXVK "No adapters found") did not recur after clean reinstall + renderer setting — original cause was the botched first-run install. Sober 1.7.1 kept. Logs: `~/.var/app/org.vinegarhq.Vinegar/cache/vinegar/logs/`.
- ✅ **Path A locked (2026-09-23): no-Studio loop** — push → CI build → Open Cloud publish (`POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`, scope `universe-places:write`, .rbxlx as data-binary, official docs verified) → playtest in Sober. CI `publish` job exists but **skips until repo is configured**: secret `ROBLOX_API_KEY` + vars `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID`.
- ⏳ **Rojo Studio plugin NOT installed yet** (manual step in Studio): https://www.roblox.com/library/96353449041057/Rojo-7-5-1 → then `rojo serve` in `~/Dev/Party Panic` + Connect = local hot-sync loop.
- Known CI noise (not bugs): `actions/checkout@v4` / `upload-artifact@v4` Node 20 deprecation warning (forced onto Node 24, harmless); `ubuntu-latest` → Ubuntu 26 migration notice (Oct 2026).

## Next steps (in order)

1. Operator setup for Path A — **Studio now runs on the SleekBook, no borrowing needed** (web Create still can't make experiences; Open Cloud has no create endpoint — creation is Studio-only): File → New → Baseplate → File → **Publish to Roblox As…** → name "Party Panic", keep Private (avoids overwriting `Owner_Vsad's Place`) → dashboard: Universe ID (thumbnail ⋯ menu) + Place ID (Places tab → URL) → API key (create.roblox.com/dashboard/credentials), **universe-places → Write**, bound to the game → repo secret `ROBLOX_API_KEY` + vars `ROBLOX_UNIVERSE_ID`/`ROBLOX_PLACE_ID` → push → confirm `versionNumber` in publish step → playtest in Sober.
2. Sprint 1–2: lobby + Floor Fall round (creates `src/rounds/`, round contract).
3. Operator assigns agent roles/skills → wire into herdr panes.
