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
Revenue scenarios (Operator analysis 2026-09-24, planning reference — 100k MAU, 70% developer share, DevEx ≈ $0.0038/Robux): 5 R$/player ≈ $1,330/mo · 25 ≈ $6,650/mo · 100 ≈ $26,600/mo · 300 ≈ $79,800/mo. Varies with purchases, regional pricing, Premium, ads, taxes, splits.
Backlog (gated — kept in clear sight per Operator): player voting for new minigame ideas — post-v1, same cohort-proof gate as the battle pass. Squads/rank depth/trading stay out until the first cohort returns (analyst's strategic warning).

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
- Candidate (Operator find, 2026-09-24): **CadXStudio** (cadxstudio.in) — browser text/sketch-to-CAD, parametric BREP, projects/workbenches (Razorpay checkout present = paid tier exists). Potential fit: precise mechanical props via CAD → mesh export. Gates before use: free-tier export formats + output commercial rights verified (Tripo rule — ambiguous rights never ship) and output decimates into the <5k-tris style bible. Does not displace Meshy/Hunyuan as primary.
- Anti-spaghetti applies to assets too: style bible (`docs/STYLE.md`) before mass generation — palette, <5k tris, stud scale, single texture. Mesh QA (tri/texture count) is a candidate CI script over `assets/*.obj`.

## Round backlog (future data drops — advisory review 2026-09-24)

Launch five stay as-is; differentiation comes from presentation, modifiers, social chaos, progression — not new genres. Candidate pool (each = one file, zero core edits): Hot Potato, Color Panic, Push-Off, Package Panic, Bomb Relay, Prop Hide-and-Seek, Rising Water, Team Tangle (temporary teams; crown bonus stays individual).

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
