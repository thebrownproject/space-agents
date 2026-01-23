# Beads Integration Exploration

**Date:** 2026-01-20
**Topic:** Full Beads integration to replace SQLite database
**Decision:** Option A - Full replacement with Beads graph-based work tracker

---

## Executive Summary

Replace Space-Agents' current SQLite database with Beads (Steve Yegge's graph-based work tracker) to gain:
1. **Graph-based dependencies** - Ralph won't start blocked work
2. **Better tooling** - `bd` CLI provides superior UX over raw SQL
3. **Future parallel execution** - Hash-based IDs enable multiple Ralph loops
4. **Learning investment** - Deep dive into Yegge's patterns by implementing them

This is a full replacement (Option A), not a hybrid. The migration will take 3-5 days but provides foundational improvements for the system.

---

## Architecture

### Data Model Mapping

| Current (SQLite) | New (Beads) | Beads Type | Notes |
|------------------|-------------|------------|-------|
| Voyages | **Epics** | `epic` | Top-level container for large initiatives |
| Missions | **Features** | `feature` | Discrete work items (what gets built) |
| Objectives | **Tasks** | `task` | Implementation subtasks |
| Alerts | **Bugs** | `bug` | Defects/issues with blocking relationships |
| Messages | **Comments** | N/A | Attached to issues as comments |

### Terminology Decision

**Data Model:** Adopt Yegge standard terminology
- Epic, Feature, Task, Bug (no translation layer)
- Direct alignment with Beads/Gas Town documentation
- Industry-standard terms for collaboration

**Operations:** Keep space theme for personality
- Ralph (execution loop)
- CAPCOM (coordination)
- Pod (orchestrator)
- Airlock (validation)
- HOUSTON (interface)
- Worker/Inspector/Analyst (crew)

**Rationale:** Data model should be standard, operations have personality.

### Hierarchical Structure

```
Epic (bd-a3f8)
  ├─ Feature (bd-a3f8.1) - Mission 1
  │   ├─ Task (bd-a3f8.1.1) - Objective 1
  │   ├─ Task (bd-a3f8.1.2) - Objective 2
  │   └─ Bug (bd-a3f8.1.3) - Blocks bd-a3f8.1.1
  └─ Feature (bd-a3f8.2) - Mission 2
      ├─ Task (bd-a3f8.2.1) - Objective 1
      └─ Task (bd-a3f8.2.2) - Objective 2
```

**Key Properties:**
- Parent-child relationships form a tree
- `blocks` dependencies form a DAG (directed acyclic graph)
- Hash-based IDs prevent collisions in parallel execution
- Up to 3 levels of nesting supported by Beads

---

## Graph Model

### Dependency Types

Beads supports multiple edge types in the graph:

| Edge Type | Semantics | Affects `bd ready`? | Use Case |
|-----------|-----------|---------------------|----------|
| `parent-child` | Hierarchical ownership | ✅ Yes | Epic → Feature → Task |
| `blocks` | Dependency (A must finish before B) | ✅ Yes | Bug blocks Task |
| `related` | Soft reference | ❌ No | Cross-references |
| `discovered-from` | Audit trail | ❌ No | Track where bugs came from |

### Ready-State Algorithm

The `bd ready` command returns only unblocked work:

```sql
-- Conceptual query (Beads uses materialized cache)
SELECT * FROM issues
WHERE status = 'open'
AND id NOT IN (
  SELECT blocked_issue_id
  FROM dependencies
  WHERE blocking_issue_status != 'closed'
)
ORDER BY priority ASC;
```

**Performance:** Beads maintains a materialized cache of blocking relationships for 25x speedup (752ms → 29ms on 10K issues).

### Bug Blocking Pattern

When Pod/Airlock/Inspector finds issues:

```bash
# Create bug
bd create "Bug: JWT tokens expire immediately" \
  --parent bd-feature-id \
  -t bug \
  --label severity:critical \
  --priority 0
# → bd-bug-123

# Block the task that failed
bd dep add bd-task-456 bd-bug-123

# Now Ralph's next iteration:
bd ready  # Returns bd-bug-123, NOT bd-task-456 (blocked)
```

This replaces the current alerts table with graph edges.

---

## Components

### 1. Ralph.sh (Main Execution Loop)

**Current Implementation:**
- Queries SQLite for next pending objective
- Spawns Pod for that objective
- Marks complete/failed based on exit code
- Creates alerts for failures

**Beads Implementation:**
```bash
get_next_objective() {
    local feature_id="$1"

    # Get ready (unblocked) tasks for this feature
    bd ready --json | \
        jq -r '.[] |
            select(.labels[] | contains("feature:'$feature_id'")) |
            select(.type == "task") |
            "\(.id)|\(.title)|\(.description)"' | \
        head -1
}

mark_objective_complete() {
    local task_id="$1"

    bd close "$task_id" --reason "Completed by Pod"
    bd sync  # Push to JSONL + git commit
}

create_blocking_bug() {
    local task_id="$1"
    local description="$2"
    local feature_id="$3"

    # Create bug
    local bug_id=$(bd create "Bug: $description" \
        --parent "$feature_id" \
        -t bug \
        --label severity:critical \
        --priority 0 \
        --json | jq -r '.id')

    # Block the failed task
    bd dep add "$task_id" "$bug_id"
}

check_critical_bugs() {
    local feature_id="$1"

    bd list --json | jq -e '.[] |
        select(.labels[] | contains("feature:'$feature_id'")) |
        select(.type == "bug") |
        select(.labels[] | contains("severity:critical")) |
        select(.status == "open")' > /dev/null
}
```

**Key Changes:**
- Replace all `sql_query` calls with `bd` CLI + `jq`
- Add `bd sync` after each task completion
- Use graph dependencies instead of alerts table
- Parse JSON instead of pipe-delimited SQL output

### 2. Skills Requiring Updates

**All 9 skills need modification:**

| Skill | Current SQLite Usage | Beads Replacement |
|-------|---------------------|-------------------|
| `/install` | Creates schema via init-db.sql | Runs `bd init`, creates templates |
| `/launch` | Initializes SQLite database | Initializes Beads, creates first epic |
| `/mission-brief` | Creates missions + objectives in SQLite | Creates features + tasks via `bd create` |
| `/mission-go` | Invokes ralph.sh (reads SQLite) | Invokes ralph.sh (reads Beads) |
| `/capcom` | SQL queries for status report | `bd list` + `bd stats` for status |
| `/dock` | Updates mission status in SQLite | Updates feature status via `bd update` |
| `/airlock` | Creates alerts on validation failure | Creates blocking bugs via `bd create` + `bd dep` |
| `/handover` | File-based (no change) | File-based (no change) |
| `/pod` | Marks objectives in_progress | Marks tasks in_progress via `bd update` |

### 3. Agent Prompts

**All 9 agent prompts need updates:**
- Replace "mission" → "feature"
- Replace "objective" → "task"
- Replace SQL query examples with `bd` CLI examples
- Add `bd sync` to completion protocols

### 4. CAPCOM Status Reports

**Current:**
```sql
SELECT id, title, status FROM missions WHERE status IN ('staged', 'active');
SELECT o.id, o.title, o.status, m.title as mission
FROM objectives o JOIN missions m ON o.mission_id = m.id;
```

**Beads:**
```bash
# Get active features
bd list --json | jq '.[] |
    select(.type == "feature") |
    select(.status == "open")'

# Get tasks under a feature
bd list --json | jq '.[] |
    select(.parent == "bd-feature-id") |
    select(.type == "task")'

# Or use dependency tree
bd dep tree bd-epic-id
```

---

## Data Flow

### Epic → Feature → Task Creation Flow

```
HOUSTON receives request
    ↓
/mission-brief skill
    ↓
Creates Epic:
  bd create "Epic: Authentication System" -t epic
  → bd-a3f8
    ↓
Creates Features:
  bd create "Feature: JWT Implementation" --parent bd-a3f8 -t feature
  → bd-a3f8.1
    ↓
Creates Tasks:
  bd create "Task: Token signing" --parent bd-a3f8.1 -t task --priority 1
  → bd-a3f8.1.1
    ↓
Ralph.sh execution loop
    ↓
bd ready --json → Returns bd-a3f8.1.1 (unblocked)
    ↓
Spawn Pod for task bd-a3f8.1.1
    ↓
Pod executes (Worker → Inspector → Analyst)
    ↓
If success:
  bd close bd-a3f8.1.1 --reason "Completed"
  bd sync
    ↓
If failure:
  bd create "Bug: <description>" -t bug --parent bd-a3f8.1
  bd dep add bd-a3f8.1.1 bd-bug-123  # Block task
    ↓
Next iteration:
  bd ready → Returns bd-bug-123 (must fix before continuing)
```

### Multi-Machine Sync Flow

```
Laptop:
  bd create "Task: Add endpoint" --parent bd-feature
  bd sync  # Exports to .beads/issues.jsonl, commits, pushes
    ↓
Git push
    ↓
Desktop:
  git pull
  Beads auto-detects JSONL changes
  Imports new task to local SQLite cache
    ↓
bd ready  # Sees new task, can execute
```

**Key Advantage:** No manual database synchronization. Git handles it.

### Ralph Loop with Graph Dependencies

```
┌─────────────────────────────────────────┐
│  Ralph Iteration N                      │
│                                         │
│  1. bd ready --json                     │
│     → Returns only unblocked tasks      │
│                                         │
│  2. Select highest priority task        │
│     bd update <id> --status in_progress │
│                                         │
│  3. Spawn Pod (execute work)            │
│                                         │
│  4a. Success Path:                      │
│      bd close <id> --reason "Done"      │
│      bd sync                            │
│                                         │
│  4b. Failure Path:                      │
│      bd create bug                      │
│      bd dep add <task> <bug>            │
│      Task now blocked!                  │
│                                         │
│  5. Loop to step 1                      │
│     bd ready won't return blocked task  │
└─────────────────────────────────────────┘
```

**Critical Insight:** The graph prevents Ralph from attempting blocked work. No manual checking required.

---

## Error Handling

### Severity Levels

Replace SQLite `severity` column with Beads labels:

| Current | Beads Equivalent | Behavior |
|---------|------------------|----------|
| Severity 0 (Critical) | `--label severity:critical` | Halt entire feature (ralph.sh checks on each iteration) |
| Severity 1 (Blocker) | `--label severity:blocker` | Block specific task via `bd dep add` |
| Severity 2 (Warning) | `--label severity:warning` | Non-blocking bug, picked up by priority |
| Severity 3 (Info) | `--label severity:info` | Informational, lowest priority |

### Critical Bug Halt Logic

```bash
# In ralph.sh main loop (line 508)
if check_critical_bugs "$feature_id"; then
    log ERROR "Critical bug detected. Halting Ralph loop."
    send_notification "Space-Agents CRITICAL" "Feature halted due to critical bug"
    exit 1
fi

check_critical_bugs() {
    bd list --json | jq -e '.[] |
        select(.labels[] | contains("feature:'$1'")) |
        select(.type == "bug") |
        select(.labels[] | contains("severity:critical")) |
        select(.status == "open")' > /dev/null
}
```

### Airlock Validation Failures

When Airlock detects issues:

```bash
# Current: create_alert 1 "$mission_id" "$objective_id" "Airlock" "Tests failed"

# Beads:
bd create "Bug: Tests failed in JWT validation" \
    --parent "$feature_id" \
    -t bug \
    --label severity:blocker \
    --label source:airlock \
    --priority 0 \
    --discovered-from "$task_id"

bd dep add "$task_id" "$bug_id"  # Block the task
```

Now Ralph can't proceed with that task until the bug is closed.

---

## Folder Structure and Lifecycle

### Overview

Folder structure **matches Beads status exactly** for consistency:

| Beads Status | Folder Path | Meaning |
|--------------|-------------|---------|
| `open` | `epics/open/{epic}/` | Epic being planned |
| `in_progress` | `epics/in_progress/{epic}/` | Epic being executed |
| `closed` | `epics/closed/{epic}/` | Completed epic |
| `open` | `epics/in_progress/{epic}/open/{feature}/` | Feature planned, not started |
| `in_progress` | `epics/in_progress/{epic}/in_progress/{feature}/` | Feature actively being worked on |
| `closed` | `epics/in_progress/{epic}/closed/{feature}/` | Feature completed |

### Epic Lifecycle

**1. Create Epic (open)**

`/launch` creates epic in Beads and folder:

```bash
bd create "Epic: Task Management API" -t epic
# → bd-a3f8 (status: open)

mkdir -p .space-agents/epics/open/bd-a3f8-task-management-api/
```

**Folder contains:**
- `README.md` - Epic overview
- `exploration/` - Optional exploration documents

**2. Activate Epic (in_progress)**

`/dock bd-a3f8` moves epic to active:

```bash
bd update bd-a3f8 --status in_progress

mv .space-agents/epics/open/bd-a3f8-task-management-api \
   .space-agents/epics/in_progress/bd-a3f8-task-management-api

mkdir -p .space-agents/epics/in_progress/bd-a3f8-task-management-api/{open,in_progress,closed}
```

**Folder now contains:**
- `README.md` - Epic progress tracker
- `open/` - Features being planned
- `in_progress/` - Features being executed
- `closed/` - Completed features

**3. Complete Epic (closed)**

When all features closed, epic moves to complete:

```bash
bd close bd-a3f8

mv .space-agents/epics/in_progress/bd-a3f8-task-management-api \
   .space-agents/epics/closed/bd-a3f8-task-management-api
```

**Folder is archived** with all completed features preserved.

### Feature Lifecycle

**1. Create Feature (open)**

`/mission-brief` creates feature in Beads and folder:

```bash
bd create "Feature: User Authentication" --parent bd-a3f8 -t feature
# → bd-a3f8.1 (status: open)

mkdir -p .space-agents/epics/in_progress/bd-a3f8-task-management-api/open/bd-a3f8.1-user-authentication/
```

**Folder contains:**
- `README.md` - Feature description
- `mission-brief.md` - Detailed plan from planning agents

**2. Activate Feature (in_progress)**

`/dock bd-a3f8.1` moves feature to active:

```bash
bd update bd-a3f8.1 --status in_progress

mv .../open/bd-a3f8.1-user-authentication \
   .../in_progress/bd-a3f8.1-user-authentication
```

**Folder now contains:**
- `README.md` - Feature status
- `mission-brief.md` - Original plan (preserved)
- `capcom.log` - Ralph execution log (created by Ralph)
- `handover.md` - Context between iterations (updated by Pod)
- `tmp/pod-prompts/` - Generated prompts for each task
- `tmp/signals/` - Pod completion signals

**3. Complete Feature (closed)**

Ralph completes all tasks and moves feature:

```bash
bd close bd-a3f8.1

mv .../in_progress/bd-a3f8.1-user-authentication \
   .../closed/bd-a3f8.1-user-authentication

rm -rf .../closed/bd-a3f8.1-user-authentication/tmp/
```

**Folder is archived** with execution history:
- `README.md` - Completion summary
- `mission-brief.md` - Original plan (historical reference)
- `capcom.log` - Full execution log
- `handover.md` - Final state

### Key Artifacts

| Artifact | Created By | Purpose | Lifecycle |
|----------|-----------|---------|-----------|
| `README.md` | Skills | Feature/Epic description and status | Created → Updated → Archived |
| `mission-brief.md` | `/mission-brief` | Detailed plan and requirements | Created once, preserved |
| `capcom.log` | Ralph | Timestamped execution log | Created on activation, grows during execution |
| `handover.md` | Pod | Context between Pod iterations | Updated after each task |
| `tmp/pod-prompts/` | Ralph | Generated prompts for each task | Ephemeral, deleted on completion |
| `tmp/signals/` | Pod | Completion signals for mprocs mode | Ephemeral, deleted on completion |

### Folder Benefits

**For Humans:**
- Browse project history by epic
- See complete execution logs
- Track what was planned vs what was built
- Reference decisions and implementation details
- Onboard new team members with archived context

**For Agents:**
- Read `handover.md` for context on next iteration
- Read `mission-brief.md` for original requirements
- Ralph generates `pod-prompts/` with full context
- Resume work after interruption

**For System:**
- Archive completed work automatically
- Preserve audit trail in git
- Multi-machine sync (folders + Beads JSONL)
- Clean separation of planning/execution/archive

---

## Migration Strategy

### Phase 1: Preparation (Day 1)
- [ ] Install Beads: `go install github.com/steveyegge/beads/cmd/bd@latest`
- [ ] Initialize Beads in repo: `bd init`
- [ ] Test basic commands: `bd create`, `bd ready`, `bd sync`
- [ ] Verify JSONL in `.beads/issues.jsonl` commits to git

### Phase 2: Schema Migration (Day 1-2)
- [ ] Write migration script: `scripts/migrate-to-beads.sh`
  - Read current SQLite database
  - For each voyage → Create epic with `bd create`
  - For each mission → Create feature as child of epic
  - For each objective → Create task as child of feature
  - For each alert → Create bug with blocking dependency
  - Preserve IDs as labels for reference
- [ ] Test migration on copy of database
- [ ] Verify `bd dep tree` shows correct hierarchy
- [ ] Archive old SQLite database

### Phase 3: Ralph.sh Rewrite (Day 2-3)
- [ ] Replace `sql_query` functions with `bd` CLI calls
- [ ] Rewrite `get_next_objective()` → `bd ready` query
- [ ] Rewrite `mark_objective_complete()` → `bd close` + `bd sync`
- [ ] Rewrite `check_critical_alerts()` → bug query
- [ ] Rewrite `create_alert()` → bug creation + blocking
- [ ] Update all 12 SQL query locations in ralph.sh
- [ ] Test with small feature: create → execute → complete

### Phase 4: Skills Update (Day 3-4)
- [ ] Update `/install` - Remove init-db.sql, add Beads init
- [ ] Update `/launch` - Initialize Beads instead of SQLite
- [ ] Update `/mission-brief` - Use `bd create` for features/tasks
- [ ] Update `/mission-go` - Already uses ralph.sh (inherits changes)
- [ ] Update `/capcom` - Rewrite status queries with `bd list`
- [ ] Update `/dock` - Use `bd update` for status changes
- [ ] Update `/airlock` - Create blocking bugs instead of alerts
- [ ] Update `/pod` - Use `bd update` to mark in_progress
- [ ] Update `/handover` - No changes (file-based)

### Phase 5: Agent Prompts (Day 4)
- [ ] Update all 9 agent prompts:
  - Replace "mission" → "feature"
  - Replace "objective" → "task"
  - Add `bd` CLI examples
  - Add `bd sync` to completion steps
- [ ] Test each agent type with small tasks

### Phase 6: Testing (Day 5)
- [ ] Create test epic with 2 features, 4 tasks
- [ ] Run ralph.sh through full cycle
- [ ] Test blocking dependencies (create bug, verify task blocked)
- [ ] Test critical bug halt (verify ralph exits)
- [ ] Test mprocs visible mode (verify Pods display)
- [ ] Test multi-machine sync (commit on laptop, pull on desktop)
- [ ] Run `/capcom` and verify status report
- [ ] Create PR, verify git diff on `.beads/issues.jsonl`

### Phase 7: Documentation (Day 5)
- [ ] Update README.md with Beads requirements
- [ ] Document `bd` CLI usage for users
- [ ] Add migration guide for existing users
- [ ] Update architecture diagrams

---

## Query Reference

### Common Query Patterns

```bash
# Get all epics (top-level)
bd list --json | jq '.[] | select(.type == "epic")'

# Get features under an epic
bd list --json | jq '.[] | select(.parent == "bd-epic-id") | select(.type == "feature")'

# Get all open tasks for a feature (ralph.sh)
bd ready --json | jq '.[] |
    select(.labels[] | contains("feature:bd-a3f8.1")) |
    select(.type == "task")'

# Get dependency tree (visual)
bd dep tree bd-epic-id

# Check if feature is complete (no open children)
! bd list --json | jq -e '.[] |
    select(.parent == "bd-feature-id") |
    select(.status == "open")'

# Get all bugs with critical severity
bd list --json | jq '.[] |
    select(.type == "bug") |
    select(.labels[] | contains("severity:critical"))'

# Get statistics
bd stats
```

### Ralph.sh Essential Queries

```bash
# 1. Get next task (line 200-212 replacement)
get_next_task() {
    local feature_id="$1"
    bd ready --json | \
        jq -r '.[] |
            select(.labels[] | contains("feature:'$feature_id'")) |
            select(.type == "task") |
            "\(.id)|\(.title)|\(.description)"' | \
        head -1
}

# 2. Mark task complete (line 217-226 replacement)
mark_task_complete() {
    local task_id="$1"
    bd close "$task_id" --reason "Completed by Pod $(date)"
    bd sync
}

# 3. Mark task failed (line 228-236 replacement)
mark_task_failed() {
    local task_id="$1"
    local reason="$2"
    local feature_id="$3"

    # Create blocking bug
    local bug_id=$(bd create "Bug: Task failed - $reason" \
        --parent "$feature_id" \
        -t bug \
        --label severity:blocker \
        --priority 0 \
        --json | jq -r '.id')

    # Block the task
    bd dep add "$task_id" "$bug_id"
}

# 4. Check if feature is complete (line 250-263 replacement)
check_feature_complete() {
    local feature_id="$1"

    # No open children = complete
    ! bd list --json | jq -e '.[] |
        select(.parent == "'$feature_id'") |
        select(.status == "open")' > /dev/null
}

# 5. Check for critical bugs (line 295-309 replacement)
check_critical_bugs() {
    local feature_id="$1"

    bd list --json | jq -e '.[] |
        select(.labels[] | contains("feature:'$feature_id'")) |
        select(.type == "bug") |
        select(.labels[] | contains("severity:critical")) |
        select(.status == "open")' > /dev/null
}
```

---

## What Stays The Same

### Operational Components (No Changes)
- ✅ Ralph.sh execution loop pattern (fresh context per iteration)
- ✅ mprocs visible mode (`--visible` flag)
- ✅ Pod spawning via Task tool or mprocs
- ✅ Three-agent review (Worker → Inspector → Analyst)
- ✅ Airlock validation gates
- ✅ CAPCOM coordination
- ✅ Handover protocol (file-based)
- ✅ HOUSTON interface
- ✅ Signal file infrastructure
- ✅ Notification system

### File Structure (Updated to Match Beads)

**Key Change:** Folder structure now matches Beads status terminology (open/in_progress/closed)

```
.space-agents/
├── epics/                                    ← RENAMED from "missions"
│   ├── open/                                 ← Epics being planned (Beads: open)
│   │   └── {epic-id}-{slug}/
│   │       ├── README.md
│   │       └── exploration/
│   │
│   ├── in_progress/                          ← Epics being executed (Beads: in_progress)
│   │   └── {epic-id}-{slug}/
│   │       ├── README.md
│   │       │
│   │       ├── open/                         ← Features planned (Beads: open)
│   │       │   └── {feature-id}-{slug}/
│   │       │       ├── README.md
│   │       │       └── mission-brief.md
│   │       │
│   │       ├── in_progress/                  ← Features active (Beads: in_progress)
│   │       │   └── {feature-id}-{slug}/
│   │       │       ├── README.md
│   │       │       ├── mission-brief.md
│   │       │       ├── capcom.log
│   │       │       ├── handover.md
│   │       │       └── tmp/
│   │       │           ├── pod-prompts/
│   │       │           └── signals/
│   │       │
│   │       └── closed/                       ← Features complete (Beads: closed)
│   │           └── {feature-id}-{slug}/
│   │               ├── README.md
│   │               ├── mission-brief.md
│   │               ├── capcom.log
│   │               └── handover.md
│   │
│   └── closed/                               ← Completed epics (Beads: closed)
│       └── {epic-id}-{slug}/
│           ├── README.md
│           └── closed/
│               └── (completed features)
│
├── comms/
│   └── notifications.md
│
└── exploration/
    └── YYYY-MM-DD-topic/
```

**Folder Naming Convention:**
- Epic folders: `bd-a3f8-task-management-api/`
- Feature folders: `bd-a3f8.1-user-authentication/`
- Slug generated from title (lowercase, hyphens)

**Artifacts Stored in Feature Folders:**
- `README.md` - Feature description and status
- `mission-brief.md` - Detailed plan (created by /mission-brief)
- `capcom.log` - Ralph execution log
- `handover.md` - Context between Pod iterations
- `tmp/pod-prompts/` - Generated prompts for each task
- `tmp/signals/` - Pod completion signals

---

## What Changes

### Database
- ❌ Remove: SQLite database (`.space-agents/comms/space-agents.db`)
- ✅ Add: Beads directory (`.beads/`)
  - `.beads/beads.db` (gitignored SQLite cache)
  - `.beads/issues.jsonl` (committed, version-controlled)

### Terminology
- ❌ Voyages → ✅ Epics
- ❌ Missions → ✅ Features
- ❌ Objectives → ✅ Tasks
- ❌ Alerts table → ✅ Bugs with `blocks` dependencies

### Folder Naming
- ❌ `missions/` → ✅ `epics/`
- ❌ `staged/active/complete/` → ✅ `open/in_progress/closed/` (matches Beads exactly)

### Query Language
- ❌ SQL queries → ✅ `bd` CLI + `jq`
- ❌ Pipe-delimited output → ✅ JSON parsing

### Skills
- All 9 skills need query updates
- Terminology changes in prompts
- No architectural changes to skills

---

## Benefits Summary

### 1. Graph-Based Dependencies
**Current Problem:** Ralph picks next objective by priority, might start work that's blocked by another task.

**Beads Solution:** `bd ready` only returns tasks with no open blockers. Graph algorithm prevents starting blocked work.

**Example:**
```
Task A: Implement JWT signing
Task B: Add JWT to routes (BLOCKED by Task A)

Current: Ralph might pick Task B if priority is higher
Beads: bd ready won't return Task B until Task A is closed
```

### 2. Better Tooling
**Current:** Raw SQL queries, manual JSON formatting for status reports

**Beads:**
- `bd dep tree bd-epic-id` - Visual hierarchy
- `bd stats` - Automatic statistics
- `bd ready` - Smart query for next work
- `bd sync` - Automatic git sync

### 3. Future Parallel Execution
**Current:** Sequential IDs (OBJ-001, OBJ-002) would collide if running multiple Ralph instances

**Beads:** Hash-based IDs (bd-a3f8, bd-f3c4) are globally unique. Multiple Ralph loops can create tasks simultaneously without coordination.

**Example:**
```
Ralph 1 (feature A): creates task → bd-a3f8.1.1
Ralph 2 (feature B): creates task → bd-f7b2.1.1

No collision! Both can run in parallel.
```

### 4. Multi-Machine Sync
**Current:** SQLite database is local, no automatic sync

**Beads:** `.beads/issues.jsonl` is committed to git. Pull on desktop, automatically syncs all tasks.

### 5. Audit Trail
**Current:** Status changes tracked in SQLite, hard to see history

**Beads:** Every `bd sync` creates a git commit. Full history in version control with diffs.

```bash
git log .beads/issues.jsonl
git diff HEAD~1 .beads/issues.jsonl  # See what changed
```

### 6. Conflict-Free Merges
**Current:** Binary SQLite would conflict on concurrent edits

**Beads:** JSONL format (one issue per line) enables automatic merge resolution.

---

## Risks and Mitigations

### Risk 1: Learning Curve
**Risk:** Team needs to learn `bd` CLI and Beads concepts

**Mitigation:**
- Beads CLI is simple (5 main commands)
- Space-Agents documentation will include `bd` examples
- Migration script demonstrates patterns
- Yegge's docs are excellent

### Risk 2: Migration Bugs
**Risk:** Migration script might not preserve all data correctly

**Mitigation:**
- Archive old SQLite database (keep backup)
- Test migration on copy first
- Verify with `bd dep tree` after migration
- Can roll back if issues found

### Risk 3: Beads Maturity
**Risk:** Beads is relatively new, might have bugs

**Mitigation:**
- Actively developed by Yegge
- Used in production by early adopters
- SQLite + JSONL are proven technologies
- Can contribute fixes back if needed

### Risk 4: Complex Queries
**Risk:** Some SQL queries might be harder in `bd` + `jq`

**Mitigation:**
- Most queries are simple (by type, by parent, by status)
- `jq` is powerful and well-documented
- Can always query `.beads/beads.db` directly if needed
- Build helper functions in ralph.sh

---

## Success Criteria

Migration is complete when:
- [ ] All SQLite queries replaced with `bd` CLI calls
- [ ] Ralph.sh executes full feature cycle (create → execute → complete)
- [ ] Blocking dependencies work (bug blocks task)
- [ ] Critical bugs halt Ralph loop
- [ ] mprocs visible mode works
- [ ] CAPCOM status reports accurate
- [ ] Multi-machine sync tested (commit/pull works)
- [ ] All 9 skills updated and tested
- [ ] Documentation updated

---

## Next Steps

1. **Create migration mission** - Use `/mission-brief` to plan implementation
2. **Prototype ralph.sh queries** - Test `bd` CLI patterns in isolation
3. **Write migration script** - Convert existing data to Beads
4. **Update ralph.sh** - Replace SQL with `bd` + `jq`
5. **Update skills** - Modify all 9 skills
6. **Test end-to-end** - Full Ralph cycle with real feature
7. **Document** - Update README and architecture docs

---

## Open Questions

1. Should we preserve old SQLite IDs as labels? (e.g., `--label old_id:OBJ-001`)
2. Do we need a reverse migration script (Beads → SQLite) for rollback?
3. Should critical bugs halt the entire epic or just the feature?
4. How to handle chores (maintenance tasks) - separate type or label?
5. Should we implement `bd compact` for long-running epics?

---

## References

- Beads Documentation: https://github.com/steveyegge/beads
- Gas Town Architecture: `docs/research/yegge-gastown.md`
- Beads Pattern Analysis: `docs/research/yegge-beads.md`
- SAL v2 Pattern Comparison: `docs/research/sal-v2-pattern-comparison.md`
- Current SQLite Schema: `skills/install/scripts/init-db.sql`
- Ralph.sh Implementation: `skills/mission-go/scripts/ralph.sh`
