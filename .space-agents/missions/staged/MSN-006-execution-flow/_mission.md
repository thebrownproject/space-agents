# MSN-006-execution-flow: Execution Flow Skills

**Status:** Staged
**Created:** 2026-01-21
**Revised:** 2026-01-21 (Council Review + Beads CLI Verification)

## Goal

Update /pod, /airlock, /capcom, and /handover to work with Beads for task status and bug tracking during execution. These skills handle the execution phase of the workflow.

## Prerequisites

- **MSN-004-beads-core complete** (ralph.sh works with Beads)
- **MSN-005-planning-flow complete** (features can be created)
- Gate 1 passed

## Objectives (4 total)

1. **OBJ-001** - Update /pod skill for Beads task operations
2. **OBJ-002** - Update /airlock to create blocking bugs
3. **OBJ-003** - Update /capcom for Beads queries
4. **OBJ-004** - Update /handover for Beads context generation

## Execution Sequence

```
OBJ-001 (/pod) → OBJ-002 (/airlock) → OBJ-003 (/capcom) → OBJ-004 (/handover)
```

- OBJ-001 → OBJ-002: **Hard dependency** (Pod invokes Airlock)
- OBJ-002 → OBJ-003: Can parallelize, but sequential recommended
- OBJ-003 → OBJ-004: Handover uses similar query patterns

## Objective Details

### OBJ-001: Update /pod skill for Beads task operations

**Goal:** Replace all SQLite queries in pod/skill.md with Beads CLI commands.

**File:** `skills/pod/skill.md`

**This is the most complex objective** - Pod has extensive SQLite usage:

| Line | Current SQL | Beads Replacement |
|------|-------------|-------------------|
| 26-36 | SELECT objective details | `bd show <task_id> --json` |
| 75-80 | UPDATE status = 'in_progress' | `bd update <task_id> --status in_progress` |
| 174-182 | UPDATE status = 'complete' | `bd close <task_id> --reason "Completed"` |
| 206-220 | UPDATE failed + INSERT alert | `bd_create_blocking_bug()` (see below) |

**Terminology changes throughout:**
- `mission_id` → `feature_id`
- `objective_id` → `task_id`
- `objective` → `task`
- `mission` → `feature`
- `alert` → `bug`

**Worker attempts tracking:**
```bash
# NOTE: bd comment does NOT exist - use labels instead
bd update <task_id> --label "attempt:$ATTEMPT_COUNT"
# Or update description to append attempt info
```

**Success criteria:**
- [ ] Pod loads task via `bd show --json`
- [ ] Pod marks task in_progress via `bd update`
- [ ] Pod marks task complete via `bd close`
- [ ] Pod creates blocking bug on failure
- [ ] No SQLite references remain

### OBJ-002: Update /airlock to create blocking bugs

**Goal:** Replace alert creation with Beads bug creation + blocking dependency.

**File:** `skills/airlock/SKILL.md`

**This is the "killer feature"** - bug-blocking prevents Ralph from picking up blocked work.

**Current behavior:**
```
Pod: Airlock validation FAILED.
     Creating blocker alert: ALT-XXX
     Returning objective to Worker for fixes.
```

**New behavior:**
```bash
# When airlock fails, create a blocking bug
BUG_ID=$(bd create "Bug: Tests failed - $SUMMARY" \
    -t bug \
    --parent $FEATURE_ID \
    -p 0 \
    --label severity:blocker \
    --label source:airlock)

# Block the task that failed
bd dep add $TASK_ID $BUG_ID
bd sync

# Now: bd ready returns the BUG, not the blocked task
# Ralph picks up bug → Pod fixes it → closes bug → task unblocks
```

**Bug severity mapping:**

| Failure Type | Severity Label | Blocks Task? |
|--------------|----------------|--------------|
| Tests fail | `severity:blocker` | Yes |
| Lint fail | `severity:warning` | No (configurable) |
| Type check fail | `severity:warning` | No (configurable) |
| Build fail | `severity:critical` | Yes + halts Ralph |

**Alert format change:**
- Old: `[ALERT:severity]` message format
- New: `[BUG:severity]` message format

**Success criteria:**
- [ ] Airlock creates bug via `bd create -t bug`
- [ ] Bug blocks task via `bd dep add`
- [ ] Blocked task NOT in `bd ready` output
- [ ] Bug IS in `bd ready` output (highest priority)

### OBJ-003: Update /capcom for Beads queries

**Goal:** Replace SQL status queries with Beads CLI for reporting.

**File:** `skills/capcom/skill.md`

**SQL queries to replace:**

| Current SQL | Beads Replacement |
|-------------|-------------------|
| `SELECT id, title, status FROM missions...` | `bd list --json \| jq '.[] \| select(.issue_type == "feature")'` |
| `SELECT o.id, o.title, o.status FROM objectives...` | `bd list --json \| jq '.[] \| select(.issue_type == "task")'` |
| `SELECT id, severity, description FROM alerts...` | `bd list --json \| jq '.[] \| select(.issue_type == "bug") \| select(.status == "open")'` |

**Note:** Use `.issue_type` NOT `.type` - verified from Beads documentation.

**Additional queries:**
```bash
# Visual hierarchy
bd dep tree $(bd_get_active_epic)

# Statistics
bd stats

# Blocked tasks - use status field, NOT .blocked field
bd list --json | jq '.[] | select(.issue_type == "task") | select(.status == "blocked")'

# Or use bd blocked command directly
bd blocked
```

**Success criteria:**
- [ ] Status report shows features, tasks, bugs from Beads
- [ ] `bd dep tree` output included
- [ ] Blocked tasks show their blockers
- [ ] Statistics accurate

### OBJ-004: Update /handover for Beads context generation

**Goal:** Replace SQL queries with Beads CLI for context handover.

**File:** `skills/handover/skill.md`

**SQL queries to replace:**

| Current SQL | Beads Replacement |
|-------------|-------------------|
| `SELECT m.id, m.title, done, total FROM missions...` | `bd list --json \| jq` + count tasks per feature |
| `SELECT o.id, o.title FROM objectives WHERE status = 'in_progress'` | `bd list --json \| jq '.[] \| select(.issue_type == "task") \| select(.status == "in_progress")'` |
| `SELECT id, severity, description FROM alerts...` | `bd list --json \| jq '.[] \| select(.issue_type == "bug") \| select(.status == "open")'` |

**Context generation:**
```bash
# For next session handover
echo "## Current State"
echo "Active epic: $(bd_get_active_epic)"
echo ""
echo "### Dependency Tree"
bd dep tree $(bd_get_active_epic)
echo ""
echo "### Next Tasks"
bd ready --json | jq -r '.[0:5] | .[] | "- \(.id): \(.title)"'
echo ""
echo "### Open Bugs"
bd list --json | jq -r '.[] | select(.issue_type == "bug") | select(.status == "open") | "- \(.id): \(.title)"'
```

**Success criteria:**
- [ ] Handover captures complete Beads state
- [ ] `bd dep tree` output included
- [ ] Next tasks from `bd ready` listed
- [ ] Open bugs listed

## Pod Bug-Handling Flow (Critical)

When Ralph gets a bug from `bd ready`, the Pod handles it like this:

```
1. bd ready returns bug (highest priority, unblocked)
         ↓
2. Pod recognizes issue_type == "bug" (not "task")
         ↓
3. Pod dispatches Worker with bug context:
   - Bug ID, title, description
   - Parent feature context
   - What task it's blocking
         ↓
4. Worker reads bug description as fix instructions
   - Bug: "Tests failed - JWT validation error"
   - Worker investigates and fixes the issue
         ↓
5. Worker signals completion to Pod
         ↓
6. Pod runs Airlock validation
         ↓
7a. If Airlock PASSES:
    - bd close $BUG_ID --reason "Fixed: $DESCRIPTION"
    - bd sync
    - Original task automatically unblocks
    - bd ready now returns the unblocked task
         ↓
7b. If Airlock FAILS again:
    - Bug stays open
    - Increment attempt count
    - After max attempts, escalate (severity:critical)
```

**Key insight:** Bugs are just high-priority items. Worker attempts to fix them like any task. The blocking relationship ensures the original task waits.

## Alert Severity Mapping

| Old (SQLite) | New (Beads Label) | Effect |
|--------------|-------------------|--------|
| severity: 0 | `severity:critical` | Halts Ralph immediately |
| severity: 1 | `severity:blocker` | Blocks task, must fix first |
| severity: 2 | `severity:warning` | Logged but doesn't block |
| severity: 3 | `severity:info` | Informational only |

**Critical bug detection:**
```bash
# Check for critical bugs (halt condition)
if bd list --json | jq -e '.[] | select(.issue_type == "bug") | select(.status == "open") | select(.labels[] | contains("severity:critical"))' > /dev/null; then
    log ERROR "CRITICAL BUG - HALTING"
    exit 1
fi
```

## Key Files

**Modify:**
- `skills/pod/skill.md` - Task status, bug handling
- `skills/airlock/SKILL.md` - Bug creation, blocking
- `skills/capcom/skill.md` - Status queries
- `skills/handover/skill.md` - Context generation

## Dependencies

- MSN-004-beads-core (ralph.sh must work with Beads)
- MSN-005-planning-flow (features must be creatable)
- beads-helpers.sh functions available

## Success Criteria

- [ ] Pod marks tasks as in_progress via Beads
- [ ] Airlock creates blocking bugs that remove task from `bd ready`
- [ ] Bug-blocking flow works end-to-end (bug → fix → close → task unblocks)
- [ ] CAPCOM shows accurate status from Beads queries
- [ ] Handover generates context with `bd dep tree` output
- [ ] Critical bugs halt Ralph execution
- [ ] No SQLite references remain in any skill

## Gate 2: Exit Criteria

After this mission completes, verify:
1. Full execution cycle works: feature → tasks → completion
2. Bug-blocking flow: create bug → blocks task → fix bug → task unblocks
3. CAPCOM shows accurate Beads status
4. Handover generates useful context for next session

Only proceed to MSN-007 after Gate 2 passes.

## Rollback Plan

If mission fails after partial completion:

```bash
# Restore skill files to SQLite versions
git checkout -- skills/pod/skill.md
git checkout -- skills/airlock/SKILL.md
git checkout -- skills/capcom/skill.md
git checkout -- skills/handover/skill.md

# Note: MSN-004 and MSN-005 changes remain intact
```

## Notes

Council review (2026-01-21): Expanded OBJ-001 and OBJ-004 descriptions (were underscoped). Added Pod bug-handling flow documentation. Added alert severity mapping. Clarified worker attempts tracking (use bd comment).

Second council review (2026-01-21): Fixed all jq queries to use `.issue_type` not `.type`. Removed `bd comment` (doesn't exist) - use labels instead. Fixed `.blocked == true` to `.status == "blocked"`. Updated `get_active_epic` to `bd_get_active_epic`. Added rollback plan.
