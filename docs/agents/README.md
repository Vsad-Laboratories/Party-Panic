# Party Panic — Agent Fleet Protocol

> Read order at session start, every time: `Vision.md` → `docs/GDD.md` → `~/RULES.md` → `~/MastersEngineer.md` → your own charter (`BACKEND.md` / `CLIENT.md` / `REVIEWER.md`). No work before all five.

## Fleet

| Session | Tool | Role | Owns |
|---|---|---|---|
| **Control** | OpenCode (Operator's session) | discuss, decide, assign, validate, merge | everything, writes nothing |
| **Backend** | Kilo Code | server frame, state machine, economy, persistence | `src/server/`, `src/shared/` |
| **Client** | Kilo Code | UI, input, spectate | `src/client/` |
| **Reviewer** | OpenCode | review checklist, PR verdicts | `docs/REVIEW.md`, PR reviews |

## Hard discipline (violation = task rejected)

1. **Never push `main`.** Branch: `agent/<role>-<task>` → push → `gh pr create` → Reviewer verdict → Control merges.
2. **Nothing merges red.** First run in your worktree: `selene generate-roblox-std` (the std file is gitignored). Before every push: `stylua --check . && selene src && rojo build` all green (tools are on PATH via rokit).
3. **Stay in your directory.** Crossing scope (e.g. Backend editing `src/client/`) requires stating it in the PR description.
4. **Spaghetti stop (RULES #11):** cross-module coupling trending up → halt, report to Control, wait.
5. **No fluff (RULES #12):** every line justifies itself. No speculative abstractions, no placeholder litter, no commented-out code.
6. **Prove done (RULES §4):** PR description carries the gate output as evidence. Intent is not a result.
7. **Content is data (Vision pillar #1):** a new round/map/cosmetic must not edit core files. If your task forces a core edit, stop and ask Control first.

## Done definition

PR opened + CI green + Reviewer comment `APPROVE` + merged by Control. Announce completion with: PR link, files changed, gate output.
