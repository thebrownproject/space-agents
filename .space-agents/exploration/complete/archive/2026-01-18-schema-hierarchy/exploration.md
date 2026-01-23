# SQLite Schema: Hierarchy Alignment

**Date:** 2026-01-18
**Status:** Ready for implementation

---

## Summary

Align the SQLite schema with the clarified hierarchy:
- **Voyage** = Project (one per installation)
- **Mission** = Feature
- **Objective** = Task

---

## Schema Changes

### voyages table (→ project)

**Current:**
```sql
CREATE TABLE voyages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('planning', 'active', 'complete', 'archived')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    notified INTEGER DEFAULT 0
);
```

**New:**
```sql
CREATE TABLE voyages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    settings TEXT,  -- JSON blob for project config
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Changes:**
- Add `description` - project description
- Add `settings` - JSON for project-level config
- Remove `status` - project is always "active"
- Remove `notified` - not applicable to project
- Single row enforced by convention (created by `/install`)

---

### missions table

**No changes.** Current schema works for features.

---

### objectives table

**No changes.** Current schema works for tasks.

---

### alerts table

**Current:**
```sql
CREATE TABLE alerts (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),
    objective_id TEXT REFERENCES objectives(id),
    source TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME
);
```

**New:**
```sql
CREATE TABLE alerts (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),
    mission_id TEXT NOT NULL REFERENCES missions(id),
    objective_id TEXT REFERENCES objectives(id),  -- nullable
    source TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME
);
```

**Changes:**
- Add `mission_id NOT NULL` - alerts always belong to a mission (feature)
- Keep `objective_id` nullable - optionally scoped to specific task

**Rationale:** Alerts like "tests failing" affect the whole feature, not just one task. Mission-level gives context; objective-level gives granularity when needed.

---

### messages table

**No changes.** Messages are task-level activity logs (started, completed, failed, feedback). Always tied to objectives.

---

## Query Updates

### /launch - Get project name

**Old:** `SELECT value FROM settings WHERE key = 'project_name';`

**New:** `SELECT title FROM voyages LIMIT 1;`

---

## Migration Notes

1. **Voyages:** Add columns, drop columns, ensure single row exists
2. **Alerts:** Add `mission_id` column, backfill from `objective_id → mission_id` join
3. **Skills to update:** `/launch` query, any alerts-related queries

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Voyages table naming | Keep "voyages" | Maintains space theme |
| Single project enforcement | Convention only | Simple, no complex constraints |
| Project settings storage | JSON in voyages.settings | Avoids separate settings table |
| Alert scope | Mission required, objective optional | Alerts are feature-level with optional task granularity |
| Messages scope | Objective only | Messages are task-level activity logs |

---

## Next Step

`/mission-brief` to plan the implementation.
