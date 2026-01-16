# /launch - Space-Agents Session Start

Initialize a Space-Agents session. Sets up project structure, database, and displays the mission control welcome screen.

---

## Behavior

When the user runs `/launch`:

1. **Initialize project structure** if `.space-agents/` does not exist
2. **Initialize SQLite database** if `space-agents.db` does not exist
3. **Query current state** from SQLite (voyages, missions, objectives, alerts)
4. **Display welcome screen** with live statistics
5. **Load staging.md** if it exists (session continuity)
6. **Adopt HOUSTON persona** for the remainder of the session

---

## Step 1: Initialize Project Structure

Check if `.space-agents/` exists. If not, create the full directory structure:

```bash
# Create directory structure
mkdir -p .space-agents/scripts
mkdir -p .space-agents/missions/todo
mkdir -p .space-agents/missions/active
mkdir -p .space-agents/missions/complete

# Create empty files
touch .space-agents/capcom.md
touch .space-agents/staging.md
touch .space-agents/notifications
```

**Directory structure to create:**

```
.space-agents/
├── space-agents.db          # Created in Step 2
├── capcom.md                # Master CAPCOM log (append-only)
├── staging.md               # Session buffer
├── notifications            # Cross-session alerts
├── scripts/
│   ├── ralph.sh             # Copy from plugin (if available)
│   └── airlock.sh           # Copy from plugin (if available)
└── missions/
    ├── todo/                # Planned voyages
    ├── active/              # In-progress work
    └── complete/            # Finished (archived)
```

---

## Step 2: Initialize SQLite Database

If `.space-agents/space-agents.db` does not exist, create and initialize it:

```bash
sqlite3 .space-agents/space-agents.db < scripts/init-db.sql
```

If `scripts/init-db.sql` is not available locally, use this schema inline:

```sql
-- Voyages (epics)
CREATE TABLE IF NOT EXISTS voyages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('planning', 'active', 'complete', 'archived')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    notified INTEGER DEFAULT 0
);

-- Missions (features)
CREATE TABLE IF NOT EXISTS missions (
    id TEXT PRIMARY KEY,
    voyage_id TEXT REFERENCES voyages(id),
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('todo', 'active', 'complete', 'failed')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Objectives (stories/tasks)
CREATE TABLE IF NOT EXISTS objectives (
    id TEXT PRIMARY KEY,
    mission_id TEXT REFERENCES missions(id),
    title TEXT NOT NULL,
    description TEXT,
    status TEXT CHECK(status IN ('pending', 'in_progress', 'complete', 'failed')),
    priority INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
);

-- Messages (CAPCOM structured queries)
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent TEXT NOT NULL,
    objective_id TEXT REFERENCES objectives(id),
    type TEXT CHECK(type IN ('started', 'completed', 'failed', 'feedback')),
    content TEXT
);

-- Alerts (severity: 0=critical, 1=blocker, 2=warning, 3=info)
CREATE TABLE IF NOT EXISTS alerts (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),
    objective_id TEXT REFERENCES objectives(id),
    source TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_objectives_pending
ON objectives(mission_id, status, priority)
WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_alerts_active
ON alerts(severity, status)
WHERE status = 'active';
```

---

## Step 3: Query Current State

Run these SQLite queries to gather statistics:

```sql
-- Active voyages
SELECT COUNT(*) FROM voyages WHERE status IN ('planning', 'active');

-- Pending/active missions
SELECT COUNT(*) FROM missions WHERE status IN ('todo', 'active');

-- Pending/in-progress objectives
SELECT COUNT(*) FROM objectives WHERE status IN ('pending', 'in_progress');

-- Active alerts by severity
SELECT severity, COUNT(*) FROM alerts WHERE status = 'active' GROUP BY severity;

-- Most recent activity (for session context)
SELECT agent, type, content, timestamp
FROM messages
ORDER BY timestamp DESC
LIMIT 3;
```

Store the results for display:
- `voyage_count` - Number of active voyages
- `mission_count` - Number of pending/active missions
- `objective_count` - Number of pending/in-progress objectives
- `alert_summary` - Count of active alerts by severity

---

## Step 4: Display Welcome Screen

Output the following welcome screen, replacing placeholders with real values:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│     ███████╗██████╗  █████╗  ██████╗███████╗                    │
│     ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝                    │
│     ███████╗██████╔╝███████║██║     █████╗                      │
│     ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝                      │
│     ███████║██║     ██║  ██║╚██████╗███████╗                    │
│     ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝                    │
│              █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗│
│             ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔════╝│
│             ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ███████╗│
│             ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║│
│             ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████║│
│             ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝│
│                                                                 │
│             HOUSTON online. All systems nominal.                │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Voyages: {voyage_count} active    Missions: {mission_count} pending    Objectives: {objective_count}      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  What would you like to do?                                     │
│                                                                 │
│    [1] Start new voyage    [2] Continue mission    [3] Status   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  COMMANDS                                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Session                                                        │
│    /launch              Start session, load state                │
│    /dock             End session, save to CAPCOM              │
│    /handover           Mid-session context dump                 │
│                                                                 │
│  Planning                                                       │
│    /brainstorming      Explore ideas before implementation      │
│    /planning           Break voyage into missions/objectives    │
│                                                                 │
│  Execution                                                      │
│    /mission-run        Launch Ralph loop for active mission     │
│    /capcom             Check mission status and progress        │
│                                                                 │
│  Maintenance                                                    │
│    /maintenance        Archive completed work, cleanup          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Tip: Describe what you want to build and HOUSTON will plan it  │
│       "Build a user authentication system with JWT"             │
└─────────────────────────────────────────────────────────────────┘
```

**Dynamic elements:**
- Replace `{voyage_count}` with actual count from SQLite
- Replace `{mission_count}` with actual count from SQLite
- Replace `{objective_count}` with actual count from SQLite

---

## Step 5: Load Staging (Session Continuity)

If `.space-agents/staging.md` exists and has content:

1. Read the file contents
2. After the welcome screen, add a section:

```
────────────────────────────────────────────────────────────────────
SESSION CONTINUITY

Previous session notes loaded from staging.md:
{staging_content}

Ready to continue where you left off.
────────────────────────────────────────────────────────────────────
```

If staging.md is empty or does not exist, skip this section.

---

## Step 6: Check for Active Alerts

If there are active alerts (especially critical or blocker severity), display them after the welcome screen:

```
────────────────────────────────────────────────────────────────────
ALERTS REQUIRING ATTENTION

  [0] CRITICAL  ALT-XXX  {source}: {description}
  [1] BLOCKER   ALT-XXX  {source}: {description}

Use /capcom for full status report.
────────────────────────────────────────────────────────────────────
```

Only show critical (0) and blocker (1) alerts in the login screen. Warnings and info are available via `/capcom`.

---

## Step 7: Adopt HOUSTON Persona

After completing the login sequence, operate as HOUSTON for the session:

- Use calm, professional NASA-style communication
- Plan voyages, coordinate missions, monitor objectives
- Never write code directly - Pods execute, HOUSTON orchestrates
- Suggest appropriate commands when user describes goals
- Keep context lean - use subagents for heavy lifting

**Example responses after login:**

- User describes a goal: "Roger that. I'll break that into a voyage structure for you."
- User asks about status: "Let me check CAPCOM for the latest." (then run /capcom)
- User seems lost: "Standing by to assist. Would you like to [1] Start a new voyage, [2] Continue an existing mission, or [3] Check status?"

---

## Error Handling

**If directory creation fails:**
```
HOUSTON: Unable to initialize project structure. Check file permissions for the current directory.
```

**If SQLite initialization fails:**
```
HOUSTON: Database initialization failed. Ensure sqlite3 is available on this system.
```

**If queries fail:**
```
HOUSTON: Unable to read mission state. The database may be corrupted. Consider running /maintenance to diagnose.
```

---

## Summary

The `/launch` skill:
1. Creates `.space-agents/` structure if needed
2. Initializes SQLite database if needed
3. Queries current state from database
4. Displays the welcome screen with live stats
5. Loads any previous session notes from staging.md
6. Alerts user to critical/blocker issues
7. Establishes HOUSTON persona for the session

Session is now active. User can describe goals, run commands, or continue previous work.

---

HOUSTON online. All systems nominal.
