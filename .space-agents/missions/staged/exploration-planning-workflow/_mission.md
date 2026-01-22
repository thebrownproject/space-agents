# MSN-009-exploration-workflow: Exploration & Planning Workflow

**Status:** Staged
**Created:** 2026-01-21

## Goal

Implement the exploration folder as a scratchpad/kanban for ideas and draft plans. Separate "thinking space" (exploration) from "doing space" (Beads). CAPCOM becomes the mission/session log.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  EXPLORATION (scratchpad)              BEADS (execution)        │
│                                                                 │
│  .space-agents/exploration/            .beads/issues.jsonl      │
│  ├── drafts/                           Features, tasks, bugs    │
│  │   └── {topic}/                      with dependencies        │
│  │       ├── exploration.md                                     │
│  │       └── draft-plan.md             ↑                        │
│  └── ready/                            │ Convert when ready     │
│      └── {topic}/                      │                        │
│          └── plan.md ──────────────────┘                        │
│                                                                 │
│  Ideas → Draft plans → Convert to Beads → Execute               │
│                                                                 │
│  CAPCOM (session log)                                           │
│  .space-agents/comms/capcom.md                                  │
│  Mission start/end entries, session summaries                   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Concepts

| Concept | Location | Purpose |
|---------|----------|---------|
| **Exploration** | `exploration/drafts/` | Brainstorming, early ideas |
| **Draft Plans** | `exploration/drafts/{topic}/` | Structured plans not yet approved |
| **Ready Plans** | `exploration/ready/{topic}/` | Approved, ready to convert to Beads |
| **Features/Tasks** | Beads | Execution-ready work items |
| **Missions** | CAPCOM entries | Session containers (start/end logs) |

## Comment Title Convention

Task comments use titled prefixes for parsing (see MSN-006):

| Title | Purpose | Example |
|-------|---------|---------|
| `[ATTEMPT]` | Starting work | `[ATTEMPT] Starting task implementation...` |
| `[PROGRESS]` | Progress update | `[PROGRESS] Completed auth module, moving to tests...` |
| `[BLOCKED]` | Hit a blocker | `[BLOCKED] Tests failing due to missing mock. Creating bug.` |
| `[HANDOVER]` | Final handover | `[HANDOVER] Complete. Files: auth.ts. Notes: Used JWT approach.` |
| `[CONTEXT]` | Background info | `[CONTEXT] Bug context: Test output, suggested fix...` |

This allows filtering: `bd comments $ID | grep "^\[HANDOVER\]"`

## Objectives (5 total)

1. **OBJ-001** - Create exploration folder structure with kanban
2. **OBJ-002** - Update /exploration skill for drafts workflow
3. **OBJ-003** - Create /planning skill to manage drafts → ready → Beads
4. **OBJ-004** - Update CAPCOM for mission/session logging
5. **OBJ-005** - Archive old missions/ folder structure

## Execution Sequence

```
OBJ-001 (folder structure) → OBJ-002 (/exploration) → OBJ-003 (/planning)
                                                            ↓
                          OBJ-005 (cleanup) ← OBJ-004 (CAPCOM)
```

---

## OBJ-001: Create exploration folder structure

**Goal:** Set up the exploration kanban structure.

### Folder Structure

```
.space-agents/
├── exploration/
│   ├── drafts/              # Ideas and draft plans (kanban: backlog)
│   │   └── {topic-slug}/
│   │       ├── exploration.md    # Brainstorm notes
│   │       └── draft-plan.md     # Optional: structured plan draft
│   └── ready/               # Approved plans (kanban: ready)
│       └── {topic-slug}/
│           └── plan.md           # Final plan, ready for Beads conversion
├── comms/
│   ├── capcom.md            # Session log (mission entries)
│   └── handover.md          # Session handover context
└── .beads/                  # Execution (source of truth)
```

### Implementation

Update `/install` skill to create this structure:
```bash
mkdir -p .space-agents/exploration/{drafts,ready}
mkdir -p .space-agents/comms
```

### Success Criteria
- [ ] `exploration/drafts/` and `exploration/ready/` exist after install
- [ ] Old `missions/staged/active/complete/` structure not created
- [ ] Documentation updated

---

## OBJ-002: Update /exploration skill for drafts workflow

**Goal:** /exploration writes to `exploration/drafts/` with proper structure.

**File:** `skills/exploration/skill.md`

### Current Behavior
- Creates `exploration/YYYY-MM-DD-{topic}/exploration.md`

### New Behavior
- Creates `exploration/drafts/{topic-slug}/`
- Writes `exploration.md` (brainstorm notes)
- Optionally writes `draft-plan.md` (if plan emerges)
- Offers to move to `ready/` when exploration is complete

### Exploration Output

```markdown
# {Topic} Exploration

**Created:** YYYY-MM-DD
**Status:** draft | ready

## Context
{Why we're exploring this}

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|

## Architecture
{If applicable}

## Next Steps
- [ ] Item 1
- [ ] Item 2
```

### Draft Plan Output (Optional)

```markdown
# {Topic} Plan

**Created:** YYYY-MM-DD
**Status:** draft

## Goal
{One sentence}

## Tasks
1. {Task 1}
2. {Task 2}

## Key Files
- file1.ts
- file2.ts

## Dependencies
- Requires X
- Blocked by Y
```

### Success Criteria
- [ ] /exploration creates in `drafts/{topic}/`
- [ ] exploration.md follows template
- [ ] Optional draft-plan.md when plan emerges
- [ ] Offers "move to ready" at end

---

## OBJ-003: Create /planning skill for drafts → ready → Beads

**Goal:** New skill to manage the planning kanban and Beads conversion.

**File:** `skills/planning/skill.md` (NEW)

### /planning Menu

```
┌─────────────────────────────────────────────────────────────┐
│  PLANNING                                                   │
├─────────────────────────────────────────────────────────────┤
│  Drafts (exploration/drafts/):                              │
│    [1] auth-system - User authentication exploration        │
│    [2] caching-layer - Redis caching ideas                  │
│                                                             │
│  Ready (exploration/ready/):                                │
│    [3] api-refactor - Ready to convert to Beads             │
│                                                             │
│  Actions:                                                   │
│    [M] Move draft to ready                                  │
│    [C] Convert ready plan to Beads                          │
│    [D] Delete draft                                         │
│    [V] View plan details                                    │
└─────────────────────────────────────────────────────────────┘
```

### Move to Ready

```bash
# Move draft to ready
mv .space-agents/exploration/drafts/{topic} .space-agents/exploration/ready/{topic}

# Update status in plan file
sed -i 's/Status: draft/Status: ready/' .space-agents/exploration/ready/{topic}/*.md
```

### Convert to Beads

```bash
# Read plan from ready folder
PLAN_DIR=".space-agents/exploration/ready/{topic}"

# Get active epic
EPIC_ID=$(bd_get_active_epic)

# Create feature
FEATURE_ID=$(bd create "{Feature Title}" -t feature --parent $EPIC_ID --json | jq -r '.id')

# Create tasks from plan
# Parse tasks from plan.md and create each one
bd create "{Task 1}" -t task --parent $FEATURE_ID -p 1
bd create "{Task 2}" -t task --parent $FEATURE_ID -p 2

# Set up dependencies if specified
bd dep add {task2} {task1}

bd sync

# Archive the plan (don't delete - reference)
mv "$PLAN_DIR" ".space-agents/exploration/archive/{topic}"

echo "Created feature $FEATURE_ID with tasks. Run /mission to execute."
```

### Success Criteria
- [ ] /planning shows drafts and ready items
- [ ] Can move drafts to ready
- [ ] Can convert ready plans to Beads features/tasks
- [ ] Converted plans archived (not deleted)
- [ ] Dependencies created from plan

---

## OBJ-004: Update CAPCOM for mission/session logging

**Goal:** CAPCOM becomes the mission log with structured session entries.

**File:** `skills/capcom/skill.md` (update)
**File:** `skills/launch/skill.md` (update)
**File:** `skills/dock/skill.md` (update)

### Mission = Session

A "mission" is now a session container, logged in CAPCOM:

```markdown
## [2026-01-21 14:30] Mission Start
**ID:** MSN-2026-01-21-001
**Target:** space-agents-05x.2 (MSN-006: Execution Flow Skills)
**Goal:** Complete OBJ-001 and OBJ-002

---

## [2026-01-21 17:45] Mission End
**ID:** MSN-2026-01-21-001
**Duration:** 3h 15m

### Completed
- [x] space-agents-05x.2.1 - Update /pod skill

### In Progress
- [ ] space-agents-05x.2.2 - Update /airlock (blocked by bug)

### Created
- 1 bug: BUG-001 - Test failures in airlock

### Next Session
- Fix BUG-001, then continue OBJ-002
- Run: `bd ready` to see available work
```

### /launch Updates

Add mission start logging:
```bash
# Generate mission ID
MISSION_ID="MSN-$(date +%Y-%m-%d)-$(printf '%03d' $(($(grep -c 'Mission Start' .space-agents/comms/capcom.md 2>/dev/null || echo 0) + 1)))"

# Prompt for target and goal
# ... AskUserQuestion ...

# Log mission start
cat >> .space-agents/comms/capcom.md << EOF

## [$(date '+%Y-%m-%d %H:%M')] Mission Start
**ID:** $MISSION_ID
**Target:** $TARGET_FEATURE
**Goal:** $GOAL

EOF
```

### /dock Updates

Add mission end logging:
```bash
# Query Beads for session summary
COMPLETED=$(bd list -t task --status closed --json | jq -r '...')
IN_PROGRESS=$(bd list -t task --status in_progress --json | jq -r '...')
BUGS=$(bd list -t bug --status open --json | jq -r '...')

# Get handovers from completed tasks (using titled comments)
HANDOVERS=""
for TASK_ID in $(bd list -t task --status closed --json | jq -r '.[].id'); do
    HANDOVER=$(bd comments $TASK_ID | grep "^\[HANDOVER\]" | tail -1)
    if [ -n "$HANDOVER" ]; then
        HANDOVERS="$HANDOVERS\n- **$TASK_ID:** $HANDOVER"
    fi
done

# Get blockers from in-progress tasks
BLOCKERS=""
for TASK_ID in $(bd list -t task --status in_progress --json | jq -r '.[].id'); do
    BLOCKED=$(bd comments $TASK_ID | grep "^\[BLOCKED\]" | tail -1)
    if [ -n "$BLOCKED" ]; then
        BLOCKERS="$BLOCKERS\n- **$TASK_ID:** $BLOCKED"
    fi
done

# Log mission end
cat >> .space-agents/comms/capcom.md << EOF

## [$(date '+%Y-%m-%d %H:%M')] Mission End
**ID:** $MISSION_ID
**Duration:** $DURATION

### Completed
$COMPLETED

### Handovers (from [HANDOVER] comments)
$HANDOVERS

### In Progress
$IN_PROGRESS

### Blockers (from [BLOCKED] comments)
$BLOCKERS

### Created
$BUGS

### Next Session
$NEXT_CONTEXT

---

EOF

bd sync
```

### Success Criteria
- [ ] /launch logs mission start to CAPCOM
- [ ] /dock logs mission end with summary
- [ ] Mission IDs are sequential per day
- [ ] Can query CAPCOM for session history

---

## OBJ-005: Archive old missions/ folder structure

**Goal:** Clean up legacy folder structure, preserve history.

### Migration Steps

```bash
# 1. Archive completed missions (historical reference)
if [ -d ".space-agents/missions/complete" ]; then
    mkdir -p .space-agents/archive
    mv .space-agents/missions/complete .space-agents/archive/missions-complete
fi

# 2. Check staged missions are in Beads
# (MSN-006, MSN-008 should already be in Beads)
for dir in .space-agents/missions/staged/*/; do
    echo "Verify in Beads: $(basename $dir)"
done

# 3. Archive staged folder
if [ -d ".space-agents/missions/staged" ]; then
    mv .space-agents/missions/staged .space-agents/archive/missions-staged
fi

# 4. Remove empty missions directory
rmdir .space-agents/missions 2>/dev/null || true

# 5. Update .gitignore
echo ".space-agents/archive/" >> .gitignore
```

### Success Criteria
- [ ] `missions/complete/` archived to `archive/missions-complete/`
- [ ] `missions/staged/` archived to `archive/missions-staged/`
- [ ] No `missions/` folder in active structure
- [ ] Archive gitignored (optional, or commit for history)

---

## Summary: New Workflow

```
1. /exploration
   └── Brainstorm in exploration/drafts/{topic}/

2. /planning
   ├── Review drafts
   ├── Move to ready/ when approved
   └── Convert to Beads when ready to execute

3. /launch
   ├── Log mission start to CAPCOM
   └── Declare target (which Beads feature)

4. /mission
   └── Execute from Beads (Pod self-fetches, comments for handovers)

5. /dock
   ├── Log mission end to CAPCOM
   ├── Summarize what was done
   └── bd sync
```

---

## Success Criteria

- [ ] Exploration folder has drafts/ready kanban
- [ ] /exploration writes to drafts/
- [ ] /planning manages kanban and Beads conversion
- [ ] CAPCOM logs mission start/end
- [ ] Old missions/ folder archived
- [ ] Clear separation: exploration (thinking) vs Beads (doing)

## Dependencies

- MSN-006 complete (execution flow uses Beads)
- MSN-008 complete (terminology updated)

## Notes

Created 2026-01-21: New workflow separating exploration (scratchpad) from execution (Beads). Missions become session containers logged in CAPCOM, not folder structures.
