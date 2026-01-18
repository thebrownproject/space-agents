---
name: mission-go
description: "Launch the Ralph execution loop to process mission objectives. Use when ready to execute a planned mission with the Pod/Worker/Inspector/Analyst cycle."
---

# /mission-go - Ralph Execution Loop

Launch the Ralph execution loop to process objectives for an active mission. Ralph spawns fresh Pods for each objective, maintaining state in SQLite while avoiding context rot.

---

## Purpose

The Ralph loop is the execution engine of Space-Agents. It:

1. Picks up pending objectives from SQLite (ordered by priority)
2. Spawns a fresh Pod for each objective
3. Monitors Pod exit codes to determine success/failure
4. Creates alerts on blockers or critical failures
5. Continues until mission complete or critical halt

### Core Principle

> **"Agents are compute, not memory."**

Each Pod is spawned fresh with no memory of previous objectives. State persists in SQLite. This prevents context rot and enables indefinite scaling.

---

## When to Use

Run `/mission-go` when:

- A mission has been planned with objectives in SQLite
- The mission status is "active"
- You're ready to begin automated execution

**Prerequisites:**
- Space-Agents must be installed (`/install`)
- A mission must exist in the database
- The mission must have status "active"
- At least one objective must be "pending"

### Activating a Staged Mission

When a mission is planned via `/mission-brief`, it starts with status "staged" and files in:
```
.space-agents/missions/staged/<mission_id>/
```

Before launching, you must:
1. Update the mission status to "active" in SQLite
2. Copy/move mission files from `staged/` to `active/`
3. Create the handovers folder for inter-Pod context sharing

```sql
UPDATE missions SET status = 'active' WHERE id = '<mission_id>';
```

```bash
mkdir -p .space-agents/missions/active/<mission_id>/handovers
cp -r .space-agents/missions/staged/<mission_id>/* .space-agents/missions/active/<mission_id>/
```

---

## Mode Selection

Before launching Ralph, choose an execution mode:

### Visible Mode (`--visible`) - Recommended

Ralph launches inside mprocs, spawning each Pod as a visible panel. Use when:
- You want to watch Pods execute in real-time
- Debugging or demonstrating the system
- You need to see what each Pod is doing

**IMPORTANT:** Visible mode requires manual execution. Claude Code cannot run mprocs through the Bash tool - it must run in your actual terminal to display the TUI.

When the user selects visible mode, provide the command for them to copy/paste:

```
HOUSTON: Run this in your terminal to launch visible mode:

    cd /path/to/project && bash .claude/plugins/cache/space-agents/space-agents/<VERSION>/skills/mission-go/scripts/ralph.sh MSN-XXX --visible

    (Or if using local skills: bash skills/mission-go/scripts/ralph.sh MSN-XXX --visible)
```

The user runs this command manually and watches the mprocs screen. Each Pod spawns as a new panel with live output.

### Attended Mode (`--attended`)

Ralph runs in the foreground with full output. Use when:
- Debugging or first-time execution
- You want to watch Pod progress in real-time
- You need to intervene quickly if issues arise

```bash
bash scripts/ralph.sh <mission_id> --attended
```

### Background Mode (default)

Ralph runs with minimal output. Use when:
- Executing a well-tested workflow
- Running overnight or unattended
- You'll check status via `/capcom`

```bash
bash scripts/ralph.sh <mission_id>
```

---

## Instructions

When `/mission-go` is invoked, follow these steps:

### Step 1: Verify Prerequisites

Query SQLite to find active missions:

```sql
SELECT m.id, m.title,
       (SELECT COUNT(*) FROM objectives WHERE mission_id = m.id AND status = 'pending') as pending_count
FROM missions m
WHERE m.status = 'active';
```

If no active missions:
```
HOUSTON: No active missions found. Use /mission-brief to create a mission first.
```

### Step 2: Confirm Mission Selection

If multiple active missions exist, present options to the user:

```
Active missions found:

  [1] MSN-001: JWT Token Management (VOY-001: Auth System) - 5 objectives pending
  [2] MSN-002: User Registration (VOY-001: Auth System) - 3 objectives pending

Which mission should I launch?
```

### Step 3: Select Mode

Ask the user:

```
Launch mode:

  [1] Attended - Full output, watch in real-time
  [2] Background - Minimal output, check via /capcom

Select mode:
```

### Step 4: Launch Ralph

Execute the ralph.sh script:

```bash
# Attended mode
bash scripts/ralph.sh <mission_id> --attended

# Background mode
bash scripts/ralph.sh <mission_id>
```

### Step 5: Monitor and Report

After launch:

**Attended mode:** Output streams directly to terminal.

**Background mode:** Report:
```
HOUSTON: Ralph loop launched for mission MSN-001.
         Monitor progress with /capcom.
         Notifications will appear on completion or critical failure.
```

---

## Exit Codes

Ralph reports these exit codes:

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Mission complete | All objectives done. Celebrate. |
| 1 | Mission failed | Critical alert or all objectives failed. Check alerts. |
| 2 | Configuration error | DB missing, mission not found, etc. Run /launch first. |

---

## Pod Lifecycle

Each iteration of Ralph:

1. **Select** next pending objective (by priority, then created_at)
2. **Mark** objective as "in_progress"
3. **Spawn** fresh Pod with objective context
4. **Pod executes:**
   - Worker implements
   - Inspector reviews requirements
   - Analyst reviews quality
   - Airlock validates (tests/lint)
5. **Handle** Pod exit code:
   - 0: Mark complete, continue
   - 1: Mark failed, create blocker alert, try next
   - 2: Mark failed, create critical alert, HALT
6. **Repeat** until no pending objectives

---

## Alert Handling

Ralph creates alerts automatically:

| Situation | Severity | Ralph Action |
|-----------|----------|--------------|
| Pod exits 1 (blocker) | 1 | Create alert, continue to next objective |
| Pod exits 2 (critical) | 0 | Create alert, HALT loop |
| Max iterations reached | 0 | Create alert, HALT loop |
| Existing critical alert | - | Check at start of each iteration, HALT if found |

---

## Safety Limits

Ralph includes safety mechanisms:

- **Max iterations:** 100 (prevents infinite loops)
- **Critical alert check:** Before each objective
- **Notification on halt:** macOS notification + notifications file

---

## Integration with CAPCOM

During execution, Ralph logs to:

- **Per-mission log:** `.space-agents/missions/active/<mission_id>/capcom.log`
- **Notifications file:** `.space-agents/notifications`

Check progress with `/capcom` - it reads these logs and SQLite state.

---

## Error Handling

### Mission not found

```
Ralph: Mission not found: MSN-999
       Run /mission-brief to create a mission first.
```

### Mission not active

```
Ralph: Mission is not active (status: complete)
       Only active missions can be executed.
```

### Database missing

```
Ralph: Database not found at .space-agents/space-agents.db
       Run /launch first to initialize Space-Agents.
```

### Claude CLI not found

```
Ralph: claude CLI not found.
       Please install Claude Code CLI.
```

---

## Example Session

```
User: /mission-go

HOUSTON: Active missions found:

  [1] MSN-001: JWT Token Management - 5 objectives pending

Launching MSN-001 in attended mode...

===========================================
RALPH LOOP STARTING
===========================================
Mission: JWT Token Management (MSN-001)
===========================================

--- Iteration 1 ---
Selected objective: Implement token signing (OBJ-001)
Spawning Pod...

[Pod output streams here]

Pod completed objective: Implement token signing
Objective complete: OBJ-001

--- Iteration 2 ---
...
```

---

## Troubleshooting

### Ralph hangs on first objective

- Check if Claude CLI is properly installed
- Verify the `agents/mission-pod.md` file exists
- Check SQLite permissions

### Objectives keep failing

- Review alerts via `/capcom`
- Check the per-mission capcom.log for details
- Consider running `/airlock` manually to debug

### Critical alert halts everything

- Run `/capcom` to see the alert
- Address the underlying issue
- Clear the alert in SQLite
- Re-run `/mission-go`

---

Ralph standing by. Ready to launch when you are.
