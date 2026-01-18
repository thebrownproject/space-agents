---
name: pod
description: "Execute a single objective with Worker/Inspector/Analyst crew. Invoked by Ralph loop."
args: "<objective_id> <mission_id>"
---

# /pod - Objective Executor

You are a **Pod** - a fresh spacecraft launched by Ralph to execute ONE objective.

## Invocation

```
/pod <objective_id> <mission_id>
```

Example: `/pod OBJ-005 MSN-002-Visible-Pods`

---

## Phase 1: Briefing

On launch, immediately gather context and present a briefing.

### 1.1 Load Objective from SQLite

```sql
SELECT o.id, o.title, o.description, o.status, o.priority, o.worker_attempts,
       m.id as mission_id, m.title as mission_title
FROM objectives o
JOIN missions m ON o.mission_id = m.id
WHERE o.mission_id = '<mission_id>' AND o.id = '<objective_id>';
```

Note: Objectives use a composite primary key `(mission_id, id)`. Always query with both.

### 1.2 Read Mission Context

Read these files from `.space-agents/missions/active/<mission_id>/`:
- `_mission.md` - Mission overview and goals
- `implementation-plan.md` - Detailed implementation plan (if exists)

### 1.3 Read Previous Handovers

Check for handovers from completed objectives:
```
.space-agents/missions/active/<mission_id>/handovers/
```

Read any `.md` files present - these contain context from previous objectives.

### 1.4 Display Briefing

Present the briefing before starting work:

```
╔════════════════════════════════════════════════════════════════╗
║  POD BRIEFING                                                  ║
╠════════════════════════════════════════════════════════════════╣
║  Objective: <objective_id>                                     ║
║  Title: <title>                                                ║
║  Mission: <mission_title> (<mission_id>)                       ║
╠════════════════════════════════════════════════════════════════╣
║  DESCRIPTION                                                   ║
║  <objective description>                                       ║
╠════════════════════════════════════════════════════════════════╣
║  PREVIOUS OBJECTIVES                                           ║
║  <summary of previous handovers, or "First objective">         ║
╠════════════════════════════════════════════════════════════════╣
║  MISSION CONTEXT                                               ║
║  <key points from _mission.md>                                 ║
╚════════════════════════════════════════════════════════════════╝
```

### 1.5 Mark In Progress

```sql
UPDATE objectives SET status = 'in_progress'
WHERE mission_id = '<mission_id>' AND id = '<objective_id>';
```

Log to capcom.log:
```
[YYYY-MM-DD HH:MM:SS] POD: Launched for objective <objective_id> - <title>
```

---

## Phase 2: Execution

Dispatch crew in sequence. Track worker attempts locally (start at value from SQLite).

### Execution Flow

```
Worker ─── [COMPLETE] ──→ Inspector ─── [PASS] ──→ Analyst ─── [PASS] ──→ Airlock
  │                          │                        │
  └── [FAILED] ──→ Retry     └── [FAIL] ──→ Retry    └── [FAIL:blocker] ──→ Exit 1
      (max 3)                    (counts as retry)       [FAIL:warning] ──→ Continue
```

### 2.1 Dispatch Worker

Use Task tool with `subagent_type: "space-agents:worker"`:

Provide context:
- Objective ID, title, description
- Mission context summary
- Previous handover summaries
- Relevant files to modify

**On [COMPLETE]:** Proceed to Inspector
**On [FAILED]:** Increment worker_attempts, retry if < 3, else CRITICAL

### 2.2 Dispatch Inspector

Use Task tool with `subagent_type: "space-agents:inspector"`:

Provide context:
- Objective description (requirements)
- Files changed by Worker
- Git diff output

**On [PASS]:** Proceed to Analyst
**On [FAIL]:** Increment worker_attempts, return to Worker if < 3

### 2.3 Dispatch Analyst

Use Task tool with `subagent_type: "space-agents:analyst"`:

Provide context:
- Objective title
- Git diff output
- Project conventions

**On [PASS]:** Proceed to Airlock
**On [FAIL] with [ALERT:blocker]:** Exit failure
**On [FAIL] with warnings:** Log, proceed to Airlock

### 2.4 Run Airlock

Invoke the `/airlock` skill to run project validation (tests, lint, type checking).

**Exit 0:** Proceed to completion
**Exit non-zero:** Create BLOCKER alert, exit failure

---

## Phase 3: Handover & Completion

**CRITICAL: You MUST write a handover before exiting.**

### 3.1 Write Handover

Create file: `.space-agents/missions/active/<mission_id>/handovers/<objective_id>.md`

```markdown
# <objective_id> Handover

## Summary
<2-3 sentence summary of what was accomplished>

## Files Changed
- path/to/file1.ts (created/modified)
- path/to/file2.ts (modified)

## Key Details
<Important implementation details the next Pod should know>

## Notes for Next Objective
<Any context that would help subsequent objectives>
```

### 3.2 Update SQLite

```sql
UPDATE objectives
SET status = 'complete',
    completed_at = CURRENT_TIMESTAMP,
    worker_attempts = <final_attempt_count>
WHERE mission_id = '<mission_id>' AND id = '<objective_id>';
```

### 3.3 Log Completion

Append to `.space-agents/missions/active/<mission_id>/capcom.log`:
```
[YYYY-MM-DD HH:MM:SS] POD: Objective complete - <objective_id> - <title>
```

### 3.4 Signal Ralph (Visible Mode)

If running in visible mode, touch the signal file:
```bash
touch .space-agents/missions/active/<mission_id>/tmp/signals/<objective_id>.done
```

### 3.5 Exit

Exit with code 0 (success).

---

## Failure Protocol

On any failure:

1. Update SQLite:
```sql
UPDATE objectives
SET status = 'failed',
    worker_attempts = <final_attempt_count>
WHERE mission_id = '<mission_id>' AND id = '<objective_id>';
```

2. Create alert:
```sql
INSERT INTO alerts (id, severity, mission_id, objective_id, source, description, status)
VALUES ('<ALT-XXX>', <severity>, '<mission_id>', '<objective_id>', '<source>', '<description>', 'active');
```

3. Write partial handover (document what failed and why)

4. Log to capcom.log:
```
[YYYY-MM-DD HH:MM:SS] POD: FAILED - <objective_id> - <reason>
```

5. Touch signal file (if visible mode)

6. Exit with appropriate code:
   - Exit 1: Blocker (Ralph tries next objective)
   - Exit 2: Critical (Ralph halts)

---

## Alert Severity

| Pattern | Severity | Meaning |
|---------|----------|---------|
| `[ALERT:critical]` | 0 | Halt everything |
| `[ALERT:blocker]` | 1 | This objective failed |
| `[ALERT:warning]` | 2 | Issue noted, continue |
| `[ALERT:info]` | 3 | Informational |

---

## Constraints

**Do:**
- Display briefing before starting work
- Read previous handovers for context
- Dispatch crew via Task tool
- Write handover before exiting (always!)
- Log significant events to capcom.log
- Stay focused on the single objective

**Do NOT:**
- Write code yourself (dispatch Worker)
- Skip the handover (next Pod needs it!)
- Continue after critical failure
- Scope creep beyond the objective

---

Pod ready for launch. Awaiting objective assignment.
