# TASKS.md — Active Task Tracking
## Party Panic — Live Task Board

> **Updated by Orchestrator**. Leader reads this for status. Agents report completion here.

---

## Active Tasks

| ID | Title | Agent | Role | Branch | Status | Depends | Started | Acceptance |
|----|-------|-------|------|--------|--------|---------|---------|------------|

---

## Completed Tasks (This Session)

| ID | Title | Agent | Completed | PR | Merged |
|----|-------|-------|-----------|-----|--------|

---

## Backlog (Prioritized)

| ID | Title | Goal | Agent | Role | Priority | Blocked By |
|----|-------|------|-------|------|----------|------------|

---

## Task Template (Copy for New Tasks)

```markdown
## T-<uuid> — <Title>
- **Goal**: G-<uuid> (<description>)
- **Agent**: <builder|tester|researcher|docs>
- **Role**: <backend|client|map|ui>
- **Branch**: agent/<role>-<slug>
- **Worktree**: ~/Dev/PartyPanic-<role>
- **Status**: CREATED|ASSIGNED|IN_PROGRESS|IMPLEMENTED|VERIFIED|BLOCKED|FAILED
- **Depends**: [T-<uuid>]
- **Assigned**: <timestamp>
- **Files**:
  - <exact path>
  - <exact path>
- **Acceptance**:
  - <command that must pass>
  - <command that must pass>
- **Skills**: [roblox-xxx, roblox-yyy]
- **Context**: <link to goal, Operator request, or prior task>
```

---

## Status Definitions

| Status | Meaning | Next Valid Transitions |
|--------|---------|------------------------|
| CREATED | Task exists, not yet assigned | ASSIGNED |
| ASSIGNED | Orchestrator gave to agent | IN_PROGRESS, BLOCKED |
| IN_PROGRESS | Agent working | IMPLEMENTED, BLOCKED, FAILED |
| IMPLEMENTED | Builder pushed, reported | VERIFIED, BLOCKED |
| VERIFIED | Tester passed all gates | REVIEWED |
| REVIEWED | Jules posted review | APPROVED, NEEDS_REWORK |
| APPROVED | Jules = APPROVE | MERGED (by Operator) |
| MERGED | Operator merged to main | — |
| BLOCKED | External blocker | IN_PROGRESS (when unblocked) |
| FAILED | Verification failed | IN_PROGRESS (after fix) |
| NEEDS_REWORK | Jules REQUEST CHANGES | IN_PROGRESS (after fix) |

---

## Quick Commands

```bash
# View all tasks
cat /home/vsad/Dev/"Party Panic"/.ai/TASKS.md

# Add task (Orchestrator)
# Edit this file, add task in Active section

# Update status (Agent/Orchestrator)
# Edit status column, add completion data

# Archive completed (Orchestrator weekly)
# Move to Completed section, add PR/merge info
```