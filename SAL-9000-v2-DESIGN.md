# Launchpad: Architecture Design

*Formerly SAL-9000 v2*

**Name**: Launchpad - Agent orchestration for Claude Code

**Terminology**:
- **Launchpad** = The system/product name
- **SAL** = The main session role (your conversation with Claude, the commander)

---

## The Breakthrough

**Separate orchestration from execution.**

- SAL **orchestrates** (plans, reports) but stays outside the execution loop
- Pods **execute** but are ephemeral (fresh context every iteration)
- State lives **outside all agents** in SQLite + files

This combines:
- **Ralph's context freshness** - every execution layer resets
- **Hierarchical structure** - SAL → Pod → Worker → Inspector → Analyst
- **Persistent human interface** - SAL stays available for conversation

---

## The Computing Model

Agent orchestration maps directly to computer architecture:

| Traditional Computing | Agent Orchestration | Launchpad Component |
|-----------------------|---------------------|---------------------|
| CPU (stateless compute) | Claude Code session (fresh context) | Pod, Worker, Inspector, Analyst |
| RAM/Disk (persistent state) | SQLite + files | `.launchpad/launchpad.db`, CAPCOM log |
| Process lifecycle | Spawn → execute → exit | Each iteration of Ralph loop |
| OS scheduler | Bash loop / orchestrator | `ralph.sh` |
| IPC / message passing | File-based communication | CAPCOM log, SQLite messages table |

**The key insight**: Agents are compute, not memory.

You don't try to make agents remember - you give them clean state each time and let them process. Context rot happens when you treat agents like storage (accumulating context). Fresh agents + persistent state = indefinite scaling.

```
Traditional process:              Agent process:

┌─────────────┐                   ┌─────────────┐
│ Load from   │                   │ Read SQLite │
│ disk/RAM    │                   │ + task spec │
├─────────────┤                   ├─────────────┤
│             │                   │             │
│   COMPUTE   │        ≡          │   COMPUTE   │
│             │                   │   (fresh)   │
├─────────────┤                   ├─────────────┤
│ Write to    │                   │ Update DB   │
│ disk/RAM    │                   │ + CAPCOM    │
└─────────────┘                   └─────────────┘
      ↓                                 ↓
 Next process                     Next agent
 (new context)                    (fresh context)
```

The inference loop boundary (task completion) is the natural place to reset context - that's when state is clean and can be serialized to storage.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  YOU ↔ SAL (main session, persistent)                          │
│         │                                                       │
│         │ 1. Create mission, plan tasks                         │
│         │ 2. Start Ralph loop                                   │
│         │ 3. Read results when complete                         │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              RALPH LOOP (bash script)                   │    │
│  │                                                         │    │
│  │  while pending_tasks > 0:                               │    │
│  │                                                         │    │
│  │    ┌─────────────────────────────────────────────────┐  │    │
│  │    │           POD (fresh each iteration)            │  │    │
│  │    │                                                 │  │    │
│  │    │  1. Read SQLite → select highest priority task  │  │    │
│  │    │  2. Spawn Worker (fresh) → implements           │  │    │
│  │    │  3. Spawn Inspector (fresh) → reviews reqs      │  │    │
│  │    │     └── Fail? Spawn Worker again with feedback  │  │    │
│  │    │  4. Spawn Analyst (fresh) → reviews quality     │  │    │
│  │    │     └── Fail? Spawn Worker again with feedback  │  │    │
│  │    │  5. Run Airlock (tests/lint)                    │  │    │
│  │    │  6. Update CAPCOM log + SQLite                  │  │    │
│  │    │  7. Exit                                        │  │    │
│  │    └─────────────────────────────────────────────────┘  │    │
│  │                                                         │    │
│  │  end while                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│         │                                                       │
│         ▼                                                       │
│  SAL reads CAPCOM log, summarizes results to you                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components

### Layer 1: Human Interface

| Component | Type | Role |
|-----------|------|------|
| **SAL** | Main session | Plan missions, start loops, report results. Never executes code. |

SAL is your conversation partner. You describe what you want, SAL breaks it into missions/tasks, kicks off the Ralph loop, and summarizes results when complete.

### Layer 2: Execution Loop

| Component | Type | Role |
|-----------|------|------|
| **Ralph Loop** | Bash script | Spawns fresh Pods, checks SQLite for completion |
| **Pod** | Subagent (ephemeral) | Orchestrates one task through full review cycle |

The Ralph loop is the engine. Each iteration:
1. Query SQLite: any pending tasks?
2. If yes → spawn fresh Pod
3. If no → exit loop, mission complete

### Layer 3: Workers

| Component | Type | Role |
|-----------|------|------|
| **Worker** | Subagent (ephemeral) | Implements the task (writes code) |
| **Inspector** | Subagent (ephemeral) | Reviews against requirements |
| **Analyst** | Subagent (ephemeral) | Reviews code quality and patterns |

All workers are spawned by Pod via Task tool. Fresh context each time.

### Layer 4: Infrastructure

| Component | Type | Role |
|-----------|------|------|
| **CAPCOM log** | File | Append-only communication record |
| **SQLite** | Database | Task state, message routing |
| **Airlock** | Bash function | Runs tests/lint validation |

CAPCOM is **not an agent** - it's the messaging infrastructure. Agents read/write to CAPCOM log and SQLite.

---

## Data Flow

### Mission Creation (SAL)

```
User: "Build user authentication"
         │
         ▼
SAL creates mission in SQLite:
  INSERT INTO missions (id, title, status)
  VALUES ('m-001', 'user-auth', 'active')

SAL creates tasks:
  INSERT INTO tasks (id, mission_id, title, status, priority)
  VALUES
    ('t-001', 'm-001', 'JWT token generation', 'pending', 1),
    ('t-002', 'm-001', 'Login endpoint', 'pending', 2),
    ('t-003', 'm-001', 'Auth middleware', 'pending', 3)

Launchpad creates CAPCOM log:
  missions/active/user-auth/capcom.log

SAL starts Ralph loop:
  ./ralph.sh user-auth
```

### Task Execution (Pod)

```
Pod reads SQLite:
  SELECT * FROM tasks
  WHERE mission_id = 'm-001' AND status = 'pending'
  ORDER BY priority LIMIT 1
         │
         ▼
Pod spawns Worker with task context
         │
         ▼
Worker implements, returns result
         │
         ▼
Pod spawns Inspector with implementation
         │
         ├── Pass → continue
         └── Fail → spawn Worker with feedback, loop
         │
         ▼
Pod spawns Analyst with implementation
         │
         ├── Pass → continue
         └── Fail → spawn Worker with feedback, loop
         │
         ▼
Pod runs Airlock (bash):
  npm test && npm run lint
         │
         ▼
Pod updates state:
  UPDATE tasks SET status = 'complete' WHERE id = 't-001'
         │
         ▼
Pod appends to CAPCOM log:
  ## [2026-01-14 10:30] Pod-001 completed task t-001
  - Worker: Implemented JWT sign/verify
  - Inspector: PASSED - meets requirements
  - Analyst: PASSED - follows patterns
  - Airlock: PASSED - tests green
         │
         ▼
Pod exits (context discarded)
```

### Loop Completion

```
Ralph loop checks SQLite:
  SELECT COUNT(*) FROM tasks
  WHERE mission_id = 'm-001' AND status NOT IN ('complete', 'failed')
         │
         ├── > 0 → spawn next Pod
         └── = 0 → exit loop
         │
         ▼
SAL reads CAPCOM log, summarizes to user
```

---

## File Structure

```
.launchpad/
└── launchpad.db                        # SQLite coordination

system/
├── staging.md                          # Session buffer (full read, cleared often)
└── capcom.md                           # Master CAPCOM (append-only, grep only)

missions/
├── todo/                               # Not started
├── active/
│   └── user-auth/
│       ├── _mission.md                 # Mission overview
│       ├── capcom.log                  # Mission CAPCOM (execution logs)
│       └── tasks/
│           ├── t-001-jwt.md            # Task specs
│           └── t-002-login.md
├── complete/                           # Finished (with archived capcom.log)
└── archive/                            # Abandoned

docs/
├── architecture.md                     # Program-level docs
└── prd.md

scripts/
├── ralph.sh                            # The Ralph loop
├── airlock.sh                          # Test/lint validation
├── watcher.sh                          # Background notification watcher
└── prompts/
    ├── pod.md                          # Pod system prompt
    ├── worker.md                       # Worker system prompt
    ├── inspector.md                    # Inspector system prompt
    └── analyst.md                      # Analyst system prompt

commands/                               # Slash commands
├── login.md                            # /login - session start
├── logout.md                           # /logout - session end
└── capcom.md                           # /capcom - status check
```

---

## SQLite Schema (Simplified)

```sql
-- Missions
CREATE TABLE missions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT CHECK(status IN ('todo', 'active', 'complete', 'archived')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tasks (flat, no Pod layer in DB)
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    mission_id TEXT REFERENCES missions(id),
    title TEXT NOT NULL,
    description TEXT,
    status TEXT CHECK(status IN ('pending', 'in_progress', 'complete', 'failed')),
    priority INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
);

-- Messages (for structured queries)
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent TEXT NOT NULL,
    task_id TEXT REFERENCES tasks(id),
    type TEXT CHECK(type IN ('started', 'completed', 'failed', 'feedback')),
    content TEXT
);

-- Index for quick "what's pending" queries
CREATE INDEX idx_tasks_pending ON tasks(mission_id, status, priority)
WHERE status = 'pending';
```

---

## Ralph Loop Script

```bash
#!/bin/bash
# ralph.sh - The execution engine

MISSION_ID=$1
DB_PATH=".launchpad/launchpad.db"

if [ -z "$MISSION_ID" ]; then
    echo "Usage: ./ralph.sh <mission_id>"
    exit 1
fi

echo "Starting Ralph loop for mission: $MISSION_ID"

ITERATION=0
MAX_ITERATIONS=${2:-100}  # Safety limit

while true; do
    # Check for pending tasks
    PENDING=$(sqlite3 "$DB_PATH" \
        "SELECT COUNT(*) FROM tasks
         WHERE mission_id = '$MISSION_ID'
         AND status NOT IN ('complete', 'failed')")

    if [ "$PENDING" -eq 0 ]; then
        echo "Mission complete! All tasks done."
        break
    fi

    if [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Max iterations reached: $MAX_ITERATIONS"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo ""
    echo "═══════════════════════════════════════════"
    echo "ITERATION $ITERATION - $PENDING tasks remaining"
    echo "═══════════════════════════════════════════"

    # Spawn fresh Pod
    cat scripts/prompts/pod.md | claude -p \
        --dangerously-skip-permissions \
        --model sonnet

done

echo ""
echo "Ralph loop complete after $ITERATION iterations"
```

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| SAL outside loop | Yes | Keeps human interface persistent, avoids context rot |
| Pod per iteration | Fresh | Maximum context efficiency |
| Worker/Inspector/Analyst | Three agents | Thorough review, each with fresh context |
| CAPCOM as infrastructure | Not an agent | Simpler, no AI needed for routing |
| Task dependencies | Pod decides | Keep simple, avoid complex dependency graphs |
| Stopping condition | SQLite query | Clean, reliable, no special signals |

---

## Launch Options

When SAL prepares a mission, it presents the user with launch options:

```
Mission "user-auth" ready (3 tasks)

How would you like to run it?

1. Attended (recommended for new missions)
   → Run in separate terminal: claude -p < .launchpad/missions/user-auth/ralph-prompt.md

2. Background
   → I'll start it now, use /capcom to check progress

3. tmux session
   → I'll create a session, attach with: tmux attach -t user-auth
```

| Mode | How It Works | User Visibility | SAL Availability |
|------|--------------|-----------------|------------------|
| **Attended** | User runs command in separate terminal | Full - watching directly | Available for conversation |
| **Background** | SAL runs `ralph.sh` with `run_in_background: true` | Use `/capcom` to check | Available for conversation |
| **tmux** | SAL creates tmux session | `tmux attach` to watch | Available for conversation |

**Attended mode** is recommended for new missions (Huntley's "attended → unattended" progression). Once you trust the mission setup, switch to background or tmux.

---

## CAPCOM Skill

The `/capcom` command lets users check mission status without blocking SAL.

### Architecture

```
User: /capcom
    │
    ▼
┌─────────────────────────────────────────┐
│  SAL                                    │
│  → Invokes Launchpad capcom skill       │
│  → Spawns CAPCOM subagent (Task tool)   │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  CAPCOM Subagent (fresh context)        │
│  → Query SQLite for mission/task state  │
│  → Read recent CAPCOM log entries       │
│  → Format summary                       │
│  → Return to SAL                        │
│  → Exit (context discarded)             │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  SAL                                    │
│  → Receives summary                     │
│  → Displays formatted output to user    │
└─────────────────────────────────────────┘
```

This keeps SAL's context lean - the subagent does the heavy lifting (SQLite queries, log parsing), returns just the summary.

### Output Format

```
CAPCOM — Mission: user-auth
═══════════════════════════════════════
Status: ACTIVE (iteration 3 of Ralph loop)

Tasks:
  ✓ t-001 JWT token generation     [complete]
  ◉ t-002 Login endpoint           [in_progress]
  ○ t-003 Auth middleware          [pending]

Recent activity:
  [10:32] Pod-003 started task t-002
  [10:31] Pod-002 completed t-001 (Worker ✓ Inspector ✓ Analyst ✓)
  [10:28] Pod-002 started task t-001

──────────────────────────────────────
Run: tmux attach -t user-auth (if tmux mode)
```

### Triggers

| Trigger | Description |
|---------|-------------|
| **Manual** | User types `/capcom` when curious |
| **SAL-prompted** | SAL occasionally asks "Want a CAPCOM update?" |
| **On completion** | SAL detects mission complete, auto-summarizes |

---

## Notifications System

Cross-session notification allows Ralph/Pods to signal SAL when events occur.

### The Challenge

Claude Code hooks are session-local - a hook in Pod's session can't directly call into SAL's session. Solution: file-based coordination with hook polling.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  SAL's Claude Code session                                      │
│                                                                 │
│  Hook: PreToolUse (fires before every tool)                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  #!/bin/bash                                               │ │
│  │  if [ -f .launchpad/notifications ]; then                  │ │
│  │    cat .launchpad/notifications                            │ │
│  │    rm .launchpad/notifications                             │ │
│  │  fi                                                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ reads
                              │
┌─────────────────────────────────────────────────────────────────┐
│  .launchpad/notifications (file)                                │
│                                                                 │
│  Written by background watcher or Ralph loop directly           │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ writes
                              │
┌─────────────────────────────────────────────────────────────────┐
│  Background watcher (started by SAL)                            │
│                                                                 │
│  while true; do                                                 │
│    # Check for completed missions                               │
│    COMPLETE=$(sqlite3 .launchpad/launchpad.db \                 │
│      "SELECT id FROM missions WHERE status='complete' \         │
│       AND notified=0")                                          │
│    if [ -n "$COMPLETE" ]; then                                  │
│      echo "Mission $COMPLETE complete!" >> .launchpad/notifications│
│      sqlite3 .launchpad/launchpad.db \                          │
│        "UPDATE missions SET notified=1 WHERE id='$COMPLETE'"    │
│    fi                                                           │
│    sleep 5                                                      │
│  done                                                           │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ monitors
                              │
┌─────────────────────────────────────────────────────────────────┐
│  Ralph loop / Pods                                              │
│                                                                 │
│  Update SQLite as they work                                     │
│  On completion: UPDATE missions SET status='complete'           │
└─────────────────────────────────────────────────────────────────┘
```

### Flow

1. SAL starts background watcher (optional) or Ralph writes directly
2. Ralph/Pods update SQLite as they work
3. On mission complete, watcher detects and writes `.launchpad/notifications`
4. Next time SAL uses any tool, hook fires, sees file, outputs content
5. SAL sees hook output, reports to user

### macOS Notification (Optional)

For immediate user attention, Ralph loop can trigger system notification:

```bash
# At end of ralph.sh, after loop completes:
osascript -e 'display notification "Mission complete: user-auth" with title "Launchpad"'
```

User sees macOS notification → returns to SAL → SAL detects completion → auto-summarizes.

### Limitation

Hook-based notification fires on next SAL tool use, not true real-time interruption. For most workflows this is sufficient - during active conversation, tool use is frequent.

---

## Session Commands

Launchpad provides `/login` and `/logout` commands for session management (like HAL's `/boot`/`/shutdown`).

### `/login`

Initialize SAL session and load current state.

```
1. Read master CAPCOM (system/capcom.md)
2. Query SQLite for active missions
3. Check for running background processes
4. Present status overview

Output:
─────────────────────────────────────────
LAUNCHPAD — Session Start
═════════════════════════════════════════

Active Missions:
  ◉ user-auth      [3/5 tasks] background running
  ○ api-refactor   [0/4 tasks] ready to start

Recent Activity (from master CAPCOM):
  [Yesterday] Completed: database-migration (5 tasks)
  [2 days ago] Completed: auth-endpoints (3 tasks)

Background Processes:
  ⚡ ralph.sh user-auth (PID 12345) - running 23m

Options:
  1. /capcom         - Check user-auth progress
  2. Start new mission
  3. Resume api-refactor
─────────────────────────────────────────
```

### `/logout`

Clean session end with state persistence.

```
1. Check for running background processes
   → Warn if missions still active
2. Update master CAPCOM with session summary
3. Optionally compress old entries (--compress flag)
4. Show session summary

Output:
─────────────────────────────────────────
LAUNCHPAD — Session End
═════════════════════════════════════════

Session Summary:
  Started: user-auth mission
  Progress: 3/5 tasks complete
  Status: Background process still running

⚠️  Warning: Ralph loop still active (PID 12345)
    Use `kill 12345` to stop, or leave running

Master CAPCOM updated with:
  - Session start/end times
  - Mission progress snapshot
  - [Compressed 3 old entries] (if --compress)

Next session: /login to resume
─────────────────────────────────────────
```

---

## Memory Architecture

Launchpad uses a three-tier memory system, similar to HAL-OS but optimized for agent orchestration.

### Three Tiers

```
┌─────────────────────────────────────────────────────────────┐
│  system/staging.md                                          │
│  - Scratch buffer for current session                       │
│  - Full read on /login                                      │
│  - Cleared or archived on /logout                           │
│  - Working notes, pending items, active context             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  system/capcom.md (Master CAPCOM)                           │
│  - Append-only source of truth                              │
│  - NEVER read in full (grep only)                           │
│  - Session entries: missions, decisions, learnings          │
│  - /logout appends new session entry                        │
│  - Expected to grow to 1000s of lines over time             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  missions/active/[name]/capcom.log                          │
│  - Per-mission execution logs                               │
│  - Pod/Worker/Inspector activity (detailed)                 │
│  - Moved to missions/complete/ when done                    │
└─────────────────────────────────────────────────────────────┘
```

| Tier | File | Read Pattern | Write Pattern | Lifecycle |
|------|------|--------------|---------------|-----------|
| **Staging** | `system/staging.md` | Full read | Overwrite | Per-session |
| **Master CAPCOM** | `system/capcom.md` | Grep only | Append only | Permanent |
| **Mission CAPCOM** | `missions/.../capcom.log` | Full or grep | Append | Per-mission |

### staging.md (Session Buffer)

Active workspace for current session. Read fully on `/login`, cleared on `/logout`.

```markdown
# Staging

Current session workspace.

## Pending

- [ ] Review user-auth mission output
- [ ] Check why t-003 failed

## Notes

Worker on t-002 needed 2 retries - validation logic was complex.
Consider breaking down validation tasks more granularly.

## Scratch

[temporary working notes...]
```

### capcom.md (Master CAPCOM)

Append-only source of truth. **Never read in full** - grep for context.

```markdown
# CAPCOM

Master log. Append only. Grep to query.

---

## Session 1 - 2026-01-10 - Initial Setup ✅

**Missions:** Created project structure
**Decisions:** SQLite over Beads CLI for v1 (simpler)
**Next:** Implement ralph.sh

---

## Session 2 - 2026-01-11 - Ralph Loop ✅

**Missions:**
- test-mission: 3/3 tasks complete

**Decisions:**
- Pod uses sonnet, Workers use haiku (cost optimization)
- Airlock runs after Analyst pass, not before

**Issues:**
- Worker retried 4x on validation task - need clearer specs

**Learnings:**
- Small, specific tasks = fewer retries
- Inspector catches spec drift, Analyst catches code quality

**Next:** Add /capcom status command

---

## Session 3 - 2026-01-12 - CAPCOM Skill
...
```

**Grep patterns:**
```bash
# Find all decisions
grep -A2 "^\*\*Decisions:" system/capcom.md

# Find specific mission
grep -A10 "user-auth" system/capcom.md

# Find issues/learnings
grep -A2 "^\*\*Issues:\|^\*\*Learnings:" system/capcom.md

# Get latest session
grep -n "^## Session" system/capcom.md | tail -1
```

### Lifecycle

```
/login
    │
    ├── Read staging.md (full)
    ├── Grep capcom.md for latest session
    ├── Query SQLite for active missions
    └── Present status

[Session work...]

/logout
    │
    ├── Append session entry to capcom.md
    ├── Clear or archive staging.md
    ├── Optionally compress old capcom entries
    └── Show summary
```

### Compression

Old Master CAPCOM entries compress to preserve learnings while reducing detail:

**Before:**
```
## Session 5 - 2025-12-10 - Auth Endpoints ✅

**Missions:**
- auth-endpoints: 3/3 tasks complete
  - t-001: JWT generation - Worker ✓, Inspector ✓, Analyst found missing expiry, Worker fixed ✓
  - t-002: Login endpoint - Worker ✓, Inspector edge case, Worker fixed ✓
  - t-003: Logout - Clean pass ✓

**Decisions:** Use RS256 for JWT signing
**Issues:** Analyst catches things Inspector misses
**Learnings:** Auth tasks need thorough specs
```

**After (compressed):**
```
## December 2025 (Sessions 1-8) [COMPRESSED]

- 4 missions, 15 tasks completed
- Key: Analyst catches validation edge cases - worth the review cost
- Pattern: Auth tasks often need 1-2 Worker retries
- Decision: RS256 for JWT (Session 5)
```

**Triggers:**
- Manual: `/logout --compress`
- Auto: Sessions older than 30 days
- Size: When capcom.md exceeds threshold

---

## Research Patterns Applied

| Pattern | How It's Used |
|---------|---------------|
| **Ralph Wiggum** | Fresh Pod each iteration, state in files/SQLite |
| **Superpowers** | GUPP-like: Pod executes autonomously, no waiting |
| **Beads** | SQLite for state, CAPCOM log for audit trail |
| **Gas Town** | Hierarchical roles, but ephemeral not persistent |
| **tmux** | Future: can swap Task tool for tmux sessions |

---

## Implementation Order

### Phase 1: Core Engine
1. **SQLite schema** - Create database and tables (+ `notified` column)
2. **Ralph script** - Basic loop with SQLite check
3. **Pod prompt** - Task selection, worker spawning
4. **Worker prompt** - Implementation with context
5. **Inspector prompt** - Requirements review
6. **Analyst prompt** - Quality review
7. **Airlock script** - Test/lint validation

### Phase 2: Memory & Session
8. **staging.md format** - Session buffer structure
9. **capcom.md format** - Master CAPCOM append format
10. **Mission capcom.log format** - Per-mission execution log format
11. **`/login` command** - Read staging, grep capcom, query SQLite, present status
12. **`/logout` command** - Append to capcom, clear staging, warn on active processes

### Phase 3: Monitoring & Integration
13. **Launch options** - Attended/background/tmux selection in SAL
14. **`/capcom` skill** - Status check with subagent
15. **Notification hook** - PreToolUse hook for cross-session alerts
16. **Background watcher** - Optional SQLite monitor script

### Phase 4: Polish
17. **Compression** - `/logout --compress` and auto-compression logic
18. **macOS notifications** - `osascript` alerts on mission complete

---

## Verification

To test the system end-to-end:

1. Create a simple mission via SAL
2. Verify SQLite has mission + tasks
3. Run `./ralph.sh <mission_id>` manually
4. Observe Pod spawning, worker execution
5. Check CAPCOM log for communication record
6. Verify tasks marked complete in SQLite
7. Confirm loop exits when all tasks done

---

## Future Evolution

### Near-term
- **Parallel Pods**: Multiple Ralph loops for independent features (separate worktrees)
- **Beads integration**: Replace SQLite with `bd` CLI if distributed coordination needed

### Long-term (Swarm Scale)
- **tmux orchestration**: Full tmux-based agent management for 10+ agents
- **Web dashboard**: Real-time visualization beyond CLI (complements `/capcom`)
- **Witness agent**: Health monitoring for stuck/failed agents (Gas Town pattern)
- **Git worktree isolation**: Each Pod gets isolated workspace to prevent conflicts
