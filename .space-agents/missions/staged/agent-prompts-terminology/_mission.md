# MSN-008-prompts-comms: Agent Prompts and Terminology

**Status:** Staged
**Created:** 2026-01-21
**Revised:** 2026-01-21 (Simplified - removed folder/rename objectives)

## Goal

Update all 9 agent prompts with Beads terminology. Change mission→feature, objective→task, alert→bug throughout.

## Prerequisites

- MSN-006 complete (execution skills use Beads)
- Beads integration working

## Objectives (4 total)

1. **OBJ-001** - Update planning agent prompts (3 files)
2. **OBJ-002** - Update execution agent prompts (3 files) + rename
3. **OBJ-003** - Update exploration agent prompts (3 files)
4. **OBJ-004** - Validation sweep

## Execution Sequence

```
OBJ-001 ─┐
OBJ-002 ─┼─→ OBJ-004 (validation)
OBJ-003 ─┘
```

- OBJ-001, OBJ-002, OBJ-003: **Parallelizable** (independent file groups)
- OBJ-004: Last (validation sweep)

---

## Terminology Changes

### Entity Terminology
| Old Term | New Term | Beads Type |
|----------|----------|------------|
| mission | feature | `feature` |
| objective | task | `task` |
| alert | bug | `bug` |

### Status Terminology
| Old Term | New Term | Beads Status |
|----------|----------|--------------|
| staged | open | `open` |
| active | in_progress | `in_progress` |
| complete | closed | `closed` |

### Format Changes
| Old | New |
|-----|-----|
| `[ALERT:severity]` | `[BUG:severity]` |

---

## OBJ-001: Update planning agent prompts

**Goal:** Update terminology and add bd CLI examples to planning agents.

**Files:**
- `agents/planning-task-planner.md`
- `agents/planning-sequencer.md`
- `agents/planning-implementer.md`

### Changes

**planning-task-planner.md:**
- `mission` → `feature`
- `objective` → `task`
- Add bd CLI examples for creating tasks

**planning-sequencer.md:**
- `objective` → `task`
- Add `bd dep add` examples

**planning-implementer.md:**
- `objective` → `task`
- `mission` → `feature`

### Verification
```bash
grep -n "mission\|objective" agents/planning-*.md
# Expected: 0 hits
```

### Success Criteria
- [ ] No "mission" or "objective" terms in planning agents
- [ ] bd CLI examples present
- [ ] Terminology consistent

---

## OBJ-002: Update execution agent prompts + rename files

**Goal:** Update terminology, change alert format, rename files.

**Files to rename:**
- `agents/mission-worker.md` → `agents/feature-worker.md`
- `agents/mission-inspector.md` → `agents/feature-inspector.md`
- `agents/mission-analyst.md` → `agents/feature-analyst.md`

### Changes

**All three files:**
- `mission` → `feature`
- `objective` → `task`
- `[ALERT:severity]` → `[BUG:severity]`
- Remove SQLite references

### Verification
```bash
# Check renames
ls agents/feature-*.md

# Check terminology
grep -n "mission\|objective\|\[ALERT:" agents/feature-*.md
# Expected: 0 hits
```

### Success Criteria
- [ ] Files renamed to `feature-*.md`
- [ ] No "mission" or "objective" terms
- [ ] `[ALERT:]` → `[BUG:]` format
- [ ] SQLite references removed

---

## OBJ-003: Update exploration agent prompts

**Goal:** Verify/update terminology in exploration agents (minimal expected changes).

**Files:**
- `agents/exploration-research.md`
- `agents/exploration-architecture.md`
- `agents/exploration-risk.md`

### Changes

Search and update any:
- `mission` → `feature`
- `objective` → `task`
- `alert` → `bug`

### Verification
```bash
grep -n "mission\|objective\|alert" agents/exploration-*.md
# Expected: 0 hits (or acceptable context)
```

### Success Criteria
- [ ] No old terminology in exploration agents
- [ ] Files consistent with new terminology

---

## OBJ-004: Validation sweep

**Goal:** Verify no old terminology remains anywhere.

### Validation Commands
```bash
# Check agents
grep -rn "mission" agents/ --include="*.md"
grep -rn "objective" agents/ --include="*.md"
grep -rn "\[ALERT:" agents/ --include="*.md"

# Check skills
grep -rn "mission" skills/ --include="*.md" | grep -v "_mission.md"
grep -rn "objective" skills/ --include="*.md"
grep -rn "\[ALERT:" skills/ --include="*.md"

# Check for SQLite
grep -rn "sqlite3\|SQLite" agents/ skills/ --include="*.md"
```

### Acceptable Exceptions
- Historical context explaining old system
- `_mission.md` filenames (legacy)
- Archive references

### Success Criteria
- [ ] All greps return 0 hits (or documented exceptions)
- [ ] Terminology consistent across codebase

---

## Agent Prompts Summary

| Agent | Category | Changes |
|-------|----------|---------|
| planning-task-planner.md | Planning | Terminology + bd create examples |
| planning-sequencer.md | Planning | Terminology + bd dep add examples |
| planning-implementer.md | Planning | Terminology |
| feature-worker.md | Execution | Rename + terminology + [BUG:] format |
| feature-inspector.md | Execution | Rename + terminology + [BUG:] format |
| feature-analyst.md | Execution | Rename + terminology + [BUG:] format |
| exploration-research.md | Exploration | Verify clean |
| exploration-architecture.md | Exploration | Verify clean |
| exploration-risk.md | Exploration | Verify clean |

---

## Success Criteria

- [ ] All 9 agent prompts use feature/task terminology
- [ ] Prompts include bd CLI examples where relevant
- [ ] `[ALERT:]` → `[BUG:]` format in all agents
- [ ] No references to old terminology in codebase
- [ ] Validation grep returns 0 unexpected hits
- [ ] Agent files renamed (mission-* → feature-*)

## Rollback Plan

```bash
git checkout -- agents/
```

## Notes

Revised 2026-01-21: Simplified from 6 to 4 objectives. Removed OBJ-004 (capcom.md rename - not doing), removed OBJ-005 (/dock update - already done). Focus is purely on terminology consistency.
