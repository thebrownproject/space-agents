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
Task comments track the full work history with structured titles for parsing:

| Title | Purpose | When Used |
|-------|---------|-----------|
| `[ATTEMPT]` | Work attempt log | Starting work on task |
| `[PROGRESS]` | Progress update | Partial work done |
| `[BLOCKED]` | Hit a blocker | Creating bug, pausing work |
| `[HANDOVER]` | Final handover | Task complete, context for next task |
| `[CONTEXT]` | Additional context | Feature-level background info |

```
[ATTEMPT] Starting work on task...
[PROGRESS] Completed X, moving to Y...
[BLOCKED] Hit blocker: Z. Creating bug. Progress so far: X done.
[ATTEMPT] Resumed after bug fix. Continuing from Y...
[HANDOVER] Complete. Files: foo.ts, bar.ts. Notes: Used approach X because Y.
```

Pods can filter comments by title:
```bash
bd comments $TASK_ID | grep "^\[HANDOVER\]"  # Get final handover only
bd comments $TASK_ID | grep "^\[BLOCKED\]"   # See what blockers occurred
```

### No Mission Folders
- No `.space-agents/missions/` structure
- No `handovers/OBJ-XXX.md` files
- No `prompts/OBJ-XXX.txt` files
- Everything lives in Beads (features, tasks, comments)

### Beads Description Convention
Features and tasks should have descriptions populated so Pod can get all context from Beads:

| Field | Contains | Example |
|-------|----------|---------|
| **Feature description** | Goal, key changes, success criteria | "Update /pod, /airlock, /capcom, /handover for Beads-first execution..." |
| **Task description** | Specific work details, file targets, verification steps | "File: skills/pod/skill.md. Implement Model B flow..." |
| **Task comments** | Work log, handovers (added during execution) | `[HANDOVER] Complete. Files: X. Notes: Y.` |

This ensures Pod reads `bd show $FEATURE_ID` and `bd show $TASK_ID` to get full context without needing external files.

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

# 4. Get parent feature for mission requirements
FEATURE_ID=$(bd show $TASK_ID --json | jq -r '.[0].parent')
echo "=== Feature Requirements ==="
bd show $FEATURE_ID --json  # Contains goal, description, acceptance criteria

# 5. Get dependency handovers (context from previous tasks)
DEPS=$(bd dep list $TASK_ID --json | jq -r '.[] | select(.dependency_type == "blocks") | .id')
for DEP in $DEPS; do
    echo "=== Handover from $DEP ==="
    bd comments $DEP | grep "^\[HANDOVER\]"  # Get final handover only
done

# 6. Work on task, log progress as comments
bd comments add $TASK_ID "[ATTEMPT] Starting work..."

# 7. Log progress during work
bd comments add $TASK_ID "[PROGRESS] Completed X, moving to Y..."

# 8. If blocked, write partial handover and create bug
bd comments add $TASK_ID "[BLOCKED] Hit blocker: Y. Progress so far: X done."
BUG_ID=$(bd create "Bug: Y" -t bug --parent $FEATURE_ID -p 0)
bd dep add $TASK_ID $BUG_ID
bd update $TASK_ID --status open  # Back to open, now blocked

# 9. On success, write handover and close
bd comments add $TASK_ID "[HANDOVER] Complete. Files: X. Notes: Y. Next task needs: Z."
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
- [ ] Pod reads parent feature for mission requirements (`bd show $FEATURE_ID`)
- [ ] Pod reads dependency comments for handover context (filter by `[HANDOVER]`)
- [ ] Pod writes progress with titled comments: `[ATTEMPT]`, `[PROGRESS]`, `[BLOCKED]`
- [ ] Pod writes final handover as `[HANDOVER]` comment before closing
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
bd comments add $BUG_ID "[CONTEXT] Bug Context
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
- [ ] Bug includes `[CONTEXT]` comment with failure details (for Worker fixing it)
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
    # Show latest progress/attempt, filter out noise
    bd comments $TASK_ID | grep -E "^\[(ATTEMPT|PROGRESS|BLOCKED)\]" | tail -3
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
# Last progress comment from each in-progress task
for TASK_ID in $(bd list -t task --status in_progress --json | jq -r '.[].id'); do
    echo "**$TASK_ID:**"
    bd comments $TASK_ID | grep -E "^\[(ATTEMPT|PROGRESS|BLOCKED)\]" | tail -1
done

echo ""
echo "### Completed Task Handovers"
# Handovers from recently closed tasks (for context)
for TASK_ID in $(bd list -t task --status closed --json | jq -r '.[0:3] | .[].id'); do
    HANDOVER=$(bd comments $TASK_ID | grep "^\[HANDOVER\]" | tail -1)
    if [ -n "$HANDOVER" ]; then
        echo "**$TASK_ID:** $HANDOVER"
    fi
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
- [ ] Comments use titled format: `[ATTEMPT]`, `[PROGRESS]`, `[BLOCKED]`, `[HANDOVER]`, `[CONTEXT]`
- [ ] Airlock creates blocking bugs with `[CONTEXT]` comment
- [ ] Bug-blocking flow works end-to-end
- [ ] CAPCOM shows accurate Beads status with work log (filtered by comment titles)
- [ ] Session handover generates from Beads including `[HANDOVER]` comments
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
