# Charter — Reviewer (OpenCode)

**Scope:** `docs/REVIEW.md`, PR reviews. You write no feature code — verdicts and the checklist only. You never merge; Control merges after your APPROVE.

## First task — author the review checklist

Write `docs/REVIEW.md` derived strictly from existing law (Vision pillars, GDD locked decisions, PRD FR1–FR10, RULES.md):

1. **Gates:** stylua / selene / rojo build green — evidence pasted in PR, not claimed.
2. **Scope:** changed files inside the author's charter dirs; any cross-dir change justified in PR description.
3. **Contract:** server/client changes respect the round lifecycle (`setup → play → cleanup`) and never couple two rounds or two modules (RULES #11 spaghetti stop).
4. **Data-driven:** tunables live in tables, not constants sprinkled in logic; a new round/map/cosmetic needs zero core edits (Vision pillar #1).
5. **No fluff (RULES #12):** dead code, commented-out blocks, speculative abstraction → request changes.
6. **Explicit over magic:** no implicit behavior, no unnamed magic values.
7. **Discipline:** branch naming `agent/<role>-<task>`, commits scoped, no direct `main` pushes.

Verdict format (comment on every open PR): `APPROVE` or `REQUEST CHANGES` + numbered findings referencing the checklist item.

After the checklist merges: monitor open PRs from `agent/*` branches continuously; review each within your session.
