# Party Panic — GDD & Decision Log

Single source of truth for design + cross-session decisions. Update this file when a decision is made (Session Memory rule, ~/RULES.md).

## Concept (locked 2026-09-23)

- Round-based party royale: 60–90 s rounds, map voting, cosmetics. Winner gets a crown in lobby.
- Audience: kids 9–13. Solo operator, 10–15 h/week.
- First five rounds: Floor Fall, Obstacle Sprint, Tag Blast, King of the Hill, Gold Rush.
- Retention: daily quests, 4-week battle pass seasons, coins, cosmetic locker, rank tiers (Bronze→Crown), party bonus.
- Virality: squads, referral cosmetics (both get reward), spectate/fail clips, winner crown flex.
- Advisory review adopted (2026-09-24, external Roblox analyst): launch with the five rounds only after four excellences — fast first round (≤ 30 s join→play), fun spectating after elimination, friend/rematch flow, visible cosmetic status. Micro-wins (best comeback, fastest finisher, longest survival…) join the crown every round. Update rhythm: weekly = 1 cosmetic collection + limited challenge + QoL; every 2–4 wks = new round + modifier/mini-event; every 6–8 wks = season (pass refresh, lobby theme, crown progression).

## Monetization (locked)

Cosmetics + battle pass + power/perk gamepasses + products. Ads later.
Recorded warning: power gamepasses aimed at 9–13 risk review-score and retention burn; recommendation = cap power, lead with cosmetics. Operator's call either way.
Decisions (2026-09-24, advisory review): battle pass gated until a returning cohort proves out (D7 ≥ PRD Minimum, 2 consecutive weeks) — never launch a pass into an empty game. No random paid rewards without a clear preview (gambling-feel caution, ages 9–13). The cosmetic line sells status: crown trails, victory poses, entrance effects, emotes, elimination effects, lobby pets, nameplates, seasonal pass, VIP-server perks, preview-gated reroll product.
Revenue model (Operator + external specialist, 2026-09-24 — planning reference, not forecast): DevEx **$0.0035/Robux** (official $350/100,000; the earlier $0.0038 figure was unverified and is retired) · 70% developer share after Roblox's 30% marketplace cut. 100k MAU × spend: 5 R$/player ≈ $1,225/mo · 25 ≈ $6,125 · 100 ≈ $24,500 · 300 ≈ $73,500. Varies with purchases, regional pricing, Premium, ads, taxes, splits.

DAU × blended ARPU (cash ≈ DAU × ARPU × 0.7 × 30 × $0.0035):

| DAU | ARPU (all players) | Monthly cash |
|---|---|---|
| 1,000 | 10 R$ | $735 |
| 1,000 | 50 R$ | $3,675 |
| 5,000 | 20 R$ | $7,350 |
| 5,000 | 100 R$ | $36,750 |
| 20,000 | 50 R$ | $73,500 |
| 20,000 | 200 R$ | $294,000 |

Party-game levers (specialist rounds 1–3 reconciled 2026-09-25): payer conversion 2–5% at scale (volume-dependent for cosmetics-only) · **Creator Rewards** (replaces legacy Premium playtime): flat reward when a qualifying active spender ($9.99+ spend / 60d) stays 10+ min as one of their first three daily stops → target sessions **10–12 min** via bridge loops: spectator mini-games (cosmetic-only), 30s winner-podium flex intermission (+~2 min/session), daily streak-protect multiplier, lobby micro-quest roll-overs ("1 more round to finish X"), seamless map-vote overlay at session end (PRD ≥8 min stays the floor) · retention reality: platform median D1 10.3% / D7 1.6%, "good" floor D1 20% → staged gates D1 20/30 confirmed; D1 35% = flawless-FTUE stretch goal · cosmetics build order for ages 9–13: **trails/auras > emotes/soundboards > outfits** (players keep their own avatar) · DevEx: 30k Earned Robux minimum, age 13+, no Premium required, under-18 cashouts need parent/guardian legal name + tax docs. High DAU rows require deep shop + high conversion — cosmetics-led strategy (locked) targets the middle rows first.
Backlog (gated — kept in clear sight per Operator): player-created minigame voting — concept superseded by Operator's **Game Votes** (live-ops polls ~5 days after each update); squads/rank depth/player-to-player trading stay out until the first cohort returns (analyst's strategic warning). **Battle Pass concept REMOVED (2026-09-25) → Party Pass**: monthly Free-Fire-style pass, daily free rewards + purchasable premium tier, new pass each month.

## Workflow (locked)

- Git-push-driven: every push → CI (stylua --check → selene → rojo build) → place artifact `PartyPanic.rbxlx` for testing in Studio (no local Studio on the Linux dev machine; there is no official browser Studio — verified 2026-09-23).
- Agent stack: herdr (terminal agent multiplexer, v0.9.1 — **replaced OpenChamber, rejected 2026-09-23**), Kilo Code (feature code), Jules (autonomous GitHub PRs), AI mesh gen (Meshy/Tripo/Rodin: low-poly, <5k tris, single palette texture).
- Agent roles/skills: Operator will assign — pending.

## Architecture rules (locked)

- Content is data: one file per minigame in `src/rounds/` (directory created when the first round lands — nothing speculative before then).
- Anti-spaghetti STOP rule + no-fluff rule live in `~/RULES.md` and `MastersEngineer.md` canonical sets (2 + 4 byte-identical copies).
- Quality gate: nothing merges red — CI must pass before a PR is reviewed.

## 3D asset pipeline (recorded 2026-09-23, terms verified same day)

| Tool | Role | Verified free terms | Rule |
|---|---|---|---|
| Hunyuan 3D Global | volume engine (props, decor) | 20 gens/day (Tencent official); free tier CC BY 4.0 | caveats: quota may be a launch promo ("limited time" reported); confirm output rights in-account before monetizing |
| Meshy | primary — characters, hero assets | 100 cr/mo ≈ 3 full PBR gens (30 cr each); free = CC BY 4.0, commercial OK with credit; rigging + preset anims free | attribution = one line in game description + credits panel |
| Tripo | experimentation only | own terms contradict (pricing page: free = non-commercial; blog: CC BY 4.0) | **ambiguous rights never ship** — prototypes/placeholders only |

- No paid tiers at v1 — free tiers suffice; revisit only if exclusivity needed (battle-pass hero items).
- Anti-spaghetti applies to assets too: style bible (`docs/STYLE.md`) before mass generation — palette, <5k tris, stud scale, single texture. Mesh QA (tri/texture count) is a candidate CI script over `assets/*.obj`.

## Round backlog (future data drops — advisory review 2026-09-24)

Launch five stay as-is; differentiation comes from presentation, modifiers, social chaos, progression — not new genres. Candidate pool (each = one file, zero core edits): Hot Potato, Color Panic, Push-Off, Package Panic, Bomb Relay, Prop Hide-and-Seek, Rising Water, Team Tangle (temporary teams; crown bonus stays individual).

### Pro consultation — recommended minigames (2026-09-26, advisory, deferred)

**Status: NOT NOW.** Operator directive: foundations first; later we build them **1 by 1**.
⚠ **Roster conflict to ratify after foundations:** PRD/GDD launch five (Floor Fall, Obstacle
Sprint, Tag Blast, King of the Hill, Gold Rush) vs pro's five (below) overlap only on Obstacle
Sprint — replacement vs addition is an open Operator call.

| # | Minigame | Core loop | Demand | Difficulty |
|---|---|---|---|---|
| 1 | Color Rush | stand on announced color before tiles vanish | very high | very easy |
| 2 | Last Platform | platforms vanish mid-jump; last survivor wins | very high | easy |
| 3 | Bomb Pass | pass timed bomb by touch; holder at zero = eliminated | high | easy |
| 4 | Obstacle Sprint | race short course (30–60 s), checkpoints + times | very high | easy–medium |
| 5 | Coin Scramble | most coins collected before timer ends | high | easy |
| 6 | Freeze Tag | taggers freeze others; touch to unfreeze | high | easy–medium |
| 7 | Memory Tiles | memorize safe tiles, cross arena | high | easy |
| 8 | Push Arena | knock opponents off small platform | high | medium |
| 9 | Delivery Dash | carry objects to matching destinations | medium–high | easy |
| 10 | Guess the Safe Door | wrong door = eliminated | medium–high | very easy |

MVP five (pro): Color Rush, Last Platform, Bomb Pass, Obstacle Sprint, Coin Scramble.
Round structure: intermission → arena → one-sentence objective → 60–90 s round → winners →
back to lobby fast; match ≈ 8–12 min. Competitive edge = polish, not count: faster matchmaking,
mobile controls, clear instructions, funnier transitions, social features, frequent updates,
cosmetics-led fairness (no pay-to-win). Per-game dev requirements + expansion ideas: ask
Operator for the full consultation text (recorded in session, 2026-09-26).

## Roadmap

| Weeks | Deliverable |
|-------|-------------|
| 1–2 | Repo bootstrap ✓ → lobby + FloorFall playable |
| 3–5 | Rounds 2–5 + map voting + round state machine |
| 6–7 | Persistence (coins, wins) + coin economy + shop shell |
| 8 | Daily quests + status/micro-win systems + elimination engagement |
| 9 | Monetization: gamepasses + products (capped power, previews on reward products) |
| 10 | 3D pass: lobby decor + cosmetics + UI polish |
| 11 | Private beta → funnel + retention gates (first-round speed/completion, D1/D7, rematch) |
| 12 | Publish → weekly content drops (data-only changes); Battle Pass S1 = first update after D7 cohort proof |
