# Research & Design Decisions

Summary of research and design decisions for SAL-9000.

## The Gap We Fill

There's a gap in the agent orchestration landscape:

| Too Simple | SAL-9000 | Too Complex |
|------------|----------|-------------|
| Ad-hoc file coordination | Structured with SQLite | Gas Town, LangGraph |
| No review cycles | 3-Crew review per task | Enterprise workflows |
| Context rot | Context filtering via CAPCOM | Complex message buses |

## Design Decisions

### 1. SQLite for Coordination

We use SQLite as the coordination layer (inspired by Steve Yegge's Beads):

| Why SQLite | Benefit |
|------------|---------|
| Persistence | State survives session restarts |
| Message queue | Agents communicate via `messages` table |
| Status tracking | Review phases tracked per task |
| Audit trail | All agent interactions logged |
| Queries | "What tasks are pending review?" |

### 2. File Structure for Documentation

SQLite handles coordination, files handle human documentation:

| Layer | Contains |
|-------|----------|
| **SQLite** | Status, messages, reviews, agent state |
| **Files** | Designs, requirements, code artifacts |

### 3. SAL = Main Session

SAL is the conversation, not a spawned subagent.

**Why?** Simpler mental model. You talk directly to SAL.

### 4. Three Crew Types Per Task

Each task goes through a review cycle with specialized workers:

```
Engineer → Inspector → Analyst
    ↑          │           │
    └──────────┴───────────┘
           (feedback loop)
```

| Crew Type | Role |
|-----------|------|
| **Engineer** | Does the work |
| **Inspector** | Verifies requirements |
| **Analyst** | Reviews code quality |

**Why?**
- Catches issues early
- Separation of concerns
- Mirrors real development workflow (dev → QA → code review)
- Extensible - can add more Crew types later

### 5. CAPCOM as Message Broker

CAPCOM is the central hub that filters context:

| Problem | Solution |
|---------|----------|
| Context rot | CAPCOM summarizes before forwarding |
| Direct coupling | All messages go through CAPCOM |
| Information overload | Each agent gets only what they need |

**Why not direct agent-to-agent calls?**
- Creates tight coupling
- Context accumulates (rot)
- Hard to debug
- No audit trail

### 6. Hooks Trigger CAPCOM

CAPCOM isn't persistent - it's spawned on-demand when Crew complete:

```
Crew completes → Hook fires → CAPCOM spawns → Processes queue
```

**Why?**
- Claude Code doesn't have persistent background agents
- SQLite queue simulates persistence
- Efficient - CAPCOM only runs when needed

### 7. Airlock as Function, Not Agent

Airlock (validation) is called by CAPCOM, not a separate agent:

```
CAPCOM: runAirlock(tests, lint, build) → pass/fail
```

**Why?**
- Validation is deterministic (run tests, check result)
- Doesn't need agent reasoning
- Faster as a function call

## Naming Decisions

### Space Theme

| Role | Why This Name |
|------|---------------|
| **SAL** | HAL's twin from 2010: A Space Odyssey |
| **Pod** | EVA pods from 2001 |
| **Crew** | Astronauts category |
| **Engineer** | Does technical work |
| **Inspector** | Checks quality |
| **Analyst** | Reviews and analyzes |
| **CAPCOM** | NASA's Capsule Communicator |
| **Airlock** | Single entry/exit point |

### Hierarchy

| Term | NASA Equivalent |
|------|-----------------|
| Program | Apollo Program |
| Mission | Apollo 11 |
| Pod | Department |
| Crew | Astronauts |

## Comparison to Beads (Gas Town)

| Aspect | Beads | SAL-9000 |
|--------|-------|----------|
| Storage | JSONL | SQLite |
| Structure | Flat | Hierarchical |
| Core principle | Shared state | Same |
| Review cycles | Not built-in | 3-Crew review |
| Message routing | Implicit | Explicit via CAPCOM |
| Worker types | Single (Polecat) | Multiple (Engineer, Inspector, Analyst) |

We adapted Yegge's insight (shared state coordination) for our structured workflow.

## Context Filtering Rationale

Each agent should receive minimal context:

| Agent | Why Minimal Context |
|-------|---------------------|
| SAL | Only needs progress summaries |
| Pod | Only needs its tasks' status |
| Engineer | Only needs requirements + feedback |
| Inspector | Only needs requirements + output |
| Analyst | Only needs code output |

**Result**: Agents stay focused, context stays fresh.

## What We Avoided

| Pattern | Why Avoided |
|---------|-------------|
| External daemon | Complexity, separate process |
| Direct agent calls | Coupling, context accumulation |
| Always-on CAPCOM | Claude Code doesn't support persistent agents |
| Single worker type | No review cycle, catches fewer issues |
| File-only coordination | Can't query status, no persistence |

## Evolution Path

If we hit limits:

1. **More Crew types** → Add Researcher, Documenter, Tester
2. **More agents** → Shard CAPCOM by Pod
3. **Performance** → Batch message processing
4. **Scaling** → External orchestrator (Gas Town pattern)

For now, SQLite + Claude Code native features is sufficient.

## Inspirations

| Source | What We Took |
|--------|--------------|
| **2001: A Space Odyssey** | Naming, calm demeanor |
| **NASA Mission Control** | Hierarchy, CAPCOM role |
| **Steve Yegge's Beads** | Shared state coordination |
| **Claude Code** | Subagents, hooks, skills |
| **Pull request workflow** | Review cycle pattern |
