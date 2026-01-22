---
name: mission-go-solo
description: "HOUSTON executes feature tasks directly. No agents. Context fills quickly - only for small tasks."
---

# /mission-go-solo - Direct Execution

HOUSTON executes tasks directly without spawning agents. Fast for small features, but context fills quickly.

## Warning

```
HOUSTON: Solo mode fills context fast. Only use for:
         - Small features (3-5 tasks)
         - Quick demos
         - Debugging a single task

         For larger work, use /mission-go-orchestrated.
```

## The Process

1. **Load feature** - Run `bd show FEATURE_ID` to get feature details and tasks
2. **Activate feature** - Run `bd update FEATURE_ID --status in_progress`
3. **Get next task** - Source helpers and call `bd_get_next_task FEATURE_ID`
4. **Execute task** - Implement the work directly (write code, run tests)
5. **Mark complete** - Call `bd_mark_task_complete TASK_ID`
6. **Loop** - Repeat steps 3-5 until no tasks remain
7. **Complete feature** - Run `bd close FEATURE_ID`

## Helper Functions

Source from `skills/mission-go/scripts/beads-helpers.sh`:

```bash
source skills/mission-go/scripts/beads-helpers.sh

# Get next ready task for feature
bd_get_next_task "FEATURE_ID"  # Returns: task_id|title|description

# Mark task complete
bd_mark_task_complete "TASK_ID"

# Mark task failed (creates blocking bug)
bd_mark_task_failed "TASK_ID" "reason"
```

## On Completion

```
HOUSTON: Feature complete. {N} tasks executed.
         Run /capcom for status summary.
```

## On Blocker

If you hit a blocker you cannot resolve:

```bash
bd_mark_task_failed "TASK_ID" "Description of blocker"
```

Then inform user and suggest switching to orchestrated mode.
