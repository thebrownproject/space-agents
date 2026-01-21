# MSN-005-planning-flow: Planning Flow Skills

**Status:** Staged
**Created:** 2026-01-21

## Goal

Update /install, /launch, /mission-brief, and /dock skills to create and manage work items in Beads instead of SQLite.

## Objectives

1. OBJ-001 - Update /install skill for Beads
2. OBJ-002 - Update /launch skill to create epics
3. OBJ-003 - Update /mission-brief to create features and tasks
4. OBJ-004 - Update /dock skill for status changes

## Key Files

**Modify:**
- `skills/install/skill.md` - Check for bd + jq, run init-beads.sh
- `skills/launch/skill.md` - Replace 5 SQL queries with bd + jq
- `skills/mission-brief/SKILL.md` - Use bd create for hierarchy
- `skills/dock/skill.md` - Implement Land the Plane protocol

## Beads Query Patterns

```bash
# Check if epic exists
bd list --json | jq '.[] | select(.type == "epic")'

# Create epic
bd create "Epic: Project Name" -t epic
# Returns: bd-a3f8

# Create feature under epic
bd create "Feature: Auth" -t feature --parent bd-a3f8
# Returns: bd-a3f8.1

# Create task under feature
bd create "Task: JWT" -t task --parent bd-a3f8.1 -p 1
# Returns: bd-a3f8.1.1

# Activate feature
bd update bd-a3f8.1 --status in_progress

# Always sync after mutations
bd sync
```

## Land the Plane Protocol (/dock)

From Beads research - clean session boundaries:
1. File remaining work as beads issues
2. Update issue statuses
3. Run `bd sync` (export + commit)
4. Verify clean git state
5. Generate context for next session

## Dependencies

- MSN-004-beads-core (beads-helpers.sh and init-beads.sh must exist)

## Success Criteria

- [ ] `/install` creates .beads/ directory, no SQLite
- [ ] `/launch` creates epic visible via `bd list`
- [ ] `/mission-brief` creates feature with child tasks
- [ ] `bd dep tree {epic}` shows correct hierarchy
- [ ] `/dock` implements Land the Plane protocol
