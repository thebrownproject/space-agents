---
name: dock
description: "End session. Appends full context to CAPCOM, syncs Beads."
---

# /dock - End Session

Capture session context in CAPCOM. Focus on what's in your head that Beads can't store.

## Procedure

### Step 1: Gather Git State

```bash
git branch --show-current
git status --short
git log -1 --oneline
```

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
│  {one_line_summary}                                            │
│                                                                │
│  Context saved to CAPCOM. Run /launch to continue.             │
│                                                                │
│                 Safe travels, Commander.                       │
└────────────────────────────────────────────────────────────────┘
```
