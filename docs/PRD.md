# Party Panic — PRD

Status: v1 draft (inputs locked 2026-09-23) · Owner: Operator · Linked: [Vision.md](../Vision.md), [GDD.md](GDD.md) · **Amended 2026-09-26 (§9)**

## 1. Product overview

Round-based party royale for Roblox, ages 9–13: 60–90 second minigames, map voting, coins, cosmetics. Winner wears the crown in the lobby.

**Primary persona:** kid 9–13, after-school session, 10–20 min at a time, plays where their friends are, expects fun within 10 seconds of joining, follows live updates.

## 2. Success metrics (launch gates — advisory review adopted 2026-09-24)

External Roblox analyst review (2026-09-24) validated the concept and set the gates: chief risk = first 10 minutes feeling repetitive or socially empty. **Minimum** = ship gate; **Strong** = original ambition.

| Metric | Minimum | Strong | Gate for |
|---|---|---|---|
| First round starts within 30 s of join | 80% | 90%+ | onboarding / lobby pacing |
| First-round completion | 65% | 80%+ | round clarity / fail readability |
| D1 retention | ≥ 20% | ≥ 30% | content cadence investment |
| D7 retention | ≥ 5% | ≥ 10% | battle-pass / season timing |
| Average session length | ≥ 8 min | 12–15 min | round pacing / lobby design |
| Rematch / server requeue rate | 25% | 40%+ | social & loop design |
| Crash or severe-error rate | < 2% | < 1% | stability bar for every release |
| Secondary (observe, no target v1) | referral claims, shop views, pass attach rate | — | update-1 priorities |

Instrumentation: Roblox Analytics events `first_visit`, `first_round_start` (time-from-join), `first_round_complete`, `round_start`, `round_end` (round type, players, winner, micro-award), `rematch`, `shop_view`, `grant_after_receipt`, `referral_claim`; cohorts D1/D7/D30 + rounds-per-session. No custom data collection — kids' privacy stays inside Roblox's platform services.

## 3. Scope

### v1 launch (hard line)

1. Five rounds: Floor Fall, Obstacle Sprint, Tag Blast, King of the Hill, Gold Rush
2. Lobby: social hub, map vote, winner crown, spectate of active round (clip-able fails = virality); elimination keeps players engaged — good spectate camera, cheers, mini-activity, small consolation reward
3. Coins + wins persistence (DataStore, retry-safe idempotent saves)
4. Shop shell: cosmetic catalog as data tables, equip/loadout, locker
5. Monetization wiring: gamepasses (perks — capped power, see recorded warning in GDD) + products (coin packs), server-side receipt validation
6. Referral cosmetic (both parties rewarded)
7. Social: Roblox native friends/parties only — zero custom matchmaking code; play-again/requeue with current server, friend-join visibility (analyst: the social loop is the main growth engine)
8. English only; all UI strings translation-ready (no hardcoded strings)

### First updates (ordered)

1. Battle Pass S1 + daily quests — **gated: ships only after a returning cohort proves out (D7 ≥ Minimum on 2 consecutive weeks)** — a pass launched into an empty game reads expensive and dies. Doubles as proof of the live-update pipeline
2. Localization (Roblox auto-translate tables)
3. Weekly cosmetics / monthly rounds per cadence commitment

### Out of scope / non-goals

Trading, pet/economy sim depth, custom party system, ads, console certification, UGC marketplace creation, battle pass at launch, anything requiring data outside Roblox platform services.

## 4. Gameplay requirements

- Round cycle: lobby (≥ 8 s vote) → intro (5 s) → round (60–90 s) → results (10 s) → repeat. Vote options = 3 random maps from pool.
- New-player first round: spawn → 5–10 s explanation → round running within 30 s of join (§2 gate); no tutorial gating.
- Results award the crown plus micro-awards (best comeback, fastest finisher, longest survival, best prediction…) so non-winners still leave successful.
- Visible status between rounds: win streak, lifetime wins, titles (e.g. "Floor Fall Champion"), crown variants — cosmetics must communicate status, not only looks.
- Every round must be fully playable solo (1 player) — no dead lobbies.
- Elimination or scoring per round type; results award coins by placement.
- Fail states must be readable instantly (kids, 9–13: no tutorials — feedback teaches).

## 5. Functional requirements

| ID | Requirement | Why |
|---|---|---|
| FR1 | Round framework: one file per round, fixed lifecycle contract (setup → play → cleanup); adding a round touches zero core files | content = data; AI agents (Jules/Kilo) must ship rounds as safe PRs |
| FR2 | Lobby + map vote + winner crown + spectate + post-elimination engagement (camera, cheers, mini-activity, consolation) | retention + virality; eliminated players must never idle (analyst) |
| FR3 | Persistence: coins, wins, owned cosmetics — idempotent saves, load-failure fallback to session-only | kid rage-quits cannot wipe progress |
| FR4 | Coin economy: earn by placement, spend on cosmetics; all values in data tables | balancing without code changes |
| FR5 | Shop shell: catalog, equip, locker + status display (streak, lifetime wins, titles, crown variants) | monetization surface; status sells cosmetics |
| FR6 | Gamepasses/products with server-side receipt validation; perks capped (recorded warning: power sales to 9–13 burn reviews/retention) | revenue without killing retention |
| FR7 | Referral cosmetic: invitee + inviter both rewarded | virality |
| FR8 | Social = Roblox native parties/friends only | zero custom social code |
| FR9 | Safety: Roblox chat filter only (no custom text chat), no external links, no data collection beyond Roblox IDs, experience settings comply with Roblox rules for younger audiences | ages 9–13 |
| FR10 | Every content update ships as a data-only PR through green CI; cadence: cosmetics weekly, one new round monthly | honest solo cadence (10–15 h/week) |
| FR11 | Rematch/requeue with current server + party-join visibility (native Roblox APIs only) | social loop = main growth engine (analyst) |
| FR12 | Round micro-awards alongside the crown (comeback, fastest finisher, longest survival, prediction…) | non-winners must leave a round feeling successful |

## 6. Non-functional requirements

- **Performance:** 30 fps floor on low-end Android (2 GB RAM class) — part/asset budgets enforced by style bible; meshes < 5k tris, single texture, stud-scale.
- **UI:** thumb-reach mobile layout, large hit targets, no reading-heavy screens.
- **Maintainability:** architecture rules in Vision.md are requirements, not suggestions — spaghetti-stop rule (RULES.md #11) applies to every PR.
- **CI:** nothing merges red — stylua --check, selene, rojo build, (future: mesh QA script over `assets/*.obj`).
- **Dev-loop:** CI place artifact (`PartyPanic.rbxlx`) always available; Vinegar/Studio local loop is a bonus until proven stable.

## 7. Release criteria (launch checklist)

- [ ] All FR1–FR12 implemented, CI green on release tag
- [ ] Metrics instrumented; §2 funnel gates (first-round speed/completion, D1/D7, rematch, session, crash) visible in Roblox Analytics
- [ ] Playtested on a low-end Android device (30 fps floor verified, not assumed)
- [ ] Store page: attribution line for CC BY assets ("3D assets created with Meshy/Hunyuan — CC BY 4.0"), age-appropriate description, thumbnails
- [ ] Receipt validation proven with a test purchase
- [ ] Round rotation runs 30 min unattended without errors (state machine leak check)

## 8. Risks

| Risk | Mitigation |
|---|---|
| Power gamepasses → retention/review burn (recorded) | perks capped; cosmetics lead |
| Dev loop depends on external services (Roblox Open Cloud, Sober) | Path A locked — artifact download remains the fallback; Vinegar deleted (silicon ceiling, see Vision.md) |
| Solo cadence burnout | cadence commitment is the recommended honest line — protect it |
| First 10 minutes repetitive or socially empty (analyst's #1 risk) | §2 funnel gates + elimination engagement (FR2), micro-awards (FR12), rematch (FR11) are v1 scope, not post-v1 |
| Hunyuan free quota expires (reported launch promo) | bank assets while free; Meshy CC BY as stable fallback |

## 9. Amendments (2026-09-26 — Operator-locked; design detail in DESIGN.md)

**A1 — Round-start model: Rounds Field** *(supersedes §4 round-cycle line and FR2's lobby-map-vote start flow)*
Per DESIGN "Round-start model": a dedicated **Rounds Field** world where every minigame is a
physical **stall** (big banner name + small boundary) offering **variant slots** (e.g. Hot Potato:
1v4 / 1v8 / 2v12). Player picks a variant → UI lists **live running games** → join the current
instance or queue → **round starts when capacity fills**. **No timers, no automatic join** —
UX doctrine. Lobby = social hub, free roam only. §2/§4 first-round gates are measured from the
player's **first stall interaction**, not from join (no auto-join doctrine), everything else in
§2/§4 stands.

**A2 — Party Pass replaces Battle Pass** *(terminology + cadence; §3 "First updates" item 1)*
Free-Fire-style monthly pass: daily free rewards + purchasable premium tier, rotates monthly.
Rename everywhere (lobby zone = Party Pass Grotto, UI = Party Pass). The **D7 ship-gate is
unchanged** (launch only after D7 ≥ Minimum on 2 consecutive weeks); only the name and monthly
cadence changed. "Out of scope: battle pass at launch" remains true for Party Pass.

**A3 — Game Votes** *(new live-ops item; extends §3 / FR10)*
Post-update community poll: an update ships → ~5 days later a poll opens for the **next**
update's minigame (UI = Game Vote UI in DESIGN §10). Data-only per FR10; adds a community
selection step to the update cadence, does not change the weekly/monthly shipping commitment.
