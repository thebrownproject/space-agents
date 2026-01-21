# MSN-006-execution-flow: Execution Flow Skills

**Status:** Staged
**Created:** 2026-01-21

## Goal

Update /pod, /airlock, /capcom, and /handover to work with Beads for task status and bug tracking during execution.

## Objectives

1. OBJ-001 - Update /pod skill for task status
2. OBJ-002 - Update /airlock to create blocking bugs
3. OBJ-003 - Update /capcom for Beads queries
4. OBJ-004 - Update /handover for new context

## Key Files

**Modify:**
- `skills/pod/skill.md` - Use bd update for in_progress
- `skills/airlock/SKILL.md` - Create bugs with bd create + bd dep add
- `skills/capcom/skill.md` - Query via bd list, bd stats, bd dep tree
- `skills/handover/skill.md` - Update paths and terminology

## Bug-Blocking Pattern (Critical)

When Airlock detects validation failure:
```bash
# Create bug (high priority)
bd create "Bug: Tests failed - JWT validation" \
  -t bug \
  --parent bd-a3f8.1 \
  -p 0 \
  --label severity:blocker \
  --label source:airlock
# Returns: bd-bug-f7c2

# Block the original task
bd dep add bd-a3f8.1.2 bd-bug-f7c2

# Now bd ready returns the BUG, not the blocked task
# Ralph picks up bug, fixes it, closes it
# Task automatically unblocks
```

This is the killer feature - graph prevents Ralph from attempting blocked work.

## CAPCOM Query Patterns

```bash
# Epic overview
bd dep tree bd-a3f8

# All features
bd list --json | jq '.[] | select(.type == "feature")'

# Open bugs
bd list --json | jq '.[] | select(.type == "bug") | select(.status == "open")'

# Statistics
bd stats
```

## Dependencies

- MSN-004-beads-core (ralph.sh must work with Beads)
- MSN-005-planning-flow (features must be creatable)

## Success Criteria

- [ ] Pod marks tasks as in_progress via Beads
- [ ] Airlock creates blocking bugs that remove task from `bd ready`
- [ ] CAPCOM shows accurate status from Beads queries
- [ ] Handover generates context with bd dep tree output
