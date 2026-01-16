# Space-Agents Plugin Design

*Brainstormed: 2026-01-16*

---

## Overview

Space-Agents is a Claude Code plugin for multi-agent orchestration. It merges the NASA-themed hierarchy from SPACE-AGENTS-DESIGN.md with the detailed specs (notifications, 3-tier memory, compression) from SAL-9000-v2-DESIGN.md.

**Core insight:** "Agents are compute, not memory." Fresh context each cycle, state persists externally.

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Installation | Plugin install (`/plugin install space-agents`) | Portable, reusable across projects |
| Project structure | Everything in `.space-agents/` | Self-contained, clean for users |
| Session management | Explicit `/launch` and `/dock` | Clear boundaries, state persistence on dock |
| Memory system | 3-tier (staging, CAPCOM, mission logs) | Prevents context bloat, grep-only for master log |
| Notifications | Both macOS + file-based hook | Alert when tabbed away + in-session updates |
| Terminology | Space-Agents (NASA theme) | HOUSTON, Voyage, Mission, Objective, Pod |
| Launch options | Attended or Background | MVP simplicity, user chooses visibility |
| Alert system | 4-level severity (Gas Town style) | Critical/Blocker/Warning/Info for triage |
| Context handover | `/handover` command | Mid-session context dump for fresh sessions |

---

## User Project Structure

When Space-Agents is used in a project, it creates:

```
.space-agents/
├── space-agents.db          # SQLite state (includes alerts table)
├── capcom.md                # Master CAPCOM log (append-only, grep-only)
├── staging.md               # Session buffer (full read, cleared on dock)
├── notifications            # Cross-session notification file
├── scripts/
│   ├── ralph.sh             # Execution loop (copied from plugin)
│   └── airlock.sh           # Test/lint validation
└── missions/
    ├── todo/                # Planned voyages/missions
    ├── active/              # In-progress work
    │   └── <voyage-name>/
    │       ├── _voyage.md   # Voyage overview
    │       ├── capcom.log   # Per-voyage execution log
    │       └── missions/
    │           └── <mission-name>/
    │               ├── _mission.md
    │               └── objectives/
    └── complete/            # Finished (archived)
```

---

## Plugin Structure

```
space-agents/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── launch/SKILL.md           # /launch - session start, show welcome screen
│   ├── dock/SKILL.md             # /dock - session end, save to CAPCOM
│   ├── handover/SKILL.md         # /handover - mid-session context dump
│   ├── brainstorming/SKILL.md    # /brainstorming - explore ideas
│   ├── planning/SKILL.md         # /planning - mission breakdown
│   ├── mission-run/SKILL.md      # /mission-run - launch Ralph loop
│   ├── capcom/SKILL.md           # /capcom - status check
│   └── maintenance/SKILL.md      # /maintenance - cleanup/archive
├── agents/
│   ├── houston.md                # HOUSTON persona (main session)
│   ├── pod.md                    # Pod - orchestrates one objective
│   ├── worker.md                 # Worker - implements code
│   ├── inspector.md              # Inspector - reviews requirements
│   └── analyst.md                # Analyst - reviews code quality
├── hooks/
│   └── hooks.json                # Event triggers
├── scripts/
│   ├── ralph.sh                  # Execution loop
│   ├── airlock.sh                # Test/lint validation
│   ├── notify.sh                 # macOS notification
│   ├── check-notifications.sh   # Poll notification file
│   ├── on-agent-complete.sh     # Post-Task hook
│   └── init-db.sql              # SQLite schema
└── assets/
    └── launch-screen.txt         # Welcome screen ASCII art
```

---

## Hooks Configuration

**hooks/hooks.json:**

```json
{
  "description": "Space-Agents event hooks",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/check-notifications.sh",
          "timeout": 5
        }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Task",
        "hooks": [{
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/on-agent-complete.sh",
          "timeout": 10
        }]
      }
    ]
  }
}
```

---

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/launch` | Start session, display welcome screen, load state from SQLite/staging |
| `/dock` | End session, append summary to CAPCOM, optionally compress old entries |
| `/handover` | Mid-session context dump - generates prompt for next fresh session |
| `/brainstorming` | Explore ideas before implementation (Superpowers-style) |
| `/planning` | Break voyage into missions and objectives |
| `/mission-run` | Launch Ralph loop for active mission (Attended or Background mode) |
| `/capcom` | Check mission status and progress (via subagent) |
| `/maintenance` | Archive completed work, cleanup empty folders |

---

## CAPCOM Subagent Architecture

`/capcom` spawns a fresh subagent to keep HOUSTON's context clean. The subagent does heavy lifting (SQLite queries, log parsing), returns only a summary.

**Flow:**
```
User: /capcom
    │
    ▼
HOUSTON (main session)
    │
    ├── Spawns CAPCOM subagent via Task tool
    │       │
    │       ▼
    │   CAPCOM agent (fresh context)
    │       ├── Query SQLite for voyage/mission/objective state
    │       ├── Grep recent CAPCOM log entries
    │       ├── Check alerts/ACTIVE.md for open alerts
    │       ├── Format summary (~200-300 words)
    │       └── Return summary to HOUSTON
    │       │
    │       ▼
    │   Agent exits (context discarded)
    │
    ▼
HOUSTON receives summary (lean)
    │
    ▼
Displays formatted status to user
```

**Why subagent:**
- HOUSTON stays lean - no log/SQLite bloat
- Fresh context for each status check
- Only summary returns (~200-300 words)
- Pattern matches Gas Town's Witness role

**CAPCOM Output Format:**
```
CAPCOM — Mission Status
═══════════════════════════════════════════════════════

Voyage: user-authentication [ACTIVE]
  └── Mission: jwt-token-management (2/3 objectives)
        ├── ✓ jwt-signing [complete]
        ├── ✓ jwt-verification [complete]
        └── ◉ jwt-expiry-handling [in_progress - Pod-003]

Alerts: 1 warning
  └── ALT-002: Deprecated sign() method (Analyst)

Recent Activity:
  [10:45] Pod-003 Worker implementing jwt-expiry-handling
  [10:32] Pod-003 completed jwt-verification
  [10:15] Pod-003 completed jwt-signing

Ralph Loop: Running (iteration 3)
═══════════════════════════════════════════════════════
```

---

## 3-Tier Memory System

| Tier | File | Read Pattern | Write Pattern | Lifecycle |
|------|------|--------------|---------------|-----------|
| **Staging** | `.space-agents/staging.md` | Full read | Overwrite | Per-session (cleared on /dock) |
| **Master CAPCOM** | `.space-agents/capcom.md` | Grep only | Append only | Permanent (grows indefinitely) |
| **Mission CAPCOM** | `missions/.../capcom.log` | Full or grep | Append | Per-mission (archived on complete) |

**Compression:** `/dock --compress` compresses entries older than 30 days into summaries.

---

## Notification System

**Two-pronged approach:**

1. **macOS notification** - `osascript` triggers system notification when Ralph completes
2. **File-based hook** - Writes to `.space-agents/notifications`, PreToolUse hook picks it up

**Flow:**
```
Ralph loop completes
    │
    ├── osascript → macOS notification center
    │
    └── echo "Mission X complete" >> .space-agents/notifications
           │
           └── Next tool use → PreToolUse hook reads file → outputs to session
```

---

## Launch Options

When running `/mission-run`, user chooses execution mode:

| Mode | Description | Visibility | When to Use |
|------|-------------|------------|-------------|
| **Attended** | Run in terminal, watch output | Full - see everything live | New missions, debugging |
| **Background** | Run detached, use `/capcom` to check | Use `/capcom` for status | Trusted missions, multitasking |

**Flow:**
```
/mission-run
    │
    ├── "How would you like to run this mission?"
    │
    ├── [1] Attended (recommended for new missions)
    │       → Run in separate terminal: claude -p < ralph-prompt.md
    │       → User watches directly
    │
    └── [2] Background
            → HOUSTON starts ralph.sh with run_in_background: true
            → Use /capcom to check progress
            → macOS notification on completion
```

---

## Alert System (Gas Town Pattern)

Pods and Crew create alerts when they encounter problems. Severity levels based on Gas Town's priority system.

### Severity Levels

| Level | Name | Meaning | Action |
|-------|------|---------|--------|
| **0** | `critical` | Mission blocked, cannot continue | HOUSTON notified immediately |
| **1** | `blocker` | Objective stuck, needs intervention | Pod retries, then escalates |
| **2** | `warning` | Issue found, can workaround | Logged, continue working |
| **3** | `info` | FYI, potential concern | Logged for review |

### Alert Triggers

| Source | Trigger | Severity |
|--------|---------|----------|
| **Worker** | Blocker during implementation | blocker |
| **Worker** | Max retries exhausted | critical |
| **Inspector** | Requirements mismatch | warning |
| **Analyst** | Code quality issue | warning |
| **Airlock** | Tests/lint failure | blocker |
| **Pod** | Objective failed | critical |

### Alert Storage

Alerts are stored in **SQLite only** (no separate markdown files). The `/capcom` command displays them formatted.

### Alert Flow

```
Pod executing objective
    │
    ├── Worker/Inspector/Analyst hits issue
    │       │
    │       ▼
    │   Create alert in SQLite alerts table
    │   Log to CAPCOM
    │       │
    │       ▼
    │   severity 0-1? → Notify HOUSTON immediately
    │   severity 2-3? → Continue, log for review
    │
    ▼
HOUSTON sees alerts via /capcom or notifications
```

### Alert Display (via /capcom)

```
Alerts: 2 active
  [1] BLOCKER  ALT-001  Worker: Cannot resolve jsonwebtoken
  [2] WARNING  ALT-002  Analyst: Deprecated sign() method
```

---

## Handover System

When context fills up mid-session, `/handover` generates a structured prompt for the next fresh session.

### When to Use

- Context window getting full (Claude will warn)
- Switching focus, need to preserve state
- End of day, want clean restart tomorrow

### Handover Output

```markdown
# Handover: 2026-01-16 — JWT Token Mission

## Session Summary
- Completed objectives: jwt-signing, jwt-verification
- In progress: jwt-expiry-handling (Worker on attempt 2)
- Alerts: 1 warning (deprecated method usage)

## Decisions Made
- Using RS256 algorithm for signing (security requirement)
- Token expiry set to 24h with refresh token pattern

## Current State
- **Branch**: feature/user-auth
- **Uncommitted changes**: Yes (3 files)
- **Active mission**: jwt-token-management (2/3 objectives)

## Next Session Focus
Continue jwt-expiry-handling objective. Worker needs to:
1. Add expiry validation to verify() function
2. Implement refresh token rotation

## Context Files
- `src/auth/jwt.ts` - main implementation
- `src/auth/jwt.test.ts` - test file (2 failing)

## Alerts to Review
- ALT-002: Deprecated `sign()` method - consider upgrading
```

### Handover Flow

```
/handover
    │
    ├── Query SQLite for current state
    ├── Read recent CAPCOM entries
    ├── Check git status
    ├── Compile alerts
    │
    ▼
Generate handover prompt
    │
    ├── Save to .space-agents/handover-YYYY-MM-DD.md
    └── Display to user for copy/paste into new session
```

---

## Agent Hierarchy

```
COMPUTER          AGILE             SPACE-AGENTS                      WORK UNIT
────────          ─────             ────────────                      ─────────

                                    YOU (Human)
                                      │
                                      ▼
OS / Kernel  ←──  Program Mgmt  ←──  HOUSTON (Flight Director) ──────► VOYAGE (Epic)
                                      │  Plans voyages/missions
                                      │  Never touches code
                                      │
Scheduler    ←──  Sprint Board  ←──  RALPH LOOP (bash) ◄────────┐ ──► MISSION (Feature)
                                      │  Picks next objective   │
                                      │  Spawns fresh Pod       │
                                      ▼                         │
              ┌──────────────────────────────────────┐          │
              │           POD (Spacecraft)           │          │
CPU         ←─│ Developer ┌────────────────────┐    │ ─────────│───► OBJECTIVE (Story)
(stateless     │ Team      │ Worker → Inspector │    │          │
 compute)      │           │   │         │      │    │          │
               │           │   │         ▼      │    │          │
               │           │   │      Analyst   │    │          │
               │           └───│────────────────┘    │          │
               │               ▼                     │          │
               │           AIRLOCK (tests/lint)      │          │
               └───────────────│─────────────────────┘          │
                               │                                │
                               ▼                                │
RAM         ←─ Working Notes ← staging.md (session only)        │
(volatile)                     │                                │
                               ▼                                │
Disk        ←─ Jira / Docs  ← CAPCOM + SQLite ──────────────────┘
(persistent)                  (permanent record)
```

---

## SQLite Schema

```sql
-- Voyages (epics)
CREATE TABLE voyages (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('planning', 'active', 'complete', 'archived')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    notified INTEGER DEFAULT 0
);

-- Missions (features)
CREATE TABLE missions (
    id TEXT PRIMARY KEY,
    voyage_id TEXT REFERENCES voyages(id),
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('todo', 'active', 'complete', 'failed')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Objectives (stories/tasks)
CREATE TABLE objectives (
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
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent TEXT NOT NULL,
    objective_id TEXT REFERENCES objectives(id),
    type TEXT CHECK(type IN ('started', 'completed', 'failed', 'feedback')),
    content TEXT
);

-- Alerts (Gas Town severity pattern)
CREATE TABLE alerts (
    id TEXT PRIMARY KEY,              -- ALT-001, ALT-002, etc.
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity INTEGER CHECK(severity IN (0, 1, 2, 3)),  -- 0=critical, 1=blocker, 2=warning, 3=info
    objective_id TEXT REFERENCES objectives(id),
    source TEXT NOT NULL,             -- Worker, Inspector, Analyst, Airlock, Pod
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('active', 'cleared')) DEFAULT 'active',
    cleared_at DATETIME
);

-- Index for quick pending queries
CREATE INDEX idx_objectives_pending ON objectives(mission_id, status, priority)
WHERE status = 'pending';

-- Index for active alerts by severity
CREATE INDEX idx_alerts_active ON alerts(severity, status)
WHERE status = 'active';
```

---

## Launch Screen

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
│  Voyages: 0 active    Missions: 0 pending    Objectives: 0      │
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
│    /launch             Start session, load state                │
│    /dock               End session, save to CAPCOM              │
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

---

## Implementation Phases

### Phase 1: Core (MVP)
- [x] Plugin structure (plugin.json, folders)
- [x] SQLite schema + init script (including alerts table)
- [x] `/launch` skill with welcome screen
- [x] `/dock` skill with CAPCOM append
- [x] HOUSTON agent prompt
- [x] Ralph loop script (with Attended/Background options)
- [x] Pod agent prompt
- [x] Worker/Inspector/Analyst prompts
- [x] Airlock script

### Phase 2: Planning & Status
- [ ] `/brainstorming` skill
- [ ] `/planning` skill
- [ ] `/capcom` skill (status check via subagent)
- [ ] `/handover` skill (mid-session context dump)

### Phase 3: Alerts & Notifications
- [ ] Alert creation from Pod/Crew (SQLite alerts table)
- [ ] Alert display in /capcom output
- [ ] Hooks configuration
- [ ] check-notifications.sh script
- [ ] on-agent-complete.sh script
- [ ] notify.sh (macOS notification)

### Phase 4: Polish
- [ ] `/dock --compress` compression
- [ ] `/maintenance` skill
- [ ] Launch options UI for /mission-run
- [ ] Documentation / README

---

## References

- `SPACE-AGENTS-DESIGN.md` - NASA terminology, hierarchy
- `SAL-9000-v2-DESIGN.md` - Detailed specs, memory tiers, notifications
- `research/ghuntley-ralph-wiggum-loop.md` - Fresh context pattern
- `research/obra-superpowers.md` - Skill injection pattern
- `research/yegge-beads.md` - SQLite state pattern
- `research/yegge-gastown.md` - Swarm coordination pattern
