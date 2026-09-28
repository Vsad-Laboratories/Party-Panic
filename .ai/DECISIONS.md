# DECISIONS.md — Architectural Decision Record
## Party Panic — Immutable Decisions, No Re-Litigation

> **Format**: Each decision is final unless explicitly superseded. New decisions append only. Format: `DEC-<number> — <title> — <date> — <status>`

---

## DEC-001 — Fleet Architecture: 4 Local Agents + Google Jules Reviewer
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Context**: Need clear ownership, no shared working trees, professional review.  
**Decision**: 
- 4 local agents (Backend Kilo, Client Kilo, Map OpenCode, UI OpenCode) + Google Jules (GitHub)
- Herdr for terminal orchestration
- Git worktrees enforce isolation
- Jules reviews PRs on GitHub, creates fix PRs
**Consequences**: No local reviewer agent. Jules invoked via GitHub. Clear boundaries.

---

## DEC-002 — Tooling Assignments
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**:
| Agent | Tool | Rationale |
|-------|------|-----------|
| Backend | Kilo Code | Server logic, DataStore, monetization |
| Client | Kilo Code | Replication, character, effects |
| Map | OpenCode | Geometry, LobbyHub, procedural |
| UI | OpenCode | HUD, Shop, atlas, animations |
| Reviewer | Google Jules | GitHub-native, creates fix PRs |

---

## DEC-003 — Git Worktree Isolation
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Each agent owns a worktree on a long-lived branch (`backend/main`, `client/main`, `map/main`, `ui/main`). PR branches are ephemeral (`agent/<role>-<slug>`). No agent pushes to another's worktree. No agent pushes to `main` directly.  
**Enforcement**: `git worktree list` verification in SuperAgent workflow.

---

## DEC-004 — Branch Strategy
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**:
- Long-lived: `backend/main`, `client/main`, `map/main`, `ui/main` (track `main` via rebase)
- PR branches: `agent/<role>-<slug>` (ephemeral, deleted after merge)
- `main` only updated via Operator merge (squash + delete branch)
- No direct pushes to `main` by agents

---

## DEC-005 — Agent Boundaries (Hard, Git-Enforced)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: 
| Agent | Owns | Cannot Touch |
|-------|------|--------------|
| Backend | `src/server/**`, `src/shared/**` | `src/client/ui/**`, `src/server/maps/**` |
| Client | `src/client/**` (non-UI) | `src/client/ui/**`, `src/server/**` |
| Map | `src/server/maps/**` | `src/client/**`, `src/server/core/**` |
| UI | `src/client/ui/**` | `src/server/**`, `src/client/` (non-UI) |
| Tester | Read all | Write any `src/` |
| Researcher | Read all | Write `src/` |
| Docs | `docs/**`, `.ai/**`, `README.md` | `src/` |

**Enforcement**: Orchestrator validates file lists in task assignments. Git shows violations.

---

## DEC-006 — Communication Protocol (Structured JSON)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: All inter-agent communication uses structured message types (TASK_CREATED, TASK_ASSIGNMENT, TASK_COMPLETED, TEST_REPORT, FINDINGS, VERDICT). No free-form chat. Orchestrator is the only router.  
**Schema**: Defined in `WORKFLOW.md` Section 4.

---

## DEC-006 — Reviewer = Google Jules (No Local Reviewer Agent)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Google Jules (jules.google) reviews PRs on GitHub. Creates fix PRs directly. Leader invokes via "Jules, review #N" comment. No local reviewer agent runs.  
**Rationale**: Jules has full repo context, creates fix PRs, integrates with GitHub. Eliminates local reviewer session conflicts.

---

## DEC-007 — Verification Gates (Mandatory Before Report)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Every Builder task must pass these locally before reporting DONE:
```bash
# Backend/Client
stylua --check src
selene src
rojo build

# Map
stylua --check src
selene src
rojo build

# UI
stylua --check src
selene src
rojo build
```
**No exceptions**. CI must pass locally before push.

---

## DEC-007 — Monetization Architecture
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: 
- GamePass IDs: VIP=1998699067, EmotePack=1998153066, LockerSlots=pending
- Product IDs: Starter=1998099063, Standard=1999245084, Premium=1998567062, StarterBundle=1999437069
- VIP coin bonus: +50% capped at +100% total (VIPBonusCap = 0.5)
- Currency formatter: K/M/B/T ladder (1e3/1e6/1e9/1e12), mantissa logic, 100T+ cap
- Party Pass: Monthly Free-Fire style, gated by D7 cohort proof (disabled at launch)
- No gacha ever. Cosmetics lead, power capped.

---

## DEC-008 — Currency Formatter (Client/Server Parity)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Server `formatCurrency` must match client `formatCoins` exactly:
- Tiers: K (1e3), M (1e6), B (1e9), T (1e12)
- Mantissa: 1 decimal below 10, integer ≥ 10
- Round half-up, bump to next tier if rounded ≥ 1000
- Cap: 100T+ for ≥ 1e14
- Config: `CurrencyTiers` array in MonetizationConfig (shared)

---

## DEC-008 — Lobby Reference Match (Operator Mandate)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: LobbyHub must match `assets/Reference/Lobby.jpg` exactly:
| Element | Spec |
|---------|------|
| Ground disc | D140, y=1, grass (106,190,75) |
| Wall ellipse | a=60, b=40 (outer 120×80), height 15, Slate blue stone (40,60,120) |
| Platform | D24, Neon cyan (0,200,255), y=1..4 |
| Spawn | Mythical plate asset 110144096035671 centered (0,4.5,0) |
| Stalls | 3 × asset 16263631766 at x=-40, 1.2x scale (6,7,5) |
| Trees | 6 × asset 12549617200 at Z>40/Z<-40, inside disc |
| Rocks | 3 × assets 16933634812/10355509588/13471036173 spread |
| Leaderboard | Asset 5352156968 at (45,5,35) |
| Removed | ringEdge, decorRing (neon/cosmic navy) |
| Lighting | Brightness 2.5, GlobalShadows, ShadowSoftness 0.3 |

**Geometry checker mandatory**: SAT-based, chord-box model, touching allowed, no volume overlap.

---

## DEC-009 — UI Icon Atlas (Single Source of Truth)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: 
- Atlas ID: `104056199975187` (410×328, 82×82 slots, 5 cols)
- Function: `icons.apply(target, name)` sets Image, ImageRectOffset, ImageRectSize, ScaleType=Fit
- 19 shipped icons mapped; 5 pending (Level, Sell, Equip, Unequip, Gift) render blank
- **Never use raw asset IDs in UI code**. Always `icons.apply()`.
- ScaleType.Fit + AnchorPoint 0.5 everywhere.

---

## DEC-010 — Soft Pop Sounds (Every Button)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Every button gets hover + click sounds:
- Hover: `127105730240202` (volume 0.45)
- Click: `138567614125924` (volume 0.45)
- Implemented in `sounds.luau`, used in `lobby.luau` and `shop.luau` factories.

---

## DEC-011 — Shop Architecture
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**:
- ScreenGui `ShopGui`, ResetOnSpawn=false, opened via `router.open('Shop')`
- Catalog grid (UIGridLayout) from `ShopConfig.luau` (data only)
- Categories: Crown Trails, Victory Poses, Entrance Effects, Emotes, Elimination Effects, Nameplates, Locker Slots
- Purchase: RemoteEvent `ShopPurchase` → server validates via MonetizationService
- Locker: 5 default slots, +10 if GP_LockerSlots owned, drag-to-equip
- Status row in HUD: equipped crown/title/trail from player data
- No mock data: empty catalog → "Coming Soon", empty effect list → hidden

---

## DEC-012 — Asset Loading (Server → ReplicatedStorage)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: 
- Server loads asset packs via InsertService in `MonetizationService.init()`
- Strips all Script/LocalScript/ModuleScript descendants
- Places ModuleScripts in ReplicatedStorage:
  - `GUIAnimationPack` (136376766704443)
  - `EmoteSelector` (8944416554)
- Client requires from ReplicatedStorage, falls back to TweenService shim
- **Client never calls InsertService**

---

## DEC-013 — LobbyState Payload Extension
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: `LobbyStatePayload` extended with monetization data for client HUD:
```lua
ownedPasses: { string }?  -- GP_VIP, GP_EmotePack, GP_LockerSlots
equipped: { string }?     -- equipped cosmetic/emote/trail IDs
level: number?            -- current level
xp: number?               -- current XP
coinCount: number?        -- current coins
```
Populated by `LobbyMachine:_publishState()` using `MonetizationService`.

---

## DEC-014 — Proprietary License
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: `LICENSE` file added to main (commit `f001497`). Prohibits: reverse engineering, copying, distribution, commercial use, alteration, asset redistribution. All assets exclusive property of Vsad Laboratories.

---

## DEC-015 — Herdr Plugin Policy
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Install only plugins that remove manual steps. Categories:
| Category | Plugins |
|----------|---------|
| CORE | GitHub, Git/worktree automation, Agent routing |
| OBSERVABILITY | Agent status, Project status, Logs |
| AUTOMATION | Workspace bootstrap, Task creation, Agent spawning |
| OPTIONAL | Linear/task systems, Remote machines (install when needed) |

**No plugin spam**. Only install when manual step exists.

---

## DEC-016 — Task Tracking (`.ai/TASKS.md`)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Single source of truth for task status. Orchestrator updates. Leader reads. Agents report completion. Format defined in `TASKS.md`.

---

## DEC-017 — Documentation Maintenance (Docs Agent)
**Date**: 2026-09-28  
**Status**: ACCEPTED  
**Decision**: Docs agent owns `docs/**`, `.ai/**`, `README.md`, `CHANGELOG.md`. Updates AGROMPTS.md on architecture change, SuperAgent.md on workflow change. Never touches `src/`.

---

## DEC-018 — LobbyState Coin Contract: Per-Player, Not Root (supersedes DEC-013)

**Date**: 2026-09-28
**Status**: ACCEPTED
**Context**: DEC-013 put `ownedPasses/equipped/level/xp/coinCount` at the payload ROOT. `_publishState` uses ONE `FireAllClients` broadcast — a root value is identical for every client, so "my coins" at root is wrong by construction. Two divergent uncommitted implementations (main tree per-player vs backend tree root) left the tree RED; Operator chose the reconciled direction.
**Decision**:
- `PlayerInfo` (the `players[]` row) carries `coinCount: number?` — broadcast stays single-event.
- Client picks its OWN row by `userId == Players.LocalPlayer.UserId`, renders `entry.coinCount or 0` (honest zero). Root `payload.coinCount` never sent/read.
- `ownedPasses/equipped/level/xp` DROPPED from the payload: zero schema writers (inventory schema = coins, ownedCosmetics, ownedEmotes, lockerSlots, pendingGrants), zero consumers. Re-add only when a writer + consumer exist (progression system, locker UI).
- `FireClient`-per-player rejected: extra remote + wiring for zero gain at 12 players.
- The previous leader's `_loadAssetPacks` stub in the patch created ImageLabels (no InsertService, no script-strip) — wrong shape vs DEC-012; deleted with the patch preserved for the DEC-011/012 Shop task. DEC-011 (`ShopPurchase` remote, server validates → prompt) and DEC-012 stand unchanged.
**Supersedes**: DEC-013 (payload-shape portion; DEC-013's field semantics deferred per "re-add when writer+consumer exist").

> Numbering note (documentation defect, records NOT modified per append-only rule): DEC-006, DEC-007, DEC-008 each appear twice from the 2026-09-28 session — first occurrence wins; next free number = DEC-019.

---

## How to Add a Decision

```markdown
## DEC-<NNN> — <Title>
**Date**: <YYYY-MM-DD>  
**Status**: PROPOSED|ACCEPTED|SUPERSEDED  
**Context**: <why this decision needed>  
**Decision**: <what was decided>  
**Consequences**: <what changes, trade-offs>  
**Supersedes**: <DEC-XXX if applicable>
```

**Rule**: Once ACCEPTED, never modified. Supersede with new decision if needed.