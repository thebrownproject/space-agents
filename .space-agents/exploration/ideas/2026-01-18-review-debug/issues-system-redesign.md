# Exploration: Issues System Redesign

**Date:** 2026-01-19
**Status:** Ready for implementation
**Related:** `exploration.md` (code-review & debug features)

---

## Problem Statement

The current `alerts` table conflates two different concepts:
1. **Operational failures** - System broke, mission halted, pod crashed
2. **Code quality findings** - Technical debt, suggestions, minor issues

Additionally, the communication flow is complex with multiple channels, files, and 5 different sources creating alerts through text parsing.

---

## Current Communication Landscape

### Storage Locations

```
.space-agents/
├── comms/                              # Central communication hub
│   ├── space-agents.db                 # SQLite: voyages, missions, objectives, alerts
│   ├── capcom.md                       # Session-level log (HOUSTON conversations)
│   ├── handover.md                     # Session handover for fresh sessions
│   └── notifications.md                # Desktop notification log
│
├── missions/
│   ├── staged/<mission-id>/            # Planned missions (pre-approval)
│   ├── active/<mission-id>/            # Running missions
│   │   ├── _mission.md                 # Mission definition
│   │   ├── implementation-plan.md      # Detailed implementation plan
│   │   ├── exploration.md              # Pre-mission exploration (optional)
│   │   ├── capcom.log                  # Mission-level log (Ralph + Pod writes)
│   │   ├── handovers/                  # Objective handovers
│   │   │   ├── OBJ-001.md              # Context for next objective
│   │   │   └── OBJ-002.md
│   │   ├── prompts/                    # Pod prompts (visible mode)
│   │   │   └── OBJ-001.txt
│   │   └── signals/                    # Coordination files (visible mode)
│   │       └── OBJ-001.done
│   └── complete/<mission-id>/          # Finished missions (archived)
│
└── exploration/                        # /exploration outputs
    └── <date>-<topic>/
        └── exploration.md
```

### SQLite Tables

| Table | Purpose | Writers |
|-------|---------|---------|
| `voyages` | Project-level container | /mission-brief |
| `missions` | Mission definitions | /mission-brief, ralph.sh |
| `objectives` | Work items within missions | /mission-brief, Pod, ralph.sh |
| `alerts` | Mixed operational + findings | Pod, ralph.sh |

### Communication Channels

| Channel | Purpose | Writers | Readers |
|---------|---------|---------|---------|
| **SQLite** | Structured state | Many | Many |
| **capcom.md** | Session log | HOUSTON, /dock | /launch, /capcom |
| **capcom.log** (per mission) | Mission execution log | ralph.sh, Pod | Debugging, review |
| **handover.md** | Session continuity | /handover, /dock | Next session |
| **handovers/*.md** (per objective) | Objective context | Pod | Next Pod |
| **notifications.md** | Desktop alerts | ralph.sh | OS notification hooks |
| **signals/*.done** | Pod completion signals | Pod | ralph.sh (visible mode) |
| **prompts/*.txt** | Pod invocation prompts | ralph.sh | mprocs (visible mode) |

### Who Writes Where

```
HOUSTON (main conversation)
  └── writes to: capcom.md (via /dock)

/mission-brief
  └── writes to: SQLite (voyages, missions, objectives)
                 _mission.md, implementation-plan.md

ralph.sh
  └── writes to: SQLite (objectives status, alerts)
                 capcom.log (mission-level)
                 notifications.md
                 signals/ (visible mode)
                 prompts/ (visible mode)

Pod
  └── writes to: SQLite (objectives status, alerts - parsed from agents)
                 capcom.log (mission-level)
                 handovers/<objective>.md
                 signals/<objective>.done (visible mode)

Worker/Inspector/Analyst
  └── writes to: stdout only ([COMPLETE], [PASS], [ALERT:...])
                 Pod parses and persists
```

---

## Current Setup

### Alert Sources (5 total)

| Source | How it creates alerts | What it reports |
|--------|----------------------|-----------------|
| **Worker** | Outputs `[ALERT:severity]` text → Pod parses | Implementation blockers |
| **Inspector** | Outputs `[ALERT:severity]` text → Pod parses | Requirements concerns |
| **Analyst** | Outputs `[ALERT:severity]` text → Pod parses | Code quality findings |
| **Pod** | Parses agent output → writes to SQLite | Aggregates above |
| **ralph.sh** | Calls `create_alert()` directly | Operational failures |

### Current Schema

```sql
CREATE TABLE alerts (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),  -- 0=critical, 1=blocker, 2=warning, 3=info
    mission_id TEXT NOT NULL,
    objective_id TEXT,
    source TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME
);
```

### Current Communication Flow

```
ralph.sh
  ├── spawns Pod (claude CLI)
  ├── reads Pod exit code (0/1/2)
  ├── creates alerts (operational)
  └── writes to capcom.log

Pod
  ├── reads SQLite (objective, mission)
  ├── reads files (handovers, mission docs)
  ├── dispatches Worker → parses [ALERT:...] → writes to SQLite
  ├── dispatches Inspector → parses [ALERT:...] → writes to SQLite
  ├── dispatches Analyst → parses [ALERT:...] → writes to SQLite
  ├── runs Airlock
  ├── writes handover file
  └── exits 0/1/2

Worker/Inspector/Analyst
  └── output [COMPLETE]/[PASS] + [ALERT:severity] text (free-form)
```

### Problems

1. **Text parsing is fragile** - Pod regex-parses `[ALERT:...]` from agent stdout
2. **Mixed concerns** - "System broke" and "code could be better" in same table
3. **Multiple writers** - 5 sources creating alerts, hard to reason about
4. **No clear lifecycle** - Operational alerts need response, findings accumulate as backlog
5. **Coupling through parsing** - Agents must output exact format, Pod must parse correctly

---

## Proposed Design

### Two Separate Tables

#### 1. `alerts` - Operational Only

For system failures that need immediate attention. **Only ralph.sh writes here.**

```sql
CREATE TABLE alerts (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2)),  -- 0=critical, 1=blocker, 2=warning
    mission_id TEXT NOT NULL,
    objective_id TEXT,
    source TEXT NOT NULL,  -- 'ralph', 'pod'
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME
);
```

#### 2. `issues` - Code Quality Findings

For findings from code review, debugging, and Analyst observations. **Multiple sources write directly.**

```sql
CREATE TABLE issues (
    id TEXT PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    type TEXT CHECK(type IN ('finding', 'bug', 'debt')),  -- finding=review, bug=debug, debt=tech debt
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),     -- 0=critical, 1=blocker, 2=warning, 3=info
    source TEXT NOT NULL,      -- 'analyst', 'review', 'debug', 'user'
    description TEXT NOT NULL,
    file_path TEXT,            -- optional: specific file
    line_number INTEGER,       -- optional: specific line
    mission_id TEXT,           -- optional: NULL if standalone
    objective_id TEXT,         -- optional: NULL if standalone
    status TEXT CHECK(status IN ('active', 'investigating', 'in_progress', 'resolved', 'dismissed')) DEFAULT 'active',
    resolution TEXT,           -- notes when closed
    resolved_at DATETIME
);
```

### Simplified Agent Protocol

**Exit codes only, no text parsing:**

| Agent | Success | Failure |
|-------|---------|---------|
| Worker | exit 0 + `[COMPLETE]` | exit 1 + `[FAILED]` |
| Inspector | exit 0 + `[PASS]` | exit 1 + `[FAIL]` |
| Analyst | exit 0 + `[PASS]` | exit 1 + `[FAIL]` |
| Airlock | exit 0 | exit non-zero |

**Analyst writes findings directly to `issues` table:**

```sql
-- Analyst finds a warning (continues, exit 0)
INSERT INTO issues (id, type, severity, source, description, file_path, line_number, mission_id, objective_id, status)
VALUES ('ISS-001', 'finding', 2, 'analyst', 'SQL injection risk in query builder', 'src/db.ts', 45, 'MSN-001', 'OBJ-003', 'active');
```

```sql
-- Analyst finds a blocker (fails, exit 1)
INSERT INTO issues (id, type, severity, source, description, mission_id, objective_id, status)
VALUES ('ISS-002', 'finding', 1, 'analyst', 'Security vulnerability: hardcoded credentials', 'MSN-001', 'OBJ-003', 'active');
```

### Simplified Communication Flow

```
ralph.sh
  ├── spawns Pod
  ├── reads exit code only (0/1/2)
  ├── creates operational alerts (ONLY source)
  └── writes to capcom.log

Pod
  ├── reads context (SQLite, files)
  ├── dispatches Worker → reads exit code
  ├── dispatches Inspector → reads exit code
  ├── dispatches Analyst → reads exit code (Analyst writes issues directly)
  ├── runs Airlock → reads exit code
  ├── writes handover
  └── exits 0/1/2

Worker     → exit 0 or 1 (no alert output)
Inspector  → exit 0 or 1 (no alert output)
Analyst    → writes to issues table, then exit 0 or 1
Airlock    → exit code from test runner
```

### Integration with Future Skills

| Skill | Writes to `issues` | How |
|-------|-------------------|-----|
| **Analyst** (in Pod) | Yes, `source='analyst'` | Direct INSERT during review |
| **/code-review** | Yes, `source='review'` | Swarm reviewers INSERT findings |
| **/debug** | Yes, `source='debug'` | Creates bugs, updates status |
| **User** | Yes, `source='user'` | Via /debug "report bug" flow |

### Issue Lifecycle

```
[active] → [investigating] → [in_progress] → [resolved]
                                          → [dismissed]
```

- `/debug` shows active issues at entry
- Working on an issue → mark `investigating`
- Fix in progress → mark `in_progress`
- Fixed → mark `resolved` with resolution notes
- Won't fix → mark `dismissed` with reason

---

## Migration Path

### Phase 1: Add `issues` table
- Create new `issues` table alongside existing `alerts`
- Keep `alerts` for backward compatibility

### Phase 2: Update Analyst
- Analyst writes to `issues` instead of outputting `[ALERT:...]`
- Remove alert parsing from Pod
- Simplify Worker/Inspector to exit codes only

### Phase 3: Clean up `alerts`
- Move non-operational alerts to `issues` table
- `alerts` becomes operational-only (ralph.sh writes)

### Phase 4: Implement `/code-review` and `/debug`
- Both write to `issues` table
- `/debug` becomes the issue triage interface

---

## Files to Modify

| File | Change |
|------|--------|
| `skills/install/scripts/init-db.sql` | Add `issues` table |
| `agents/mission-analyst.md` | Write to `issues` directly, remove `[ALERT:...]` protocol |
| `agents/mission-worker.md` | Remove `[ALERT:...]` protocol, exit codes only |
| `agents/mission-inspector.md` | Remove `[ALERT:...]` protocol, exit codes only |
| `skills/pod/skill.md` | Remove alert parsing, simplify to exit code handling |
| `skills/mission-go/scripts/ralph.sh` | No change (already correct - only operational alerts) |

---

## Open Questions

1. **Issue ID format** - `ISS-001` globally? Or `ISS-MSN001-001` per mission?
2. **Orphan issues** - Issues without mission_id - how to display/manage?
3. **Issue promotion** - Can an issue become an objective in a future mission?

---

## Summary

| Aspect | Current | Proposed |
|--------|---------|----------|
| Alert sources | 5 (Worker, Inspector, Analyst, Pod, ralph) | 1 (ralph only) |
| Issue sources | 0 | 4 (Analyst, review, debug, user) |
| Agent protocol | Text parsing `[ALERT:...]` | Exit codes only |
| Tables | 1 (`alerts` mixed) | 2 (`alerts` operational, `issues` findings) |
| Pod complexity | Parses 3 agents | Reads exit codes |

**Benefits:**
- Cleaner separation of concerns
- No fragile text parsing
- Unified issue tracking for Analyst, /code-review, /debug
- Simpler agent protocols
- `alerts` table stays clean for operational health

---

## Communication Simplification (Future)

Beyond the issues system, the overall communication landscape could be simplified:

### Current Pain Points

| Channel | Issue |
|---------|-------|
| `capcom.md` (central) | Session log, manually written by /dock |
| `capcom.log` (per mission) | Mission log, written by ralph + Pod |
| `handover.md` (central) | Session handover |
| `handovers/*.md` (per objective) | Objective handovers |
| `notifications.md` | Desktop notifications log |

Two capcom files, two handover mechanisms, notifications in a separate file.

### Potential Consolidation

**Option A: SQLite for everything**
- Add `logs` table for capcom entries (queryable, structured)
- Add `handovers` table for objective context
- Remove `.md` and `.log` files entirely
- Single source of truth

**Option B: Keep files, standardize naming**
- `comms/session.md` - Session log (was capcom.md)
- `comms/session-handover.md` - Session handover
- `missions/<id>/mission.log` - Mission log (was capcom.log)
- `missions/<id>/handovers/` - Keep as-is
- Remove `notifications.md` (just use OS notifications directly)

**Recommendation:** Start with Option A for new data (issues table), evaluate file consolidation after issues system is working.

### Proposed Final State

```
.space-agents/
├── comms/
│   └── space-agents.db          # ALL structured data
│       ├── voyages
│       ├── missions
│       ├── objectives
│       ├── alerts               # Operational only (ralph.sh)
│       ├── issues               # Code quality (analyst, review, debug)
│       ├── logs                 # Future: capcom entries
│       └── handovers            # Future: objective context
│
├── missions/
│   └── <mission-id>/
│       ├── _mission.md          # Keep: human-readable mission definition
│       └── implementation-plan.md  # Keep: detailed plan
│
└── exploration/
    └── <date>-<topic>/
        └── exploration.md       # Keep: exploration reports
```

Markdown files for human-readable documents, SQLite for structured queryable state.

---

## Next Steps

1. **Implement issues table** - Add schema, update Analyst
2. **Simplify agent protocols** - Remove [ALERT:...] from Worker/Inspector
3. **Build /debug** - Issue triage interface
4. **Build /code-review** - Swarm reviews → issues
5. **Evaluate comms consolidation** - After issues system proves out
