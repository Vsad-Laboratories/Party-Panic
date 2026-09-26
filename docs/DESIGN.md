# Design Bible — Astro-Arcade Punk

Source: Operator's specialist (round 5, 2026-09-25) + Operator lobby mockup. Consumed by map agents:
Phase A ships the static geometry in palette; Phase B adds the dynamics column.

## Theme (canonical = Vision.md)

Cozy low-poly sci-fi: chunky geometry, soft neon, no lens flares. Palette: base slate blue
`fromRGB(46,58,89)` / cosmic navy `fromRGB(35,43,69)`, accent teal-cyan `fromRGB(95,227,211)`,
highlights neon pink `fromRGB(255,63,164)` + canary `fromRGB(255,225,77)` = interactive zones only.

## Lobby base v2 (Operator 2026-09-26 — binding, supersedes Phase A layout below)

Ground truth = **`assets/Reference/Lobby.jpg`**. Rounded **oval** ground — never a rectangle:

- **Shape:** oval, ~1.2–1.4× wider than deep. Starting size **24 × 18** — Operator units;
  **scale pending confirm** (treat as meters ×3.5 studs → 84×63, vs direct studs).
- **Playable central area** ≈ 14 × 10; **outer decorative ring** 2–3 wide; **perimeter wall** 4–6 tall.
- **Spawn points around the perimeter, facing the center.**
- **Central platform** ≈ 6–8 wide carrying the **mythical spawn plate** (`110144096035671`);
  players spawn there — free roam, no auto-join (UX doctrine).
- **Stalls:** pack `16263631766` (5 colours) placed per the reference image (Storefront side);
  trees `12549617200` + rocks `16933634812` / `10355509588` / `13471036173` scattered on the ring.
- **TOP Playtime Leaderboard** `5352156968`: prop now, third-party scripts stripped, playtime data later.
- Lighting block unchanged (bright daylight per reference). Zones/systems re-attach after the base ships.

## Lobby layout (LobbyHub Phase A — SUPERSEDED 2026-09-26 by "Lobby base v2"; reference only)

Ground truth = Operator's **`LobbyMap Reference.jpg`** (repo root). Lobby follows the reference image;
Astro navy palette governs minigame maps + UI.

- **Floor: grass green** (~`fromRGB(106,190,75)`), not navy. Curved **slate-blue perimeter wall with a
  green top rim**, wrapping ~270°; rocks, low-poly pines, planters scattered along it. Open airy sky.
- **Center: spawn disc (Center Hub Spawn Ring)** facing **NORTH** — first view = big **STATUS screen**
  on the wall ("STATUS: INTERMISSION (15s)") with the **Map Voting circle** right below:
  3 glowing ring pads (teal / white / yellow).
- **Left 45°: Storefront Avenue** — 3 stalls w/ striped awnings + large holo screens above
  (ring / sparkle / avatar icons), floating label "The Storefront Avenue".
- **Right 45°: Party Pass Grotto** (was "Battle Pass" — concept removed) — elevated rocky platform, glowing crown on pedestal, locked gate,
  neon pass-themed sign (e.g. "PARTY PASS — PREMIUM VAULT"), floating label "The Party Pass Grotto".
- **Front (at feet): AFK & Coin Obby Arena** — colorful parkour tile strip (pink/yellow/cyan/purple,
  ladder, platforms) along the near wall.
- **Rear: Winner Podium** (small; not in the image — from specialist flow) flanking the vote circle's back.
- **Rule: all 5 systems within 40 studs of spawn** (anti-wander + mobile render). Floating zone labels
  above each zone as in the image (part/Billboard labels, Phase A buildable).
- **Lighting (lobby-owned):** bright soft daylight per the reference image — pale sky, gentle
  atmosphere, no lens flare; set by `LobbyHub` at boot, original Lighting restored in `cleanup()`.

## Landmark styles (specialist round 5b — minigame maps)

Primitive shapes, emissive outlines, instantly readable silhouettes — no hyper-detail (low-poly law).

- **Astro-Cozy**: *Capsule Outpost* = half-buried rocket pod, glowing teal windows → LOS blocker;
  *Radar Array* = 3 oversized satellite dishes, neon-pink rim trim → platforming steps.
- **Arcade-Cabinet**: *Retro Gateway* = arcade-shell archway / neon portal ring at choke points →
  audio stinger; *Holographic Pixel Monoliths* = stacked glass cubes w/ floating 8-bit icons →
  spatial anchors ("Meet at the Pink Star Pillar").
- **Interactive Vibe**: *Overdrive Core* = floating reactor, ring pulses Green→Yellow→Pink as the
  round timer drains → visual pacing clock (replaces staring at UI timer).

## Minigame map centerpieces (one per map)

| Map | Centerpiece (Phase A static) | Phase B dynamics |
|---|---|---|
| Floor Fall | Hollow cylinder: 6 translucent neon-pink pillars + layered concentric ring core | rings alternate rotation |
| Obstacle Sprint | Low-poly rocket booster nozzle on its side, particle beam through the hollow | beam as hazard trigger |
| Tag Blast | Crisscross matte-slate gyro-sphere enclosing neon-cyan plasma ball | plasma scale pulse |
| King of the Hill | Tiered octagonal ziggurat, neon edge strips, floating crown | crown spin + teal→pink shift |
| Gold Rush | Arcade token funnel (inverted shallow cone over cylinder base) | pooled coins launched skyward |

## First map concepts (60–90 s, ≤12 players, low-end mobile)

| Concept | Minigame | Layout |
|---|---|---|
| Cosmic Crater | Gold Rush | Circular crater basin, wheel-spoke wedge rock barriers, sunken center funnels coin drops; clean sightlines |
| Neon Grid | Tag Blast | Flat 8×8 grid square, raised perimeter, 4 central L-walls for LOS breaks; close-quarters knockback tracking |
| Gravity Void | Floor Fall | Floating hexagonal arena, 3 stacked concentric tile rings, outer break first → shrinking core; self-pooling tiles |

## Open items

- Specialist offered exact Vector3 dimensions per system — accept when dispatching each map PR.
- Wishlist Station + spectator/bridge mechanics → GDD backlog (see Vision).

## Lobby screen layout (UI — binding, Operator 2026-09-25)

- **LEFT column** (top→down): Inventory, Shop, Settings, Party Pass, Packs — rounded-corner squares,
  generous size, colorful distinct backgrounds.
- **RIGHT column** (top→down): MiniGames, Maps, Stats — same shape language.
- **BOTTOM MIDDLE**: level progress bar; above its LEFT end = coin icon + count; above its RIGHT end =
  active perk/effect chips (e.g. "Bloody Aura: 5x Coins") — compact, never dominating the view.
- Buttons open their UIs via a shared router (`ui/router.luau`, empty entries = no-op until built).

## UI inventory (10 screens — Operator specs)

| UI | Spec |
|---|---|
| Inventory | Tabbed: **Items, Aura, Effects, GiftPass, Perks, Packs** — equip / unequip / manipulate owned items |
| Shop | Marketplace: buy / sell / trade; **sell-back to system BELOW buy price** (Operator example has math off: buy 1M → "sell 8.9M" — intended ≈890K / 89%; ratio to confirm) |
| Settings | Universal game settings, allowed ranges only |
| Party Pass | Horizontal scrollable grid: days, item names, claim buttons, locked states; daily rewards + purchasable premium tier |
| Packs | Bundle offers (e.g. Starter Pack: 10K coins + starter aura) |
| Map UI | Teleport hub: Lobby, MiniGames, Voting, Stats… + rounded-rect **Vote Map** button (concepts revealed per update) |
| Minigame UI | Search minigames → teleport to that game's lobby |
| Stats | 1-month history: playtime, coins, level, spending, earning, wins, losses, trades, buys, sells |
| Game Vote UI | Poll: community votes the next update's new minigame (published ~5 days after each update) |

## Round-start model (Operator — replaces lobby vote-start; supersedes PRD §round cycle)

- Dedicated **Rounds Field** world: every minigame = a physical **stall** — big banner name + small
  boundary (game-stall style).
- Stall offers **variant slots** (e.g. Hot Potato: 1v4 / 1v8 / 2v12).
- Player picks a variant → UI lists **live running games** → join the current instance or queue →
  round starts when capacity fills. **No timers, no auto-join.** Lobby = social hub (free roam only).

## Systems (Operator 2026-09-25 PM)

- **Party Pass REPLACES Battle Pass** — Free-Fire-style monthly pass: daily free rewards, purchasable
  premium tier, new pass every month. Lobby zone renamed (above); GDD + PRD to follow.
- **Game Votes** — live-ops poll cadence: update ships → ~5 days later poll opens for the next
  update's minigame.

## Particle effects (Operator 2026-09-26)

- **Event-driven bursts — the opposite of shop auras:** auras glow constantly; particle effects
  fire on a trigger and stop. Never looping, never idle glow.
- **Trigger events:** kills, revives, plays (round joins), rewards (coins/levels/pass claims),
  + other milestones as designed per screen.
- Source: **Particle Effect Pack `15261348321`** (ASSETS.md Batch 2) — ingest per binding rules:
  scripts stripped, emitters referenced only; effect logic re-built Client-side.
- **Perf law:** pooled short-lived emitters, ≤ a few active per event, low-end 30 fps budget,
  off-switchable in Settings.
