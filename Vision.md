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

- ✅ Repo bootstrapped, pushed `eadc3c7`: Rojo project, lint/format configs, CI, GDD, Vision.
- ✅ Local gates green: `stylua --check` OK, `selene` 0/0/0, `rojo build` OK (Server + Client instances verified in `.rbxlx`).
- ❌ **GitHub Actions blocked: account billing/spending-limit error — job never ran, CI steps still unproven.** Fix `Settings → Billing & plans`, or make repo public (free Actions, exposes plan).
- 🔄 Vinegar install on the SleekBook in progress — first real playtest of the smoke scripts (`[PartyPanic] server/client booted` in Output console).
- ⏳ Open Cloud auto-publish step deliberately NOT added to CI yet — decide after testing-path question is answered (artifact download vs. API publish vs. local Studio via Vinegar).

## Next steps (in order)

1. Resolve Actions billing → push a trivial change → verify CI actually goes green (watch for `rokit install` trust prompts in CI; fix empirically if they appear).
2. Vinegar verification: Studio opens, `rojo serve` connects, smoke prints appear → local dev loop restored.
3. Sprint 1–2: lobby + Floor Fall round (creates `src/rounds/`, round contract).
4. Operator assigns agent roles/skills → wire into herdr panes.
