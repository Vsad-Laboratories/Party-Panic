# Party Panic — Review Checklist

> Derived strictly from existing law: Vision pillars, GDD locked decisions, PRD FR1–FR10, `~/RULES.md`. No invented rules. The Reviewer applies every item to every open PR; each finding cites its checklist item.

## Verdict format

Comment on every open PR exactly one of:

- `APPROVE`
- `REQUEST CHANGES` + numbered findings, each referencing a checklist item (e.g. `1. [C3] Round B reaches into Round A's module.`)

The Reviewer writes no feature code and never merges — Control merges after `APPROVE`.

---

## Checklist

### C1 — Gates green (Vision pillar #3, GDD workflow, fleet discipline #2)

- [ ] `stylua --check .` passes
- [ ] `selene src` passes
- [ ] `rojo build` succeeds
- [ ] Gate output is **pasted in the PR description as evidence** — claimed-but-unshown gate output = finding (RULES §4: prove done; intent is not a result)
- [ ] Nothing merges red: any red gate is an automatic `REQUEST CHANGES`, no exceptions

### C2 — Scope (RULES #8, fleet discipline #3)

- [ ] Every changed file sits inside the author's charter dirs (Backend: `src/server/`, `src/shared/`; Client: `src/client/`; Reviewer: `docs/`)
- [ ] Any cross-dir change is explicitly justified in the PR description
- [ ] Change set matches the task — no drive-by edits to unrelated files (RULES #8: change only what was asked)

### C3 — Round contract & coupling (Vision: round contract, PRD FR1, RULES #11)

- [ ] Server/client changes respect the round lifecycle: `setup → play → cleanup`
- [ ] No round touches another round; no module reaches into a module it doesn't own
- [ ] No new cross-module coupling, duplicated logic, or purposeless wrapper layers — trending toward spaghetti = `REQUEST CHANGES` + spaghetti stop reported (RULES #11)

### C4 — Data-driven (Vision pillar #1, PRD FR1/FR4/FR10)

- [ ] Tunables (economy values, timings, round parameters) live in data tables, not constants sprinkled in logic (FR4)
- [ ] A new round/map/cosmetic requires **zero edits to core files** — if the PR forces a core edit for content, it stops and asks Control first (fleet discipline #7)
- [ ] One file per round in `src/rounds/`; the fixed frame (lobby → vote → round state machine → rewards) is untouched by content PRs (Vision pillars #1–#2)

### C5 — No fluff (RULES #9, #12)

- [ ] No dead code, unused branches, unused dependencies, commented-out blocks
- [ ] No speculative abstractions, "just in case" helpers, placeholder litter
- [ ] Every added line serves a current requirement — delete before adding

### C6 — Explicit over magic (RULES #5, #6)

- [ ] No hidden state, no implicit defaults that surprise
- [ ] No unnamed magic values — reasons in comments, not narration (RULES #10)
- [ ] Simplest solution that works; no over-engineering
- [ ] Idempotent where re-runnable (RULES #4); portable `~`/`$HOME` paths (RULES #3); real files, no symlinks (RULES #2)
- [ ] UI strings not hardcoded — translation-ready, English only (PRD scope #8)

### C7 — Discipline (fleet protocol, RULES workflow)

- [ ] Branch named `agent/<role>-<task>`
- [ ] Commits scoped to the task; commit messages explain why, not what (RULES #10)
- [ ] No direct pushes to `main` — ever
- [ ] PR description carries files changed + gate output (fleet discipline #6: report deltas, outcomes not intentions)

---

## Product-law quick reference (for requirement-level findings)

| ID | Requirement | Review angle |
|---|---|---|
| FR1 | Round framework: one file per round, lifecycle contract, zero core edits to add a round | C3 + C4 |
| FR2 | Lobby + map vote + crown + spectate | scope vs. lobby/vote/spectate specs (PRD §4) |
| FR3 | Idempotent persistence, load-failure → session-only fallback | C6 idempotency; rage-quit cannot wipe progress |
| FR4 | Coin economy values in data tables | C4 |
| FR5 | Shop shell: catalog, equip, locker | scope + data tables |
| FR6 | Server-side receipt validation; capped perks | server authority — validation never on client |
| FR7 | Referral: both parties rewarded | requirement fidelity |
| FR8 | Roblox native social only — zero custom social code | any custom party/matchmaking code = finding |
| FR9 | Chat filter only, no external links, no data beyond Roblox IDs | safety — any custom text chat or external fetch = finding |
| FR10 | Content updates ship data-only through green CI | C1 + C4 |

Design fidelity checks (PRD §4): round cycle lobby ≥ 8 s vote → 5 s intro → 60–90 s round → 10 s results; every round playable solo; fail states readable instantly.
