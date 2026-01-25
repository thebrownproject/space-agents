# Exploration: Ralph Modes and Logging

**Date:** 2026-01-25
**Status:** Ready for planning

## Context

We have four mission completion styles:

| Mode | Session | Execution | Tokens |
|------|---------|-----------|--------|
| **mission-solo** | Single | HOUSTON direct, no subagents | Low |
| **mission-orchestrated** | Single | HOUSTON + 4 subagents per task | Medium |
| **mission-ralph** | Fresh per task | Scout + HOUSTON direct | Low |
| **mission-ralph --pod** | Fresh per task | Full pod crew | High |

Currently `ralph.sh` only supports pod mode. We need to add lightweight mode as the default.

## Changes Required

### 1. ralph.sh - Add Mode Flag

**Current behavior:** Always spawns pod with full crew

**New behavior:** Default to lightweight, `--pod` flag for full crew

```bash
ralph.sh FEATURE_ID              # lightweight (default)
ralph.sh FEATURE_ID --pod        # full pod crew
ralph.sh FEATURE_ID --visible    # lightweight in mprocs
ralph.sh FEATURE_ID --visible --pod  # pod in mprocs
```

**Code changes in `spawn_pod()` function (~line 420):**

```bash
# Current prompt (pod mode):
local pod_prompt="Run /mission-pod ${task_id} ${feature_id}"

# New: check POD_MODE flag
if [[ "$POD_MODE" == "true" ]]; then
    local pod_prompt="Run /mission-pod ${task_id} ${feature_id}"
else
    local pod_prompt="Execute task ${task_id} for feature ${feature_id}.

## Instructions
1. Run Scout agent to explore codebase for this task
2. Implement the task directly (you are the worker)
3. Run /mission-airlock to validate (tests, lint)
4. Display POD COMPLETE summary with files changed

## Task Details
$(bd show ${task_id})

## Feature Context
$(bd show ${feature_id})"
fi
```

**Argument parsing in `main()` (~line 454):**

```bash
POD_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --pod)
            POD_MODE=true
            shift
            ;;
        # ... existing cases
    esac
done
```

### 2. File Logging

**Location:** `.space-agents/comms/logs/ralph-{feature_id}-{YYYYMMDD-HHMMSS}.log`

**Implementation:** Modify `main()` to set up logging at start:

```bash
# Create logs directory
LOG_DIR="${SPACE_AGENTS_DIR}/comms/logs"
mkdir -p "$LOG_DIR"

# Log file path
LOG_FILE="${LOG_DIR}/ralph-${feature_id}-$(date '+%Y%m%d-%H%M%S').log"

# Redirect all output to both terminal and log file
exec > >(tee -a "$LOG_FILE") 2>&1

log INFO "Log file: $LOG_FILE"
```

This captures all `log()` output to both stdout (for mprocs visibility) and the log file.

### 3. Update mission-ralph/SKILL.md

Document both modes:

```markdown
## Modes

**Lightweight (default):**
- Scout explores codebase
- HOUSTON executes task directly
- Airlock validates (tests/lint)
- ~2 agent spawns per task

**Pod mode (--pod flag):**
- Full pod crew: Scout → Worker → Inspector → Analyst → Airlock
- Best for complex/critical tasks
- ~5 agent spawns per task
```

### 4. Update /mission Router

Add explanation in `mission/SKILL.md`:

```markdown
| Mode | Skill | Best For |
|------|-------|----------|
| Solo | `mission-solo` | Small (1-3 tasks), single session |
| Orchestrated | `mission-orchestrated` | Medium (4-10 tasks), single session |
| Ralph | `mission-ralph` | Any size, fresh context, lightweight |
| Ralph --pod | `mission-ralph --pod` | Any size, fresh context, full validation |
```

## Lightweight Mode Execution Flow

```
ralph.sh loop:
  │
  ├─ Get next task (bd ready)
  │
  ├─ Spawn claude session with lightweight prompt:
  │     │
  │     ├─ Scout (Explore agent) - gather codebase context
  │     │
  │     ├─ HOUSTON executes directly - write code, no Worker agent
  │     │
  │     └─ Airlock (/mission-airlock) - run tests, lint
  │
  ├─ Wait for completion (signal file)
  │
  ├─ Mark task done (bd close)
  │
  └─ Loop until feature complete
```

## Pod Mode Execution Flow (existing)

```
ralph.sh --pod loop:
  │
  ├─ Get next task (bd ready)
  │
  ├─ Spawn claude session with pod prompt:
  │     │
  │     └─ /mission-pod invokes full crew:
  │           Scout → Worker → Inspector → Analyst → Airlock
  │
  ├─ Wait for completion (signal file)
  │
  ├─ Mark task done (bd close)
  │
  └─ Loop until feature complete
```

## Files to Modify

| File | Change |
|------|--------|
| `skills/mission-ralph/scripts/ralph.sh` | Add --pod flag, lightweight prompt, file logging |
| `skills/mission-ralph/SKILL.md` | Document both modes |
| `skills/mission/SKILL.md` | Update router to explain ralph vs ralph --pod |

## Token Comparison

| Mode | Agents per task | Estimated tokens |
|------|-----------------|------------------|
| Lightweight | Scout + Airlock | ~50k |
| Pod | Scout + Worker + Inspector + Analyst + Airlock | ~150k+ |

## Next Steps

Run `/plan` to create Beads tasks for implementation.
