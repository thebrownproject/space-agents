# Beads (bd)

Reference material for SAL-9000 development.

**Sources**:
- https://github.com/steveyegge/beads (Steve Yegge)
- https://betterstack.com/community/guides/ai/beads-issue-tracker-ai-agents/
- https://paddo.dev/blog/beads-memory-for-coding-agents/

---

## The Core Insight

> "All they know is what's on disk... if you got competing documents, obsolete documents, conflicting documents, ambiguous documents - they get dementia."

Beads solves the **50 First Dates problem**: every agent session starts fresh, forcing you to re-explain context. Instead of scattered markdown files, Beads provides **addressable work items** with IDs, priorities, dependencies, and audit trails.

### Why Not Markdown Task Lists?

Traditional approach: `TASKS.md`, `TODO.md`, spec files scattered everywhere.

**Problems**:
- Consumes context itself (loading full specs)
- No explicit dependency tracking
- Can't distinguish "decided yesterday" from "brainstorm three weeks ago"
- Competing/obsolete documents cause "dementia"

**Beads approach**: Queryable database. Agent asks for ready work, gets targeted response.

```
Markdown specs:              Beads:

  ┌────────────────────┐     ┌────────────────────┐
  │ PRD.md (2k tokens) │     │ bd ready --json    │
  │ TASKS.md           │     │                    │
  │ SPEC.md            │     │ → Returns only     │
  │ NOTES.md           │     │   unblocked tasks  │
  └────────────────────┘     └────────────────────┘

  Load everything into       Query only what's
  context window             needed
```

Yegge's analogy: Using agents without persistent memory is **"running in socks"** - functional but painful. Beads is putting on shoes.

---

## First Principles (From the Creator)

> "I asked the AI what it wanted for a memory system. It designed one that uses Git."
> — Steve Yegge

### The 85% Rule

Agent-written code quality standard: accept code that's 85% of what you'd write yourself. Perfect is the enemy of shipped.

### Team Lead Guidance Model

Direct agents like a team lead directs junior devs - clear objectives, let them figure out implementation, review output.

### Land the Plane Protocol

End every session cleanly. The plane is airborne until `git push` succeeds:

1. File remaining work as beads issues
2. Pass quality gates (lint, tests)
3. Update issue status (close completed work)
4. Execute push sequence
5. Clean git state
6. Verify cleanliness
7. Provide context-rich prompt for next session

**Non-negotiable**: Never say "ready to push when you are." Agents must execute the push. Unpushed work breaks multi-agent coordination.

---

## Architecture

Beads uses a **three-layer architecture** that syncs across machines without a central server:

```
┌─────────────────────────────────────────────────────────┐
│                     CLI INTERFACE                        │
│  bd ready, bd create, bd update, bd close, bd sync      │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                   SQLite Database                        │
│  .beads/beads.db (gitignored)                           │
│  - Fast local queries (milliseconds)                     │
│  - Tables: issues, dependencies, labels, comments        │
│  - Each machine has its own copy                         │
└────────────────────────┬────────────────────────────────┘
                         │ sync
┌────────────────────────▼────────────────────────────────┐
│                  JSONL + Git                             │
│  .beads/issues.jsonl (committed)                        │
│  - One JSON object per line                              │
│  - Human-readable diffs                                  │
│  - Automatic merge success                               │
│  - Distributed via git push/pull                         │
└─────────────────────────────────────────────────────────┘
```

### Why Git as Database?

- **Archival**: Closed issues remain in version history
- **Offline**: No external service dependency
- **Agent familiarity**: Agents already understand Git
- **Collaboration**: Standard push/pull for teams
- **Conflict-free**: JSONL format enables automatic merges

### Why SQLite + JSONL?

Binary SQLite files create merge nightmares. JSONL provides:
- Text-based, diffable storage
- One entity per line = clean merges
- Human-readable history
- Append-only semantics

SQLite provides:
- Fast local queries
- Proper indexing
- Relational integrity

Sync keeps them in harmony.

---

## Data Model

### Hierarchical Issue Structure

```
bd-a3f8           (Epic: User Authentication)
  │
  ├── bd-a3f8.1   (Task: JWT Service)
  │     │
  │     ├── bd-a3f8.1.1  (Subtask: Token generation)
  │     └── bd-a3f8.1.2  (Subtask: Token validation)
  │
  └── bd-a3f8.2   (Task: OAuth Integration)
```

### Dependency Types

| Type | Affects Readiness | Purpose |
|------|-------------------|---------|
| `blocks` | Yes | Task A must complete before B |
| `parent-child` | Yes | Hierarchical ownership |
| `related` | No | Soft reference |
| `discovered-from` | No | Audit trail |

### Issue Status Flow

```
open → in_progress → closed
  ↑                    │
  └────── reopen ──────┘
```

### Hash-Based IDs

Sequential IDs (bd-1, bd-2) cause collisions when multiple agents create issues simultaneously. Beads uses **content-based hashing**:

```
bd-a1b2, bd-f14c, bd-9xyz
```

- Random UUID produces short hash
- Length grows as database expands
- No central coordination needed
- Convergence guaranteed across machines

---

## The Agent Workflow

### Core Loop: ready → create → update → close → sync

```
┌─────────────────────────────────────────┐
│  1. bd ready --json                     │
│     → Returns unblocked tasks           │
│     → Empty = project complete          │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  2. Select highest priority task        │
│     bd update <id> --status in_progress │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  3. Implement the work                  │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  4. bd close <id> --reason "Done"       │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  5. bd sync                             │
│     (export → commit → pull → push)     │
└──────────────────┬──────────────────────┘
                   │
                   └──────► Loop to step 1
```

### Key Commands

| Command | Purpose |
|---------|---------|
| `bd ready` | List tasks with no open blockers |
| `bd ready --json` | Machine-readable output |
| `bd ready --priority 1` | Filter by priority |
| `bd create "Title" -p 1` | Create priority-1 task |
| `bd create "Epic" -t epic` | Create epic |
| `bd update <id> --status in_progress` | Mark working |
| `bd close <id> --reason "text"` | Complete task |
| `bd dep add <child> <parent>` | Link dependency |
| `bd show <id>` | View details + audit trail |
| `bd sync` | Force immediate sync |
| `bd stats` | Open/closed counts |
| `bd list` | Flat issue list |
| `bd dep tree <id>` | Hierarchical view |

### Never Use Interactive Commands

Agents can't handle interactive editors. Avoid `bd edit`. Use flags:

```bash
# Wrong
bd edit bd-a1b2

# Right
bd update bd-a1b2 --description "New description"
bd update bd-a1b2 --title "New title"
```

---

## Sync Mechanism

### Write Path

```
User: bd create "New feature"
         │
         ▼
┌─────────────────────────────┐
│ 1. Write to SQLite          │
│ 2. Mark database "dirty"    │
│ 3. 5-second debounce window │
│ 4. Export modified entities │
│ 5. Auto-commit if configured│
└─────────────────────────────┘
```

### Read Path

```
User: git pull
         │
         ▼
┌─────────────────────────────┐
│ 1. Auto-import detection    │
│ 2. Parse JSONL              │
│ 3. Merge with local state   │
│    (content hash comparison)│
│ 4. Update SQLite            │
└─────────────────────────────┘
```

### Merge Logic

- **Same ID + same content hash** → Skip
- **Same ID + different content hash** → Update
- **No ID match** → Create

This eliminates central coordination while ensuring convergence.

---

## Memory Decay (Compaction)

Context windows are finite. Beads implements **semantic summarization** of old closed issues:

```bash
bd compact
```

1. Identify old, closed issues (30+ days)
2. Use LLM to summarize detailed content
3. Replace full text with summary
4. Reclaim context space

This is "agentic memory decay" - like human memory, recent details stay sharp while old completed work fades to summaries.

### Scope Focus

Beads tracks **current work** (today/this week). Excluded:

| Category | Where It Belongs |
|----------|------------------|
| Future planning | Roadmap docs |
| Past documentation | Wiki/docs |
| Long-term backlog | Traditional PM tools |

Recent closed work ranks higher by default - prevents P2 follow-ups from languishing.

---

## Multi-Agent Coordination

### The Problem

Multiple agents working simultaneously:
- Sequential IDs collide (both create bd-42)
- No central server to coordinate
- Git merges must succeed automatically

### The Solution

Hash-based IDs + JSONL + Git = distributed coordination without a server.

```
Agent A (branch feature-x):     Agent B (branch feature-y):
  bd create "Auth"                bd create "Cache"
  → bd-a1b2                       → bd-f3c4
       │                               │
       └───────────┬───────────────────┘
                   │
              git merge
                   │
              No collision!
              (different hashes)
```

### Wisps for Local Iteration

For fast local work that shouldn't sync:

- **Molecules**: Template work items defining workflows
- **Wisps**: Ephemeral child issues tracking execution steps
- Never export to JSONL
- `bd mol squash` performs hard delete

---

## Claude Code Integration

Beads uses **CLI + Hooks** rather than MCP or Skills:

```bash
bd setup claude              # Install hooks globally
bd setup claude --project    # Project-only
bd setup claude --stealth    # Local only, no git ops
```

### What Gets Installed

Two automatic hooks:
- **SessionStart**: Activates when Claude Code begins
- **PreCompact**: Preserves instructions before context compression

### Why Not MCP?

MCP tool schemas introduce 10-50x more context overhead. Beads prioritizes lean context - `bd prime` delivers ~1-2k tokens of workflow context.

### Why Not Skills?

- Redundancy: `bd prime` covers workflow
- Simplicity: Core to beads philosophy
- Editor agnostic: Works with Cursor, Windsurf, Zed

---

## Performance Optimizations

### Blocked Issues Cache

Computing blocking relationships via recursive CTE on every `bd ready` query is expensive. Beads maintains a materialized cache:

| Metric | Without Cache | With Cache |
|--------|---------------|------------|
| Query time (10K issues) | ~752ms | ~29ms |
| Speedup | - | **25x** |

Cache rebuilds completely on dependency changes (rebuild is fast: <50ms on 10K issues).

### Selective Invalidation

Only `blocks` and `parent-child` changes trigger rebuilds. `related` and `discovered-from` don't affect readiness, so no rebuild needed.

---

## SAL-9000 Relevance

### What Beads Solves

| Problem | Beads Solution |
|---------|----------------|
| Context amnesia | Persistent SQLite + Git |
| Scattered markdown | Addressable work items |
| No dependency awareness | Explicit blocks/parent-child |
| Multi-agent collisions | Hash-based IDs |
| Context bloat | Targeted queries, compaction |

### Direct Applicability to SAL

**1. Mission/Pod State = Beads Database**

SAL already uses SQLite for coordination:

| SAL Table | Beads Equivalent |
|-----------|------------------|
| `missions` | Epics |
| `pods` | Tasks |
| `tasks` | Subtasks |
| `messages` | Comments/Events |

The key insight: **dependency tracking**. SAL could adopt Beads' `blocks` semantics for task ordering.

**2. CAPCOM as Sync Layer**

CAPCOM currently routes messages. It could also handle:
- Beads-style sync (export/import)
- Ready-state computation for crews
- Multi-pod coordination without collisions

**3. "Land the Plane" for Pod Completion**

SAL's Pod completion protocol could mirror Beads:

```
1. File remaining work to messages table
2. Pass Airlock validation
3. Update task status
4. Sync to SQLite
5. Clean state
6. Generate context for next session
```

**4. Ready-State Detection**

SAL could implement `bd ready` semantics:

```sql
-- Tasks ready for work (no open blockers)
SELECT * FROM tasks
WHERE status = 'open'
AND id NOT IN (
  SELECT blocked_task_id
  FROM dependencies
  WHERE blocking_task_status != 'closed'
)
ORDER BY priority ASC;
```

This prevents crews from starting blocked work.

**5. Compaction for Long-Running Missions**

Long missions accumulate context. CAPCOM could implement memory decay:
- Summarize old completed tasks
- Keep recent work detailed
- Maintain audit trail in full (but compressed)

### Key Patterns to Adopt

1. **Addressable work items** with explicit dependencies
2. **Ready-state computation** - only surface unblocked work
3. **Hash-based IDs** for multi-agent safety
4. **Land the Plane protocol** - clean session boundaries
5. **Query over load** - ask for what you need, don't load everything
6. **Memory decay** - summarize old work, preserve recent detail

### What SAL Already Has

- Fresh subagents (like Ralph's sessions)
- SQLite coordination (like Beads' database)
- CAPCOM filtering (targeted context)
- Airlock validation (quality gates)

The gap: **explicit dependency tracking** and **ready-state semantics**. Beads shows how to implement these cleanly.

---

## Summary

Beads complements Ralph (fresh sessions) and Superpowers (skill injection):

| System | Problem Solved | Mechanism |
|--------|---------------|-----------|
| Ralph | Context rot | Fresh sessions |
| Superpowers | Behavioral drift | Skill checkpoints |
| Beads | Context amnesia | Persistent queryable state |

SAL could combine all three:
- Pods/Crew = fresh context (Ralph)
- CAPCOM injects skills (Superpowers)
- SQLite with dependencies (Beads)

**The core Beads insight**: Replace "load everything into context" with "query what's needed." This scales to complex projects while staying context-efficient.
