---
name: mission-orchestrated
description: "HOUSTON spawns Pathfinder, Builder, Inspector per task. Best for medium features (4-10 tasks)."
---

# /mission-orchestrated - Agents-Per-Task Execution

HOUSTON coordinates execution by spawning fresh agents for each task. Prevents context rot.

## The Process

1. **Load feature** - Run `bd show FEATURE_ID` to get details
2. **Activate feature** - Run `bd update FEATURE_ID --status in_progress`
3. **Task loop** - For each task:
   - Get next task: `bd list --parent FEATURE_ID --status open` (pick highest priority)
   - Claim task: `bd update TASK_ID --status in_progress`
   - Spawn Pathfinder agent (explores codebase, adds findings to bead comments)
   - Spawn Builder agent (reads Pathfinder findings from Beads, implements)
   - Spawn Inspector agent (verifies Tests checklist from task description)
   - HOUSTON decides: continue, fix issues, or escalate
   - Mark task complete: `bd close TASK_ID`
4. **Complete feature** - Run `bd close FEATURE_ID`

## Spawning Agents

Use Task tool with `run_in_background: false` (wait for completion).

**CRITICAL:** Always pass task_id and feature_id explicitly. Agents will run `bd show` to fetch authoritative details from Beads.

**Pathfinder** (`subagent_type: "space-agents:mission-pathfinder"`):
```
"Explore codebase for task [TASK_ID] under feature [FEATURE_ID].

 Run `bd show [TASK_ID]` and `bd show [FEATURE_ID]` first to get full context.

 Add findings as a [PATHFINDER] comment on the task bead."
```

**Builder** (`subagent_type: "space-agents:mission-builder"`):
```
"Execute task [TASK_ID] for feature [FEATURE_ID].

 Run `bd show [TASK_ID]` and `bd show [FEATURE_ID]` first to get full context.
 Read [PATHFINDER] comment for codebase findings.
 Use **Tests:** checklist in task description as TDD targets."
```

**Inspector** (`subagent_type: "space-agents:mission-inspector"`):
```
"Review task [TASK_ID] for feature [FEATURE_ID].

 Run `bd show [TASK_ID]` and `bd show [FEATURE_ID]` first to get requirements.

 Verify each **Tests:** item in task description. Report pass/fail count."
```

## Decision Points

After Inspector returns, HOUSTON decides:

| Result | Action |
|--------|--------|
| All pass | Mark complete, continue to next task |
| Minor issues | Log warning, continue |
| Blocker found | Create bug via `bd create -t bug`, ask user |
| Critical issue | Halt, escalate to user |

## On Completion

```
HOUSTON: Feature complete. {N} tasks executed via orchestrated mode.
         Pathfinder/Builder/Inspector cycle completed for each task.
```
