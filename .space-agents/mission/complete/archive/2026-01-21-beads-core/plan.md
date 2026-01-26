# MSN-004-beads-core: Beads Core Integration

**Status:** Staged
**Created:** 2026-01-21
**Revised:** 2026-01-21 (Council Review + Beads CLI Verification)

## Goal

Replace SQLite with Beads in ralph.sh using the three-layer architecture (CLI → SQLite cache → JSONL+Git). This is the foundation that proves the concept.

## Prerequisites (Gate 0)

Before starting this mission, verify:
- [ ] `bd --version` works (Beads CLI installed)
- [ ] `jq --version` works (JSON parsing)
- [ ] Manual bd test: `bd init`, `bd create`, `bd ready --json`, `bd close`

**Installation options:**
```bash
# Homebrew (recommended)
brew tap steveyegge/beads && brew install bd

# npm
npm install -g @beads/bd

# Go
go install github.com/steveyegge/beads/cmd/bd@latest
```

**Windows requirement:** Scripts require Git Bash or WSL. Native cmd.exe not supported.

## Objectives (6 total)

1. **OBJ-001** - Verify bd CLI patterns and create test fixture
2. **OBJ-002** - Create beads-helpers.sh query functions
3. **OBJ-003** - Create beads-helpers.sh mutation functions
4. **OBJ-004** - Create init-beads.sh initialization script
5. **OBJ-005** - Rewrite ralph.sh to use beads-helpers
6. **OBJ-006** - Smoke test ralph.sh end-to-end

## Objective Details

### OBJ-001: Verify bd CLI patterns and create test fixture

**Goal:** Confirm the correct bd CLI syntax and jq query patterns before implementation. **This is the critical gate** - all subsequent work depends on verified patterns.

**Tasks:**
1. Run `bd init` in a test directory
2. Create test hierarchy: epic → feature → tasks
3. Capture and document `bd ready --json` and `bd list --json` output format
4. Verify JSON field names (expected: `id`, `title`, `status`, `priority`, `issue_type`, `labels`, `dependencies`)
5. Confirm valid types: `epic`, `feature`, `task`, `bug` (verified via web research)
6. Confirm valid statuses: `open`, `in_progress`, `blocked`, `closed`
7. Test jq query: `jq '.[] | select(.issue_type == "task")'` (note: `issue_type` not `type`)
8. Document verified patterns in test fixture

**Verified from Beads docs:**
- Valid types (`-t`): `task`, `bug`, `feature`, `epic`, `molecule`, `gate`, `message`, `merge-request`, `agent`, `event`
- JSON field is `.issue_type` NOT `.type`
- `bd comment` does NOT exist - use labels or description for notes
- `bd show <id> --json` confirmed working

**Output:** `skills/mission-go/scripts/tests/beads-patterns.md`

### OBJ-002: Create beads-helpers.sh query functions

**Goal:** Implement read-only helper functions that wrap bd CLI with proper error handling.

**File:** `skills/mission-go/scripts/beads-helpers.sh`

**Functions to implement:**
```bash
bd_get_active_epic()                   # Returns active epic ID (mandatory - used by all skills)
bd_get_next_task(feature_id)           # Returns id|title|description
bd_get_feature_info(feature_id)        # Returns title
bd_check_feature_complete(feature_id)  # Returns 0 if all tasks closed
bd_check_critical_bugs(feature_id)     # Returns 0 if critical bugs exist
bd_init_check()                        # Verify Beads is initialized
```

**Error handling requirement (all functions):**
```bash
bd_get_next_task() {
    local feature_id="$1"
    local result
    result=$(bd ready --json 2>&1) || {
        log ERROR "bd ready failed: $result"
        return 1
    }
    # Parse with jq, use .issue_type not .type
    echo "$result" | jq -r '.[] | select(.issue_type == "task") | ...'
}
```

**Test criteria:**
- Each function parses bd JSON output correctly using `.issue_type`
- Functions return expected exit codes (0=success, 1=error)
- Error messages logged on bd CLI failure
- Works with test fixture from OBJ-001

### OBJ-003: Create beads-helpers.sh mutation functions

**Goal:** Implement write helper functions that modify Beads state with retry logic.

**File:** `skills/mission-go/scripts/beads-helpers.sh` (append)

**Functions to implement:**
```bash
bd_sync_with_retry()                   # Retry bd sync up to 3 times
bd_mark_task_in_progress(task_id)      # bd update --status in_progress
bd_mark_task_complete(task_id)         # bd close + bd_sync_with_retry
bd_mark_task_failed(task_id, reason)   # Keep status in_progress, create blocking bug
bd_close_feature(feature_id)           # bd close feature + bd_sync_with_retry
bd_create_blocking_bug(task_id, description, feature_id, severity)
```

**Sync retry pattern (required):**
```bash
bd_sync_with_retry() {
    local attempts=0
    while [[ $attempts -lt 3 ]]; do
        bd sync && return 0
        attempts=$((attempts + 1))
        log WARN "bd sync attempt $attempts failed, retrying..."
        sleep 2
    done
    log ERROR "bd sync failed after 3 attempts"
    return 1
}
```

**Note on failed tasks:** Beads has no "failed" status. When a task fails:
1. Keep status as `in_progress`
2. Create a blocking bug with `bd dep add $TASK_ID $BUG_ID`
3. Bug must be resolved before task appears in `bd ready` again

**Test criteria:**
- `bd_sync_with_retry` called after every mutation
- Bug creation includes `bd dep add` to block task
- Blocked task no longer appears in `bd ready`
- Retry logic handles transient failures

### OBJ-004: Create init-beads.sh initialization script

**Goal:** Create initialization script for new projects.

**File:** `skills/install/scripts/init-beads.sh`

**Script must:**
1. Check `bd` CLI is installed (exit 2 if not)
2. Check `jq` is installed (exit 2 if not)
3. Run `bd init` if `.beads/` doesn't exist
4. Verify `.beads/issues.jsonl` created
5. Add `.beads/beads.db` to `.gitignore`
6. Be idempotent (safe to run multiple times)

**Test criteria:**
- Creates `.beads/` directory
- Creates `issues.jsonl`
- Exits cleanly if already initialized

### OBJ-005: Rewrite ralph.sh to use beads-helpers

**Goal:** Replace all 12 SQL locations in ralph.sh with beads-helpers calls.

**File to modify:** `skills/mission-go/scripts/ralph.sh`

**SQL locations to replace (12 total):**

| Line | Current | New |
|------|---------|-----|
| 95-96 | sqlite3 prerequisite check | bd_init_check |
| 112 | SELECT mission status | bd_get_feature_info |
| 157-163 | sql_query helpers | DELETE (not needed) |
| 205-212 | get_next_objective | bd_get_next_task |
| 221-225 | mark_objective_complete | bd_mark_task_complete |
| 232-236 | mark_objective_failed | bd_mark_task_failed |
| 243-247 | get_mission_info | bd_get_feature_info |
| 255-261 | check_mission_complete | bd_check_feature_complete |
| 268-272 | mark_mission_complete | bd_close_feature |
| 300-307 | check_critical_alerts | bd_check_critical_bugs |
| 324-342 | create_alert | bd_create_blocking_bug |

**Changes:**
- Source beads-helpers.sh at top
- Replace `$MISSION_ID` with `$FEATURE_ID`
- Remove `$DB` variable
- Remove sql_query helper functions
- Update terminology in logs (mission→feature, objective→task)

### OBJ-006: Smoke test ralph.sh end-to-end

**Goal:** Verify rewritten ralph.sh executes a complete feature cycle.

**Test scenarios:**

1. **Happy path** - 2 tasks complete successfully
   ```bash
   bd create "Test Epic" -t epic
   bd create "Test Feature" -t feature --parent $EPIC_ID
   bd create "Task 1" -t task --parent $FEATURE_ID
   bd create "Task 2" -t task --parent $FEATURE_ID
   ./ralph.sh $FEATURE_ID
   # Verify: exit 0, both tasks closed
   ```

2. **Bug blocking** - Task blocked by bug
   ```bash
   # Create bug that blocks task
   bd create "Bug: Test failure" -t bug --parent $FEATURE_ID
   bd dep add $TASK_ID $BUG_ID
   bd ready --json  # Should return bug, not task
   ```

3. **Critical bug halts** - Ralph stops on critical bug
   ```bash
   bd create "Critical bug" -t bug --parent $FEATURE_ID --label severity:critical
   ./ralph.sh $FEATURE_ID
   # Verify: exit 1, halted
   ```

## Key Files

**Create:**
- `skills/mission-go/scripts/beads-helpers.sh` - Wrapper functions
- `skills/install/scripts/init-beads.sh` - Initialization script
- `skills/mission-go/scripts/tests/beads-patterns.md` - Verified patterns

**Modify:**
- `skills/mission-go/scripts/ralph.sh` - Replace 12 SQL locations
- `skills/mission-go/scripts/ralph-visible.sh` - Update path references if needed

**Delete (after migration verified):**
- `skills/install/scripts/init-db.sql` - No longer needed
- `skills/install/scripts/migrate-v2.sql` - Orphaned migration file

## Rollback Plan

If mission fails after partial completion:

```bash
# Restore ralph.sh to SQLite version
git checkout -- skills/mission-go/scripts/ralph.sh
git checkout -- skills/mission-go/scripts/ralph-visible.sh

# Remove new files
rm -f skills/mission-go/scripts/beads-helpers.sh
rm -f skills/install/scripts/init-beads.sh
rm -rf skills/mission-go/scripts/tests/

# Keep .beads/ for inspection but don't use it
# Delete only after confirming SQLite version works
```

**Point of no return:** After MSN-005 starts modifying skills, rollback becomes complex.

## Beads Architecture Reference

```
CLI Interface (bd commands)
         ↓
SQLite Database (.beads/beads.db) ← gitignored, fast local queries
         ↓
JSONL + Git (.beads/issues.jsonl) ← committed, human-readable diffs
```

## Critical Beads Commands

| Command | Purpose |
|---------|---------|
| `bd init` | Initialize Beads in project |
| `bd ready --json` | Returns ONLY unblocked tasks |
| `bd create "Title" -t task --parent X` | Create task under feature |
| `bd update <id> --status in_progress` | Mark working |
| `bd close <id> --reason "text"` | Complete task |
| `bd dep add <child> <parent>` | Link blocking dependency |
| `bd sync` | Export → commit to JSONL |
| `bd list --json` | All issues as JSON |
| `bd dep tree <id>` | Visual hierarchy |

## Success Criteria

- [ ] Prerequisites verified (bd, jq installed)
- [ ] beads-helpers.sh provides all needed functions
- [ ] init-beads.sh initializes Beads correctly
- [ ] ralph.sh has zero sqlite3 calls
- [ ] ralph.sh executes full feature cycle using bd CLI
- [ ] `bd ready` returns only unblocked tasks
- [ ] Bug-blocking flow works (bug blocks task, fixing unblocks)
- [ ] `bd sync` commits changes to .beads/issues.jsonl

## Gate 1: Exit Criteria

After this mission completes, verify:
1. Run ralph.sh against a test feature with 2 tasks
2. Both tasks complete successfully
3. Feature marked closed in Beads
4. `bd dep tree` shows correct hierarchy
5. No SQLite references remain in ralph.sh

Only proceed to MSN-005 after Gate 1 passes.

## Notes

This is the foundation mission. All subsequent missions depend on this working correctly. Get ralph.sh + beads-helpers.sh solid before touching any skills.

Council review (2026-01-21): Split original OBJ-001 into query/mutation helpers. Added CLI verification step. Total objectives: 6 (was 4).

Second council review (2026-01-21): Added error handling requirements, bd sync retry logic, rollback plan, ralph-visible.sh to scope. Verified Beads CLI patterns via web research - `.issue_type` not `.type`, `bd comment` doesn't exist. Added `bd_get_active_epic()` as mandatory function.
