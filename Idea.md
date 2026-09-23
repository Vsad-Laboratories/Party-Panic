# Party Panic

**Round-based party royale for Roblox.** 4–12 players, 60–90 second minigames, one lobby, one crown. Built for ages 9–13 — and built to be maintained by data, not by rewrites.

## Concept

Party Panic takes the party-minigame genre to its simplest replayable form: short rounds, instant queues, visible rewards. Players enter a lobby, vote on the next round, play a 60–90 second minigame, then return to the lobby where the winner wears the crown. Coins buy cosmetics — cosmetics are the status game. The design targets after-school sessions (10–20 minutes) with fun within 10 seconds of joining.

## Core loop

Lobby → map vote → minigame (60–90 s) → results + coins → cosmetics → next round.

The frame is fixed. Every new round is added as **data**, never as an edit to the core loop.

## Launch content (v1)

- **Five rounds:** Floor Fall, Obstacle Sprint, Tag Blast, King of the Hill, Gold Rush
- **Lobby:** queue, map voting, winner crown, coin balance
- **Economy:** coin rewards + cosmetics shop shell
- **Round feel:** eliminated players stay engaged (spectate camera, cheers, consolation) and still win something — micro-awards for best comeback, fastest finish, longest survival; visible status: streaks, titles, crown variants
- **Social loop:** play-again/requeue, party + friend bonuses, invite rewards — the main growth engine
- **Staged & gated:** daily quests, battle pass seasons (ships only once players demonstrably return), rank tiers (Bronze → Crown), squads, referral cosmetics (both players rewarded)

## Audience & success gates

- Primary: kids 9–13, mobile-first — 30 fps floor on low-end Android; English v1, translation-ready
- Launch gates (staged): first round starts < 30 s for 80%+ of joins · D1 ≥ 20% (30% = strong) · session ≥ 8 min · rematch ≥ 25% · crash rate < 2%
- Privacy: Roblox Analytics events only; no custom data collection

## Monetization (locked direction)

Cosmetics-led: cosmetics + battle pass + capped power gamepasses/products; ads deferred. Unrestricted power perks aimed at 9–13 carry review-score and retention risk — recorded in the GDD, deliberately capped.

## How it's built

- **Roblox + Luau via Rojo; everything in git.** Every push to `main` runs CI (stylua → selene → rojo build) and publishes a new place version automatically — any change is playtestable within minutes.
- **Data-driven architecture.** One file per minigame; rounds communicate only through a shared contract (`setup → play → cleanup`); a round registry makes new content a data-only change. A bad contribution cannot break the loop structure.
- **AI-agent workflow.** A four-role agent fleet (Control, Backend, Client/UI, Reviewer) works isolated branches under written charters; nothing merges without green CI and a checklist-based review derived from the product docs.
- **Free-tier 3D pipeline.** Volume engine + Meshy for props and cosmetics (Tripo for prototyping only); no paid asset tiers at v1.

## Roadmap (12 weeks)

| Phase | Deliverable |
|---|---|
| Weeks 1–2 | Playable frame: lobby FSM, round contract, lobby UI shell — **landed**; first real round |
| Weeks 3–7 | Rounds, UI, coins, shop shell, low-end mobile pass |
| Weeks 8–10 | Daily quests + status systems, gamepasses/products, 3D + UI polish (battle pass ships post-cohort-proof) |
| Weeks 11–12 | Analytics gates, retention tuning, public launch |

Release cadence after v1: **cosmetics weekly, rounds monthly.**

## Documents

| File | Contents |
|---|---|
| `Vision.md` | Pillars, architecture, current state |
| `docs/GDD.md` | Locked design decisions + full roadmap |
| `docs/PRD.md` | Requirements, metrics, release criteria |
| `docs/REVIEW.md` | Checklist every change must pass |
| `docs/agents/` | Fleet charters + working protocol |
