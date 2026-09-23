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
| Local Studio | **Vinegar on HP Pavilion 14 SleekBook — EXPERIMENT IN PROGRESS, UNVERIFIED** | Linux box; no official browser Studio exists. Until Vinegar is proven, testing path = CI artifact `PartyPanic.rbxlx` |
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
- 🔄 **Vinegar on the SleekBook:** Studio launched, first-launch package install in progress (slow first boot expected). NOT verified yet — mark verified only after `rojo serve` connects and the smoke prints (`[PartyPanic] server/client booted`) appear in Studio Output.
- ⏳ Open Cloud auto-publish deliberately NOT added to CI — local Studio via Vinegar is now the likely primary loop; revisit only if Vinegar fails.
- Known CI noise (not bugs): `actions/checkout@v4` / `upload-artifact@v4` Node 20 deprecation warning (forced onto Node 24, harmless); `ubuntu-latest` → Ubuntu 26 migration notice (Oct 2026).

## Next steps (in order)

1. Vinegar proof: open built place or `rojo serve` → smoke prints in Output → local dev loop restored.
2. Sprint 1–2: lobby + Floor Fall round (creates `src/rounds/`, round contract).
3. Operator assigns agent roles/skills → wire into herdr panes.
4. Deferred: Open Cloud publish step (only if artifact/local loop proves insufficient).
