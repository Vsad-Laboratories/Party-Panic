# WORKFLOW.md — Party Panic Development Workflows
## Git-Synchronized, Herdr-Orchestrated, Jules-Reviewed

> **Golden Rule**: Git is the synchronization boundary. Herdr handles terminals. Jules handles reviews. Agents never share working trees.

---

## 1. Worktree Architecture (Git-Enforced Isolation)

```
~/Dev/
├── Party Panic/                    # Main repo (Leader, Orchestrator, Docs, Researcher)
│   ├── .git/
│   ├── src/
│   ├── .ai/
│   ├── docs/
│   └── LICENSE
├── PartyPanic-backend/             # Builder (Backend) — Kilo Code
│   ├── src/server/
│   ├── src/shared/
│   └── .git → ../Party Panic/.git/worktrees/PartyPanic-backend
├── PartyPanic-client/              # Builder (Client) — Kilo Code
│   ├── src/client/
│   ├── src/shared/
│   └── .git → ../Party Panic/.git/worktrees/PartyPanic-client
├── PartyPanic-map/                 # Builder (Map) — OpenCode
│   ├── src/server/maps/
│   └── .git → ../Party Panic/.git/worktrees/PartyPanic-map
├── PartyPanic-ui/                  # Builder (UI) — OpenCode
│   ├── src/client/ui/
│   └── .git → ../Party Panic/.git/worktrees/PartyPanic-ui
└── PartyPanic-test/                # Tester (ephemeral)
    └── .git → ../Party Panic/.git/worktrees/PartyPanic-test
```

### Worktree Commands
```bash
# Create worktrees (one-time setup)
cd ~/Dev/"Party Panic"
git worktree add ../PartyPanic-backend backend/main
git worktree add ../PartyPanic-client client/main
git worktree add ../PartyPanic-map map/main
git worktree add ../PartyPanic-ui ui/main
git worktree add ../PartyPanic-test test/main

# List worktrees
git worktree list

# Prune dead worktrees
git worktree prune
```

### Branch Strategy
| Agent | Long-lived Branch | PR Branch Pattern |
|-------|-------------------|-------------------|
| Backend | `backend/main` | `agent/backend-<slug>` |
| Client | `client/main` | `agent/client-<slug>` |
| Map | `map/main` | `agent/map-<slug>` |
| UI | `ui/main` | `agent/ui-<slug>` |
| Test | `test/main` | `agent/test-<slug>` |
| Docs | `main` | `agent/docs-<slug>` |
| Research | `main` | `agent/research-<slug>` |

**Rule**: Long-lived branches (`backend/main`, etc.) track `main` via rebase. PR branches are ephemeral, deleted after merge.

---

## 2. Task Lifecycle (The Protocol)

```
TASK_CREATED (Leader → Orchestrator)
       ↓
TASK_DECOMPOSED (Orchestrator → Task Graph)
       ↓
TASK_ASSIGNED (Orchestrator → Agent)
       ↓
ASSIGNED (Agent acknowledges)
       ↓
IMPLEMENTING (Builder) / INVESTIGATING (Researcher) / TESTING (Tester) / WRITING (Docs)
       ↓
IMPLEMENTED / FINDINGS / TEST_REPORT / DOC_UPDATE (Agent → Orchestrator)
       ↓
VERIFICATION (Tester runs gates + playtest)
       ↓
VERIFIED (Tester → Orchestrator)
       ↓
PR_OPENED (Builder pushes → CI → PR)
       ↓
JULES_REVIEW (Leader invokes Jules)
       ↓
APPROVED (Jules → Leader)
       ↓
MERGE (Operator merges)
       ↓
DEPLOY (main CI + publish)
```

### State Machine (Per Task)
```
CREATED → ASSIGNED → IN_PROGRESS → IMPLEMENTED → VERIFIED → REVIEWED → APPROVED → MERGED
                ↓            ↓            ↓
             BLOCKED      FAILED       NEEDS_REWORK
                ↓            ↓            ↓
             (reassign)  (fix + retry)  (reassign)
```

### Status Transitions (Enforced)
| From | To | Trigger |
|------|-----|---------|
| CREATED | ASSIGNED | Orchestrator assigns |
| ASSIGNED | IN_PROGRESS | Agent acknowledges |
| IN_PROGRESS | IMPLEMENTED | Builder pushes + reports |
| IN_PROGRESS | BLOCKED | Blocker reported |
| IN_PROGRESS | FAILED | Verification fails |
| IMPLEMENTED | VERIFIED | Tester passes all gates |
| VERIFIED | REVIEWED | Jules posts review |
| REVIEWED | APPROVED | Jules verdict = APPROVE |
| APPROVED | MERGED | Operator merges |
| BLOCKED/FAILED | IN_PROGRESS | Fix pushed + re-verify |

---

## 3. Task Specification (Orchestrator Output)

### Task Assignment Template
```yaml
# Orchestrator writes to .ai/TASKS.md or dispatches via Herdr
TASK_ASSIGNMENT:
  id: T-<uuid>
  parent_goal: G-<uuid>  # from Leader
  agent: builder|tester|researcher|docs
  role: backend|client|map|ui
  branch: agent/<role>-<slug>
  worktree: ~/Dev/PartyPanic-<role>
  priority: high|normal|low
  depends_on: [T-<uuid>]  # optional
  files:
    - src/server/MonetizationService.luau
    - src/shared/MonetizationConfig.luau
  skills: [roblox-monetization, roblox-security, roblox-datastores]
  acceptance:
    - "stylua --check src"
    - "selene src"
    - "rojo build"
    - "MonetizationService.grantCoins(player, 100, 'test') → coinCount = 100"
  skills: [roblox-monetization, roblox-security, roblox-datastores]
  context: "Implement coin grant with VIP bonus cap. Part of monetization backend."
```

### Task Status File (`.ai/TASKS.md`)
```markdown
# Active Tasks

## T-<uuid> — Monetization Backend
- **Goal**: G-<uuid> (Monetization backend)
- **Agent**: builder (backend)
- **Branch**: agent/backend-monetization
- **Status**: IN_PROGRESS
- **Depends**: []
- **Assigned**: 2026-09-28 14:30
- **Files**: src/server/MonetizationService.luau, src/shared/MonetizationConfig.luau
- **Acceptance**: stylua, selene, rojo, grantCoins test

## T-<uuid> — Lobby Redesign
- **Goal**: G-<uuid> (Lobby reference match)
- **Agent**: builder (map)
- **Branch**: agent/map-lobby-redesign
- **Status**: ASSIGNED
- **Depends**: []
- **Assigned**: 2026-09-28 14:35
```

---

## 4. Communication Protocol (Structured, Predictable)

### Message Types

#### TASK_CREATED (Leader → Orchestrator)
```json
{
  "type": "TASK_CREATED",
  "id": "T-<uuid>",
  "goal": "Monetization backend with receipt validation",
  "scope": ["src/server/MonetizationService.luau", "src/shared/MonetizationConfig.luau"],
  "acceptance": ["stylua", "selene", "rojo", "grantCoins test"],
  "priority": "high",
  "assigned_to": "orchestrator"
}
```

#### TASK_ASSIGNMENT (Orchestrator → Agent)
```json
{
  "type": "TASK_ASSIGNMENT",
  "id": "T-<uuid>",
  "parent_goal": "G-<uuid>",
  "agent": "builder",
  "role": "backend",
  "branch": "agent/backend-monetization",
  "worktree": "~/Dev/PartyPanic-backend",
  "files": ["src/server/MonetizationService.luau", "src/shared/MonetizationConfig.luau"],
  "acceptance": ["stylua --check src", "selene src", "rojo build", "grantCoins test"],
  "skills": ["roblox-monetization", "roblox-security", "roblox-datastores"],
  "depends_on": []
}
```

#### ASSIGNED (Agent → Orchestrator)
```json
{
  "type": "ASSIGNED",
  "task_id": "T-<uuid>",
  "agent": "builder",
  "status": "ACKNOWLEDGED",
  "started_at": "2026-09-28T14:30:00Z"
}
```

#### TASK_COMPLETED (Builder → Orchestrator)
```json
{
  "type": "TASK_COMPLETED",
  "id": "T-<uuid>",
  "status": "DONE",
  "branch": "agent/backend-monetization",
  "commits": ["abc1234"],
  "changes": [
    "src/server/MonetizationService.luau: Added ProcessReceipt + ShopPurchase handler",
    "src/shared/MonetizationConfig.luau: Added CurrencyTiers matching client"
  ],
  "verification": {
    "stylua": "PASS",
    "selene": "PASS",
    "rojo": "PASS",
    "grantCoins": "PASS"
  },
  "files": [
    "src/server/MonetizationService.luau",
    "src/shared/MonetizationConfig.luau"
  ],
  "blockers": null
}
```

#### TEST_REPORT (Tester → Orchestrator)
```json
{
  "type": "TEST_REPORT",
  "task_id": "T-<uuid>",
  "status": "PASS",
  "tests_run": {
    "stylua": "PASS",
    "selene": "PASS",
    "rojo": "PASS",
    "playtest": "monetization_flow: PASS"
  },
  "failures": [],
  "evidence": "logs/test_run.log"
}
```

#### FINDINGS (Researcher → Orchestrator/Builder)
```json
{
  "type": "FINDINGS",
  "task_id": "T-<uuid>",
  "topic": "Roblox DataStore UpdateAsync patterns",
  "findings": "Use UpdateAsync for atomic read-modify-write. Never SetAsync for counters.",
  "options": [
    {"name": "UpdateAsync with retry", "pros": ["atomic", "idempotent"], "cons": ["complexity"]}
  ],
  "recommendation": "Use UpdateAsync with exponential backoff retry (max 3). TTL receipt tracking.",
  "sources": ["roblox-datastores skill", "Roblox docs"]
}
```

#### TEST_REPORT (Tester → Orchestrator)
```json
{
  "type": "TEST_REPORT",
  "task_id": "T-<uuid>",
  "status": "PASS",
  "tests_run": {
    "stylua": "PASS",
    "selene": "PASS",
    "rojo": "PASS",
    "playtest": "monetization_flow: PASS"
  },
  "failures": [],
  "evidence": "logs/test_run.log"
}
```

#### VERDICT (Jules → Leader)
```json
{
  "type": "VERDICT",
  "pr": 42,
  "head": "abc1234",
  "verdict": "APPROVE",
  "findings": {
    "verified": ["ProcessReceipt idempotent", "VIP cap enforced"],
    "blockers": [],
    "majors": [],
    "minors": ["Add comment on TTL calculation"]
  }
}
```

---

## 5. Herdr Integration (Terminal Orchestration)

### Agent Spawning
```bash
# Backend (Kilo Code)
herdr agent start backend --kind kilo --pane w1:p3 -- -m kilo/poolside/laguna-s-2.1:free

# Client (Kilo Code)
herdr agent start client --kind kilo --pane w1:p4 -- -m kilo/poolside/laguna-s-2.1:free

# Map (OpenCode)
herdr agent start map --kind opencode --pane w1:p8

# UI (OpenCode)
herdr agent start ui --kind opencode --pane w1:p9

# Orchestrator (OpenCode)
herdr agent start orchestrator --kind opencode --pane w1:p3
```

### Task Dispatch
```bash
# Dispatch task to agent
herdr agent prompt w1:p3 "
TASK_ASSIGNMENT:
  id: T-<uuid>
  agent: builder
  role: backend
  branch: agent/backend-monetization
  worktree: ~/Dev/PartyPanic-backend
  files: [src/server/MonetizationService.luau, src/shared/MonetizationConfig.luau]
  acceptance: [stylua --check src, selene src, rojo build]
  skills: [roblox-monetization, roblox-security, roblox-datastores]
" --wait --until working --timeout 25000
```

### Status Check
```bash
herdr agent list | python3 -c "import json,sys; d=json.load(sys.stdin); [print(f'{a[\"pane_id\"]}: {a.get(\"name\",\"\")} status={a[\"agent_status\"]}') for a in d['result']['agents']]"
```

---

## 6. Git Synchronization Protocol

### Pre-Push Checklist (Builder)
```bash
cd ~/Dev/PartyPanic-backend
# 1. Sync with main
git fetch origin
git rebase origin/main

# 2. Run gates
stylua --check src
selene src
rojo build default.project.json -o /tmp/build.rbxlx

# 3. Commit
git add -A
git commit -m "feat(monetization): ProcessReceipt + ShopPurchase + VIP cap

- MonetizationService: ProcessReceipt with PurchaseId idempotency (30d TTL)
- ShopPurchase RemoteEvent handler for client purchases
- VIP coin bonus capped at +100% total (VIPBonusCap = 0.5)
- CurrencyTiers matching client formatCoins (K/M/B/T ladder)
- Asset packs loaded to ReplicatedStorage (GUIAnimationPack, EmoteSelector)

Skills: roblox-monetization, roblox-security, roblox-datastores, roblox-luau-patterns
Gates: stylua 0, selene 0/0/0, rojo OK"

# 4. Push PR branch
git push -u origin agent/backend-monetization

# 4. Create PR
cd /home/vsad/Dev/"Party Panic"
gh pr create --repo Vsad-Laboratories/Party-Panic \
  --title "feat(monetization): ProcessReceipt + ShopPurchase + VIP cap" \
  --body "..." \
  --head agent/backend-monetization \
  --base main
```

### Post-Merge Cleanup
```bash
# After Operator merges
git checkout main
git pull origin main
git branch -d agent/backend-monetization
git push origin --delete agent/backend-monetization
git worktree prune
```

---

## 7. Jules Review Integration

### Trigger
```bash
# Leader posts on PR
gh pr comment <number> --body "Jules, review #<number> at <head_sha>"
```

### Expected Jules Output (GitHub PR Review)
```markdown
## Jules Review — PR #42

### VERIFIED ✅
- ProcessReceipt idempotent on PurchaseId (30-day TTL)
- VIP coin bonus capped at +100% total
- CurrencyTiers match client formatCoins exactly
- ShopPurchase RemoteEvent created in init()
- Asset packs loaded to ReplicatedStorage

### BLOCKERS 🔴
None

### MAJORS 🟠
None

### MINORS 🟡
- Add comment explaining TTL calculation in _recordReceipt

### VERDICT: APPROVE
```

### Leader Action on Verdict
| Verdict | Action |
|---------|--------|
| APPROVE | Notify Operator to merge |
| REQUEST CHANGES | Dispatch fix task to Builder with Jules' findings |

---

## 8. Merge & Deploy Protocol

### Merge Requirements
- [ ] Jules verdict = `APPROVE`
- [ ] CI green at exact PR head
- [ ] Operator merges (squash + delete branch)
- [ ] Main CI green + publish (versionNumber in logs)

### Post-Merge
```bash
# Operator merges via GitHub UI (squash + delete branch)
# Control verifies:
cd /home/vsad/Dev/"Party Panic"
gh run list --branch main --limit 1 --json headSha,status,conclusion
# → must show success + publish step with versionNumber
```

---

## 9. Emergency Procedures

| Scenario | Procedure |
|----------|-----------|
| **Agent silent** | `herdr agent send-keys <pane> "C-c"` ×2 → re-dispatch with context |
| **CI fails** | Read logs → dispatch fix with error + file:line |
| **Jules finds spaghetti** | Stop features → dispatch refactor task → re-review |
| **Agent overwrites other** | Git shows conflict → `git worktree list` → verify isolation |
| **Worktree corrupted** | `git worktree remove <path>` → recreate from main |
| **Main broken** | `git revert <bad_merge>` → hotfix branch → Jules review |

---

## 10. Metrics & Observability

### Key Metrics (Tracked in `.ai/TASKS.md`)
| Metric | Target |
|--------|--------|
| Task cycle time (ASSIGNED → VERIFIED) | < 4 hours |
| CI pass rate (first push) | > 90% |
| Jules first-review approval | > 80% |
| Regressions per merge | 0 |
| Agent utilization | Balanced |

### Daily Standup (Leader → Operator)
```
Date: 2026-09-28
Active Tasks: 3 (2 IN_PROGRESS, 1 ASSIGNED)
Completed: 2 (Monetization backend, Lobby redesign)
Blocked: 0
Jules Queue: 1 (PR #42 - APPROVED)
Main CI: GREEN
Next: UI HUD polish + Shop shell
```

---

*This workflow is the fleet's operating system. Follow it exactly. Deviations cause collisions.*