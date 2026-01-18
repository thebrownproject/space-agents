-- Space-Agents Schema Migration: v1 → v2
-- ============================================================================
-- Changes:
--   1. Remove messages table
--   2. Add worker_attempts to objectives
--   3. Change objectives to composite primary key (mission_id, id)
--   4. Renumber objectives per-mission (OBJ-001, OBJ-002... per mission)
-- ============================================================================

-- Step 1: Drop messages table
DROP TABLE IF EXISTS messages;

-- Step 2: Create new objectives table with composite key
CREATE TABLE objectives_new (
    id TEXT NOT NULL,
    mission_id TEXT NOT NULL REFERENCES missions(id),
    title TEXT NOT NULL,
    description TEXT,
    status TEXT CHECK(status IN ('pending', 'in_progress', 'complete', 'failed')),
    priority INTEGER DEFAULT 0,
    worker_attempts INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    PRIMARY KEY (mission_id, id)
);

-- Step 3: Migrate MSN-001 objectives (already OBJ-001, OBJ-002, OBJ-003)
INSERT INTO objectives_new (id, mission_id, title, description, status, priority, worker_attempts, created_at, completed_at)
SELECT id, mission_id, title, description, status, priority, 0, created_at, completed_at
FROM objectives
WHERE mission_id = 'MSN-001-Schema-v2';

-- Step 4: Migrate MSN-002 objectives (renumber OBJ-004→OBJ-001, etc.)
INSERT INTO objectives_new (id, mission_id, title, description, status, priority, worker_attempts, created_at, completed_at)
SELECT
    'OBJ-00' || (CAST(SUBSTR(id, 5) AS INTEGER) - 3),
    mission_id, title, description, status, priority, 0, created_at, completed_at
FROM objectives
WHERE mission_id = 'MSN-002-Visible-Pods';

-- Step 5: Update alerts to reference new objective IDs for MSN-002
UPDATE alerts
SET objective_id = 'OBJ-00' || (CAST(SUBSTR(objective_id, 5) AS INTEGER) - 3)
WHERE mission_id = 'MSN-002-Visible-Pods' AND objective_id IS NOT NULL;

-- Step 6: Drop old table, rename new
DROP TABLE objectives;
ALTER TABLE objectives_new RENAME TO objectives;

-- Step 7: Recreate index
CREATE INDEX IF NOT EXISTS idx_objectives_pending
ON objectives(mission_id, status, priority)
WHERE status = 'pending';

-- Step 8: Update alerts foreign key (recreate table for proper FK)
CREATE TABLE alerts_new (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),
    mission_id TEXT NOT NULL REFERENCES missions(id),
    objective_id TEXT,
    source TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME,
    FOREIGN KEY (mission_id, objective_id) REFERENCES objectives(mission_id, id)
);

INSERT INTO alerts_new SELECT * FROM alerts;
DROP TABLE alerts;
ALTER TABLE alerts_new RENAME TO alerts;

-- Step 9: Recreate alerts indexes
CREATE INDEX IF NOT EXISTS idx_alerts_mission ON alerts(mission_id, status);
CREATE INDEX IF NOT EXISTS idx_alerts_active ON alerts(severity, status) WHERE status = 'active';

-- Done!
