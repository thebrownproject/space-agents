---
name: mission-go-orchestrated
description: "HOUSTON spawns Task agents: Worker, Inspector, Analyst per task. Recommended for most features."
---

# /mission-go-orchestrated - Agent-Per-Task Execution

HOUSTON coordinates execution by spawning fresh agents for each task. Recommended mode - prevents context rot.

## The Process

1. **Load feature** - Run `bd show FEATURE_ID` to get details
2. **Activate feature** - Run `bd update FEATURE_ID --status in_progress`
3. **Task loop** - For each task:
   - Get next task via `bd_get_next_task FEATURE_ID`
   - Spawn Worker agent (implements the task)
   - Wait for Worker completion
   - Spawn Inspector agent (verifies requirements met)
   - Spawn Analyst agent (reviews code quality)
   - HOUSTON decides: continue, fix issues, or escalate
   - Mark task complete via `bd_mark_task_complete TASK_ID`
4. **Complete feature** - Run `bd close FEATURE_ID`

## Spawning Agents

Use Task tool with `run_in_background: false` (wait for completion):

**Worker** (`subagent_type: "space-agents:worker"`):
```
"Execute task TASK_ID for feature FEATURE_ID.
 Task: [title]
 Description: [description]
 Context files: [relevant files from feature brief]"
```

**Inspector** (`subagent_type: "space-agents:inspector"`):
```
"Review task TASK_ID implementation.
 Verify: requirements met, tests pass, acceptance criteria satisfied."
```

**Analyst** (`subagent_type: "space-agents:analyst"`):
```
"Analyze task TASK_ID code quality.
 Check: patterns followed, no regressions, maintainable."
```

## Decision Points

After Inspector/Analyst return, HOUSTON decides:

| Result | Action |
|--------|--------|
| All pass | Mark complete, continue to next task |
| Minor issues | Log warning, continue |
| Blocker found | Create bug via `bd_mark_task_failed`, ask user |
| Critical issue | Halt, escalate to user |

## Helper Functions

Source `skills/mission-go/scripts/beads-helpers.sh` for:
- `bd_get_next_task FEATURE_ID`
- `bd_mark_task_complete TASK_ID`
- `bd_mark_task_failed TASK_ID "reason"`

## On Completion

```
HOUSTON: Feature complete. {N} tasks executed via orchestrated mode.
         Worker/Inspector/Analyst cycle completed for each task.
```
