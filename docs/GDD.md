# Party Panic — GDD & Decision Log

Single source of truth for design + cross-session decisions. Update this file when a decision is made (Session Memory rule, ~/RULES.md).

## Concept (locked 2026-09-23)

- Round-based party royale: 60–90 s rounds, map voting, cosmetics. Winner gets a crown in lobby.
- Audience: kids 9–13. Solo operator, 10–15 h/week.
- First five rounds: Floor Fall, Obstacle Sprint, Tag Blast, King of the Hill, Gold Rush.
- Retention: daily quests, 4-week battle pass seasons, coins, cosmetic locker, rank tiers (Bronze→Crown), party bonus.
- Virality: squads, referral cosmetics (both get reward), spectate/fail clips, winner crown flex.

## Monetization (locked)

Cosmetics + battle pass + power/perk gamepasses + products. Ads later.
Recorded warning: power gamepasses aimed at 9–13 risk review-score and retention burn; recommendation = cap power, lead with cosmetics. Operator's call either way.

## Workflow (locked)

- Git-push-driven: every push → CI (stylua --check → selene → rojo build) → place artifact `PartyPanic.rbxlx` for testing in Studio (no local Studio on the Linux dev machine; there is no official browser Studio — verified 2026-09-23).
- Agent stack: herdr (terminal agent multiplexer, v0.9.1 — **replaced OpenChamber, rejected 2026-09-23**), Kilo Code (feature code), Jules (autonomous GitHub PRs), AI mesh gen (Meshy/Tripo/Rodin: low-poly, <5k tris, single palette texture).
- Agent roles/skills: Operator will assign — pending.

## Architecture rules (locked)

- Content is data: one file per minigame in `src/rounds/` (directory created when the first round lands — nothing speculative before then).
- Anti-spaghetti STOP rule + no-fluff rule live in `~/RULES.md` and `MastersEngineer.md` canonical sets (2 + 4 byte-identical copies).
- Quality gate: nothing merges red — CI must pass before a PR is reviewed.

## Roadmap

| Weeks | Deliverable |
|-------|-------------|
| 1–2 | Repo bootstrap ✓ → lobby + FloorFall playable |
| 3–5 | Rounds 2–5 + map voting + round state machine |
| 6–7 | Persistence (coins, wins) + coin economy + shop shell |
| 8 | Battle pass S1 + daily quests |
| 9 | Monetization: gamepasses + products |
| 10 | 3D pass: lobby decor + cosmetics + UI polish |
| 11 | Private beta → D1 retention + session length |
| 12 | Publish → weekly content drops (data-only changes) |
