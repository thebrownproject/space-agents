# SAL-9000

*"I am completely operational, and ready to assist."*

An agent orchestration plugin for Claude Code, inspired by 2001: A Space Odyssey and NASA Mission Control.

## Vision

SAL-9000 turns Claude Code into an "Agent OS" - a system for orchestrating multiple AI agents to work together on complex tasks. Users describe what they want, SAL breaks it down into parallel workstreams, and a hierarchy of agents executes the work with built-in review cycles.

## The Hierarchy

```
PROGRAM (Your Project)
    │
    └── MISSION (Epic)
            │
            └── POD (Feature)
                    │
                    └── CREW (Workers)
                            ├── Engineer
                            ├── Inspector
                            └── Analyst
```

## Agent Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   YOU (Mission Control)                                                     │
│   "Build user authentication"                                               │
│                         │                                                   │
│                         ▼                                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    SAL (Commander)                                  │   │
│   │                    This conversation                                │   │
│   └───────────────────────────┬─────────────────────────────────────────┘   │
│                               │                                             │
│            ┌──────────────────┼──────────────────┐                         │
│            ▼                  ▼                  ▼                          │
│      ┌──────────┐       ┌──────────┐       ┌──────────┐                    │
│      │  POD 1   │       │  POD 2   │       │  POD 3   │                    │
│      │  "JWT"   │       │ "Login"  │       │"Midware" │                    │
│      └────┬─────┘       └────┬─────┘       └────┬─────┘                    │
│           │                  │                  │                           │
│      ┌────┴────┐        ┌────┴────┐        ┌────┴────┐                     │
│      │  CREW   │        │  CREW   │        │  CREW   │                     │
│      │┌───────┐│        │┌───────┐│        │┌───────┐│                     │
│      ││Engineer│        ││Engineer│        ││Engineerr│                    │
│      │├───────┤│        │├───────┤│        │├───────┤│                     │
│      ││Inspctor│        ││Inspctor│        ││Inspctor│                     │
│      │├───────┤│        │├───────┤│        │├───────┤│                     │
│      ││Analyst││        ││Analyst││        ││Analyst││                     │
│      │└───────┘│        │└───────┘│        │└───────┘│                     │
│      └────┬────┘        └────┬────┘        └────┬────┘                     │
│           │                  │                  │                           │
│           └──────────────────┴──────────────────┘                           │
│                              │                                              │
│                              ▼                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    CAPCOM (Message Broker)                          │   │
│   │   - Receives all Crew reports via SQLite message queue             │   │
│   │   - Runs Airlock validation (tests, lint)                          │   │
│   │   - Filters context - each agent gets only what they need          │   │
│   │   - Routes issues back to Pods, summaries to SAL                   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Terminology

| Term | Role | NASA Equivalent |
|------|------|-----------------|
| **SAL** | Main session (Commander) | Mission Commander |
| **Pod** | Feature lead (subagent) | Department Lead |
| **Crew** | Workers (subagent category) | Astronauts |
| **CAPCOM** | Message broker (subagent) | Capsule Communicator |
| **Airlock** | Validation (called by CAPCOM) | Release Manager |
| **Maintenance** | Cleanup (skill) | Ground Support |

### Crew Types (Workers)

| Crew Type | Role |
|-----------|------|
| **Engineer** | Does the work (writes code, creates files) |
| **Inspector** | Verifies requirements are met |
| **Analyst** | Reviews code quality and patterns |
| *(future)* | More specialist types can be added |

## Key Principle

> **Agents never call each other directly. All coordination happens through SQLite.**

This keeps context clean - each agent receives only the information they need.

## Coordination: SQLite + Files

| Layer | Purpose |
|-------|---------|
| **SQLite (.sal/sal.db)** | Coordination state - status, messages, reviews |
| **Files (control-centre/)** | Human documentation - designs, code, artifacts |

### SQLite Tables

```sql
missions   -- Mission status and metadata
pods       -- Pod status per mission
tasks      -- Task status with review phases
reviews    -- Spec and code review results
messages   -- Agent communication queue (CAPCOM's inbox)
```

## Folder Structure

```
.sal/
└── sal.db                        # SQLite coordination

control-centre/
├── program/                      # Program-level docs
│   ├── architecture.md
│   └── prd.md
│
└── missions/
    ├── todo/                     # Not started
    ├── active/                   # In progress
    │   └── user-auth/
    │       ├── _mission.md
    │       └── pods/
    │           └── jwt-service/
    │               ├── _pod.md
    │               └── tasks/
    ├── complete/                 # Finished
    └── archive/                  # Abandoned
```

## How It Works

```
1. You → SAL: "Build user authentication"

2. SAL creates mission, proposes Pod plan:
   ┌─────────────────────────────────────────┐
   │  Mission: user-auth                     │
   │                                         │
   │  Pod 1: JWT Service      (3 tasks)      │
   │  Pod 2: Login Endpoint   (2 tasks)      │
   │  Pod 3: Auth Middleware  (1 task)       │
   │                                         │
   │  Proceed? [yes/no]                      │
   └─────────────────────────────────────────┘

3. You approve → SAL spawns Pod subagents

4. Each Pod spawns Crew:
   └── Engineer → does the work
   └── Inspector → verifies requirements
   └── Analyst → reviews code quality

5. Crew write reports to SQLite messages table

6. Hook triggers CAPCOM to process queue:
   ├── Runs Airlock validation (tests, lint)
   ├── Issues found → Routes feedback to Pod
   └── All passed → Summarizes to SAL

7. Pod handles issues or continues to next task

8. When complete → /maintenance to archive
```

## Installation

```bash
# Add marketplace (once published)
/plugin marketplace add fraserbrown/sal-9000-marketplace

# Install plugin
/plugin install sal-9000
```

## Usage

```bash
# Start a mission
/sal "Build user authentication with JWT"

# Check status
/sal status

# Cleanup completed missions
/maintenance
```

## Inspiration

- **2001: A Space Odyssey** - SAL-9000 is HAL's twin from 2010
- **NASA Mission Control** - Hierarchical orchestration
- **Steve Yegge's Beads** - Shared state coordination pattern
- **Claude Code** - Native subagents, skills, and hooks
