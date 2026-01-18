-- Space-Agents SQLite Schema
-- ============================================================================
-- Usage: sqlite3 .space-agents/space-agents.db < init-db.sql
-- ============================================================================
-- Tables: voyages, missions, objectives, alerts
-- Designed for idempotent execution (CREATE IF NOT EXISTS)
-- ============================================================================

-- Voyages (project - one per installation)
CREATE TABLE IF NOT EXISTS voyages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    settings TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Missions (features)
CREATE TABLE IF NOT EXISTS missions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('staged', 'active', 'complete', 'failed')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Objectives (stories/tasks)
-- Composite key: (mission_id, id) allows OBJ-001 in each mission
CREATE TABLE IF NOT EXISTS objectives (
    id TEXT NOT NULL,                -- OBJ-001, OBJ-002... (resets per mission)
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

-- Alerts (Gas Town severity pattern)
-- Severity: 0=critical, 1=blocker, 2=warning, 3=info
CREATE TABLE IF NOT EXISTS alerts (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),
    mission_id TEXT NOT NULL REFERENCES missions(id),
    objective_id TEXT,               -- References composite key with mission_id
    source TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME,
    FOREIGN KEY (mission_id, objective_id) REFERENCES objectives(mission_id, id)
);

-- Index for alerts by mission
CREATE INDEX IF NOT EXISTS idx_alerts_mission
ON alerts(mission_id, status);

-- Index for quick pending objective queries
CREATE INDEX IF NOT EXISTS idx_objectives_pending
ON objectives(mission_id, status, priority)
WHERE status = 'pending';

-- Index for active alerts by severity
CREATE INDEX IF NOT EXISTS idx_alerts_active
ON alerts(severity, status)
WHERE status = 'active';
