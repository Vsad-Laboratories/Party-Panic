# Design Bible — Astro-Arcade Punk

Source: Operator's specialist (round 5, 2026-09-25) + Operator lobby mockup. Consumed by map agents:
Phase A ships the static geometry in palette; Phase B adds the dynamics column.

## Theme (canonical = Vision.md)

Cozy low-poly sci-fi: chunky geometry, soft neon, no lens flares. Palette: base slate blue
`fromRGB(46,58,89)` / cosmic navy `fromRGB(35,43,69)`, accent teal-cyan `fromRGB(95,227,211)`,
highlights neon pink `fromRGB(255,63,164)` + canary `fromRGB(255,225,77)` = interactive zones only.

## Lobby layout (LobbyHub Phase A — binding)

- Spawn disc faces **NORTH**; player's first view = STATUS screen + Map Voting circle dead ahead.
- Left 45°: **Storefront Avenue** (3D shop shells). Right 45°: elevated **Battle Pass Grotto**.
- Rear 180°: **Winner Podium**, flanked by the **AFK & Coin Obby** entry at the player's feet.
- Perimeter wraps tightly around the disc; all 5 systems **within 40 studs of spawn**.

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
