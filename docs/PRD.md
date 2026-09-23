# Party Panic — PRD

Status: v1 draft (inputs locked 2026-09-23) · Owner: Operator · Linked: [Vision.md](../Vision.md), [GDD.md](GDD.md)

## 1. Product overview

Round-based party royale for Roblox, ages 9–13: 60–90 second minigames, map voting, coins, cosmetics. Winner wears the crown in the lobby.

**Primary persona:** kid 9–13, after-school session, 10–20 min at a time, plays where their friends are, expects fun within 10 seconds of joining, follows live updates.

## 2. Success metrics (measured at week 4)

| Metric | Target | Gate for |
|---|---|---|
| D1 retention | ≥ 30% | continuing to invest in content cadence |
| Average session length | ≥ 8 min | round pacing / lobby design changes |
| Secondary (observe, no target v1) | referral claims, shop views, pass attach rate | update-1 priorities |

Instrumentation: Roblox Analytics events `first_visit`, `round_start`, `round_end` (round type, players, winner), `shop_view`, `grant_after_receipt`, `referral_claim`. No custom data collection — kids' privacy stays inside Roblox's platform services.

## 3. Scope

### v1 launch (hard line)

1. Five rounds: Floor Fall, Obstacle Sprint, Tag Blast, King of the Hill, Gold Rush
2. Lobby: social hub, map vote, winner crown, spectate of active round (clip-able fails = virality)
3. Coins + wins persistence (DataStore, retry-safe idempotent saves)
4. Shop shell: cosmetic catalog as data tables, equip/loadout, locker
5. Monetization wiring: gamepasses (perks — capped power, see recorded warning in GDD) + products (coin packs), server-side receipt validation
6. Referral cosmetic (both parties rewarded)
7. Social: Roblox native friends/parties only — zero custom matchmaking code
8. English only; all UI strings translation-ready (no hardcoded strings)

### First updates (ordered)

1. Battle Pass S1 + daily quests — doubles as proof of the live-update pipeline
2. Localization (Roblox auto-translate tables)
3. Weekly cosmetics / monthly rounds per cadence commitment

### Out of scope / non-goals

Trading, pet/economy sim depth, custom party system, ads, console certification, UGC marketplace creation, battle pass at launch, anything requiring data outside Roblox platform services.

## 4. Gameplay requirements

- Round cycle: lobby (≥ 8 s vote) → intro (5 s) → round (60–90 s) → results (10 s) → repeat. Vote options = 3 random maps from pool.
- Every round must be fully playable solo (1 player) — no dead lobbies.
- Elimination or scoring per round type; results award coins by placement.
- Fail states must be readable instantly (kids, 9–13: no tutorials — feedback teaches).

## 5. Functional requirements

| ID | Requirement | Why |
|---|---|---|
| FR1 | Round framework: one file per round, fixed lifecycle contract (setup → play → cleanup); adding a round touches zero core files | content = data; AI agents (Jules/Kilo) must ship rounds as safe PRs |
| FR2 | Lobby + map vote + winner crown + spectate | retention + virality pillars |
| FR3 | Persistence: coins, wins, owned cosmetics — idempotent saves, load-failure fallback to session-only | kid rage-quits cannot wipe progress |
| FR4 | Coin economy: earn by placement, spend on cosmetics; all values in data tables | balancing without code changes |
| FR5 | Shop shell: catalog, equip, locker | monetization surface |
| FR6 | Gamepasses/products with server-side receipt validation; perks capped (recorded warning: power sales to 9–13 burn reviews/retention) | revenue without killing retention |
| FR7 | Referral cosmetic: invitee + inviter both rewarded | virality |
| FR8 | Social = Roblox native parties/friends only | zero custom social code |
| FR9 | Safety: Roblox chat filter only (no custom text chat), no external links, no data collection beyond Roblox IDs, experience settings comply with Roblox rules for younger audiences | ages 9–13 |
| FR10 | Every content update ships as a data-only PR through green CI; cadence: cosmetics weekly, one new round monthly | honest solo cadence (10–15 h/week) |

## 6. Non-functional requirements

- **Performance:** 30 fps floor on low-end Android (2 GB RAM class) — part/asset budgets enforced by style bible; meshes < 5k tris, single texture, stud-scale.
- **UI:** thumb-reach mobile layout, large hit targets, no reading-heavy screens.
- **Maintainability:** architecture rules in Vision.md are requirements, not suggestions — spaghetti-stop rule (RULES.md #11) applies to every PR.
- **CI:** nothing merges red — stylua --check, selene, rojo build, (future: mesh QA script over `assets/*.obj`).
- **Dev-loop:** CI place artifact (`PartyPanic.rbxlx`) always available; Vinegar/Studio local loop is a bonus until proven stable.

## 7. Release criteria (launch checklist)

- [ ] All FR1–FR10 implemented, CI green on release tag
- [ ] Metrics instrumented; D1 + session length visible in Roblox Analytics
- [ ] Playtested on a low-end Android device (30 fps floor verified, not assumed)
- [ ] Store page: attribution line for CC BY assets ("3D assets created with Meshy/Hunyuan — CC BY 4.0"), age-appropriate description, thumbnails
- [ ] Receipt validation proven with a test purchase
- [ ] Round rotation runs 30 min unattended without errors (state machine leak check)

## 8. Risks

| Risk | Mitigation |
|---|---|
| Power gamepasses → retention/review burn (recorded) | perks capped; cosmetics lead |
| Vinegar dev-loop fragility (current failure) | CI artifact path proven; fallback documented in Vision.md |
| Solo cadence burnout | cadence commitment is the recommended honest line — protect it |
| Hunyuan free quota expires (reported launch promo) | bank assets while free; Meshy CC BY as stable fallback |
