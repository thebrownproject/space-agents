---
name: mission-ralph
description: "Launch ralph.sh in background. Lightweight mode (default) or full Pod crew (--pod). Best for large features (10+ tasks)."
---

# /mission-ralph - Automatic Background Execution

Launch the Ralph loop in background. Runs automatically until all tasks complete or a critical blocker halts execution.

## The Process

1. **Validate feature** - Check feature exists and has tasks
2. **Activate feature** - Run `bd update FEATURE_ID --status in_progress`
3. **Ask launch mode** - "Start Ralph in mprocs (visible) or background (invisible)?"
4. **Launch Ralph**:
   - If **background**: Run the script directly
   - If **visible**: Print the command for user to run in a new terminal window
5. **Inform user** - Tell them how to monitor progress
6. **Exit** - HOUSTON's job is done, Ralph takes over

## Modes

| Mode | Flag | Execution | Token Cost |
|------|------|-----------|------------|
| Lightweight (default) | (none) | Pathfinder scout → HOUSTON direct → Airlock | ~50k/task |
| Pod | `--pod` | Full crew via /mission-pod skill | ~150k+/task |

Use lightweight mode for straightforward tasks. Use `--pod` when tasks need deeper analysis or have complex requirements.

## Launch Command

```bash
# Lightweight mode (default) - background
bash skills/mission-ralph/scripts/ralph.sh FEATURE_ID &

# Lightweight mode - visible (mprocs TUI)
bash skills/mission-ralph/scripts/ralph.sh FEATURE_ID --visible

# Pod mode - background (full crew per task)
bash skills/mission-ralph/scripts/ralph.sh FEATURE_ID --pod &

# Pod mode - visible
bash skills/mission-ralph/scripts/ralph.sh FEATURE_ID --pod --visible
```

## What Ralph Does

Ralph executes tasks in a loop until completion:

**Lightweight mode (default):**
1. Get next ready task via `bd ready`
2. Run Pathfinder scout to gather context
3. HOUSTON executes task directly
4. Run Airlock validation
5. Handle result (complete, retry, or create blocking bug)
6. Continue until no tasks remain or critical halt

**Pod mode (`--pod`):**
1. Get next ready task via `bd ready`
2. Spawn full Pod crew (Pathfinder → Builder → Inspector → Airlock)
3. Handle result (complete, retry, or create blocking bug)
4. Continue until no tasks remain or critical halt

## User Communication

**If background mode:**
```
HOUSTON: Ralph loop launched for feature FEATURE_ID.

         Ralph runs automatically in background.
         Check progress: /capcom

         You'll be notified on:
         - Feature completion
         - Critical blocker (requires intervention)

         Safe to close this session.
```

**If visible mode:**
```
HOUSTON: Run this command in a new terminal window:

         bash skills/mission-ralph/scripts/ralph.sh FEATURE_ID --visible

         This opens mprocs with live task progress.
         Check status anytime: /capcom
```

## Monitoring

- `/capcom` - Check feature status and task progress
- `bd list --parent FEATURE_ID` - See all tasks
- `bd ready` - See what's next in queue
- `bd dep tree FEATURE_ID` - See task hierarchy and status

## Logging

Ralph logs to both console and file via `tee`:

```
.space-agents/mission/staged/{feature-slug}/ralph.log
```

When the mission completes, the entire feature folder (including logs) moves to:

```
.space-agents/mission/complete/{feature-slug}/
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Feature complete |
| 1 | Critical blocker - check `/capcom` |
| 2 | Configuration error |
