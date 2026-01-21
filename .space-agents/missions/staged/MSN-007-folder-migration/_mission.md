# MSN-007-folder-migration: Folder Structure Migration

**Status:** Staged
**Created:** 2026-01-21

## Goal

Implement stable folder structure (paths never change) and create migration script for existing SQLite projects.

## Objectives

1. OBJ-001 - Define stable folder structure
2. OBJ-002 - Create SQLite to Beads migration script
3. OBJ-003 - Update folder lifecycle in all skills
4. OBJ-004 - Test migration on sample project

## Stable Folder Structure

```
.space-agents/
├── epics/
│   └── bd-a3f8-auth-system/           # Hash ID + slug
│       ├── _epic.md                    # Metadata
│       └── features/
│           └── bd-a3f8.1-jwt-impl/    # Child hash + slug
│               ├── _feature.md
│               ├── mission-brief.md
│               ├── capcom.log
│               └── handover.md
├── .beads/                             # Beads three-layer storage
│   ├── beads.db                        # SQLite cache (GITIGNORED)
│   └── issues.jsonl                    # Source of truth (COMMITTED)
└── comms/
    └── voyage-log.md                   # Session log + handover

```

## Key Principle: Folders Don't Move

**OLD (Kanban folders):**
- `missions/staged/` → `missions/active/` → `missions/complete/`
- Files moved on status change → messy git history

**NEW (Stable folders):**
- Folders stay at `epics/bd-a3f8/features/bd-a3f8.1/` forever
- Status lives in Beads (`bd show bd-a3f8.1 --json | jq .status`)
- Clean git history, simple skill logic

## Migration Script Logic

```bash
# For each SQLite mission
bd create "Feature: $title" -t feature --parent $epic_id \
  --label old_id:$mission_id

# For each SQLite objective
bd create "Task: $title" -t task --parent $feature_id \
  -p $priority \
  --label old_id:$objective_id

# For each SQLite alert (creates blocking bug)
bd create "Bug: $description" -t bug --parent $feature_id \
  --label severity:$severity \
  --label old_id:$alert_id
bd dep add $blocked_task_id $bug_id

# Preserve for debugging
--label old_id:MSN-001
--label old_id:OBJ-002
```

## Dependencies

- MSN-004 through MSN-006 (all Beads integration complete)

## Success Criteria

- [ ] Folder paths include hash IDs (bd-a3f8-slug/)
- [ ] Folders never move on status change
- [ ] Migration script converts SQLite → Beads
- [ ] Old IDs preserved as labels
- [ ] `bd dep tree` matches old hierarchy
- [ ] Full Ralph loop works on migrated data
