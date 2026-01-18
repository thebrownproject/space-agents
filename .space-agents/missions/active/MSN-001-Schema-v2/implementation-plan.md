# SQLite Schema v2 Implementation Plan

**Mission:** MSN-001
**Created:** 2026-01-18
**Status:** Ready for execution

---

## Objectives

| # | Objective | Est. | Status |
|---|-----------|------|--------|
| 1 | Update init-db.sql schema | 30 min | pending |
| 2 | Update agent alert INSERTs | 45 min | pending |
| 3 | Update skill queries | 30 min | pending |

---

## Sequence

```
1. init-db.sql ──────────────────────────────┐
                                              ├──> Re-run /install
2. Agent alert INSERTs (depends on #1) ──────┤
                                              │
3. Skill queries (parallel with #2) ─────────┘
```

---

## Objective 1: Update init-db.sql Schema

**Goal:** Update schema definition for fresh installs

**Files:**
- Modify: `skills/install/scripts/init-db.sql`

**Tasks:**

1. **Update voyages table**
   ```sql
   CREATE TABLE IF NOT EXISTS voyages (
       id TEXT PRIMARY KEY,
       title TEXT NOT NULL,
       description TEXT,
       settings TEXT,
       created_at DATETIME DEFAULT CURRENT_TIMESTAMP
   );
   ```
   - Add: `description TEXT`, `settings TEXT`
   - Remove: `status`, `notified`

2. **Update alerts table**
   ```sql
   CREATE TABLE IF NOT EXISTS alerts (
       id TEXT PRIMARY KEY,
       timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
       severity INTEGER CHECK(severity IN (0, 1, 2, 3)),
       mission_id TEXT NOT NULL REFERENCES missions(id),
       objective_id TEXT REFERENCES objectives(id),
       source TEXT NOT NULL,
       description TEXT NOT NULL,
       status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
       cleared_at DATETIME
   );
   ```
   - Add: `mission_id TEXT NOT NULL REFERENCES missions(id)`
   - Keep: `objective_id` as nullable

3. **Add mission_id index**
   ```sql
   CREATE INDEX IF NOT EXISTS idx_alerts_mission
   ON alerts(mission_id, status);
   ```

4. **Verify**
   ```bash
   rm -f /tmp/test-schema.db
   sqlite3 /tmp/test-schema.db < skills/install/scripts/init-db.sql
   sqlite3 /tmp/test-schema.db ".schema voyages"
   sqlite3 /tmp/test-schema.db ".schema alerts"
   ```

5. **Commit:** `feat(schema): update init-db.sql to v2 schema`

---

## Objective 2: Update Agent Alert INSERTs

**Goal:** Update alert creation to include mission_id

**Files:**
- Modify: `skills/mission/scripts/ralph.sh`
- Modify: `agents/mission-pod.md`
- Modify: `agents/mission-analyst.md`

**Tasks:**

1. **Update ralph.sh create_alert function**
   - Change signature: `create_alert(severity, mission_id, objective_id, source, description)`
   - Update INSERT to include `mission_id`

2. **Update ralph.sh call sites**
   - Find all `create_alert` calls
   - Add `mission_id` parameter to each

3. **Update mission-pod.md INSERT statement**
   ```sql
   INSERT INTO alerts (id, severity, mission_id, objective_id, source, description, status)
   VALUES ('<id>', <severity>, '<mission_id>', '<objective_id>', '<crew_member>', '<description>', 'active');
   ```

4. **Update mission-analyst.md INSERT statement**
   ```sql
   INSERT INTO alerts (id, severity, mission_id, objective_id, source, description)
   VALUES ('ALT-XXX', 2, '<mission_id>', '<objective_id>', 'Analyst', '<description>');
   ```

5. **Verify ralph.sh syntax**
   ```bash
   bash -n skills/mission/scripts/ralph.sh
   ```

6. **Commit:** `feat(alerts): update alert INSERTs to include mission_id`

---

## Objective 3: Update Skill Queries

**Goal:** Update read queries to use new schema

**Files:**
- Modify: `skills/launch/SKILL.md`
- Modify: `skills/capcom/SKILL.md`
- Modify: `skills/handover/SKILL.md`

**Tasks:**

1. **Update /launch**
   - Project name query: `SELECT title FROM voyages LIMIT 1;`

2. **Update /capcom alert query**
   ```sql
   SELECT a.id, a.severity, a.source, a.description,
          m.title as mission_title
   FROM alerts a
   LEFT JOIN missions m ON a.mission_id = m.id
   WHERE a.status = 'active'
   ORDER BY a.severity;
   ```

3. **Update /handover alert query**
   - Same JOIN pattern as capcom

4. **Commit:** `docs(skills): update queries for v2 schema`

---

## Post-Implementation

After all objectives complete:

1. **Delete old database**
   ```bash
   rm .space-agents/space-agents.db
   ```

2. **Re-run install**
   ```bash
   sqlite3 .space-agents/space-agents.db < skills/install/scripts/init-db.sql
   ```

3. **Insert project voyage**
   ```sql
   INSERT INTO voyages (id, title, description)
   VALUES ('VOY-001', 'space-agents', 'Claude Code plugin for mission-based development');
   ```

4. **Verify**
   ```bash
   sqlite3 .space-agents/space-agents.db ".schema"
   ```

---

## Success Criteria

- [ ] Fresh database has voyages with description, settings columns
- [ ] Fresh database has alerts with mission_id NOT NULL
- [ ] ralph.sh passes syntax check
- [ ] /launch displays project name from voyages.title
