# MSN-004-beads-core: Beads Core Integration

**Status:** Staged
**Created:** 2026-01-21

## Goal

Replace SQLite with Beads in ralph.sh using the three-layer architecture (CLI → SQLite cache → JSONL+Git). This is the MVP that proves the concept.

## Objectives

1. OBJ-001 - Create beads-helpers.sh abstraction layer
2. OBJ-002 - Create Beads initialization script
3. OBJ-003 - Rewrite ralph.sh to use beads-helpers
4. OBJ-004 - Smoke test ralph.sh end-to-end

## Key Files

**Create:**
- `skills/mission-go/scripts/beads-helpers.sh` - Wrapper functions for Beads CLI
- `skills/install/scripts/init-beads.sh` - Beads initialization

**Modify:**
- `skills/mission-go/scripts/ralph.sh` - Replace 12 SQL locations

## Beads Architecture (Three Layers)

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
| `bd ready --json` | Returns ONLY unblocked tasks |
| `bd create "Title" -t epic` | Create epic |
| `bd create "Title" -t task --parent X -p 1` | Create priority-1 task |
| `bd update <id> --status in_progress` | Mark working |
| `bd close <id> --reason "text"` | Complete task |
| `bd dep add <child> <parent>` | Link blocking dependency |
| `bd sync` | Export → commit to JSONL |
| `bd dep tree <id>` | Visual hierarchy |

## Hash-Based IDs

Beads uses content-based hashing, NOT sequential IDs:
- `bd-a3f8` (epic)
- `bd-a3f8.1` (feature, child of epic)
- `bd-a3f8.1.1` (task, child of feature)

This prevents collisions when multiple agents create issues simultaneously.

## Dependency Types

| Type | Affects `bd ready`? |
|------|---------------------|
| `blocks` | ✅ Yes - Task A must complete before B |
| `parent-child` | ✅ Yes - Hierarchical ownership |
| `related` | ❌ No - Soft reference |
| `discovered-from` | ❌ No - Audit trail |

## Success Criteria

- [ ] ralph.sh executes full feature cycle using `bd` CLI
- [ ] `bd ready` returns only unblocked tasks
- [ ] Bug-blocking flow works (bug blocks task, fixing unblocks)
- [ ] `bd sync` commits changes to .beads/issues.jsonl
- [ ] No sqlite3 calls remain in ralph.sh

## Notes

This is the foundation mission. All subsequent missions depend on this working correctly. Get ralph.sh + beads-helpers.sh solid before touching any skills.
