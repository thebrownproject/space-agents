# Exploration: Communication & Voyages Redesign

**Date:** 2026-01-20
**Status:** Ready for implementation

---

## Summary

Simplified the communication architecture and redesigned the voyages/missions structure based on key insight: **use each tool for what it's good at** - filesystem for content/organization, database for status/queries.

---

## Communication Simplification

### Before (4 files)
```
.space-agents/comms/
├── space-agents.db
├── capcom.md          # Session log
├── handover.md        # Session handover
└── notifications.md   # Desktop notification log
```

### After (2 files)
```
.space-agents/comms/
├── space-agents.db    # Structured state
└── voyage-log.md      # Combined session log + handover + decisions
```

### Changes

| File | Action | Reasoning |
|------|--------|-----------|
| `capcom.md` | Rename → `voyage-log.md` | Combined with handover |
| `handover.md` | Merge into `voyage-log.md` | Same content, no duplication |
| `notifications.md` | Delete | Just send notifications, don't log them |

### voyage-log.md Format

Each `/dock` appends an entry that serves as both session log AND handover for next session:

```markdown
## [2026-01-20 14:30] Session End

### Summary
- Exploration session focused on communication simplification
- Decided to consolidate capcom.md and handover.md
- Redesigned voyages structure

### Current State
- No active missions
- Comms redesign explored, ready for implementation

### Next Session
- Implement the combined voyage-log format
- Or move to voyages restructure
```

**Source of truth** for the project - logs decisions, progress, context for next session.

---

## Voyages Restructure

### Key Insight

**Containment vs State** - these are separate concerns:
- **Containment** (what belongs to what) → Folders
- **State** (what status is it) → Database

Double-kanban (`voyages/active/VOY-001/missions/active/MSN-001/`) conflates these, creating 6 levels of nesting and requiring file moves on status changes.

### Before (flat missions with kanban)
```
.space-agents/
├── missions/
│   ├── staged/
│   │   └── MSN-001/
│   ├── active/
│   │   └── MSN-002/
│   └── complete/
│       └── MSN-003/
```

### After (voyages contain missions, status in DB)
```
.space-agents/
├── comms/
│   ├── space-agents.db
│   └── voyage-log.md
├── voyages/
│   └── VOY-001-mvp/
│       ├── _voyage.md           # status in frontmatter + DB
│       └── missions/
│           ├── MSN-001-auth/
│           │   ├── _mission.md  # status in frontmatter + DB
│           │   └── implementation-plan.md
│           ├── MSN-002-profiles/
│           │   └── _mission.md
│           └── MSN-003-cart/
│               └── _mission.md
└── exploration/
```

### Benefits

| Aspect | Before | After |
|--------|--------|-------|
| Depth | 6 levels (with double kanban) | 4 levels |
| Path stability | Paths change on status update | Paths never change |
| Git history | Delete + add (messy diffs) | Clean modifications |
| Mission sprawl | 100+ in one folder over time | Grouped by voyage |
| Status queries | Glob entire tree | Single DB query |

---

## Workflow

### Two Modes

**1. Batch Execution (Overnight Ralph)**
1. Create voyage "MVP" with all missions planned
2. Run Ralph loop - grinds through all missions automatically
3. Wake up to completed voyage

**2. Iterative (Mission by Mission)**
1. Create voyage "MVP" with initial missions
2. Work through mission 1
3. Realize you need mission 1b? Add it
4. Continue, adding missions as you learn
5. Voyage completes when all missions done

Both work with same structure. Voyages grow with you.

### Adding Missions to Existing Voyage

```bash
# /mission-brief can add to existing voyage
voyages/VOY-001-mvp/missions/MSN-004-payment/
```

No need to plan everything upfront.

---

## /capcom Status View

Visual progress tracking from database query:

```
────────────────────────────────────────
VOYAGE: MVP (3/5 missions complete)
────────────────────────────────────────
● MSN-001  Auth system      complete
● MSN-002  User profiles    complete
● MSN-003  Shopping cart    complete
◐ MSN-004  Checkout         active
○ MSN-005  Payment          staged
────────────────────────────────────────
Progress: ████████████░░░░░░░░ 60%
────────────────────────────────────────
```

**Status indicators:**
- `●` complete
- `◐` active / in_progress
- `○` staged / pending

---

## Database Schema Updates

### voyages table
```sql
CREATE TABLE voyages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT CHECK(status IN ('staged', 'active', 'complete')) DEFAULT 'staged',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
);
```

### missions table (updated)
```sql
CREATE TABLE missions (
    id TEXT PRIMARY KEY,
    voyage_id TEXT NOT NULL,           -- Links to voyage
    title TEXT NOT NULL,
    description TEXT,
    status TEXT CHECK(status IN ('staged', 'active', 'complete')) DEFAULT 'staged',
    priority INTEGER DEFAULT 0,        -- Order within voyage
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    FOREIGN KEY (voyage_id) REFERENCES voyages(id)
);
```

### objectives table (updated)
```sql
CREATE TABLE objectives (
    id TEXT PRIMARY KEY,
    mission_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT CHECK(status IN ('pending', 'in_progress', 'complete', 'failed', 'blocked')) DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    handover TEXT,                     -- Pod-to-Pod context (was separate file)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    FOREIGN KEY (mission_id) REFERENCES missions(id)
);
```

---

## File Structure Summary

```
.space-agents/
├── comms/
│   ├── space-agents.db          # All structured state
│   │   ├── voyages              # Epic-level containers
│   │   ├── missions             # Work chunks within voyages
│   │   ├── objectives           # Tasks within missions
│   │   ├── alerts               # Operational issues (ralph.sh only)
│   │   └── issues               # Code quality findings (future)
│   │
│   └── voyage-log.md            # Session log + handover + decisions
│
├── voyages/
│   └── <voyage-id>/
│       ├── _voyage.md           # Voyage definition, goals
│       └── missions/
│           └── <mission-id>/
│               ├── _mission.md
│               └── implementation-plan.md
│
└── exploration/
    └── <date>-<topic>/
        └── exploration.md
```

---

## Migration Path

### Phase 1: Communication
1. Rename `capcom.md` → `voyage-log.md`
2. Merge `handover.md` content into voyage-log format
3. Delete `notifications.md`
4. Update `/launch` to read from `voyage-log.md`
5. Update `/dock` to write combined format

### Phase 2: Voyages Structure
1. Create `voyages/` folder
2. Add `voyage_id` to missions table
3. Migrate existing missions into default voyage
4. Update `/mission-brief` to create within voyages
5. Update `/capcom` to show voyage progress view
6. Remove old `missions/staged|active|complete` structure

### Phase 3: Issues System (from previous exploration)
1. Add `issues` table
2. Update Analyst to write directly to issues
3. Remove `[ALERT:...]` text parsing

---

## Open Questions

1. **Default voyage** - What happens if user creates mission without specifying voyage? Auto-create "default" voyage?
2. **Voyage completion** - Auto-complete voyage when all missions complete? Or manual?
3. **Voyage archival** - Move completed voyages somewhere? Or leave in place?

---

## Next Steps

1. `/mission-brief` to implement voyage-aware mission creation
2. Update `/capcom` with voyage progress view
3. Implement communication simplification (voyage-log.md)
4. Migration script for existing projects
