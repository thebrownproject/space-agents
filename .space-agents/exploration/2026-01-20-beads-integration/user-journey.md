# Beads Integration: Complete User Journey

**Date:** 2026-01-20
**Purpose:** Step-by-step walkthrough of how users interact with Space-Agents after Beads integration

---

## Table of Contents

1. [Installation & Setup](#phase-1-installation--setup)
2. [Launch & First Epic](#phase-2-launch--first-epic)
3. [Exploration (Optional)](#phase-3-exploration-optional)
4. [Mission Planning](#phase-4-mission-planning)
5. [Activate Feature](#phase-5-activate-feature)
6. [Execute Feature](#phase-6-execute-feature-the-main-loop)
7. [Check Status Anytime](#phase-7-check-status-anytime)
8. [Multi-Machine Workflow](#phase-8-multi-machine-workflow)
9. [Visual Dependency Inspection](#phase-9-visual-dependency-inspection)
10. [Complete User Journey Summary](#complete-user-journey-summary)

---

## Phase 1: Installation & Setup

### `/install` - First Time Setup

**User runs:**
```bash
claude /install
```

**What happens:**
1. HOUSTON checks for dependencies (claude CLI, git, mprocs, **bd CLI**)
2. Creates `.space-agents/` directory structure
3. **NEW:** Runs `bd init` instead of creating SQLite database
4. **NEW:** Creates `.beads/` directory with:
   - `.beads/beads.db` (local cache, gitignored)
   - `.beads/issues.jsonl` (committed to git)
5. Creates issue templates:
```bash
bd template create epic --title "Epic: {title}" --description "Large initiative"
bd template create feature --title "Feature: {title}" --description "Work item"
bd template create task --title "Task: {title}" --description "Implementation subtask"
```
6. Commits initial setup to git

**Beads State After:**
```
.beads/
├── beads.db (empty database)
└── issues.jsonl (empty file, ready for issues)
```

**User sees:**
```
Space-Agents installed successfully!
✓ Dependencies verified
✓ Beads initialized
✓ Directory structure created

Ready to launch. Run /launch to create your first epic.
```

---

## Phase 2: Launch & First Epic

### `/launch` - Initialize Project

**User runs:**
```bash
claude /launch
```

**What happens:**
1. HOUSTON asks: "What's your project about?"
2. User: "Build a task management API"
3. **NEW:** HOUSTON creates the first epic in Beads:
```bash
bd create "Epic: Task Management API" \
  -t epic \
  --label project:space-agents \
  --label category:voyage \
  --priority 1 \
  --description "Build REST API for task management with auth, CRUD, and notifications"
```
4. **NEW:** Beads generates hash ID: `bd-a3f8`
5. Creates epic directory: `.space-agents/epics/open/bd-a3f8-task-management-api/`
6. **NEW:** Runs `bd sync` - commits to `.beads/issues.jsonl`:
```jsonl
{"id":"bd-a3f8","type":"epic","title":"Epic: Task Management API","status":"open","priority":1,"labels":["project:space-agents","category:voyage"],"created_at":"2026-01-20T10:00:00Z"}
```
7. Git commits the JSONL file

**Beads State After:**
```
bd-a3f8 [epic] Epic: Task Management API (open)
```

**User sees:**
```
Epic created: bd-a3f8

Title: Task Management API
Status: Open
Type: Epic

Ready to start planning. Run /exploration or /mission-brief when ready.
```

---

## Phase 3: Exploration (Optional)

### `/exploration` - Brainstorm Ideas

**User runs:**
```bash
claude /exploration
```

**What happens:**
1. HOUSTON asks questions about the feature
2. User and HOUSTON discuss architecture, approach, risks
3. May spawn background agents (exploration-research, exploration-architecture, exploration-risk)
4. **Beads is NOT used during exploration** - it's pure conversation
5. At the end, creates exploration document in `.space-agents/exploration/YYYY-MM-DD-topic/`
6. No Beads issues created yet

**This phase doesn't touch Beads - it's planning only.**

**User sees:**
```
We've explored your authentication approach. Key decisions:
- JWT with HS256 algorithm
- Token expiry: 24 hours
- Refresh token pattern for long sessions
- Password hashing with bcrypt

Want me to write up an exploration report? [yes/no]
```

---

## Phase 4: Mission Planning

### `/mission-brief` - Create Feature with Tasks

**User runs:**
```bash
claude /mission-brief
```

**What HOUSTON does:**
1. Spawns planning agents (sequencer → planner → implementer)
2. Agents analyze the epic, break down into features and tasks
3. **NEW:** Agents use Beads to create the work breakdown:

**Sequencer creates features:**
```bash
# Feature 1
bd create "Feature: User Authentication" \
  --parent bd-a3f8 \
  -t feature \
  --label epic:bd-a3f8 \
  --priority 1 \
  --description "JWT-based authentication with login/logout"
# → bd-a3f8.1

# Feature 2
bd create "Feature: Task CRUD API" \
  --parent bd-a3f8 \
  -t feature \
  --label epic:bd-a3f8 \
  --priority 2
# → bd-a3f8.2
```

**Planner creates tasks under Feature 1:**
```bash
bd create "Task: Create user model and schema" \
  --parent bd-a3f8.1 \
  -t task \
  --label feature:bd-a3f8.1 \
  --priority 1 \
  --description "Create User model with email, password hash, timestamps"
# → bd-a3f8.1.1

bd create "Task: Implement JWT signing" \
  --parent bd-a3f8.1 \
  -t task \
  --label feature:bd-a3f8.1 \
  --priority 2 \
  --description "Create signToken() and verifyToken() functions with HS256"
# → bd-a3f8.1.2

bd create "Task: Add login endpoint" \
  --parent bd-a3f8.1 \
  -t task \
  --label feature:bd-a3f8.1 \
  --priority 3 \
  --description "POST /auth/login - validate credentials, return JWT"
# → bd-a3f8.1.3

bd create "Task: Add logout endpoint" \
  --parent bd-a3f8.1 \
  -t task \
  --label feature:bd-a3f8.1 \
  --priority 4 \
  --description "POST /auth/logout - invalidate token, clear session"
# → bd-a3f8.1.4
```

4. **NEW:** Runs `bd sync` - commits all issues to `.beads/issues.jsonl`
5. Creates mission brief document at `.space-agents/epics/in_progress/bd-a3f8-task-management-api/open/bd-a3f8.1-user-authentication/mission-brief.md`

**Beads State After:**
```
bd-a3f8 [epic] Epic: Task Management API
  ├─ bd-a3f8.1 [feature] Feature: User Authentication (open)
  │   ├─ bd-a3f8.1.1 [task] Task: User model (open)
  │   ├─ bd-a3f8.1.2 [task] Task: JWT signing (open)
  │   ├─ bd-a3f8.1.3 [task] Task: Login endpoint (open)
  │   └─ bd-a3f8.1.4 [task] Task: Logout endpoint (open)
  └─ bd-a3f8.2 [feature] Feature: Task CRUD API (open)
      └─ (tasks to be planned)
```

**User sees:**
```
Mission Brief Created: Feature: User Authentication (bd-a3f8.1)

Overview:
JWT-based authentication system with secure login/logout

Tasks Created: 4
─────────────────
Priority 1: bd-a3f8.1.1 - Create user model and schema
Priority 2: bd-a3f8.1.2 - Implement JWT signing
Priority 3: bd-a3f8.1.3 - Add login endpoint
Priority 4: bd-a3f8.1.4 - Add logout endpoint

Mission brief document: .space-agents/epics/in_progress/bd-a3f8-task-management-api/open/bd-a3f8.1-user-authentication/mission-brief.md

Ready to execute. Run /mission-go bd-a3f8.1
```

---

## Phase 5: Activate Feature

### `/dock` - Activate Feature for Execution

**User runs:**
```bash
claude /dock bd-a3f8.1
```

**What happens:**
1. **NEW:** HOUSTON updates feature status in Beads:
```bash
bd update bd-a3f8.1 --status in_progress
bd sync
```
2. Moves feature folder: `.space-agents/epics/in_progress/bd-a3f8-task-management-api/open/bd-a3f8.1-user-authentication/` → `in_progress/bd-a3f8.1-user-authentication/`
3. Creates CAPCOM log: `.space-agents/epics/in_progress/bd-a3f8-task-management-api/in_progress/bd-a3f8.1-user-authentication/capcom.log`

**Beads State After:**
```
bd-a3f8.1 [feature] Feature: User Authentication (in_progress) ← STATUS CHANGED
```

**User sees:**
```
Feature bd-a3f8.1 activated and ready for execution.

Status: in_progress
Tasks: 4 pending
Location: .space-agents/epics/in_progress/bd-a3f8-task-management-api/in_progress/bd-a3f8.1-user-authentication/

Run /mission-go bd-a3f8.1 to start Ralph loop.
```

---

## Phase 6: Execute Feature (The Main Loop!)

### `/mission-go` - Start Ralph Loop

**User runs:**
```bash
claude /mission-go bd-a3f8.1
```

**What happens - Overview:**
Ralph enters an execution loop that:
1. Queries Beads for next unblocked task
2. Spawns Pod to execute the task
3. If success: marks complete
4. If failure: creates blocking bug
5. **Ralph also works on bugs!** Treats them as high-priority tasks
6. Loops until all tasks complete

---

### Iteration 1: First Task Success

**Ralph queries Beads:**
```bash
bd ready --json | \
    jq -r '.[] |
        select(.labels[] | contains("feature:bd-a3f8.1")) |
        select(.type == "task") |
        "\(.id)|\(.title)|\(.description)"' | \
    head -1
```

**Beads returns:**
```
bd-a3f8.1.1|Task: Create user model and schema|Create User model with email, password hash, timestamps
```

**Ralph marks in progress:**
```bash
bd update bd-a3f8.1.1 --status in_progress
bd sync
```

**Ralph spawns Pod:**
```bash
claude /pod bd-a3f8.1.1
```

**Pod executes (3-agent review):**
1. **Worker:** Creates `src/models/user.ts` with User model
2. **Inspector:** Reviews code, runs tests
3. **Analyst:** Validates against requirements

**Pod reports success (exit 0)**

**Ralph marks complete:**
```bash
bd close bd-a3f8.1.1 --reason "Completed by Pod - User model created with Mongoose schema, includes email validation and password hashing setup"
bd sync  # Commits to .beads/issues.jsonl
```

**Beads State After Iteration 1:**
```
bd-a3f8.1.1 [task] Task: User model (closed) ✓ COMPLETED
bd-a3f8.1.2 [task] Task: JWT signing (open) ← NEXT
bd-a3f8.1.3 [task] Task: Login endpoint (open)
bd-a3f8.1.4 [task] Task: Logout endpoint (open)
```

**User sees (in terminal):**
```
[2026-01-20 10:15:23] INFO --- Iteration 1 ---
[2026-01-20 10:15:23] INFO Selected task: Create user model and schema (bd-a3f8.1.1)
[2026-01-20 10:15:23] INFO Spawning Pod for task: bd-a3f8.1.1
[2026-01-20 10:18:45] SUCCESS Pod completed task: Create user model and schema
[2026-01-20 10:18:45] SUCCESS Task marked complete: bd-a3f8.1.1
```

---

### Iteration 2: Task Fails Validation (Bug Created!)

**Ralph queries Beads:**
```bash
bd ready --json
```

**Beads returns:**
```
bd-a3f8.1.2|Task: Implement JWT signing|Create signToken() and verifyToken() functions with HS256
```

**Ralph spawns Pod for bd-a3f8.1.2**

**Pod executes:**
1. **Worker:** Implements JWT signing in `src/auth/jwt.ts`
2. **Inspector:** Reviews code
3. **Inspector calls /airlock** to validate

**Airlock runs validation:**
```bash
npm test
npm run lint
```

**Tests FAIL:**
```
FAIL src/auth/jwt.test.ts
  ✕ signToken should use HS256 algorithm (expected HS256, got RS256)
```

**Airlock creates blocking bug:**
```bash
# Create bug
bd create "Bug: JWT signing tests failing - expects HS256, got RS256" \
  --parent bd-a3f8.1 \
  -t bug \
  --label feature:bd-a3f8.1 \
  --label severity:blocker \
  --label source:airlock \
  --priority 0 \
  --description "Tests expect HS256 algorithm but implementation uses RS256. Need to change jwt.sign() call to use HS256."
# → bd-bug-f7c2

# Block the original task
bd dep add bd-a3f8.1.2 bd-bug-f7c2
bd sync
```

**Pod exits with code 1** (blocker)

**Ralph receives blocker exit code:**
```bash
# Ralph does NOT mark task complete
# Task remains open but is now blocked by bug
```

**Beads State After Iteration 2:**
```
bd-a3f8.1.2 [task] Task: JWT signing (open) ⊘ BLOCKED BY bd-bug-f7c2
bd-bug-f7c2 [bug] Bug: JWT signing tests failing (open, priority 0) ← BLOCKS bd-a3f8.1.2
```

**Graph visualization:**
```
bd-a3f8.1.2 [task] ──blocks──> bd-bug-f7c2 [bug]
    (can't proceed)              (must fix first)
```

**User sees:**
```
[2026-01-20 10:20:12] INFO --- Iteration 2 ---
[2026-01-20 10:20:12] INFO Selected task: Implement JWT signing (bd-a3f8.1.2)
[2026-01-20 10:20:12] INFO Spawning Pod for task: bd-a3f8.1.2
[2026-01-20 10:24:33] WARNING Pod reported blocker for: Implement JWT signing
[2026-01-20 10:24:33] WARNING Blocking bug created: bd-bug-f7c2
[2026-01-20 10:24:33] INFO Continuing to next objective...
```

---

### Iteration 3: Ralph Fixes The Bug! (This is the magic!)

**Ralph queries Beads:**
```bash
bd ready --json
```

**Beads returns:**
```
bd-bug-f7c2|Bug: JWT signing tests failing - expects HS256, got RS256|Tests expect HS256 algorithm...
```

**KEY INSIGHT:** Beads returns the **bug**, NOT bd-a3f8.1.2 (which is blocked).

**Ralph treats bug as a task:**
```bash
# Ralph marks bug in progress
bd update bd-bug-f7c2 --status in_progress
bd sync

# Ralph spawns Pod to fix the bug
claude /pod bd-bug-f7c2
```

**Pod executes bug fix:**
1. **Worker:** Changes `src/auth/jwt.ts` - switches algorithm to HS256
2. **Inspector:** Reviews fix
3. **Inspector calls /airlock** to validate

**Airlock runs validation:**
```bash
npm test
```

**Tests PASS!** ✓

**Pod reports success (exit 0)**

**Ralph marks bug complete:**
```bash
bd close bd-bug-f7c2 --reason "Fixed: Changed JWT algorithm from RS256 to HS256 in jwt.sign() call. All tests passing."
bd sync
```

**Beads State After Iteration 3:**
```
bd-a3f8.1.2 [task] Task: JWT signing (open) ← NOW UNBLOCKED!
bd-bug-f7c2 [bug] Bug: JWT signing tests failing (closed) ✓
```

**The graph edge is gone - task is unblocked!**

**User sees:**
```
[2026-01-20 10:25:01] INFO --- Iteration 3 ---
[2026-01-20 10:25:01] INFO Selected task: Bug: JWT signing tests failing (bd-bug-f7c2)
[2026-01-20 10:25:01] INFO Spawning Pod for bug: bd-bug-f7c2
[2026-01-20 10:28:15] SUCCESS Pod completed bug fix: JWT signing tests failing
[2026-01-20 10:28:15] SUCCESS Bug marked closed: bd-bug-f7c2
```

---

### Iteration 4: Resume Original Task

**Ralph queries Beads:**
```bash
bd ready --json
```

**Beads returns:**
```
bd-a3f8.1.2|Task: Implement JWT signing|Create signToken() and verifyToken() functions with HS256
```

**Task is unblocked! Ralph can continue.**

**Ralph spawns Pod for bd-a3f8.1.2 again**

**Pod executes:**
1. **Worker:** Sees JWT signing is already implemented (from bug fix)
2. **Worker:** Adds verifyToken() function
3. **Worker:** Adds error handling
4. **Inspector:** Reviews, validates with Airlock
5. **Airlock:** Tests pass ✓

**Pod reports success**

**Ralph marks task complete:**
```bash
bd close bd-a3f8.1.2 --reason "Completed: JWT signing and verification implemented with HS256, tests passing, error handling added"
bd sync
```

**Beads State After Iteration 4:**
```
bd-a3f8.1.2 [task] Task: JWT signing (closed) ✓ COMPLETED
bd-a3f8.1.3 [task] Task: Login endpoint (open) ← NEXT
bd-a3f8.1.4 [task] Task: Logout endpoint (open)
```

**User sees:**
```
[2026-01-20 10:28:45] INFO --- Iteration 4 ---
[2026-01-20 10:28:45] INFO Selected task: Implement JWT signing (bd-a3f8.1.2)
[2026-01-20 10:28:45] INFO Spawning Pod for task: bd-a3f8.1.2
[2026-01-20 10:31:22] SUCCESS Pod completed task: Implement JWT signing
[2026-01-20 10:31:22] SUCCESS Task marked complete: bd-a3f8.1.2
```

---

### Iterations 5-6: Remaining Tasks Complete

**Iteration 5:** bd-a3f8.1.3 (Login endpoint) - completes successfully
**Iteration 6:** bd-a3f8.1.4 (Logout endpoint) - completes successfully

**All tasks done!**

---

### Feature Completion

**Ralph checks if feature is complete:**
```bash
check_feature_complete() {
    # No open children = complete
    ! bd list --json | jq -e '.[] |
        select(.parent == "bd-a3f8.1") |
        select(.status == "open")'
}
```

**All tasks closed → Feature is complete!**

**Ralph marks feature complete:**
```bash
bd close bd-a3f8.1 --reason "All 4 tasks completed successfully. User authentication system implemented with JWT."
bd sync
```

**Ralph moves mission folder:**
```bash
mv .space-agents/epics/in_progress/bd-a3f8-task-management-api/in_progress/bd-a3f8.1-user-authentication \
   .space-agents/epics/in_progress/bd-a3f8-task-management-api/closed/bd-a3f8.1-user-authentication
```

**Ralph exits with code 0**

**Final Beads State:**
```
bd-a3f8.1 [feature] Feature: User Authentication (closed) ✓
  ├─ bd-a3f8.1.1 [task] Task: User model (closed) ✓
  ├─ bd-a3f8.1.2 [task] Task: JWT signing (closed) ✓
  ├─ bd-a3f8.1.3 [task] Task: Login endpoint (closed) ✓
  ├─ bd-a3f8.1.4 [task] Task: Logout endpoint (closed) ✓
  └─ bd-bug-f7c2 [bug] Bug: JWT tests (closed) ✓
```

**User sees:**
```
============================================
MISSION COMPLETE: Feature: User Authentication
============================================

Tasks completed: 4/4
Bugs fixed: 1
Duration: 45 minutes

Files changed:
  • src/models/user.ts
  • src/auth/jwt.ts
  • src/routes/auth.ts
  • tests/auth/*.test.ts

Feature moved to: .space-agents/epics/in_progress/bd-a3f8-task-management-api/closed/bd-a3f8.1-user-authentication/

Run /capcom to see overall status.
```

---

## Phase 7: Check Status Anytime

### `/capcom` - Status Report

**User runs (during or after execution):**
```bash
claude /capcom
```

**What happens:**
1. HOUSTON spawns CAPCOM agent
2. **NEW: CAPCOM queries Beads:**
```bash
# Get all epics
bd list --json | jq '.[] | select(.type == "epic")'

# Get all features
bd list --json | jq '.[] | select(.type == "feature")'

# Get tasks by feature
bd list --json | jq '.[] | select(.parent == "bd-a3f8.1")'

# Get open bugs
bd list --json | jq '.[] | select(.type == "bug") | select(.status == "open")'

# Get statistics
bd stats
```

3. **CAPCOM formats report**

**User sees:**
```
────────────────────────────────────────────────────────────────────
CAPCOM STATUS REPORT
────────────────────────────────────────────────────────────────────

EPICS: 1 total (1 active)
─────────────────
◐ bd-a3f8: Epic: Task Management API (active)

FEATURES: 2 total (1 complete, 1 active)
─────────────────
● bd-a3f8.1: Feature: User Authentication (complete)
◐ bd-a3f8.2: Feature: Task CRUD API (active)

TASKS: 8 total (4 complete, 2 in_progress, 2 pending)
─────────────────
bd-a3f8.2 - Feature: Task CRUD API:
  ◐ bd-a3f8.2.1: Create task model (in_progress)
  ○ bd-a3f8.2.2: Add GET /tasks endpoint (pending)
  ○ bd-a3f8.2.3: Add POST /tasks endpoint (pending)
  ○ bd-a3f8.2.4: Add DELETE /tasks endpoint (pending)

BUGS: 0 active
─────────────────
No active bugs

STATISTICS (from bd stats):
─────────────────
Total issues: 15
Open: 5
Closed: 10
Bugs fixed: 1

────────────────────────────────────────────────────────────────────
HOUSTON standing by. What would you like to do next?
────────────────────────────────────────────────────────────────────
```

---

## Phase 8: Multi-Machine Workflow

### Working Across Devices

**Scenario:** Start on laptop, continue on desktop

**On Laptop:**
```bash
# Plan a feature
claude /mission-brief

# HOUSTON creates features/tasks in Beads
# bd create "Feature: ..." --parent bd-epic
# bd create "Task: ..." --parent bd-feature
# bd sync  # Commits to .beads/issues.jsonl

# Push to remote
git add .beads/issues.jsonl
git commit -m "feat: add Task CRUD feature with 4 tasks"
git push
```

**On Desktop:**
```bash
# Pull changes
git pull

# Beads automatically detects .beads/issues.jsonl changes
# Imports new issues to local .beads/beads.db cache

# Continue where laptop left off
claude /mission-go bd-a3f8.2

# Ralph sees all the tasks created on laptop!
# No manual database copying needed
```

**The magic:**
- `.beads/issues.jsonl` is committed to git (source of truth)
- `.beads/beads.db` is gitignored (local cache)
- On `git pull`, Beads auto-imports JSONL → local db
- **Automatic multi-machine sync with zero configuration**

**Example JSONL diff in git:**
```diff
+{"id":"bd-a3f8.2","type":"feature","title":"Feature: Task CRUD API","status":"open","parent":"bd-a3f8","priority":2,"created_at":"2026-01-20T11:00:00Z"}
+{"id":"bd-a3f8.2.1","type":"task","title":"Task: Create task model","status":"open","parent":"bd-a3f8.2","priority":1,"labels":["feature:bd-a3f8.2"]}
+{"id":"bd-a3f8.2.2","type":"task","title":"Task: Add GET endpoint","status":"open","parent":"bd-a3f8.2","priority":2,"labels":["feature:bd-a3f8.2"]}
```

Clean, readable, merge-friendly!

---

## Phase 9: Visual Dependency Inspection

### Direct Beads Commands (Outside Skills)

**User can run Beads CLI directly for inspection:**

**See full hierarchy:**
```bash
bd dep tree bd-a3f8
```

**Output:**
```
bd-a3f8 [epic] Epic: Task Management API (in_progress)
  ├─ bd-a3f8.1 [feature] Feature: User Authentication (closed)
  │   ├─ bd-a3f8.1.1 [task] User model (closed)
  │   ├─ bd-a3f8.1.2 [task] JWT signing (closed)
  │   ├─ bd-a3f8.1.3 [task] Login endpoint (closed)
  │   ├─ bd-a3f8.1.4 [task] Logout endpoint (closed)
  │   └─ bd-bug-f7c2 [bug] JWT tests (closed)
  └─ bd-a3f8.2 [feature] Feature: Task CRUD API (in_progress)
      ├─ bd-a3f8.2.1 [task] Task model (in_progress)
      ├─ bd-a3f8.2.2 [task] GET endpoint (open)
      ├─ bd-a3f8.2.3 [task] POST endpoint (open)
      └─ bd-a3f8.2.4 [task] DELETE endpoint (open)
```

**Get only ready (unblocked) work:**
```bash
bd ready
```

**Output:**
```
bd-a3f8.2.1 [task] Create task model (in_progress)
bd-a3f8.2.2 [task] Add GET /tasks endpoint (open)
```

**Get statistics:**
```bash
bd stats
```

**Output:**
```
Total issues: 15
Open: 5
Closed: 10
By type:
  epic: 1 (1 open, 0 closed)
  feature: 2 (1 open, 1 closed)
  task: 11 (3 open, 8 closed)
  bug: 1 (0 open, 1 closed)
```

**See detailed issue information:**
```bash
bd show bd-a3f8.1.2
```

**Output:**
```
ID: bd-a3f8.1.2
Type: task
Title: Task: Implement JWT signing
Status: closed
Parent: bd-a3f8.1
Priority: 2
Labels: feature:bd-a3f8.1
Created: 2026-01-20 10:05:00
Closed: 2026-01-20 10:31:22
Closed reason: Completed: JWT signing and verification implemented with HS256, tests passing, error handling added

Dependencies:
  Blocked by: bd-bug-f7c2 [bug] JWT signing tests failing (closed)

History:
  2026-01-20 10:05:00 - Created
  2026-01-20 10:20:12 - Status: open → in_progress
  2026-01-20 10:24:33 - Blocked by bd-bug-f7c2
  2026-01-20 10:28:15 - Unblocked (bd-bug-f7c2 closed)
  2026-01-20 10:31:22 - Status: in_progress → closed
```

---

## Complete User Journey Summary

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│ 1. First Time Setup                                         │
│    User → /install → Creates .beads/ → bd init              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Start New Epic                                           │
│    User → /launch → Creates epic → bd-a3f8                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Plan Feature (Optional: /exploration first)              │
│    User → /mission-brief → Creates feature + tasks          │
│    Result: bd-a3f8.1 with 4 tasks                           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Activate & Execute                                       │
│    User → /dock bd-a3f8.1 → Marks in_progress               │
│    User → /mission-go bd-a3f8.1 → Ralph loop starts         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Ralph Loop (each iteration)                              │
│    1. bd ready → Get next unblocked task                    │
│    2. bd update → Mark in_progress                          │
│    3. Spawn Pod → Execute work                              │
│    4a. Success: bd close → Mark complete                    │
│    4b. Failure: bd create bug + bd dep add → Block task     │
│    5. bd sync → Commit to git                               │
│    6. Loop to step 1                                        │
│                                                             │
│    KEY: Ralph also fixes bugs in the loop!                  │
│    Bugs are treated as high-priority tasks                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Check Status Anytime                                     │
│    User → /capcom → Queries Beads → Shows report            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Multi-Machine (Optional)                                 │
│    Laptop: /mission-brief + bd sync + git push              │
│    Desktop: git pull + /mission-go (auto-synced!)           │
└─────────────────────────────────────────────────────────────┘
```

### Command Reference

| Command | Purpose | Beads Operations |
|---------|---------|------------------|
| `/install` | First time setup | `bd init` |
| `/launch` | Create first epic | `bd create -t epic` |
| `/exploration` | Brainstorm (optional) | None (pure conversation) |
| `/mission-brief` | Plan feature with tasks | `bd create -t feature`, `bd create -t task --parent` |
| `/dock` | Activate feature | `bd update --status in_progress` |
| `/mission-go` | Execute feature (Ralph loop) | `bd ready`, `bd update`, `bd close`, `bd create bug`, `bd dep add`, `bd sync` |
| `/capcom` | Status report | `bd list`, `bd stats`, `bd dep tree` |
| `/airlock` | Validate work (called by Pod) | `bd create bug` + `bd dep add` (on failure) |
| `/handover` | Generate handover doc | None (file-based) |
| `/pod` | Execute single task | Called by ralph.sh |

---

## Key Integration Points

### Where Beads is Used Extensively

1. **`/install`** - Initialize Beads (`bd init`)
2. **`/launch`** - Create first epic (`bd create -t epic`)
3. **`/mission-brief`** - Create features and tasks (`bd create` with hierarchy)
4. **`/dock`** - Update feature status (`bd update`)
5. **`/mission-go` (ralph.sh)** - Main execution loop:
   - `bd ready` - Get next unblocked task
   - `bd update` - Mark in progress
   - `bd close` - Mark complete
   - `bd create` + `bd dep add` - Create blocking bugs
   - `bd sync` - Commit after each change
6. **`/capcom`** - Status queries (`bd list`, `bd stats`, `bd dep tree`)
7. **`/airlock`** - Create blocking bugs on validation failure

### Where Beads is NOT Used

- **`/exploration`** - Pure conversation, no data
- **`/handover`** - File-based protocol
- **Pod internals** - Pods execute work but don't query Beads directly

---

## The Graph in Action

### Example: Manual Dependencies

**User creates explicit dependency:**
```bash
# Task 4 depends on Task 3
bd dep add bd-a3f8.2.4 bd-a3f8.2.3

# "DELETE endpoint depends on POST endpoint being done first"
```

**Effect on Ralph:**
```bash
# Before dependency:
bd ready → Returns [bd-a3f8.2.3, bd-a3f8.2.4] (both unblocked)

# After dependency:
bd ready → Returns [bd-a3f8.2.3] only (bd-a3f8.2.4 is blocked)

# After bd-a3f8.2.3 closes:
bd ready → Returns [bd-a3f8.2.4] (now unblocked)
```

**Ralph automatically respects the dependency graph - no manual coordination needed!**

### Example: Bug Blocking Flow

```
1. Ralph starts bd-a3f8.2.1 (Task: Create task model)
   bd update bd-a3f8.2.1 --status in_progress

2. Pod implements work

3. Airlock finds issue (tests fail)
   bd create "Bug: Task schema missing validation" -t bug → bd-bug-abc
   bd dep add bd-a3f8.2.1 bd-bug-abc

4. Task is now blocked
   Graph: bd-a3f8.2.1 ──blocks──> bd-bug-abc

5. Next Ralph iteration:
   bd ready → Returns bd-bug-abc (NOT bd-a3f8.2.1)

6. Ralph fixes bug
   bd close bd-bug-abc

7. Task automatically unblocks
   Graph edge removed

8. Next Ralph iteration:
   bd ready → Returns bd-a3f8.2.1 (can continue now)
```

**The graph prevents Ralph from attempting blocked work - this is the killer feature!**

---

## Benefits Illustrated

### 1. Graph Prevents Blocked Work

**Without Beads (old SQLite):**
```
Ralph picks tasks by priority only
Might start Task B even if Task A (which B needs) isn't done
Developer must manually set priorities perfectly
```

**With Beads:**
```
bd ready uses graph algorithm
Only returns tasks with no open blockers
Impossible to start blocked work
```

### 2. Ralph Manages Bugs Automatically

**Without Beads:**
```
Bug created → Alert table entry → Ralph halts OR skips task
Developer must manually fix bug, then resume
```

**With Beads:**
```
Bug created → Blocks task via graph edge
Ralph sees bug as high-priority work → Fixes it automatically
When bug closes → Task unblocks → Ralph continues
No manual intervention!
```

### 3. Multi-Machine Sync

**Without Beads:**
```
SQLite database is local file
No automatic sync between machines
Must manually copy database or use shared drive
```

**With Beads:**
```
.beads/issues.jsonl committed to git
git pull automatically syncs
Zero configuration multi-machine workflow
```

### 4. Visual Dependencies

**Without Beads:**
```
SQL queries show flat lists
Hard to visualize hierarchy
No dependency tree
```

**With Beads:**
```
bd dep tree bd-a3f8 → Beautiful ASCII tree
bd show bd-task → Full dependency info
Visual understanding of work structure
```

---

## What Makes This Special

### The Ralph + Beads Combination

1. **Ralph provides fresh context** (Ralph Wiggum pattern from Yegge)
   - Each iteration spawns fresh Pod
   - No context rot
   - Agents stay in "smart zone"

2. **Beads provides persistent state** (Beads pattern from Yegge)
   - Graph tracks dependencies
   - Work survives restarts
   - Multi-machine coordination

3. **Together they enable autonomous execution**
   - Ralph doesn't need human to tell it what's blocked
   - Bugs become just another task type
   - System self-organizes around dependencies

**This is "vibe coding" - fast, autonomous, graph-aware execution at the speed of thought.**

---

## Edge Cases & Failure Modes

### What Happens If...

**1. Critical bug detected?**
```bash
# Ralph checks each iteration
if bd list --json | jq -e '.[] |
    select(.labels[] | contains("severity:critical"))'; then
    echo "CRITICAL BUG - HALTING"
    exit 1
fi
```
Ralph stops, sends notification, user investigates.

**2. Task times out?**
Ralph marks as failed, creates alert bug, continues to next task.

**3. Pod crashes mid-execution?**
Task status stays "in_progress", Ralph picks it up again next iteration.

**4. User manually edits Beads?**
```bash
bd create "Task: Manual addition" --parent bd-feature
bd sync
```
Ralph sees it on next iteration, works on it automatically.

**5. Git conflict on .beads/issues.jsonl?**
JSONL format enables automatic merges (one issue per line).
If conflict occurs, resolve manually - it's human-readable.

---

## Conclusion

After Beads integration, Space-Agents becomes a **graph-aware autonomous execution system**:

- **Users plan** via `/mission-brief` (creates features/tasks in Beads)
- **Ralph executes** via `/mission-go` (traverses graph, fixes bugs automatically)
- **System self-organizes** around dependencies (no manual blocking coordination)
- **Multi-machine works** out of the box (git + JSONL)
- **Visual inspection** at any time (`bd dep tree`, `/capcom`)

The combination of Ralph's fresh context + Beads' persistent graph = **vibe coding at scale**.
