# MSN-005-planning-flow: Planning Flow Skills

**Status:** Staged
**Created:** 2026-01-21
**Revised:** 2026-01-21 (Council Review + Beads CLI Verification)

## Goal

Update /install, /launch, /mission-brief, and /dock skills to create and manage work items in Beads instead of SQLite. These skills handle the planning phase of the workflow.

## Prerequisites

- **MSN-004-beads-core complete** (Gate 1 passed)
- beads-helpers.sh exists and works
- init-beads.sh exists and works

## Objectives (4 total)

1. **OBJ-001** - Update /install skill for Beads
2. **OBJ-002** - Update /launch skill to query Beads and create epics
3. **OBJ-003** - Update /mission-brief to create features and tasks
4. **OBJ-004** - Update /dock skill with Land the Plane protocol

## Execution Sequence

**Strict sequential** - each skill depends on the previous:

```
OBJ-001 (/install) → OBJ-002 (/launch) → OBJ-003 (/mission-brief) → OBJ-004 (/dock)
```

- /launch checks if system is installed (needs /install)
- /mission-brief creates features under epic (needs /launch to create epic)
- /dock updates status of items created by /mission-brief

## Objective Details

### OBJ-001: Update /install skill for Beads

**Goal:** Replace SQLite initialization with Beads initialization.

**File:** `skills/install/skill.md`

**Changes:**
1. Remove SQLite prerequisite check
2. Add `bd` CLI prerequisite check
3. Add `jq` prerequisite check
4. Replace `scripts/init-db.sql` with `scripts/init-beads.sh`
5. Update folder structure creation (nested under epic):
   - `missions/staged/` → `epics/{epic-slug}/open/`
   - `missions/active/` → `epics/{epic-slug}/in_progress/`
   - `missions/complete/` → `epics/{epic-slug}/closed/`
6. Update terminology throughout

**SQL to remove:**
```sql
sqlite3 .space-agents/comms/space-agents.db < scripts/init-db.sql
```

**Beads replacement:**
```bash
./scripts/init-beads.sh
```

**Success criteria:**
- [ ] `/install` creates `.beads/` directory
- [ ] No SQLite database created
- [ ] New folder structure template: `epics/{epic-slug}/open|in_progress|closed/`

### OBJ-002: Update /launch skill to query Beads and create epics

**Goal:** Replace 5 SQL queries with Beads CLI + jq queries.

**File:** `skills/launch/skill.md`

**SQL queries to replace:**

| Current SQL | Beads Replacement |
|-------------|-------------------|
| `SELECT title FROM voyages LIMIT 1` | `bd list --json \| jq -r '.[] \| select(.issue_type == "epic") \| .title' \| head -1` |
| `SELECT COUNT(*) FROM objectives WHERE status IN ('pending','in_progress')` | `bd list --json \| jq '[.[] \| select(.issue_type == "task") \| select(.status == "open" or .status == "in_progress")] \| length'` |
| `SELECT severity, COUNT(*) FROM alerts...` | `bd list --json \| jq '[.[] \| select(.issue_type == "bug") \| select(.status == "open")]'` |
| `SELECT status, id, title FROM missions...` | `bd list --json \| jq '.[] \| select(.issue_type == "feature")'` |
| `SELECT description FROM alerts WHERE severity<2` | `bd list --json \| jq '.[] \| select(.issue_type == "bug") \| select(.labels[] \| contains("severity:critical") or contains("severity:blocker"))'` |

**Note:** Use `.issue_type` NOT `.type` - verified from Beads documentation.

**Epic creation on first launch:**
```bash
# If no epic exists, create one
# $PROJECT_NAME from folder name: basename $(pwd)
if ! bd list --json | jq -e '.[] | select(.issue_type == "epic")' > /dev/null; then
    PROJECT_NAME=$(basename "$(pwd)")
    bd create "Epic: $PROJECT_NAME" -t epic
    bd sync
fi
```

**Shared helper function (MUST be in beads-helpers.sh - not inline):**
```bash
bd_get_active_epic() {
    bd list --json | jq -r '.[] | select(.issue_type == "epic") | select(.status != "closed") | .id' | head -1
}
```

**Important:** This function is defined in MSN-004's beads-helpers.sh. All skills MUST use `bd_get_active_epic()` from there - do not redefine inline.

**Terminology updates:**
- "Missions: {count}" → "Features: {count}"
- "Objectives: {count}" → "Tasks: {count}"

**Success criteria:**
- [ ] Detects `.beads/` for installation check
- [ ] Creates epic on first launch if none exists
- [ ] All queries return correct data from Beads
- [ ] Display shows "Features" and "Tasks"

### OBJ-003: Update /mission-brief to create features and tasks

**Goal:** Replace SQL INSERTs with Beads create commands.

**File:** `skills/mission-brief/SKILL.md`

**SQL to replace:**
```sql
INSERT INTO missions (id, title, status) VALUES ('<mission_id>', '<title>', 'staged');
INSERT INTO objectives (mission_id, id, title, description, status, priority)
VALUES ('<mission_id>', 'OBJ-001', '<title>', '<desc>', 'pending', 1);
```

**Beads replacement:**
```bash
# Get active epic (from beads-helpers.sh)
EPIC_ID=$(bd_get_active_epic)
EPIC_SLUG=$(bd show "$EPIC_ID" --json | jq -r '.title' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# Create feature under epic
FEATURE_ID=$(bd create "Feature: $TITLE" -t feature --parent $EPIC_ID --json | jq -r '.id')
bd sync

# Create tasks under feature
bd create "Task: $TASK_TITLE" -t task --parent $FEATURE_ID -p 1
bd create "Task: $TASK_TITLE" -t task --parent $FEATURE_ID -p 2
bd sync
```

**Folder creation (nested under epic):**
```bash
# Old: .space-agents/missions/staged/<mission-id>/
# New: .space-agents/epics/<epic-slug>/open/<feature-slug>/
mkdir -p ".space-agents/epics/${EPIC_SLUG}/open/${FEATURE_SLUG}"
```

**Terminology updates:**
- "Mission" → "Feature" throughout
- "Objective" → "Task" throughout
- "MSN-001-slug" → feature slug (human-readable)
- "OBJ-001" → Beads assigns hash ID automatically

**Success criteria:**
- [ ] `bd create ... -t feature --parent <epic>` succeeds
- [ ] `bd create ... -t task --parent <feature>` succeeds
- [ ] Folder created at `epics/<epic-slug>/open/<feature-slug>/`
- [ ] `bd dep tree <epic>` shows correct hierarchy

### OBJ-004: Update /dock skill with Land the Plane protocol

**Goal:** Replace SQL status queries with Beads queries, implement clean session end.

**File:** `skills/dock/skill.md`

**SQL queries to replace:**

| Current SQL | Beads Replacement |
|-------------|-------------------|
| `SELECT m.id, m.title, done, total FROM missions...` | `bd list --json \| jq '.[] \| select(.issue_type == "feature") \| select(.status == "in_progress")'` |
| `SELECT o.id, o.title FROM objectives WHERE status = 'in_progress'` | `bd list --json \| jq '.[] \| select(.issue_type == "task") \| select(.status == "in_progress")'` |

**Land the Plane Protocol:**
```bash
# 1. File remaining work as Beads issues
# (Any incomplete tasks stay open - Beads tracks them)

# 2. Update issue statuses
# (Tasks completed this session already closed)

# 3. Run bd sync (export + commit) with retry
bd_sync_with_retry  # From beads-helpers.sh

# 4. Verify clean git state
git status --porcelain | grep -v "\.beads/beads.db"

# 5. Generate context for next session
bd dep tree $(bd_get_active_epic)
bd ready --json | jq '.[0:5]'  # Next 5 tasks
```

**Status terminology:**
- `staged` → `open`
- `active` → `in_progress`
- `complete` → `closed`

**Success criteria:**
- [ ] Feature progress query returns correct counts
- [ ] In-progress tasks listed correctly
- [ ] `bd sync` called at session end
- [ ] Land the Plane protocol generates useful context

## Key Files

**Modify:**
- `skills/install/skill.md` - Beads init, new folders
- `skills/launch/skill.md` - 5 SQL queries → bd CLI
- `skills/mission-brief/SKILL.md` - INSERT → bd create
- `skills/dock/skill.md` - Land the Plane protocol

## Shared Patterns

### Epic ID Discovery

Multiple skills need to find the active epic. **This is defined in MSN-004's beads-helpers.sh:**

```bash
bd_get_active_epic() {
    bd list --json | jq -r '.[] | select(.issue_type == "epic") | select(.status != "closed") | .id' | head -1
}
```

**Do NOT redefine inline** - always source beads-helpers.sh and call `bd_get_active_epic()`.

### Folder Path Construction (Nested Under Epic)

```bash
# Get epic slug from active epic
EPIC_ID=$(bd_get_active_epic)
EPIC_SLUG=$(bd show "$EPIC_ID" --json | jq -r '.title' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# Feature folder uses human-readable slug, nested under epic
FEATURE_SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
FEATURE_PATH=".space-agents/epics/${EPIC_SLUG}/open/${FEATURE_SLUG}"
```

## Dependencies

- MSN-004-beads-core must be complete (beads-helpers.sh, init-beads.sh)
- Gate 1 must pass (ralph.sh works with Beads)

## Success Criteria

- [ ] `/install` creates `.beads/` directory, no SQLite
- [ ] `/launch` creates epic visible via `bd list`
- [ ] `/mission-brief` creates feature with child tasks
- [ ] `bd dep tree {epic}` shows correct hierarchy
- [ ] `/dock` implements Land the Plane protocol
- [ ] All skills use nested folder structure (`epics/{epic}/open/` etc.)
- [ ] All skills use new terminology (feature/task)
- [ ] All jq queries use `.issue_type` not `.type`

## Rollback Plan

If mission fails after partial completion:

```bash
# Restore skill files to SQLite versions
git checkout -- skills/install/skill.md
git checkout -- skills/launch/skill.md
git checkout -- skills/mission-brief/SKILL.md
git checkout -- skills/dock/skill.md

# Note: beads-helpers.sh from MSN-004 remains - it doesn't break SQLite
```

## Notes

Council review (2026-01-21): Structure validated. Added shared epic ID helper pattern. Strict sequential execution required. Folder paths updated for new structure.

Second council review (2026-01-21): Fixed folder paths to nested structure (`epics/{epic}/open/` not `epics/open/`). Mandated `bd_get_active_epic()` in beads-helpers.sh only. Fixed all jq queries to use `.issue_type`. Added rollback plan.
