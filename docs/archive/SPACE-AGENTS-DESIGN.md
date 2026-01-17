# Space-Agents

**Experimental framework for orchestrating Claude Code agents with fresh context loops.**

*Evolved from SAL-9000 / Agent Launchpad*

---

## Core Insight

> **"Agents are compute, not memory."**

You don't try to make agents remember — you give them clean state each time and let them process. Context rot happens when you treat agents like storage. Fresh agents + persistent state = indefinite scaling.

---

## Hierarchy

| Level | Maps To | Description |
|-------|---------|-------------|
| **Voyage** | Epic | Large initiative, multiple features |
| **Mission** | Feature | Coherent capability |
| **Objective** | Story | Atomic work item |
| **Pod** | Execution | Fresh Ralph iteration per objective |

```
VOYAGE: "User Authentication System"
    │
    ├── MISSION: "JWT Token Management"
    │       ├── Objective: Implement signing
    │       ├── Objective: Implement verification
    │       └── Objective: Add expiry handling
    │
    └── MISSION: "Login Flow"
            ├── Objective: Login endpoint
            ├── Objective: Session middleware
            └── Objective: Logout endpoint
```

Each objective triggers one Pod launch (one Ralph iteration). The Pod is the spacecraft. The crew (Worker, Inspector, Analyst) complete the objective, transmit results to CAPCOM, and the Pod is done.

---

## Roles

| Role | Type | Responsibility |
|------|------|----------------|
| **HOUSTON** | Flight Director | Commander. Plans voyages, launches pods, reads CAPCOM. Never touches code. |
| **Pod** | Spacecraft | Orchestrates one objective through crew cycle. Fresh context, then discarded. |
| **Worker** | Crew | Implements the objective |
| **Inspector** | Crew | Reviews against requirements |
| **Analyst** | Crew | Reviews code quality |

### HOUSTON (Flight Director)

HOUSTON is your persistent conversation partner — like a NASA Flight Director sitting in Mission Control. HOUSTON:

- Plans voyages and breaks them into missions/objectives
- Launches Pods via the Ralph loop
- Monitors progress via CAPCOM
- Reports results
- Never executes code directly

HOUSTON has skills (Superpowers-style):
- `/brainstorming` — Pre-implementation exploration
- `/planning` — Mission breakdown, objective decomposition
- `/capcom` — Status check via subagent

### Pod (Spacecraft)

The Pod is the execution context — a fresh Claude Code session spawned for each objective. The Pod:

1. Reads SQLite, selects the objective
2. Spawns Worker → implements
3. Spawns Inspector → reviews requirements (retry Worker if fail)
4. Spawns Analyst → reviews quality (retry Worker if fail)
5. Runs Airlock (tests/lint)
6. Updates CAPCOM log + SQLite
7. Exits (context discarded)

**Key decision**: Pod is the orchestrator. No separate Commander role — keeps it simple.

---

## Architecture

```
YOU ↔ HOUSTON (persistent session, Flight Director)
        │
        ├── /brainstorming    ← Superpowers-style skill
        ├── /planning         ← Mission breakdown
        ├── /capcom           ← Status via subagent
        │
        ▼
    RALPH LOOP (bash)
        │
        ▼
    POD (fresh each iteration)
        ├── Worker
        ├── Inspector
        └── Analyst
        │
        ▼
    AIRLOCK (tests/lint)
        │
        ▼
    CAPCOM + SQLite (state persists)
```

### Where It Lives

**Updated (2026-01-16):** Skills are now project-local, distributed as a plugin:

```
space-agents/                    # Plugin repository
├── skills/
│   ├── launch/                  # Session start + HOUSTON persona
│   │   └── SKILL.md
│   ├── dock/                    # Session end + logout screen
│   │   └── SKILL.md
│   ├── install/                 # Setup wizard
│   │   ├── SKILL.md
│   │   └── init-db.sql
│   ├── airlock/                 # Test/lint validation
│   │   ├── SKILL.md
│   │   └── airlock.sh
│   └── mission-run/             # Launch Ralph loop
│       ├── SKILL.md
│       └── ralph.sh
├── agents/                      # Agent prompts
│   ├── pod.md
│   ├── worker.md
│   ├── inspector.md
│   └── analyst.md
└── docs/                        # Documentation
```

---

## Zero Dependencies

Space-Agents requires no external packages. Everything is built with Claude Code primitives:

| Component | How It's Created | Dependency |
|-----------|------------------|------------|
| Skills | Markdown files | None (Write tool) |
| Prompts | Markdown files | None (Write tool) |
| ralph.sh | Shell script | Bash (built-in) |
| airlock.sh | Shell script | Bash (built-in) |
| SQLite DB | `sqlite3` command | Built into macOS/Linux |
| CAPCOM log | Markdown file | None (Write tool) |
| Directory structure | `mkdir -p` | Bash (built-in) |

Anyone with Claude Code can install and run Space-Agents. No `npm install`, no `pip install`, no Docker.

---

## Installation (`/install` Skill)

A single command sets up the entire system:

```
User: /install
```

### What It Creates

**1. Global skills** (if not present):
```
~/.claude/skills/space-agents/
├── houston.md
├── brainstorming.md
├── planning.md
├── capcom.md
├── mission-run.md
├── install.md
└── prompts/
    ├── pod.md
    ├── worker.md
    ├── inspector.md
    └── analyst.md
```

**2. Project structure**:
```
.space-agents/
├── space-agents.db       # SQLite database
└── capcom.md             # Master CAPCOM log

missions/
├── todo/                 # Planned voyages/missions
├── active/               # In-progress work
└── complete/             # Finished (archived)

scripts/
├── ralph.sh              # The execution loop
└── airlock.sh            # Test/lint validation
```

**3. SQLite schema**:
```sql
-- Initialize database with tables
CREATE TABLE voyages (...);
CREATE TABLE missions (...);
CREATE TABLE objectives (...);
CREATE TABLE messages (...);
```

### Output

```
Space-Agents installed successfully.

Created:
  ✓ .space-agents/space-agents.db (SQLite initialized)
  ✓ .space-agents/capcom.md (Master log)
  ✓ missions/ (todo, active, complete)
  ✓ scripts/ralph.sh
  ✓ scripts/airlock.sh

Run /houston to begin.
```

---

## Computing Model

Space-Agents maps directly to computer architecture:

| Traditional Computer | Space-Agents | Component |
|---------------------|--------------|-----------|
| **CPU** | Agents (stateless compute) | Pod, Worker, Inspector, Analyst |
| **OS / Kernel** | Orchestration layer | HOUSTON + Ralph loop |
| **Process** | Pod execution | Spawn → execute → exit |
| **Scheduler** | Ralph loop | Picks next objective, launches Pod |
| **RAM** | Session buffer | `staging.md` (cleared each session) |
| **Disk** | Persistent storage | SQLite + CAPCOM logs |
| **IPC** | Message passing | CAPCOM log, SQLite messages table |

### Visual Model

```
┌─────────────────────────────────────────────────────────────┐
│                     SPACE-AGENCY OS                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   HOUSTON (kernel/scheduler)                                │
│       │                                                     │
│       ▼                                                     │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐                │
│   │  Pod 1  │    │  Pod 2  │    │  Pod 3  │  ← CPUs        │
│   │ (done)  │    │ (done)  │    │ (active)│    (fresh      │
│   └─────────┘    └─────────┘    └─────────┘     each cycle) │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│   staging.md              ← RAM (volatile, session-scoped)  │
├─────────────────────────────────────────────────────────────┤
│   SQLite + CAPCOM logs    ← Disk (persistent, survives)     │
└─────────────────────────────────────────────────────────────┘
```

### Process Lifecycle

| CPU | Agent (Pod) |
|-----|-------------|
| Loads data from RAM/disk | Reads SQLite + objective spec |
| Processes (stateless) | Thinks + acts (fresh context) |
| Writes results back | Updates CAPCOM + SQLite |
| Cycle complete, next process | Pod exits, next Pod launches |

The inference loop boundary (objective completion) is the natural place to reset — state is clean, can be serialized to storage.

### Memory Hierarchy

Like L1/L2/RAM/Disk in traditional computing:

| Tier | File | Speed | Persistence | Pattern |
|------|------|-------|-------------|---------|
| **L1 Cache** | Agent context | Instant | None (discarded) | Think fast, forget |
| **RAM** | `staging.md` | Fast read | Session | Full read, cleared on logout |
| **Disk** | CAPCOM logs | Grep | Permanent | Append-only, never full read |
| **Database** | SQLite | Query | Permanent | Structured queries |

---

## State Management

### SQLite Schema

```sql
-- Voyages (epics)
CREATE TABLE voyages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('planning', 'active', 'complete', 'archived')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Missions (features)
CREATE TABLE missions (
    id TEXT PRIMARY KEY,
    voyage_id TEXT REFERENCES voyages(id),
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('todo', 'active', 'complete', 'failed')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Objectives (stories/tasks)
CREATE TABLE objectives (
    id TEXT PRIMARY KEY,
    mission_id TEXT REFERENCES missions(id),
    title TEXT NOT NULL,
    description TEXT,
    status TEXT CHECK(status IN ('pending', 'in_progress', 'complete', 'failed')),
    priority INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
);

-- Messages (CAPCOM structured queries)
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent TEXT NOT NULL,
    objective_id TEXT REFERENCES objectives(id),
    type TEXT CHECK(type IN ('started', 'completed', 'failed', 'feedback')),
    content TEXT
);
```

### CAPCOM Log Format

Append-only, never read in full (grep only):

```markdown
# CAPCOM

Mission Control communication log. Append only.

---

## 2026-01-15 10:30 — Pod-001 — objective-jwt-signing

**Status**: COMPLETE
**Worker**: Implemented JWT sign/verify functions
**Inspector**: PASS — meets requirements
**Analyst**: PASS — follows existing patterns
**Airlock**: PASS — tests green

---

## 2026-01-15 10:45 — Pod-002 — objective-jwt-verify

**Status**: COMPLETE (2 attempts)
**Worker**: Initial implementation
**Inspector**: FAIL — missing expiry check
**Worker**: Added expiry validation
**Inspector**: PASS
**Analyst**: PASS
**Airlock**: PASS

---
```

---

## Research Foundation

Space-Agents synthesizes four major patterns:

| Pattern | Source | Problem Solved | Key Mechanism |
|---------|--------|----------------|---------------|
| **Ralph Wiggum** | Geoffrey Huntley | Context rot | Fresh sessions via bash loop |
| **Superpowers** | Jesse Vincent (obra) | Behavioral drift | Skill injection, forcing functions |
| **Beads** | Steve Yegge | Context amnesia | Queryable SQLite + Git |
| **Gas Town** | Steve Yegge | Swarm coordination | Role hierarchy, GUPP |

### What We Took

- **Ralph Wiggum**: The entire execution model. Fresh Pod each iteration.
- **Superpowers**: HOUSTON has skills (brainstorming, planning). Forcing functions.
- **Beads**: SQLite for structured state, addressable work items.
- **Gas Town**: Role hierarchy (HOUSTON → Pod → Crew). GUPP propulsion principle.

### What We Deferred

- **Witness/Refinery**: Health monitoring and merge coordination (for 20+ agent swarms)
- **Git worktrees**: File isolation for parallel Pods (future)
- **tmux orchestration**: Real-time multi-agent visibility (future)

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Name | Space-Agents | Institution, not collection. Has gravitas. |
| Commander | HOUSTON | Flight Director. Persistent. Plans, doesn't execute. |
| Pod orchestration | Pod is orchestrator | No separate Commander role. Simpler. |
| CAPCOM | Infrastructure | Not an agent. Just logs + SQLite. |
| Skills | Superpowers-style | Brainstorming, planning as forcing functions |
| Where it lives | Claude Code skills | Native to the platform |

---

## Future Evolution

### Near-term
- Implement core skills (houston, brainstorming, planning, capcom)
- Ralph loop script
- SQLite schema + initialization
- Pod/Worker/Inspector/Analyst prompts

### Long-term (swarm scale)
- Parallel Pods with Git worktree isolation
- tmux orchestration for real-time visibility
- Witness agent for health monitoring
- Web dashboard beyond CLI

---

## Gas Town Comparison

Space-Agents is inspired by Gas Town but right-sized for Stage 6 → Stage 8 progression.

### Feature Mapping

| Component | Purpose | Space-Agents | Status |
|-----------|---------|--------------|--------|
| **Mayor** | Orchestrator | HOUSTON | ✅ Have |
| **Polecats** | Ephemeral workers | Pods + Crew | ✅ Have |
| **GUPP** | Propulsion principle | Pod executes without asking | ✅ Have |
| **Beads/SQLite** | Persistent state | SQLite + CAPCOM | ✅ Have |
| **Convoy** | Grouped work items | Missions | ✅ Have |
| **Git Worktrees** | File isolation | — | ❌ Phase 2 |
| **Refinery** | Merge queue | — | ❌ Phase 2 |
| **Witness** | Pod health monitoring | — | ❌ Phase 3 |
| **Deacon** | System health daemon | — | ❌ Phase 3 |
| **Dog** | Watchdog for Deacon | — | ❌ Phase 3 |
| **Mail System** | Priority message routing | Simplified (SQLite) | ⚠️ Partial |
| **MEOW Molecules** | Chained workflow templates | — | ❌ Not planned |
| **Handoff Protocol** | Context-full session swap | — | ❌ Not planned |
| **Seance** | Query past sessions | — | ❌ Not planned |
| **tmux Integration** | Multi-session management | — | ❌ Optional |

### Coverage by Phase

| Phase | Features | Gas Town Coverage |
|-------|----------|-------------------|
| Phase 1 (Sequential) | HOUSTON, Pods, Crew, SQLite, CAPCOM, Airlock | ~40% |
| Phase 2 (Parallel) | + Git Worktrees, Refinery | ~60% |
| Phase 3 (Monitored) | + Witness, Deacon, Dog | ~80% |
| Full Gas Town | + MEOW, Handoff, Seance | ~100% |

### What's Intentionally Skipped

| Component | Why Skip |
|-----------|----------|
| **MEOW Molecules** | Missions/Objectives cover this. Workflow templates are overkill until repeating complex patterns. |
| **Handoff Protocol** | Pods are short-lived. Mid-task handoff matters for long-running agents. |
| **Seance** | CAPCOM logs provide most of this. Structured session archaeology is a refinement. |
| **tmux Integration** | Task tool works. tmux adds value at scale for real-time visibility. |

---

## Implementation Roadmap

### Phase 1: Core (Build First)

The minimum viable orchestrator.

| Component | What It Is | Why |
|-----------|------------|-----|
| **HOUSTON skill** | Flight Director persona + `/brainstorming`, `/planning` | Your interface. The commander. |
| **SQLite schema** | Voyages, Missions, Objectives tables | State that survives sessions |
| **Ralph loop** | `ralph.sh` bash script | The execution engine |
| **Pod prompt** | Orchestrates Worker → Inspector → Analyst | The spacecraft |
| **Crew prompts** | Worker, Inspector, Analyst | The hands that do the work |
| **Airlock** | `airlock.sh` — runs tests/lint | Quality gate |
| **CAPCOM log** | Append-only markdown | Audit trail |

**Outcome:** A working sequential orchestrator. Plan voyages, break into objectives, run Ralph loop, get reviewed code.

### Phase 2: Parallel (Build When Needed)

When sequential feels too slow.

| Component | What It Is | Why |
|-----------|------------|-----|
| **Git worktree manager** | Script to create/destroy worktrees per Pod | File isolation |
| **Refinery** | Merge queue script or agent | Brings parallel work together |
| **Parallel Ralph** | Multiple `ralph.sh` instances | Run 3-5 Pods concurrently |

**Outcome:** Safe parallel execution. Multiple Pods, no conflicts.

### Phase 3: Resilience (Build If Scaling)

When agents start failing at scale.

| Component | What It Is | Why |
|-----------|------------|-----|
| **Witness** | Health check script/agent | Detects stuck Pods |
| **Deacon** | Background daemon | Continuous monitoring |
| **Dog** | Watchdog for Deacon | Monitors the monitor |

**Outcome:** Self-healing. Agents that restart when stuck.

### Phase 4: Full Gas Town (Build If Swarm Scale)

When running 20-30+ agents with complex coordination needs.

| Component | What It Is | Why |
|-----------|------------|-----|
| **MEOW Molecules** | Templated, trackable workflow chains | Repeatable multi-step processes |
| **Handoff Protocol** | Mid-task context swap | Long-running agents that fill context |
| **Seance** | Query past session decisions | Structured archaeology beyond logs |
| **Sophisticated Mail** | Priority queues, fan-out, claiming | Complex inter-agent messaging |
| **tmux Integration** | Multi-session management | Real-time visibility across swarm |

**Outcome:** Full Gas Town parity. True swarm-scale orchestration.

---

## MVP Checklist

**Updated 2026-01-16:** Phase 1 complete!

```
✅ /install skill: sets up everything with one command
✅ /launch skill: HOUSTON persona + session start
✅ /dock skill: session end + ASCII logout screen
✅ SQLite: voyages, missions, objectives, messages, alerts tables
✅ ralph.sh: loop that spawns Pods (in /mission-run skill)
✅ pod.md: prompt that orchestrates crew
✅ worker.md: implements (with structured output for alerts)
✅ inspector.md: reviews requirements
✅ analyst.md: reviews quality
✅ airlock.sh: runs tests/lint (in /airlock skill)
✅ CAPCOM log format
□ /capcom skill: status check (TODO)
□ /brainstorming skill (TODO)
□ /planning skill (TODO)
```

---

## References

- `research/ghuntley-ralph-wiggum-loop.md`
- `research/obra-superpowers.md`
- `research/yegge-beads.md`
- `research/yegge-gastown.md`
- `research/sal-v2-pattern-comparison.md`
