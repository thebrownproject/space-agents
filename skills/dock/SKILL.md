---
name: dock
description: "End Space-Agents session. Saves summary + handover to CAPCOM, syncs Beads, displays logout screen."
---

# /dock - End Session

End session: save summary to CAPCOM, sync Beads, display logout.

---

## Procedure

### Step 1: Gather State

From your session context:
- Tasks completed this session
- Features completed this session
- Alerts cleared this session

From Beads:
```bash
bd list --tree
bd ready -t task --limit 5
bd list -t bug -s open
```

From git:
```bash
git branch --show-current
git status --short
```

### Step 2: Append to CAPCOM

Append session summary + handover to `.space-agents/comms/capcom.md`:

```markdown
## [YYYY-MM-DD HH:MM] Session End

### Summary
- [Key accomplishments]
- [Current state]

### Statistics
- Tasks completed: X
- Features completed: Y
- Alerts cleared: Z

### Handover

**Ready tasks:**
[bd ready output]

**In-progress:**
[Any in-progress work with context]

**Open bugs:**
[bd list -t bug -s open output, or "None"]

**Git:** [branch] - [clean/uncommitted changes]

**Next steps:**
1. [Recommended action]
2. [Recommended action]

---
```

**Rules:**
- CAPCOM is append-only (never read it fully)
- Keep under 300 words
- Include enough context for next session to continue

### Step 3: Sync Beads

```bash
bd sync
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
│  SESSION SUMMARY                                               │
│  Tasks completed:      {tasks_completed}                       │
│  Features completed:   {features_completed}                    │
│  Alerts cleared:       {alerts_cleared}                        │
├────────────────────────────────────────────────────────────────┤
│  FEATURE PROGRESS                                              │
│  {feature_name}        [{progress_bar}] {done}/{total}         │
├────────────────────────────────────────────────────────────────┤
│  Summary + handover saved to CAPCOM.                           │
│                                                                │
│                 Safe travels, Commander.                       │
└────────────────────────────────────────────────────────────────┘
```

---

## Error Handling

| Condition | Response |
|-----------|----------|
| No .space-agents | "Run /install to initialize" |
| Beads error | Save what you can, note the error |
