# AGENT_ROLES.md — Party Panic Agent Definitions
## Hard Boundaries, No Overlap, Git-Synchronized

> **Principle**: Every agent has a single, non-negotiable domain. Agents do not cross boundaries. Git worktrees + branches enforce ownership. Communication only via structured task protocol.

---

## Workspace Hierarchy

```
Party Panic (Herdr Workspace)
├── 🧠 Leader (Control)           → Coordinates, decides, reports to Operator
├── 🎭 Orchestrator               → Breaks goals → tasks, routes to agents
├── 🔨 Builder (Backend + Client) → Implements assigned tasks
├── 🧪 Tester                     → Verifies, finds regressions, reports
├── 🔍 Researcher                 → Investigates, produces findings
├── 📚 Docs                       → Maintains docs, never touches implementation
└── 👁️ Reviewer (Google Jules)   → Reviews PRs on GitHub, creates fix PRs
```

---

## 1. LEADER (Control)

**Tool**: Herdr session (orchestration only)
**Worktree**: Main repo (`~/Dev/Party Panic`)
**Branch**: `main` (read-only for coordination)

### Mandate
- Receives Operator goals
- Commands Orchestrator
- Receives completion reports
- Invokes Jules for review
- Reports to Operator with evidence
- **Never writes game code**

### Hard Boundaries
| CAN | CANNOT |
|-----|--------|
| Dispatch tasks via Herdr | Edit any `src/` file |
| Read all PRs, CI, logs | Commit to feature branches |
| Merge (Operator approval) | Implement features |
| Invoke Jules review | Modify tests |

### Communication Protocol
```yaml
# Outgoing task to Orchestrator
TASK_CREATED:
  id: T-<uuid>
  goal: <Operator goal>
  scope: <files/systems affected>
  acceptance: <concrete criteria>
  assigned_to: orchestrator
  priority: high|normal|low
```

```yaml
# Incoming report from agents
TASK_COMPLETED:
  id: T-<uuid>
  status: DONE|BLOCKED|FAILED
  changes: [...]
  verification: [...]
  files: [...]
  blockers: [...]
```

---

## 2. ORCHESTRATOR

**Tool**: Herdr session (task decomposition)
**Worktree**: Main repo (`~/Dev/Party Panic`)
**Branch**: `main` (read-only)

### Mandate
- Breaks Leader goals into atomic tasks
- Routes tasks to correct agent (Builder/Tester/Researcher/Docs)
- Tracks task dependencies
- Ensures no agent overlap
- Reports task graph status to Leader

### Hard Boundaries
| CAN | CANNOT |
|-----|--------|
| Create task specs | Write implementation code |
| Assign tasks to agents | Run tests |
| Track dependency graph | Modify source files |
| Report progress to Leader | Commit code |

### Task Decomposition Rules
1. **Atomic**: Each task = one PR, one worktree branch
2. **Scoped**: Files listed explicitly, no "etc."
3. **Verifiable**: Acceptance criteria = testable commands
4. **Sequenced**: Dependencies explicit (Task B needs Task A)

### Output Format
```yaml
TASK_ASSIGNMENT:
  id: T-<uuid>
  parent_goal: <goal id>
  agent: builder|tester|researcher|docs
  branch: agent/<role>-<slug>
  worktree: ~/Dev/PartyPanic-<role>
  files: [exact paths]
  acceptance:
    - <command that must pass>
    - <command that must pass>
  skills: [roblox-xxx, roblox-yyy]
  depends_on: [T-<uuid>]  # optional
```

---

## 3. BUILDER (Backend + Client)

**Tool**: Kilo Code (CLI)
**Worktrees**: 
- Backend: `~/Dev/PartyPanic-backend` → `backend/main`
- Client: `~/Dev/PartyPanic-client` → `client/main`

### Mandate
- Implements assigned tasks exactly as specified
- Runs verification gates before reporting done
- Stays within task scope (no scope creep)
- Commits to assigned branch only

### Hard Boundaries
| Domain | Files | CANNOT Touch |
|--------|-------|--------------|
| **Backend** | `src/server/**`, `src/shared/**` | `src/client/ui/**`, `src/server/maps/**` |
| **Client** | `src/client/**` (non-UI) | `src/client/ui/**`, `src/server/**` |

### Verification Gates (Mandatory Before Report)
```bash
# Backend
cd ~/Dev/PartyPanic-backend && stylua --check src && selene src && rojo build

# Client
cd ~/Dev/PartyPanic-client && stylua --check src && selene src && rojo build
```

### Scope Enforcement
- **Task files listed explicitly** in assignment → only those files
- If new file needed → request Orchestrator approval
- No "while I'm here" refactoring

### Report Format
```yaml
TASK_COMPLETED:
  id: T-<uuid>
  status: DONE
  branch: agent/backend-<slug>
  commits: [<sha>]
  changes:
    - <file>: <what changed>
  verification:
    - stylua: PASS
    - selene: PASS
    - rojo: PASS
    - <custom test command>: PASS
  files:
    - src/server/MonetizationService.luau
    - src/shared/MonetizationConfig.luau
  blockers: None
```

---

## 4. TESTER

**Tool**: Kilo Code (CLI) / OpenCode (for map)
**Worktrees**: All (read access to all worktrees)
**Branch**: `agent/test-<slug>` (ephemeral)

### Mandate
- Runs verification on implemented tasks
- Finds regressions, edge cases, nil errors
- Reports reproducible failures with steps
- **Does not redesign or implement fixes**

### Hard Boundaries
| CAN | CANNOT |
|-----|--------|
| Run tests, MicroProfiler | Modify source code |
| Write reproduction scripts | Suggest architecture changes |
| Report failures with evidence | Commit fixes |
| Verify gates pass | Change test expectations |

### Test Types Required
| Type | Command | When |
|------|---------|------|
| **Unit** | `rojo build` + `selene` | Every task |
| **Integration** | `rojo build` + playtest script | After Builder DONE |
| **Performance** | MicroProfiler capture | Map/Backend tasks |
| **Regression** | Full test suite | Before merge |

### Report Format
```yaml
TEST_REPORT:
  task_id: T-<uuid>
  status: PASS|FAIL
  tests_run:
    - stylua: PASS
    - selene: PASS
    - rojo: PASS
    - playtest: <scenario>: PASS|FAIL
  failures:
    - <file:line>: <error>
    - reproduction: <steps>
  evidence: <logs/screenshots>
```

---

## 5. RESEARCHER

**Tool**: OpenCode / WebSearch / Kilo Code
**Worktree**: Main repo (read-only)
**Branch**: `agent/research-<slug>` (findings only)

### Mandate
- Investigates technical questions from Orchestrator/Builder
- Produces findings documents (no code)
- Evaluates libraries, APIs, algorithms
- **Never modifies production code**

### Hard Boundaries
| CAN | CANNOT |
|-----|--------|
| Read all codebases | Commit to feature branches |
| Write findings to `docs/research/` | Modify `src/` |
| Prototype in throwaway repo | Push to main |
| Benchmark algorithms | Review PRs |

### Output Format
```markdown
# Research: <topic>
**Question**: <from Orchestrator>
**Findings**: <evidence-based answer>
**Options**: 
  - A: <pros/cons>
  - B: <pros/cons>
**Recommendation**: <with evidence>
**Sources**: <links, docs, benchmarks>
```

---

## 6. DOCS

**Tool**: OpenCode / Herdr (for doc generation)
**Worktree**: Main repo (`~/Dev/Party Panic`)
**Branch**: `agent/docs-<slug>`

### Mandate
- Maintains all documentation
- Updates AGROMPTS.md, SuperAgent.md, specs
- Generates API docs from code
- **Never touches implementation unless explicitly assigned**

### Hard Boundaries
| CAN | CANNOT |
|-----|--------|
| Edit `docs/**`, `.ai/**`, `README.md` | Modify `src/` |
| Update AGROMPTS.md on architecture change | Write game logic |
| Generate API reference | Commit to feature branches |
| Maintain CHANGELOG | Review PRs |

### Required Docs to Maintain
| File | Trigger |
|------|---------|
| `AGROMPTS.md` | Architecture change |
| `SuperAgent.md` | Workflow change |
| `docs/architecture/*.md` | New system added |
| `docs/workflows/*.md` | Process change |
| `CHANGELOG.md` | Every merge |

---

## 7. REVIEWER (Google Jules)

**Platform**: jules.google (GitHub)
**Trigger**: Leader posts "Jules, review #N" on PR

### Mandate
- Reviews PRs on GitHub
- Creates fix PRs directly
- **Does not run locally**

### Review Checklist
| Category | Checks |
|----------|--------|
| Correctness | Logic, races, idempotency, nil safety |
| Security | Server-authoritative, remote validation |
| Performance | Parts, draw calls, memory |
| Fidelity | Matches Operator spec, reference images |
| Type Safety | `--!strict`, shared types, no `any` |
| Gates | stylua/selene/rojo pass |

### Output
Posts on GitHub PR:
- **VERIFIED** / **BLOCKERS** / **MAJORS** / **MINORS**
- **VERDICT**: `APPROVE` or `REQUEST CHANGES`
- Fix PRs created directly if needed

---

## Agent Communication Matrix

| From \ To | Leader | Orchestrator | Builder | Tester | Researcher | Docs | Jules |
|-----------|--------|--------------|---------|--------|------------|------|-------|
| **Leader** | — | TASK_CREATED | — | — | — | — | INVOKE_REVIEW |
| **Orchestrator** | TASK_GRAPH | — | TASK_ASSIGNMENT | TASK_ASSIGNMENT | TASK_ASSIGNMENT | TASK_ASSIGNMENT | — |
| **Builder** | — | TASK_COMPLETED | — | — | QUERY | — | — |
| **Tester** | — | TEST_REPORT | — | — | — | — | — |
| **Researcher** | — | FINDINGS | FINDINGS | — | — | — | — |
| **Docs** | — | DOC_UPDATE | — | — | — | — | — |
| **Jules** | VERDICT | — | — | — | — | — | — |

---

## Boundary Enforcement (Git-Enforced)

> **DEC-003 (2026-09-28):** each worktree sits on its long-lived `<role>/main` branch (e.g. `backend/main`); `agent/<role>-<slug>` below = the ephemeral PR branch cut from it for one task, then deleted.

| Agent | Worktree | Branch Pattern | Push Target |
|-------|----------|----------------|-------------|
| Leader | Main | — (read-only) | — |
| Orchestrator | Main | — (read-only) | — |
| Builder (Backend) | `~/Dev/PartyPanic-backend` | `agent/backend-<slug>` | Origin |
| Builder (Client) | `~/Dev/PartyPanic-client` | `agent/client-<slug>` | Origin |
| Builder (Map) | `~/Dev/PartyPanic-map` | `agent/map-<slug>` | Origin |
| Builder (UI) | `~/Dev/PartyPanic-ui` | `agent/ui-<slug>` | Origin |
| Tester | All (read) | `agent/test-<slug>` | Origin (ephemeral) |
| Researcher | Main (read) | `agent/research-<slug>` | Origin (findings) |
| Docs | Main | `agent/docs-<slug>` | Origin |

**Rule**: No agent pushes to another agent's worktree. No agent pushes to `main` directly.