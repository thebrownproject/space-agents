# SAL-9000 Architecture

## Design Philosophy

SAL-9000 fills the gap between ad-hoc coordination and enterprise-complexity frameworks. It provides structure without overwhelming complexity.

**Core Principles:**
- Agents coordinate through shared state (SQLite), never direct calls
- Hierarchical orchestration with built-in review cycles
- Context filtering - each agent receives only what they need
- Human-in-the-loop at key checkpoints

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

| Level | NASA Equivalent | Example |
|-------|-----------------|---------|
| Program | Apollo Program | "My SaaS App" |
| Mission | Apollo 11 | "Build user authentication" |
| Pod | Department Lead | "JWT Service" |
| Crew | Astronauts | Workers executing tasks |

## Agent Roles

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AGENT ORCHESTRATION                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   YOU (Mission Control)                                                     │
│   └── Gives high-level objectives                                           │
│                         │                                                   │
│                         ▼                                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    SAL (Commander)                                  │   │
│   │                    THIS CONVERSATION                                │   │
│   │                    Owns the mission, creates docs                   │   │
│   └───────────────────────────┬─────────────────────────────────────────┘   │
│                               │                                             │
│            ┌──────────────────┼──────────────────┐                         │
│            ▼                  ▼                  ▼                          │
│      ┌──────────┐       ┌──────────┐       ┌──────────┐                    │
│      │   POD    │       │   POD    │       │   POD    │  Subagents         │
│      │ Feature 1│       │ Feature 2│       │ Feature 3│                    │
│      └────┬─────┘       └────┬─────┘       └────┬─────┘                    │
│           │                  │                  │                           │
│      ┌────┴────────────┐     │                  │                           │
│      │     CREW        │     │                  │                           │
│      │  ┌───────────┐  │     │                  │                           │
│      │  │ Engineer  │──┼─────┼──────────────────┼───────┐                   │
│      │  ├───────────┤  │     │                  │       │                   │
│      │  │ Inspector │──┼─────┼──────────────────┼───────┤                   │
│      │  ├───────────┤  │     │                  │       │                   │
│      │  │ Analyst   │──┼─────┼──────────────────┼───────┤                   │
│      │  └───────────┘  │     │                  │       │                   │
│      └─────────────────┘     │                  │       │                   │
│                              │                  │       │                   │
│                              ▼                  ▼       ▼                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    CAPCOM (Message Broker)                          │   │
│   │   - Reads messages from SQLite queue                                │   │
│   │   - Runs Airlock validation                                         │   │
│   │   - Routes issues back to Pods                                      │   │
│   │   - Summarizes results to SAL                                       │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   MAINTENANCE (Skill) - Manual cleanup via /maintenance                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

| Agent | Type | Role | Spawned By |
|-------|------|------|------------|
| **SAL** | Main Session | Mission coordination | - (is the conversation) |
| **Pod** | Subagent | Feature coordination | SAL |
| **Crew** | Subagent | Task execution (see types below) | Pod |
| **CAPCOM** | Subagent | Message broker, context filter | Hook (on Crew completion) |
| **Airlock** | Function | Validation (tests, lint) | Called by CAPCOM |
| **Maintenance** | Skill | Cleanup and archiving | User (/maintenance) |

### Crew Types (Workers)

| Crew Type | Role | Spawned By |
|-----------|------|------------|
| **Engineer** | Does the work (writes code, creates files) | Pod |
| **Inspector** | Verifies requirements are met | CAPCOM (after Engineer) |
| **Analyst** | Reviews code quality and patterns | CAPCOM (after Engineer) |
| *(future)* | More specialist types can be added | - |

## Coordination: SQLite + Files

**Hybrid approach** - each layer does what it's best at:

| Layer | Purpose | Contents |
|-------|---------|----------|
| **SQLite (.sal/sal.db)** | Coordination state | Status, messages, reviews |
| **Files (control-centre/)** | Human documentation | Designs, code, artifacts |

### Key Principle

> **Agents never call each other directly. All coordination happens through SQLite.**

This enables:
- **Context isolation** - each agent only sees what they need
- **Persistence** - state survives session restarts
- **Audit trail** - all messages logged
- **Async handoffs** - agents don't need to wait for each other

## SQLite Schema

```sql
-- Missions (epics)
CREATE TABLE missions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('todo', 'active', 'complete', 'archived')),
    folder_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
);

-- Pods (features)
CREATE TABLE pods (
    id TEXT PRIMARY KEY,
    mission_id TEXT REFERENCES missions(id),
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('pending', 'active', 'complete', 'failed')),
    folder_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tasks (work items)
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    pod_id TEXT REFERENCES pods(id),
    title TEXT NOT NULL,
    status TEXT CHECK(status IN (
        'pending',
        'engineering',      -- Engineer working
        'inspecting',       -- Inspector reviewing
        'analyzing',        -- Analyst reviewing
        'complete',
        'failed'
    )),
    current_crew TEXT,      -- Which Crew type is working
    folder_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Reviews (Inspector + Analyst results)
CREATE TABLE reviews (
    id TEXT PRIMARY KEY,
    task_id TEXT REFERENCES tasks(id),
    crew_type TEXT CHECK(crew_type IN ('inspector', 'analyst')),
    status TEXT CHECK(status IN ('pending', 'passed', 'failed')),
    feedback TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Messages (agent communication queue)
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    from_agent TEXT NOT NULL,
    to_agent TEXT NOT NULL,
    message_type TEXT CHECK(message_type IN (
        'task_complete',
        'review_complete',
        'feedback',
        'pod_complete',
        'status_update'
    )),
    payload TEXT,  -- JSON content
    processed INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX idx_messages_unprocessed ON messages(to_agent, processed) WHERE processed = 0;
CREATE INDEX idx_tasks_status ON tasks(pod_id, status);
CREATE INDEX idx_pods_status ON pods(mission_id, status);
```

### Status Lifecycle

```
Task Status Flow:
                                         ┌─── failed
                                         │
pending → engineering → inspecting → analyzing → complete
               │             │            │
               └─────────────┴────────────┘
                      (feedback loop)
```

## Folder Structure

```
.sal/
└── sal.db                        # SQLite coordination database

control-centre/
├── program/                      # Program-level documentation
│   ├── architecture.md
│   ├── prd.md
│   ├── decisions.md
│   └── roadmap.md
│
└── missions/
    ├── todo/                     # Status: Not started
    │   └── future-feature/
    │       └── _mission.md
    │
    ├── active/                   # Status: In progress
    │   └── user-auth/
    │       ├── _mission.md       # Mission overview
    │       ├── design.md         # Design decisions
    │       └── pods/
    │           ├── jwt-service/
    │           │   ├── _pod.md   # Pod overview
    │           │   └── tasks/
    │           │       ├── implement-tokens.md
    │           │       └── add-refresh.md
    │           ├── login-endpoint/
    │           │   ├── _pod.md
    │           │   └── tasks/
    │           └── auth-middleware/
    │               ├── _pod.md
    │               └── tasks/
    │
    ├── complete/                 # Status: Finished
    │   └── old-feature/
    │
    └── archive/                  # Status: Abandoned/superseded
```

## Workflow

### 1. User Request

```
User: "Build user authentication with JWT"
```

### 2. SAL Creates Mission

SAL creates database record and folder structure:

```sql
INSERT INTO missions (id, title, status, folder_path)
VALUES ('m-001', 'user-auth', 'active', 'control-centre/missions/active/user-auth');
```

### 3. SAL Proposes Pod Plan

```
Mission: user-auth

Pod 1: JWT Service
├── Task: Implement token generation
├── Task: Add refresh token support
└── Task: Write tests

Pod 2: Login Endpoint (depends on Pod 1)
├── Task: Design API contract
└── Task: Implement endpoint

Proceed with this plan? [yes/no/adjust]
```

### 4. User Approves → SAL Spawns Pods

### 5. Pod Spawns Crew

For each task, Pod spawns Crew in sequence:

```
Pod-1 (JWT Service)
    │
    └── Task: Implement token generation
            │
            ├── 1. Engineer → does the work
            │   └── Reports to CAPCOM via messages table
            │
            ├── 2. Inspector → verifies requirements
            │   └── Spawned by CAPCOM, reports back
            │
            └── 3. Analyst → reviews code quality
                └── Spawned by CAPCOM, reports back
```

### 6. Crew Report to CAPCOM

When Engineer completes:

```sql
INSERT INTO messages (from_agent, to_agent, message_type, payload)
VALUES (
    'engineer-001',
    'capcom',
    'task_complete',
    '{"task_id": "t-001", "files_changed": ["src/jwt.ts"], "summary": "Implemented sign/verify"}'
);
```

Hook triggers CAPCOM to process.

### 7. CAPCOM Orchestrates Review

CAPCOM:
1. Spawns Inspector → reviews requirements
2. Spawns Analyst → reviews code quality
3. Runs Airlock validation (tests, lint)
4. Aggregates results

### 8. CAPCOM Routes Results

**If all passed:**
```sql
UPDATE tasks SET status = 'complete' WHERE id = 't-001';

INSERT INTO messages (from_agent, to_agent, message_type, payload)
VALUES ('capcom', 'pod-001', 'task_complete', '{"task_id": "t-001", "status": "passed"}');
```

**If issues found:**
```sql
INSERT INTO reviews (task_id, crew_type, status, feedback)
VALUES ('t-001', 'inspector', 'failed', 'Missing refresh token handling');

INSERT INTO messages (from_agent, to_agent, message_type, payload)
VALUES ('capcom', 'pod-001', 'feedback', '{"task_id": "t-001", "issues": [...]}');
```

### 9. Pod Handles Feedback

If feedback received:
- Resume Engineer with specific issues
- Engineer fixes → cycle repeats

### 10. Mission Completes

When all Pods done, user invokes `/maintenance` to archive.

## Context Filtering

Each agent only receives what they need:

| Agent | Receives | Does NOT Receive |
|-------|----------|------------------|
| **SAL** | Pod summaries from CAPCOM | Task details, code diffs |
| **Pod** | Task summaries, feedback | Other Pods' work, review logs |
| **Engineer** | Task requirements, feedback | Other tasks, review process |
| **Inspector** | Requirements + implementation | Code style issues |
| **Analyst** | Implementation summary | Requirements rationale |
| **CAPCOM** | All reports (summarizes before forwarding) | - |

## Plugin Structure

```
sal-9000/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── pod.md              # Pod subagent definition
│   ├── crew/               # Crew worker types
│   │   ├── engineer.md
│   │   ├── inspector.md
│   │   └── analyst.md
│   └── capcom.md           # Message broker
├── skills/
│   └── maintenance/SKILL.md
├── hooks/
│   └── hooks.json          # Triggers CAPCOM on Crew completion
├── mcp/
│   └── sal-db.ts           # MCP server for SQLite access
└── docs/
```

## Execution Modes

| Mode | Behavior |
|------|----------|
| **Supervised** | Pause after each task for review |
| **Checkpoints** | Auto-proceed tasks, pause after each Pod |
| **Autonomous** | Run everything, pause only on errors |

## Implementation Status

| Component | Status |
|-----------|--------|
| Architecture docs | ✓ Updated |
| Plugin metadata | ✓ Created |
| SQLite schema | ✓ Designed |
| Folder structure | ✓ Designed |
| Pod subagent | TODO |
| Crew: Engineer | TODO |
| Crew: Inspector | TODO |
| Crew: Analyst | TODO |
| CAPCOM subagent | TODO |
| Hooks | TODO |
| MCP server | TODO |
| Maintenance skill | ✓ Created |
