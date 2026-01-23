---
name: dock
description: "End session. Reconciles exploration folders, appends context to CAPCOM, syncs Beads, displays session stats."
---

# /dock - End Session

Capture session context in CAPCOM and reconcile any folder states that were missed during the session.

## Procedure

### Step 0: Reconcile Exploration Folders

Check for folder/state mismatches and fix them:

| If folder in... | But has... | Move to... |
|-----------------|------------|------------|
| `ideas/` | `plan.md` | `planned/` |
| `planned/` | Beads feature exists | `staged/` |
| `staged/` | Beads feature closed | `complete/` |

For each mismatch: show user, confirm, then `mv` the folder.

### Step 1: Gather State

```bash
git branch --show-current
git status --short
git log -1 --oneline
bd stats
bd list -t feature --status in_progress
```

From your session memory, note:
- Tasks completed this session
- Bugs fixed this session
- Active feature and its progress (done/total tasks)

### Step 2: Append to CAPCOM

Append full session context to `.space-agents/comms/capcom.md`:

```markdown
## [YYYY-MM-DD HH:MM] Session End

**Branch:** {branch} | **Git:** {clean/uncommitted}

### What Happened
[Narrative of what was worked on. Be specific - file names, function names, what changed and why.]

### Decisions Made
[Architectural decisions, trade-offs chosen, "we decided X because Y". Skip if none.]

### Gotchas
[Things that surprised you, bugs encountered, "watch out for X". Skip if none.]

### In Progress
[If stopped mid-task: what state, next step, files involved. Skip if clean stop.]

### Next Action
[One clear thing to do next session.]

---
```

**Guidelines:**
- Be specific ("added JWT refresh in auth/tokens.ts:45" not "updated auth")
- Include file paths where relevant
- Capture reasoning, not just actions
- Skip empty sections
- CAPCOM is append-only

### Step 3: Sync and Push

```bash
bd sync
git add -A && git commit -m "dock: session end" && git push
```

### Step 4: Display Logout Screen

Query all features and their task progress:

```bash
bd list -t feature --status open,in_progress
bd list --tree
```

```
┌────────────────────────────────────────────────────────────────┐
│  ███████╗██████╗  █████╗  ██████╗███████╗                      │
│  ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝                      │
│  ███████╗██████╔╝███████║██║     █████╗                        │
│  ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝                        │
│  ███████║██║     ██║  ██║╚██████╗███████║                      │
│  ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝                      │
│           █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗  │
│          ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔════╝  │
│          ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ███████╗  │
│          ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║  │
│          ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████║  │
│          ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝  │
├────────────────────────────────────────────────────────────────┤
│                      SESSION COMPLETE                          │
├────────────────────────────────────────────────────────────────┤
│  SESSION SUMMARY                                               │
│  Tasks completed:      {tasks_completed}                       │
│  Bugs fixed:           {bugs_fixed}                            │
├────────────────────────────────────────────────────────────────┤
│  PROGRESS                                                      │
│  {feature_1}           [{progress_bar}] {done}/{total}         │
│    ├─ {task_1}         {status_icon}                           │
│    ├─ {task_2}         {status_icon}                           │
│    └─ {task_3}         {status_icon}                           │
│  {feature_2}           [{progress_bar}] {done}/{total}         │
│    ├─ {task_1}         {status_icon}                           │
│    └─ {task_2}         {status_icon}                           │
├────────────────────────────────────────────────────────────────┤
│  Context saved to CAPCOM. Run /launch to continue.             │
│                                                                │
│                 Safe travels, Commander.                       │
└────────────────────────────────────────────────────────────────┘
```

**Placeholders:**

| Placeholder | Source | Example |
|-------------|--------|---------|
| `{tasks_completed}` | Session memory | `3` |
| `{bugs_fixed}` | Session memory | `1` |
| `{feature_N}` | Feature name (truncate to 20 chars) | `Agent Prompts...` |
| `{progress_bar}` | Visual bar (10 chars): █ for done, ░ for remaining | `████████░░` |
| `{done}/{total}` | Completed/Total tasks in feature | `8/10` |
| `{task_N}` | Task name (truncate to 20 chars) | `Update planning...` |
| `{status_icon}` | ✓ complete, ◐ in_progress, ○ open, ⊘ blocked | `○` |

**Progress bar formula:** `done / total * 10` filled blocks, rest empty.

**Show all open/in_progress features** with their child tasks. Skip closed features.
