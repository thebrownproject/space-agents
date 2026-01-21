# MSN-007-folder-structure: Epic/Feature Folder Hierarchy

**Status:** Staged
**Created:** 2026-01-21
**Revised:** 2026-01-21 (Council Review - Complete Rewrite + CLI Verification)

## Goal

Implement epic/feature folder hierarchy with status kanban. Replace `missions/` terminology with `epics/features/` to align with Beads, while maintaining visual folder-based status tracking.

## Prerequisites

- **MSN-004, MSN-005, MSN-006 complete** (Gate 2 passed)
- Beads integration working
- All skills use Beads CLI

## Objectives (4 total)

1. **OBJ-001** - Define folder structure and naming conventions
2. **OBJ-002** - Create migration script (missions/ → epics/)
3. **OBJ-003** - Update skills to use new paths
4. **OBJ-004** - Test migration on current project

## New Folder Structure

```
.space-agents/
├── epics/
│   └── {epic-slug}/                    # e.g., auth-system/
│       ├── _epic.md                    # Epic metadata
│       ├── open/                       # Features planned
│       │   └── {feature-slug}/
│       │       ├── _feature.md
│       │       └── capcom.log
│       ├── in_progress/                # Features being executed
│       │   └── {feature-slug}/
│       │       ├── _feature.md
│       │       └── capcom.log
│       └── closed/                     # Features completed
│           └── {feature-slug}/
│               ├── _feature.md
│               └── capcom.log
├── .beads/
│   ├── beads.db                        # SQLite cache (gitignored)
│   └── issues.jsonl                    # Source of truth (committed)
└── comms/
    └── voyage-log.md                   # Session log (Land the Plane)
```

## Naming Conventions

### Epic Slugs
- Human-readable, lowercase, hyphenated
- Example: `auth-system`, `caching-layer`, `api-v2`
- Created from epic title: `"User Authentication" → "user-authentication"`

### Feature Slugs
- Human-readable, lowercase, hyphenated
- Example: `jwt-implementation`, `oauth-integration`
- Created from feature title

### No Hash IDs in Folder Names
- Beads IDs (bd-a3f8) stored in metadata files, not folder paths
- Folders use human-readable slugs for easy navigation
- `_feature.md` contains `beads_id: bd-a3f8.1` frontmatter

## Objective Details

### OBJ-001: Define folder structure and naming conventions

**Goal:** Document the new structure and create template files.

**Deliverables:**

1. **_epic.md template:**
```markdown
---
beads_id: bd-{hash}
title: Epic Title
status: open | in_progress | closed
created: YYYY-MM-DD
---

# {Epic Title}

## Description
{One paragraph description}

## Features
- [ ] feature-slug-1 - Title
- [ ] feature-slug-2 - Title
```

2. **_feature.md template:**
```markdown
---
beads_id: bd-{hash}.{n}
title: Feature Title
status: open | in_progress | closed
epic: {epic-slug}
created: YYYY-MM-DD
---

# {Feature Title}

## Goal
{One sentence}

## Tasks
1. Task title (bd-{hash}.{n}.1)
2. Task title (bd-{hash}.{n}.2)

## Key Files
- file1.ts
- file2.ts
```

3. **Slug generation function:**
```bash
make_slug() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}
```

**Success criteria:**
- [ ] Templates created in `skills/install/templates/`
- [ ] Slug function documented
- [ ] Naming conventions documented in CLAUDE.md

### OBJ-002: Create migration script (missions/ → epics/)

**Goal:** Create script to migrate existing project structure.

**File:** `scripts/migrate-to-epics.sh`

**Migration logic:**
```bash
#!/bin/bash
# Migrate missions/ to epics/ structure

SPACE_AGENTS_DIR=".space-agents"

# 1. Create new structure
mkdir -p "$SPACE_AGENTS_DIR/epics"

# 2. Get or create default epic
EPIC_SLUG="space-agents-core"
mkdir -p "$SPACE_AGENTS_DIR/epics/$EPIC_SLUG/{open,in_progress,closed}"

# Create _epic.md
cat > "$SPACE_AGENTS_DIR/epics/$EPIC_SLUG/_epic.md" << EOF
---
beads_id: $(bd list --json | jq -r '.[] | select(.issue_type == "epic") | .id' | head -1)
title: Space Agents Core
status: in_progress
created: $(date +%Y-%m-%d)
---

# Space Agents Core

Migrated from legacy missions/ structure.
EOF

# 3. Migrate each mission folder
for status_dir in staged active complete; do
    for mission_dir in "$SPACE_AGENTS_DIR/missions/$status_dir"/*; do
        [ -d "$mission_dir" ] || continue

        mission_name=$(basename "$mission_dir")
        feature_slug=$(echo "$mission_name" | sed 's/^MSN-[0-9]*-//' | tr '[:upper:]' '[:lower:]')

        # Map old status to new
        case "$status_dir" in
            staged)   new_status="open" ;;
            active)   new_status="in_progress" ;;
            complete) new_status="closed" ;;
        esac

        # Move folder
        target_dir="$SPACE_AGENTS_DIR/epics/$EPIC_SLUG/$new_status/$feature_slug"
        mkdir -p "$target_dir"
        cp -r "$mission_dir"/* "$target_dir/" 2>/dev/null || true

        # Rename _mission.md to _feature.md
        if [ -f "$target_dir/_mission.md" ]; then
            mv "$target_dir/_mission.md" "$target_dir/_feature.md"
        fi

        echo "Migrated: $mission_name → $EPIC_SLUG/$new_status/$feature_slug"
    done
done

# 4. Archive old structure
mv "$SPACE_AGENTS_DIR/missions" "$SPACE_AGENTS_DIR/missions.archive"
echo "Old structure archived to missions.archive/"

# 5. Update .gitignore
echo ".space-agents/missions.archive/" >> .gitignore
```

**Success criteria:**
- [ ] Script handles staged/active/complete → open/in_progress/closed
- [ ] _mission.md files renamed to _feature.md
- [ ] Old structure archived (not deleted)
- [ ] Script is idempotent

### OBJ-003: Update skills to use new paths

**Goal:** Update all skills that reference folder paths.

**Skills to update:**

| Skill | Path Changes |
|-------|--------------|
| `/install` | Create `epics/` not `missions/` |
| `/launch` | Check for `epics/` structure |
| `/mission-brief` | Create feature in `epics/{epic}/open/` |
| `/mission-go` | Move feature to `epics/{epic}/in_progress/` on start |
| `/dock` | Move feature to `epics/{epic}/closed/` on complete |
| `/pod` | Read/write to current feature path |
| `/capcom` | Query paths within epics structure |
| `/handover` | Generate paths for epics structure |

**Path helper functions (add to beads-helpers.sh):**
```bash
get_epic_path() {
    local epic_slug="$1"
    echo ".space-agents/epics/$epic_slug"
}

get_feature_path() {
    local epic_slug="$1"
    local status="$2"  # open, in_progress, closed
    local feature_slug="$3"
    echo ".space-agents/epics/$epic_slug/$status/$feature_slug"
}

move_feature_to_status() {
    local epic_slug="$1"
    local feature_slug="$2"
    local old_status="$3"
    local new_status="$4"

    local old_path=$(get_feature_path "$epic_slug" "$old_status" "$feature_slug")
    local new_path=$(get_feature_path "$epic_slug" "$new_status" "$feature_slug")

    mkdir -p "$(dirname "$new_path")"
    mv "$old_path" "$new_path"
}
```

**Success criteria:**
- [ ] All 8 skills updated with new paths
- [ ] Path helper functions in beads-helpers.sh
- [ ] No references to `missions/staged/active/complete/`

### OBJ-004: Test migration on current project

**Goal:** Run migration on this project and verify everything works.

**Test steps:**

1. **Pre-migration backup:**
```bash
git stash
git tag pre-folder-migration
```

2. **Run migration:**
```bash
./scripts/migrate-to-epics.sh
```

3. **Verify structure:**
```bash
# Check new structure exists
ls -la .space-agents/epics/

# Check features migrated
find .space-agents/epics -name "_feature.md" | wc -l

# Check old structure archived
ls .space-agents/missions.archive/
```

4. **Test skill flow:**
```bash
# Launch should work
/launch

# Create new feature in new structure
/mission-brief "Test feature"

# Verify folder created
ls .space-agents/epics/*/open/

# Run feature
/mission-go test-feature

# Verify moved to in_progress
ls .space-agents/epics/*/in_progress/
```

5. **Verify Beads still works:**
```bash
bd list --json | jq '.[] | select(.issue_type == "feature")'
bd dep tree $(bd_get_active_epic)
```

**Success criteria:**
- [ ] All existing features migrated
- [ ] New features created in correct location
- [ ] Status changes move folders correctly
- [ ] Beads queries still work
- [ ] No data loss

## Rollback Plan

If migration fails:

```bash
# Restore old structure
rm -rf .space-agents/epics
mv .space-agents/missions.archive .space-agents/missions

# Revert skill changes
git checkout -- skills/

# Remove tag
git tag -d pre-folder-migration
```

## Key Files

**Create:**
- `scripts/migrate-to-epics.sh` - Migration script
- `skills/install/templates/_epic.md` - Epic template
- `skills/install/templates/_feature.md` - Feature template

**Modify:**
- All 8 skills with path references
- `skills/mission-go/scripts/beads-helpers.sh` - Path helper functions

**Archive (not delete):**
- `.space-agents/missions/` → `.space-agents/missions.archive/`

## Why This Structure?

Council review identified that the original MSN-007 (hash-based stable folders) added complexity without proportional benefit. This revised structure:

1. **Visual kanban** - `ls epics/auth-system/in_progress/` shows active work
2. **Epic grouping** - Features organized by parent epic
3. **Human-readable** - No hash IDs in paths
4. **Terminology aligned** - Matches Beads (epic/feature/task)
5. **Status moves** - Accepted trade-off for visual clarity

## Success Criteria

- [ ] Folder structure documented and templates created
- [ ] Migration script works on current project
- [ ] All skills updated with new paths
- [ ] Visual kanban works (can see status via folder structure)
- [ ] No data loss during migration
- [ ] Rollback plan tested

## Notes

Council review (2026-01-21): Complete rewrite. Original "stable folders with hash IDs" replaced with "epic/feature hierarchy with status kanban" per user decision. Human-readable slugs, not hash IDs in paths. Status subfolders per epic.

Second council review (2026-01-21): Fixed jq queries to use `.issue_type` not `.type`. Updated `get_active_epic` to `bd_get_active_epic`.
