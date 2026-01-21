# MSN-008-prompts-comms: Agent Prompts and Communications

**Status:** Staged
**Created:** 2026-01-21

## Goal

Update all 9 agent prompts with Beads terminology and consolidate communications into voyage-log.md following Land the Plane protocol.

## Objectives

1. OBJ-001 - Update planning agent prompts
2. OBJ-002 - Update execution agent prompts
3. OBJ-003 - Update exploration agent prompts
4. OBJ-004 - Implement voyage-log.md consolidation

## Terminology Changes

| Old Term | New Term | Beads Type |
|----------|----------|------------|
| voyages | epics | `epic` |
| missions | features | `feature` |
| objectives | tasks | `task` |
| alerts | bugs | `bug` |
| staged | open | status |
| active | in_progress | status |
| complete | closed | status |

## Agent Prompt Updates

**Planning Agents (add bd create examples):**
- planning-sequencer.md
- planning-implementer.md
- planning-task-planner.md

**Execution Agents (add bd update/close/sync):**
- mission-worker.md → consider rename to feature-worker.md
- mission-inspector.md
- mission-analyst.md

**Exploration Agents (terminology only):**
- exploration-research.md
- exploration-architecture.md
- exploration-risk.md

## Land the Plane Protocol (voyage-log.md)

From Beads research - every session ends cleanly:

```markdown
## [2026-01-21 14:30] Session End

### Summary
- Completed feature bd-a3f8.1 (JWT implementation)
- Fixed 2 bugs discovered by Airlock
- Created 3 new tasks for next feature

### Current State
- Active features: 1 (bd-a3f8.2)
- Open tasks: 4
- Open bugs: 0

### Next Session
Context for fresh agent:
- Continue with bd-a3f8.2 (User Profiles)
- Run: bd ready to see next task
- Reference: bd dep tree bd-a3f8 for full picture
```

## Files to Delete

- `.space-agents/comms/capcom.md` → merged into voyage-log.md
- `.space-agents/comms/handover.md` → merged into voyage-log.md
- `.space-agents/comms/notifications.md` → not needed

## Dependencies

- MSN-004 through MSN-007 (system stable before terminology sweep)

## Success Criteria

- [ ] All 9 agent prompts use feature/task terminology
- [ ] Prompts include bd CLI examples where relevant
- [ ] voyage-log.md implements Land the Plane format
- [ ] No references to old terminology in codebase
- [ ] grep -r "mission\|objective" agents/ returns 0 hits (except in context of explaining old system)
