# Space-Agents Roadmap

*Consolidated list of incomplete features, future vision, and planned work.*

**Created:** 2026-01-17
**Vision Reference:** `gas-town-vision.md`

---

## Priority Legend

| Priority | Meaning |
|----------|---------|
| **P0** | Blocking current work, do next |
| **P1** | High value, near-term |
| **P2** | Medium priority, when needed |
| **P3** | Low priority, future phases |
| **P4** | Deferred, distant future |

---

## P0 - Blocking / Do Next

*Nothing currently blocking.*

---

## P1 - High Priority (Near-Term)

### 1. /maintenance Skill

**Status:** Folder exists, no SKILL.md
**Source:** `2026-01-16-space-agents-plugin-design.md`

| Capability | Description |
|------------|-------------|
| Archive completed voyages | Move from `active/` to `complete/` |
| Cleanup empty folders | Remove empty mission directories |
| Database maintenance | Vacuum, integrity checks |
| Log rotation | Archive old CAPCOM entries |

**Why P1:** Completed work accumulates without cleanup. System becomes messy over time.

---

## P2 - Medium Priority (Quality of Life)

### 2. CAPCOM Memory Management

**Status:** Partially designed
**Source:** `2026-01-16-space-agents-plugin-design.md`, `yegge-beads.md`

| Item | Description |
|------|-------------|
| `/dock --compress` | Compress CAPCOM log entries older than 30 days |
| Memory decay | Summarize old closed work to reclaim context |
| Selective loading | Query CAPCOM instead of full read |

**Why P2:** CAPCOM logs grow indefinitely. Eventually becomes unwieldy.

### 3. Propulsion Principle (GUPP)

**Status:** Concept documented
**Source:** `yegge-gastown.md`

> "If there is work assigned to you, execute it. No waiting. No asking."

**Implementation:**
- Add GUPP statement to Pod/Worker prompts
- Enforce "honor the assignment" behavior
- Prevent stalled subagents waiting for confirmation

**Why P2:** Quality of life improvement. Prevents agents from pausing unnecessarily.

### 4. Dependency Tracking (Ready-State Semantics)

**Status:** Concept from Beads
**Source:** `yegge-beads.md`

| Item | Description |
|------|-------------|
| Objective dependencies | Track which objectives block others |
| Ready-state query | Only surface unblocked work to Pods |
| Dependency visualization | Show blocking relationships |

**Why P2:** Currently objectives are sequential by default. Explicit dependencies enable smarter scheduling.

### 5. Session Boundaries (Land the Plane)

**Status:** Concept from Beads
**Source:** `yegge-beads.md`

| Item | Description |
|------|-------------|
| Clean exit protocol | Ensure all work is committed before Pod exits |
| Handover generation | Auto-generate context for next session |
| State verification | Confirm SQLite and CAPCOM are in sync |

**Why P2:** Pods sometimes exit with uncommitted work. Clean boundaries prevent state drift.

---

## P3 - Low Priority (Future Phases)

### 6. Parallel Execution (Phase 2)

**Status:** Deferred until sequential feels slow
**Source:** `SPACE-AGENTS-DESIGN.md`

| Item | Description |
|------|-------------|
| Git worktrees | File isolation for parallel Pods |
| Refinery | Merge queue, sequential rebasing |
| Parallel Ralph | Multiple `ralph.sh` instances |
| Hash-based IDs | Multi-agent collision safety |

**Why P3:** Sequential execution works fine for most tasks. Parallel adds complexity.

### 7. Health Monitoring (Phase 3)

**Status:** Deferred until scaling
**Source:** `SPACE-AGENTS-DESIGN.md`, `yegge-gastown.md`

| Item | Description |
|------|-------------|
| Witness | Pod health monitoring, detect stuck agents |
| Deacon | System health daemon, patrol cycles |
| Dog | Watchdog for the watchdog |

**Why P3:** Only needed when running many agents. Overhead until then.

### 8. F-Thread Advanced Config

**Status:** Enhancement ideas
**Source:** `2026-01-16-f-thread-planning-architecture.md`

| Item | Description |
|------|-------------|
| User-configurable agent counts | `RESEARCH_AGENTS=5` env var |
| Custom agent types | User-defined specialists |
| Cost management | Budget controls for F-Threading |
| Synthesis agent | Dedicated agent to merge F-Thread outputs |

**Why P3:** Current F-Thread config is hardcoded. Flexibility is nice-to-have.

### 9. F-Thread Code Review

**Status:** Concept
**Source:** `2026-01-16-f-thread-planning-architecture.md`

Spawn 3-5 review agents in parallel to analyze code from different perspectives (security, performance, maintainability, etc.).

**Why P3:** Enhancement to existing review process. Not critical path.

### 10. F-Thread Speculative Execution

**Status:** Experimental concept
**Source:** `2026-01-16-f-thread-planning-architecture.md`

For risky objectives, spawn 3 Pods with different approaches, pick the best result.

**Why P3:** Expensive in tokens. Only valuable for high-stakes changes.

---

## P4 - Deferred (Distant Future)

### 11. tmux Orchestration (Phase 4)

**Status:** Research documented
**Source:** `SPACE-AGENTS-DESIGN.md`, `docs/research/tmux-orchestration.md`

| Item | Description |
|------|-------------|
| Session-per-agent | Each agent in named tmux session |
| Real-time visibility | Attach to any agent to observe |
| Output capture | Monitor without interrupting |

**Why P4:** Task tool works. tmux adds value at scale for 20+ agents.

### 12. Advanced Workflows (Phase 4)

**Status:** Gas Town concepts
**Source:** `SPACE-AGENTS-DESIGN.md`, `yegge-gastown.md`

| Item | Description |
|------|-------------|
| MEOW Molecules | Chained workflow templates |
| Handoff Protocol | Context-full mid-task session swap |
| Sophisticated Mail | Priority queues, fan-out, claiming |

**Why P4:** Missions/Objectives cover most use cases. These are refinements.

### 13. Session Archaeology (Seance)

**Status:** Concept from Gas Town
**Source:** `SPACE-AGENTS-DESIGN.md`

Query past session decisions. Ask "why did we do X?" and get structured answers from historical logs.

**Why P4:** CAPCOM logs provide most of this. Structured query is a refinement.

### 14. Web Dashboard

**Status:** Distant vision
**Source:** `SPACE-AGENTS-DESIGN.md`

Visual dashboard for swarm visibility beyond CLI.

**Why P4:** CLI works. Dashboard only valuable at significant scale.

---

## Completed (Reference)

### Phase 1 Core

- [x] `/install` skill - project setup
- [x] `/launch` skill - session start, HOUSTON persona
- [x] `/dock` skill - session end, logout screen
- [x] SQLite schema - voyages, missions, objectives, messages, alerts
- [x] `ralph.sh` - execution loop
- [x] Pod/Worker/Inspector/Analyst prompts
- [x] `/airlock` skill - test/lint validation
- [x] CAPCOM log format
- [x] `/capcom` skill - status check via subagent
- [x] `/brainstorming` skill - conversation-first exploration
- [x] `/planning` skill - forward-deployed F-Threading
- [x] `/mission` skill - launch Ralph loop
- [x] `/handover` skill - mid-session context dump

---

## Implementation Notes

### When to Promote Priority

- **P3 -> P2**: When you hit the limitation in practice
- **P2 -> P1**: When it's blocking a common workflow
- **P1 -> P0**: When it's blocking the current task

### Sources

All items extracted from:
- `docs/plans/2026-01-16-space-agents-plugin-design.md`
- `docs/plans/SPACE-AGENTS-DESIGN.md`
- `docs/plans/2026-01-16-f-thread-planning-architecture.md`
- `docs/research/yegge-gastown.md`
- `docs/research/yegge-beads.md`

---

*Last updated: 2026-01-17*

---

## Reference: Documents Inventory

**Location:** `docs/plans/`

| Document | Purpose | Status |
|----------|---------|--------|
| `SPACE-AGENTS-DESIGN.md` | Foundational design - NASA hierarchy, computing model | Complete |
| `2026-01-16-space-agents-plugin-design.md` | Full plugin spec - skills, agents, scripts, 4-phase roadmap | Phase 1 Complete |
| `2026-01-16-architecture-refactor.md` | Refactor checklist | 8/9 Done |
| `HANDOVER-2026-01-16.md` | Context dump from Phase 1 completion | Reference |
| `2026-01-16-f-thread-planning-architecture.md` | Two-tier system design (F-Thread + Ralph) | Design Phase |
| `2026-01-16-brainstorming-forward-deployed-fthread.md` | Forward-deployed parallel agents for brainstorming | Design Phase |
| `2026-01-16-planning-forward-deployed-fthread.md` | Forward-deployed parallel agents for planning | Design Phase |

---

## Reference: Agents Inventory

**Location:** `agents/`

| Agent | Used By | Purpose |
|-------|---------|---------|
| `mission-pod.md` | Ralph loop | Orchestrates crew for single objective |
| `mission-worker.md` | Pod | Implements code changes |
| `mission-inspector.md` | Pod | Reviews against requirements |
| `mission-analyst.md` | Pod | Reviews code quality |
| `brainstorming-research.md` | `/brainstorming` | Explores codebase for patterns |
| `brainstorming-architecture.md` | `/brainstorming` | Proposes architectural approaches |
| `brainstorming-risk.md` | `/brainstorming` | Identifies risks and estimates effort |
| `planning-task-planner.md` | `/planning` | Breaks feature into missions/objectives |
| `planning-sequencer.md` | `/planning` | Sequences missions, identifies dependencies |
| `planning-implementer.md` | `/planning` | Creates detailed TDD task breakdown |

---

## Reference: Key Design Decisions

| Decision | Choice | Source |
|----------|--------|--------|
| Installation method | Plugin install via marketplace | Plugin design |
| Project structure | Everything in `.space-agents/` | Plugin design |
| Session management | Explicit `/launch` and `/dock` | Plugin design |
| HOUSTON role | Plans, coordinates, never codes | SPACE-AGENTS-DESIGN |
| Pod orchestration | Pod is orchestrator (no separate Commander) | SPACE-AGENTS-DESIGN |
| Memory system | 3-tier (staging/CAPCOM/SQLite) | Plugin design |
| Planning architecture | Two-tier: F-Thread for planning, Ralph for execution | F-Thread architecture |
| Agent spawning | Forward-deployed (ahead of conversation) | Brainstorming F-Thread |
