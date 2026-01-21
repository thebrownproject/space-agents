# MSN-006-execution-flow: Execution Flow Skills

**Status:** Staged
**Created:** 2026-01-21
**Revised:** 2026-01-21 (Model B + Comments-as-Handovers)

## Goal

Update /pod, /airlock, /capcom, and /handover for Beads-first execution. Pod self-fetches work (Model B), handovers are Beads comments, no mission folders.

## Key Architecture Changes

### Model B: Pod Self-Fetches
- Pod queries `bd ready -t task` to pick work (not assigned by Ralph)
- Pod fetches dependency context via `bd dep list` + `bd comments`
- If Pod pivots (creates bug, changes task), it fetches context for what it's *actually* working on
- Ralph becomes simpler: spawn Pods until `bd ready` returns empty

### Comments as Work Log
Task comments track the full work history:
```
[Attempt 1] Starting work...
[Attempt 1 - Blocked] Progress: X done. Hit blocker Y. Creating bug.
[Attempt 2] Resumed after bug fix. Continuing...
[Handover] Complete. Files changed: X. Notes for next task: Y.
```

### No Mission Folders
- No `.space-agents/missions/` structure
- No `handovers/OBJ-XXX.md` files
- No `prompts/OBJ-XXX.txt` files
- Everything lives in Beads (features, tasks, comments)

## Prerequisites

- Beads CLI working (`bd ready`, `bd comments`, `bd dep list`)
- ralph.sh updated to spawn Pods without task injection

## Objectives (4 total)

1. **OBJ-001** - Update /pod for Model B with Beads comments
2. **OBJ-002** - Update /airlock to create blocking bugs with context
3. **OBJ-003** - Update /capcom for Beads queries with work log
4. **OBJ-004** - Update /handover for session context generation

## Execution Sequence

```
OBJ-001 (/pod) → OBJ-002 (/airlock) → OBJ-003 (/capcom) → OBJ-004 (/handover)
```

- OBJ-001 → OBJ-002: **Hard dependency** (Pod invokes Airlock)
- OBJ-002 → OBJ-003: Sequential recommended
- OBJ-003 → OBJ-004: Handover uses similar patterns

---

## OBJ-001: Update /pod for Model B with Beads comments

**Goal:** Rewrite pod/skill.md for self-fetch context and comment-based handovers.

**File:** `skills/pod/skill.md`

### Model B Flow

```bash
# 1. Pod starts, queries what's ready
TASK=$(bd ready -t task --json | jq -r '.[0]')
TASK_ID=$(echo $TASK | jq -r '.id')

# 2. Claim the task
bd update $TASK_ID --status in_progress

# 3. Get task details
bd show $TASK_ID --json

# 4. Get dependency handovers (context from previous tasks)
DEPS=$(bd dep list $TASK_ID --json | jq -r '.[] | select(.dependency_type == "blocks") | .id')
for DEP in $DEPS; do
    echo "=== Handover from $DEP ==="
    bd comments $DEP
done

# 5. Work on task, log progress as comments
bd comments add $TASK_ID "[Attempt 1] Starting work..."

# 6. If blocked, write partial handover and create bug
bd comments add $TASK_ID "[Attempt 1 - Blocked] Progress: X. Hit blocker: Y"
BUG_ID=$(bd create "Bug: Y" -t bug --parent $FEATURE_ID -p 0)
bd dep add $TASK_ID $BUG_ID
bd update $TASK_ID --status open  # Back to open, now blocked

# 7. On success, write handover and close
bd comments add $TASK_ID "[Handover] Complete. Files: X. Notes: Y"
bd close $TASK_ID --reason "Completed"
bd sync
```

### Terminology Changes
- `mission_id` → `feature_id`
- `objective_id` → `task_id`
- `objective` → `task`
- `mission` → `feature`
- `alert` → `bug`

### Remove From Skill
- All folder path references (`missions/active/`, `handovers/`, etc.)
- Signal file creation (`.done`, `.failed`)
- SQLite queries

### Success Criteria
- [ ] Pod queries `bd ready -t task` to select work (Model B)
- [ ] Pod claims task via `bd update --status in_progress`
- [ ] Pod reads dependency comments for handover context
- [ ] Pod writes progress as `bd comments add`
- [ ] Pod writes final handover as comment before closing
- [ ] Pod creates blocking bug on failure via `bd create -t bug`
- [ ] No SQLite references remain
- [ ] No mission folder references remain

---

## OBJ-002: Update /airlock to create blocking bugs

**Goal:** Airlock creates bugs that block tasks, with context for the fixer.

**File:** `skills/airlock/SKILL.md`

### Bug Creation Flow

```bash
# When validation fails
BUG_ID=$(bd create "Bug: Tests failed - $SUMMARY" \
    -t bug \
    --parent $FEATURE_ID \
    -p 0 \
    --label severity:blocker \
    --label source:airlock \
    --json | jq -r '.id')

# Add context for Worker that will fix it
bd comments add $BUG_ID "## Bug Context
**Task blocked:** $TASK_ID
**Failure type:** $FAILURE_TYPE
**Test output:**
\`\`\`
$TEST_OUTPUT
\`\`\`
**Suggested fix:** $SUGGESTION"

# Block the task
bd dep add $TASK_ID $BUG_ID
bd sync

# Now: bd ready returns the BUG, not the blocked task
```

### Severity Mapping

| Failure Type | Severity Label | Blocks Task? |
|--------------|----------------|--------------|
| Tests fail | `severity:blocker` | Yes |
| Lint fail | `severity:warning` | No (configurable) |
| Type check fail | `severity:warning` | No (configurable) |
| Build fail | `severity:critical` | Yes + halts Ralph |

### Success Criteria
- [ ] Airlock creates bug via `bd create -t bug`
- [ ] Bug includes context comment (for Worker fixing it)
- [ ] Bug blocks task via `bd dep add`
- [ ] Blocked task NOT in `bd ready` output
- [ ] Bug IS in `bd ready` output (highest priority)
- [ ] `[ALERT:]` format changed to `[BUG:]`
- [ ] No folder references

---

## OBJ-003: Update /capcom for Beads queries

**Goal:** CAPCOM shows status from Beads including recent work activity.

**File:** `skills/capcom/skill.md`

### Beads Queries

```bash
# Features
bd list -t feature --json

# Tasks by status
bd list -t task --status open --json
bd list -t task --status in_progress --json

# Open bugs
bd list -t bug --status open --json

# Blocked tasks
bd blocked

# Dependency tree
bd list --tree

# Statistics
bd stats

# Recent activity (comments on in-progress tasks)
for TASK_ID in $(bd list -t task --status in_progress --json | jq -r '.[].id'); do
    echo "### $TASK_ID"
    bd comments $TASK_ID | tail -3
done
```

### Success Criteria
- [ ] Status report shows features, tasks, bugs from Beads
- [ ] `bd list --tree` output included
- [ ] Blocked tasks show their blockers
- [ ] Recent comment activity shown (work log)
- [ ] Statistics accurate via `bd stats`
- [ ] No SQLite references
- [ ] No folder references

---

## OBJ-004: Update /handover for session context

**Goal:** Generate session handover from Beads state.

**File:** `skills/handover/skill.md`

### Distinction: Session vs Task Handovers

| Type | Purpose | Storage |
|------|---------|---------|
| **Task handover** | Context for next task in sequence | `bd comments` on task |
| **Session handover** | Context for next human session | `comms/handover.md` file |

Pod writes task handovers. /handover writes session handovers.

### Session Handover Generation

```bash
echo "# Space-Agents Handover"
echo "**Generated:** $(date)"
echo ""
echo "## Current State"
echo ""
echo "### Dependency Tree"
bd list --tree
echo ""
echo "### Next Ready Tasks"
bd ready -t task --json | jq -r '.[0:5] | .[] | "- \(.id): \(.title)"'
echo ""
echo "### In Progress"
bd list -t task --status in_progress --json | jq -r '.[] | "- \(.id): \(.title)"'
echo ""
echo "### Open Bugs"
bd list -t bug --status open --json | jq -r '.[] | "- \(.id): \(.title)"'
echo ""
echo "### Recent Activity"
# Last comment from each in-progress task
for TASK_ID in $(bd list -t task --status in_progress --json | jq -r '.[].id'); do
    echo "**$TASK_ID:**"
    bd comments $TASK_ID | tail -1
done
```

### Success Criteria
- [ ] Handover captures complete Beads state
- [ ] `bd list --tree` output included
- [ ] Next tasks from `bd ready` listed
- [ ] Open bugs listed
- [ ] Recent task comments included
- [ ] Saved to `.space-agents/comms/handover.md`
- [ ] No SQLite references

---

## Pod Bug-Handling Flow

When `bd ready` returns a bug:

```
1. bd ready -t task returns bug (highest priority, unblocked)
         ↓
2. Pod recognizes issue_type == "bug"
         ↓
3. Pod reads bug description + comments for context
         ↓
4. Worker fixes the bug
         ↓
5. Airlock validates
         ↓
6a. PASSES: bd close $BUG_ID → blocked task unblocks
6b. FAILS: Bug stays open, increment attempt via comment
```

---

## Success Criteria

- [ ] Pod uses Model B (self-fetch, comment handovers)
- [ ] Airlock creates blocking bugs with context
- [ ] Bug-blocking flow works end-to-end
- [ ] CAPCOM shows accurate Beads status with work log
- [ ] Session handover generates from Beads
- [ ] No SQLite references in any skill
- [ ] No mission folder references in any skill

## Rollback Plan

```bash
git checkout -- skills/pod/skill.md
git checkout -- skills/airlock/SKILL.md
git checkout -- skills/capcom/skill.md
git checkout -- skills/handover/skill.md
```

## Notes

Revised 2026-01-21: Complete rewrite for Model B architecture (Pod self-fetches) and comments-as-handovers (no folder-based handover files). Mission folders eliminated.
