# Exploration: Integration Test

**Date:** 2026-01-18
**Topic:** Full workflow integration test (exploration → mission-brief → mission-go)

---

## Context

Following the v1.0.14 release which introduced:
- /pod skill (replacing mission-pod agent)
- Composite primary keys for objectives (mission_id + id)
- Per-mission objective IDs (OBJ-001 resets per mission)
- Handover files for inter-Pod context

The handover explicitly called for a full integration test of the complete workflow.

---

## Test Design

### Test Payload

Create a throwaway todo app in `test-frontend/` at project root:
- `index.html` - Structure
- `style.css` - Styling
- `app.js` - Functionality

**Why this payload:**
- Real file creation (not mocked)
- Naturally divisible into objectives
- Easy visual verification (open in browser)
- Safe to delete after test

### Success Criteria

1. **Files exist**: `test-frontend/{index.html, style.css, app.js}`
2. **App works**: Opening index.html shows functional todo list
3. **DB correct**: All objectives show `status='completed'` in SQLite

### Failure Mode

Document issues and continue manually. This session is about understanding what works, not necessarily fixing everything.

---

## Pre-Flight Audit

Research agent audited ralph.sh and /pod skill before testing.

### What Works

- **Composite keys correct**: All SQL queries use `WHERE mission_id = X AND id = Y`
- **Schema solid**: objectives table has `PRIMARY KEY (mission_id, id)`
- **Ralph invocation**: Uses `Run /pod ${objective_id} ${mission_id}` format
- **Status updates**: mark_objective_complete/failed use composite keys

### Known Issues

1. **Filename inconsistency**: `/skills/pod/skill.md` uses lowercase while all other skills use `SKILL.md`. May not load on case-sensitive filesystems.

2. **Handovers untested**: Despite 2 complete missions with 7 objectives, no Pod handover files exist in `.space-agents/missions/`. The handover mechanism has never been exercised in production.

3. **macOS masking**: Case-insensitive filesystem may hide the filename bug that would break on Linux/CI.

---

## Architecture (For Test Mission)

### Components

| Component | Purpose | Location |
|-----------|---------|----------|
| /exploration | This exploration | Current session |
| /mission-brief | Define objectives | Next step |
| /mission-go | Execute via ralph.sh | Runs Pods |
| /pod | Execute single objective | Invoked by ralph |

### Data Flow

```
/mission-brief
    └── Creates mission in SQLite (status: staged)
    └── Creates objectives (status: pending)
    └── Writes mission file to missions/staged/

User activates mission
    └── Mission moves to missions/active/
    └── Status → active

/mission-go (ralph.sh)
    └── Queries pending objectives ORDER BY priority
    └── For each objective:
        └── spawn_pod: "Run /pod OBJ-XXX MSN-XXX"
        └── Wait for completion
        └── Update status in DB
    └── On all complete: Move to missions/complete/

/pod
    └── Queries objective details
    └── Runs Worker → Inspector → Analyst
    └── Writes handover to missions/active/<msn>/handovers/
    └── Updates objective status
```

### Error Handling

- Pod failures create blocker alerts
- ralph.sh has retry logic (configurable)
- Visible mode (mprocs) allows live debugging

---

## Testing Approach

Run the test as-is without fixing pre-identified issues:
- If filename case matters, we'll discover it
- If handovers don't write, we'll know immediately
- Document everything for post-test analysis

---

## Next Step

Run `/mission-brief` to define the test mission with objectives for:
1. Create folder structure and HTML skeleton
2. Add CSS styling
3. Add JavaScript functionality
4. (Optional) Cleanup objective

---

*Exploration complete. Ready for /mission-brief.*
