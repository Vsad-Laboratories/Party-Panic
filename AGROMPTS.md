# AGROMPTS.md — Agent Prompts & Instructions
## Party Panic — Multi-Agent Fleet Configuration

> **Purpose**: Single source of truth for all agent identities, worktree locations, tooling, and operational mandates. This file is read by the SuperAgent (Control) before dispatching any task. Agents do NOT read this directly — Control translates into per-task prompts.

---

## Fleet Architecture

| Role | Agent ID | Worktree | Branch | Tool | Primary Domain |
|------|----------|----------|--------|------|----------------|
| **Backend** | `backend` | `~/Dev/PartyPanic-backend` | `backend/main` | **Kilo Code** | Server logic, DataStore, monetization, rounds, FSM |
| **Client** | `client` | `~/Dev/PartyPanic-client` | `client/main` | **Kilo Code** | Client-side systems, replication, input, effects |
| **Map** | `map` | `~/Dev/PartyPanic-map` | `map/main` | **OpenCode** | Geometry, LobbyHub, procedural generation, dressing |
| **UI** | `ui` | `~/Dev/PartyPanic-ui` | `ui/main` | **OpenCode** | HUD, Shop, menus, atlas icons, animations |
| **Reviewer** | *(Google Jules)* | — | — | **jules.google** | Reviews PRs on GitHub, creates fix PRs directly |

> **Reviewer Note**: Google Jules operates on GitHub directly (jules.google). It scans the full repo, reviews PRs, and opens fix PRs. Control does NOT run a local reviewer agent. Jules is invoked by Control via GitHub Actions or manual trigger.

---

## 1. BACKEND AGENT (Kilo Code)

### Worktree
- **Path**: `~/Dev/PartyPanic-backend`
- **Branch**: `backend/main`
- **Tool**: Kilo Code (CLI)

### Mandate
Owns ALL server-authoritative logic. No client trust. Every system must be exploitable-proof, idempotent, and observable.

### Core Domains
| System | Files | Key Requirements |
|--------|-------|------------------|
| **Bootstrap** | `src/server/Bootstrap.server.luau` | Service init order, dependency graph, error containment |
| **Lobby FSM** | `src/server/core/LobbyMachine.luau` | Free-roam lobby, manual round start only, state publishing |
| **Placements** | `src/server/core/Placements.luau` | Deterministic spawns, tile claiming mutex, no auto-start |
| **Floor Fall** | `src/server/core/FloorFall.luau` | Procedural grid, wave drops, elimination, solo-safe |
| **Round Rotation** | `src/server/core/RoundRotation.luau` | Registry-driven, map voting, variant slots |
| **Playtime** | `src/server/core/PlaytimeService.luau` | Idempotent saves, zero-delta fold, BindToClose flush |
| **Monetization** | `src/server/MonetizationService.luau` | ProcessReceipt, GamePass cache, ShopPurchase, asset packs |
| **DataStore** | `src/server/core/DataStoreWrapper.luau` | UpdateAsync patterns, TTL receipts, retry with backoff |

### Data Contracts (Shared)
- `src/shared/LobbyState.luau` — `LobbyStatePayload` (state, players, ownedPasses, equipped, level, xp, coinCount)
- `src/shared/RoundContract.luau` — Round types, results, rewards
- `src/shared/MonetizationConfig.luau` — GamePass/Product IDs, CurrencyTiers, AssetImages

### Non-Negotiable Rules
1. **Server-authoritative**: Client NEVER decides prices, ownership, or grants.
2. **Idempotent writes**: Every DataStore write uses UpdateAsync with retry + TTL receipt tracking.
3. **No auto-round-start**: Lobby = free roam. Round start = manual trigger only (PRD §3).
4. **ProcessReceipt is singular**: One handler, idempotent on PurchaseId, returns `NotProcessedYet` on unknown products.
5. **GamePass cache**: Session-cached, invalidated on `PromptGamePassPurchaseFinished`.
5. **BindToClose flush**: All pending saves must complete within 30s timeout.
6. **Type safety**: `--!strict` on all modules. Shared types in `src/shared/`.
7. **No magic numbers**: All tunables in config modules (MonetizationConfig, RoundConfig, etc.).

### Skills to Apply
- `roblox-monetization` — Receipt handling, GamePass checks, product grants
- `roblox-security` — Authority model, remote validation, exploit vectors
- `roblox-datastores` — UpdateAsync patterns, idempotent writes, TTL
- `roblox-luau-patterns` — Module lifecycle, signals, task scheduling, cleanup
- `roblox-code-review` — Self-audit before PR: race conditions, nil risks, leak checks

### PR Discipline
- One substantial PR per system (not per file).
- Body must list: what changed, why, how verified (walkthrough with concrete state).
- Gates: `stylua --check src`, `selene src`, `rojo build` — all must pass locally before push.
- Never merge own PRs. Operator merges after reviewer (Jules) verdict.

---

## 2. CLIENT AGENT (Kilo Code)

### Worktree
- **Path**: `~/Dev/PartyPanic-client`
- **Branch**: `client/main`
- **Tool**: Kilo Code (CLI)

### Mandate
Owns ALL client-side systems. Replication consumers, never authorities. Smooth 60fps on low-end mobile.

### Core Domains
| System | Files | Key Requirements |
|--------|-------|------------------|
| **Replication** | `src/client/Replication.luau` | LobbyStateEvent listener, delta application, prediction |
| **Input** | `src/client/Input.luau` | Touch/PC unified, action binding, no ghost inputs |
| **Character** | `src/client/Character.luau` | Local animation, movement smoothing, emote playback |
| **Camera** | `src/client/Camera.luau` | Lobby orbit, round follow, shake effects |
| **Effects** | `src/client/Effects.luau` | Particle emitters, trails, auras, screen shake |
| **UI Bridge** | `src/client/UIBridge.luau` | Router events, screen transitions, HUD updates |

### Non-Negotiable Rules
1. **Zero trust on server data**: Validate all RemoteEvent payloads, handle nil/malformed.
2. **Prediction + reconciliation**: Local movement predicted, server corrections applied smoothly.
3. **Asset preloading**: All atlases, sounds, animation packs preloaded at boot via ContentProvider.
4. **Memory discipline**: Pool particles/emitters. Clean up on round end. No memory leaks over 30min sessions.
5. **Low-end target**: 30fps on 4GB RAM devices. Profile with MicroProfiler.
6. **Animation packs**: Load from ReplicatedStorage (server-placed), never InsertService on client.

### Skills to Apply
- `roblox-animations` — AnimationTrack priority, blending, emote override
- `roblox-luau-patterns` — Module ownership, cleanup, signal discipline
- `roblox-performance` — Pooling, LOD, MicroProfiler workflows

---

## 3. MAP AGENT (OpenCode)

### Worktree
- **Path**: `~/Dev/PartyPanic-map`
- **Branch**: `map/main`
- **Tool**: OpenCode

### Mandate
Owns ALL geometry, LobbyHub, procedural arenas, dressing. Deterministic, auditable, performant.

### Core Domains
| System | Files | Key Requirements |
|--------|-------|------------------|
| **LobbyHub** | `src/server/maps/LobbyHub/` | `config.luau` (data), `init.luau` (builder), `cleanup()` |
| **Floor Fall Arena** | `src/server/maps/FloorFall/` | Procedural grid, tile variants, elimination zones |
| **Round Arenas** | `src/server/maps/<RoundName>/` | Registry-driven, variant slots, voting pads |
| **Dressing** | `src/server/maps/Dressing.luau` | Asset loading (InsertService + script strip), placement |

### Current LobbyHub Spec (Reference Match)
| Element | Value |
|---------|-------|
| Ground disc | D140, y=1, grass green (106,190,75) |
| Wall ellipse | a=60, b=40 (outer 120×80), height 15, Slate blue stone (40,60,120) |
| Top rim | Grass green, y=15.5..16, width 4 |
| Platform | D24, Neon cyan (0,200,255), y=1..4 |
| Spawn | **Mythical plate asset 110144096035671** centered at (0,4.5,0) |
| Stalls | 3 × asset 16263631766 at x=-40, 1.2x scale (6,7,5) |
| Trees | 6 × asset 12549617200 at Z>40/Z<-40, inside disc |
| Rocks | 3 × assets 16933634812/10355509588/13471036173 spread |
| Leaderboard | Asset 5352156968 at (45,5,35) |
| Lighting | Brightness 2.5, Ambient (160,160,160), GlobalShadows, ShadowSoftness 0.3, Atmosphere Density 0.25 |

### Geometry Checker (Mandatory)
- SAT-based checker modeling chord boxes (chord-mid center, Z=chord dir, length=chord×arcFactor)
- Layers checked only where y-ranges strictly overlap
- Touching allowed (gap ≥ -0.001), no volume overlap
- Max corner radius ≤ disc radius (margin ≥ 0)
- Output pasted in PR body

### Non-Negotiable Rules
1. **Config-driven**: All plan dimensions in `config.luau`. `init.luau` derives — no hardcoded numbers.
2. **Deterministic**: Same config → identical geometry every run. No RNG in builder.
3. **Part budget**: LobbyHub ≤ 150 parts base + dressing ≤ 250 total.
4. **Script stripping**: InsertService loads → destroy all Script/LocalScript/ModuleScript descendants → parent.
5. **Reference fidelity**: Match `assets/Reference/Lobby.jpg` composition. Visual diff = PR blocker.
6. **No neon/edge lines**: RingEdge, DecorRing REMOVED per Operator.

### Skills to Apply
- `roblox-building` — Geometry, parts, materials, lighting
- `roblox-luau` — Config patterns, builder functions
- `roblox-performance` — Part count, draw calls, LOD

---

## 4. UI AGENT (OpenCode)

### Worktree
- **Path**: `~/Dev/PartyPanic-ui`
- **Branch**: `ui/main`
- **Tool**: OpenCode

### Mandate
Owns ALL player-facing UI. HUD, Shop, menus, atlas icons, animations. Charter: `src/client/ui/` only.

### Core Domains
| System | Files | Key Requirements |
|--------|-------|------------------|
| **HUD** | `src/client/ui/lobby.luau` | Nav columns, bottom cluster, tooltips, preload |
| **Shop** | `src/client/ui/shop.luau` | Catalog grid, purchase flow, locker, status row |
| **Icons** | `src/client/ui/icons.luau` | Atlas 104056199975187, `icons.apply()` |
| **Tokens** | `src/client/ui/tokens.luau` | Palette, fonts (BuilderSans), radii, textSizes |
| **Sounds** | `src/client/ui/sounds.luau` | Hover 127105730240202, Click 138567614125924 |
| **Router** | `src/client/ui/router.luau` | ScreenGui lifecycle, lazy open/close |
| **Shop Config** | `src/client/ui/ShopConfig.luau` | Catalog data (cosmeticId, coinPrice, atlas slot) |
| **Monetization Config** | `src/client/ui/MonetizationConfig.luau` | GamePass/Product IDs, formatCoins, AssetImages |

### Current HUD Spec (Operator Mandate)
| Element | Spec |
|---------|------|
| Nav buttons | Uniform navy boxes, rounded (radii.lg), ScaleType.Fit, atlas icons centered |
| SFX | Hover 127105730240202 (0.45 vol), Click 138567614125924 (0.45 vol) |
| Tooltip | 100×25 frame, text size 6, 0.12s delay, 0.1s fade, instant hide, mouse-only |
| Level bar | Centered, taller, LV inside + track + 0/100 inside |
| Coin pill | Upper-left of bar, AutomaticSize.X, dynamic width, formatCoins |
| Effect list | Upper-right of bar, hidden when empty, no mock data |
| Preload | Atlas (104056199975187) + hover/click sounds at boot |

### Icon Atlas (Source of Truth)
- **Atlas ID**: `104056199975187` (410×328, 82×82 slots, 5 cols)
- **Function**: `icons.apply(target, name)` sets Image, ImageRectOffset, ImageRectSize, ScaleType=Fit
- **19 shipped**: Back, Buy, Claim, Close, Coin, Confirm, Inventory, Lock, MiniGames, Packs, PartyPass, Perk, Play, Players, Settings, Shop, Stats, VoteMap, WorldMap
- **5 pending**: Level, Sell, Equip, Unequip, Gift → render blank

### Non-Negotiable Rules
1. **Charter boundary**: ALL UI in `src/client/ui/`. No UI code outside.
2. **Atlas-only**: Never use raw asset IDs in UI code. Always `icons.apply()`.
3. **ScaleType.Fit + AnchorPoint 0.5**: Every icon centered in square hitbox, zero letterbox.
4. **Palette law**: `tokens.palette` only. BuilderSans via `Font.fromName`.
5. **Soft pop sounds**: Every button hover/click. Volume 0.45.
6. **No mock data**: Empty catalog → "Coming Soon". Empty effect list → hidden.
6. **ContentProvider preload**: Atlas + sounds at `Lobby._preload()`.
7. **Mobile-first**: Touch targets ≥ 44px. Tooltip mouse-only (no mobile hover).

### Skills to Apply
- `roblox-gui` — ScreenGui, ImageButton, UICorner, UIStroke, ScaleType
- `roblox-ui-design` — Visual hierarchy, scaling, accessibility
- `roblox-monetization` — Shop flow, GamePass gating, price display
- `roblox-animations` — TweenService, GUIAnimationPack helpers
- `roblox-luau-patterns` — Module ownership, cleanup, lazy loading

---

## 5. REVIEWER (Google Jules)

### Identity
- **Platform**: jules.google (Google's AI coding agent)
- **Operation**: Scans GitHub repo directly, reviews PRs, opens fix PRs
- **Trigger**: Control invokes via GitHub Actions or manual "Jules, review #N" comment

### Scope
Reviews ALL PRs before Operator merge. Focus: correctness, security, performance, fidelity to spec.

### Review Checklist (Per PR)
| Category | Checks |
|----------|--------|
| **Correctness** | Logic matches spec, no race conditions, idempotent writes, nil safety |
| **Security** | Server-authoritative, no client trust, remote validation, exploit vectors |
| **Performance** | Part count, draw calls, memory, MicroProfiler hot paths |
| **Fidelity** | Matches Operator spec, reference images, charter boundaries |
| **Type Safety** | `--!strict` clean, shared types used, no `any` leakage |
| **Gates** | stylua/selene/rojo pass, PR body honest, skills named |

### Output Format
Jules posts review on GitHub PR with:
- **VERIFIED** items (green)
- **BLOCKERS** (red — must fix before merge)
- **MAJORS** (orange — significant but not blocking)
- **MINORS** (yellow — polish)
- **VERDICT**: `APPROVE` or `REQUEST CHANGES`

### Control Integration
Control reads Jules' review, dispatches fix tasks to agents, re-requests review after fixes. Operator merges only after Jules `APPROVE`.

---

## Operational Protocols

### Dispatch Protocol (Control → Agent)
```
herdr agent prompt <pane> "<task prompt>" --wait --until working --timeout 25000
```
- Prompt includes: exact head SHA, files to touch, acceptance criteria, gates, skills.
- Agent works in its worktree on its branch.
- Agent commits, pushes, opens PR with structured body.

### Review Protocol
1. Agent pushes → CI runs (stylua/selene/rojo).
2. Control invokes Jules: "Jules, review #N" or GitHub Action.
3. Jules posts review on GitHub.
4. Control reads verdict → dispatches fixes if needed → re-review.
5. Operator merges after Jules `APPROVE`.

### Merge Protocol
- **Operator merges**. Fleet never merges.
- Merge order: no file overlap → order irrelevant; squash + delete branch.
- Post-merge: main CI + publish → playtest.

### Branch Hygiene
- Agent branches: `<role>/main` (long-lived) + `<role>/<task>` (ephemeral PR branches).
- Ephemeral branches deleted after merge.
- `git worktree prune` periodically.

---

## Reference Assets (ASSETS.md)

| Category | Asset IDs |
|----------|-----------|
| **Lobby Props** | Tree 12549617200, Rocks 16933634812/10355509588/13471036173, Stalls 16263631766, Mythical Plate 110144096035671, Leaderboard 5352156968 |
| **Animations** | Emote Pack 109991912171331, Selector 8944416554, GUI Pack 136376766704443 |
| **VFX** | Particle Pack 15261348321, Trail System 3222976721, Aura Packs 15374038687/106979401006635 |
| **Audio** | Hover 127105730240202, Click 138567614125924, Lobby Loop 9112819065, etc. |
| **UI Icons** | Atlas 104056199975187 (19 icons), Coin 115356376743509 |

---

## Key Operator Decisions (Locked)

1. **No gacha ever** — Every paid reward previewed.
2. **Party Pass replaces Battle Pass** — Monthly, free-fire style, gated by D7 cohort proof.
3. **Cosmetics lead, power capped** — VIP +50% coins capped at +100% total.
4. **No auto-round-start** — Lobby = free roam, manual trigger only.
5. **Soft pop sounds** — Hover 127105730240202, Click 138567614125924 on EVERY button.
6. **UI charter** — All UI in `src/client/ui/`. UI agent owns that subtree.
7. **Icon pipeline** — Open Cloud upload → assets/IDs.txt → icons.luau atlas.
8. **Google Jules reviewer** — Reviews on GitHub, creates fix PRs. Control coordinates.

---

*This document is the fleet constitution. Control reads it before every dispatch. Update when architecture changes.*