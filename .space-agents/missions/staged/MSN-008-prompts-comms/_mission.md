# MSN-008-prompts-comms: Agent Prompts and Communications

**Status:** Staged
**Created:** 2026-01-21
**Revised:** 2026-01-21 (Council Review + Beads CLI Verification)

## Goal

Update all 9 agent prompts with Beads terminology and consolidate communications into voyage-log.md following Land the Plane protocol.

## Prerequisites

- **MSN-004 through MSN-007 complete** (system stable)
- Beads integration working
- New folder structure in place

## Objectives (6 total)

1. **OBJ-001** - Update planning agent prompts (3 files)
2. **OBJ-002** - Update execution agent prompts (3 files) + rename
3. **OBJ-003** - Update exploration agent prompts (3 files)
4. **OBJ-004** - Rename capcom.md → voyage-log.md and update references
5. **OBJ-005** - Update /dock skill with Land the Plane format
6. **OBJ-006** - Validation sweep (grep for old terms)

## Execution Sequence

```
OBJ-001 ─┐
OBJ-002 ─┼─→ OBJ-004 → OBJ-005 → OBJ-006
OBJ-003 ─┘
```

- OBJ-001, OBJ-002, OBJ-003: **Parallelizable** (independent file groups)
- OBJ-004: After terminology changes finalized
- OBJ-005: After voyage-log.md created
- OBJ-006: Last (validation)

## Terminology Changes

### Entity Terminology
| Old Term | New Term | Beads Type |
|----------|----------|------------|
| voyages | epics | `epic` |
| missions | features | `feature` |
| objectives | tasks | `task` |
| alerts | bugs | `bug` |

### Status Terminology
| Old Term | New Term | Beads Status |
|----------|----------|--------------|
| staged | open | `open` |
| active | in_progress | `in_progress` |
| complete | closed | `closed` |

### File/Agent Renames
| Old Name | New Name |
|----------|----------|
| mission-worker.md | feature-worker.md |
| mission-inspector.md | feature-inspector.md |
| mission-analyst.md | feature-analyst.md |

## Objective Details

### OBJ-001: Update planning agent prompts

**Goal:** Update terminology and add bd CLI examples to planning agents.

**Files:**
- `agents/planning-task-planner.md`
- `agents/planning-sequencer.md`
- `agents/planning-implementer.md`

**Changes per file:**

**planning-task-planner.md:**
- Line 3: `Break a mission into objectives` → `Break a feature into tasks`
- Line 12-14: Update hierarchy (Voyage→Epic, Mission→Feature, Objective→Task)
- Line 22: `Break the mission into 3-5 objectives` → `Break the feature into 3-5 tasks`
- Add bd CLI examples section

**planning-sequencer.md:**
- Line 3: `sequence objectives` → `sequence tasks`
- Lines 29-31: `Obj 1, Obj 2, Obj 3` → `Task 1, Task 2, Task 3`
- Add `bd dep add` examples

**planning-implementer.md:**
- Line 3: `task breakdown for objectives` → `task breakdown for tasks`
- Line 16: `For each objective` → `For each task`
- Add TDD examples with bd commands

**Success criteria:**
- [ ] No "mission" or "objective" terms in planning agents
- [ ] bd CLI examples present
- [ ] Terminology consistent

### OBJ-002: Update execution agent prompts + rename files

**Goal:** Update terminology, add Beads examples, rename files.

**Files to rename:**
- `agents/mission-worker.md` → `agents/feature-worker.md`
- `agents/mission-inspector.md` → `agents/feature-inspector.md`
- `agents/mission-analyst.md` → `agents/feature-analyst.md`

**Changes:**

**feature-worker.md (178 lines - most changes):**
- Line 1: `name: worker` → `name: feature-worker`
- Line 17-21: Update context terms (objective→task, mission→feature)
- Lines 107-140: `[ALERT:severity]` → `[BUG:severity]`
- Line 99: `SQLite persistence` → `Beads persistence`
- Add bd update/close examples

**feature-inspector.md:**
- Line 3: `objective requirements` → `task requirements`
- Lines 54-69: `[ALERT:severity]` → `[BUG:severity]`
- Line 72: Remove SQLite reference

**feature-analyst.md:**
- Lines 70-93: `[ALERT:severity]` → `[BUG:severity]`
- Line 96: Remove SQLite reference

**Success criteria:**
- [ ] Files renamed
- [ ] No "mission" or "objective" terms
- [ ] `[ALERT:]` → `[BUG:]` format
- [ ] SQLite references removed

### OBJ-003: Update exploration agent prompts

**Goal:** Update terminology in exploration agents (minimal changes).

**Files:**
- `agents/exploration-research.md`
- `agents/exploration-architecture.md`
- `agents/exploration-risk.md`

**Note:** Council review found minimal terminology in these files. Mostly generic terms like "request", "findings", "patterns".

**Changes needed:**
- Search for any "mission", "objective", "alert" terms
- Update if found
- Add brief Beads context note if appropriate

**Success criteria:**
- [ ] grep -r "mission\|objective\|alert" returns 0 hits
- [ ] Files consistent with new terminology

### OBJ-004: Rename capcom.md → voyage-log.md

**Goal:** Rename communications file and update all references.

**DO NOT DELETE** - capcom.md has valuable session history (10+ sessions).

**Steps:**
1. Rename file:
```bash
mv .space-agents/comms/capcom.md .space-agents/comms/voyage-log.md
```

2. Update file header:
```markdown
# Voyage Log

*Append-only session log. Each session ends with Land the Plane entry.*

---

<!-- Previous sessions preserved below -->
```

3. Update references in skills (16 locations):
   - `skills/dock/skill.md`
   - `skills/handover/skill.md`
   - `skills/install/skill.md`
   - `skills/launch/skill.md`
   - `skills/capcom/skill.md`
   - `commands/run-capcom.md`

4. Update grep patterns:
```bash
grep -rn "capcom.md" skills/ commands/
# Replace all with voyage-log.md
```

**Success criteria:**
- [ ] voyage-log.md exists with preserved history
- [ ] capcom.md no longer exists
- [ ] All skill references updated
- [ ] No broken references

### OBJ-005: Update /dock skill with Land the Plane format

**Goal:** Implement the Land the Plane protocol in /dock.

**File:** `skills/dock/skill.md`

**Land the Plane session entry format:**
```markdown
## [YYYY-MM-DD HH:MM] Session End

### Summary
- Completed feature bd-xxxx (description)
- Fixed N bugs discovered by Airlock
- Created N new tasks for next feature

### Current State
- Active features: N (list)
- Open tasks: N
- Open bugs: N

### Next Session
Context for fresh agent:
- Continue with bd-xxxx (Feature Name)
- Run: `bd ready` to see next task
- Reference: `bd dep tree <epic>` for full picture
```

**Dock skill must:**
1. Query Beads for session statistics
2. Generate structured summary
3. Append to voyage-log.md
4. Run `bd sync`
5. Generate handover context

**Success criteria:**
- [ ] /dock appends Land the Plane entry to voyage-log.md
- [ ] Entry includes bd commands for next session
- [ ] `bd sync` called at end

### OBJ-006: Validation sweep

**Goal:** Verify no old terminology remains in codebase.

**Validation commands:**
```bash
# Should return 0 hits (excluding this file and archives)
grep -rn "mission" agents/ skills/ --include="*.md" | grep -v "mission.archive" | grep -v "_mission.md"
grep -rn "objective" agents/ skills/ --include="*.md"
grep -rn "voyage" agents/ skills/ --include="*.md" | grep -v "voyage-log"
grep -rn "\[ALERT:" agents/ --include="*.md"
grep -rn "sqlite3\|SQLite" agents/ skills/ --include="*.md"
grep -rn "capcom.md" skills/ commands/ --include="*.md"
```

**Acceptable exceptions:**
- Historical context explaining old system
- voyage-log.md filename
- missions.archive references

**Success criteria:**
- [ ] All greps return 0 hits (or documented exceptions)
- [ ] Terminology consistent across codebase

## Key Files

**Rename:**
- `agents/mission-worker.md` → `agents/feature-worker.md`
- `agents/mission-inspector.md` → `agents/feature-inspector.md`
- `agents/mission-analyst.md` → `agents/feature-analyst.md`
- `.space-agents/comms/capcom.md` → `.space-agents/comms/voyage-log.md`

**Modify:**
- All 9 agent prompts (terminology)
- `skills/dock/skill.md` (Land the Plane)
- Skills referencing capcom.md (16 locations)

**Delete (after validation):**
- `.space-agents/comms/handover.md` - merged into voyage-log.md context

**DO NOT DELETE:**
- `.space-agents/comms/notifications.md` - still used by ralph.sh (line 140)

## Agent Prompts Summary

| Agent | Category | Changes |
|-------|----------|---------|
| planning-task-planner.md | Planning | Terminology + bd create examples |
| planning-sequencer.md | Planning | Terminology + bd dep add examples |
| planning-implementer.md | Planning | Terminology |
| feature-worker.md | Execution | Rename + terminology + [BUG:] format |
| feature-inspector.md | Execution | Rename + terminology + [BUG:] format |
| feature-analyst.md | Execution | Rename + terminology + [BUG:] format |
| exploration-research.md | Exploration | Minimal (verify clean) |
| exploration-architecture.md | Exploration | Minimal (verify clean) |
| exploration-risk.md | Exploration | Minimal (verify clean) |

## Success Criteria

- [ ] All 9 agent prompts use feature/task terminology
- [ ] Prompts include bd CLI examples where relevant
- [ ] [ALERT:] → [BUG:] format in all agents
- [ ] voyage-log.md implements Land the Plane format
- [ ] No references to old terminology in codebase
- [ ] Validation grep returns 0 unexpected hits
- [ ] Agent files renamed (mission-* → feature-*)

## Notes

Council review (2026-01-21): Expanded from 4 to 6 objectives. OBJ-004 split out (was too large). Added explicit file renames. Changed "delete capcom.md" to "rename to voyage-log.md" to preserve history. Added validation sweep objective.

Second council review (2026-01-21): Removed notifications.md from deletion list - ralph.sh still uses it (line 140 writes to it). Must keep or update ralph.sh first.
