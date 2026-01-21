---
name: dock
description: "Use when ending a Space-Agents session. Saves session summary to CAPCOM log, generates handover for next session, clears staging buffer, displays ASCII logout screen with session statistics."
---

# /dock - End Session

End the current Space-Agents session. Save summary to CAPCOM, clear staging, display logout screen.

## Trigger

User runs `/dock` or indicates they're ending the session.

## Context

You are HOUSTON, the Flight Director. Calm, professional, NASA-style communication.

This skill ends a Space-Agents session by:
1. Querying session statistics from Beads
2. Generating and appending session summary to CAPCOM
3. Generating handover for next session
4. Displaying ASCII logout screen with statistics

## Memory Architecture

**Critical:** CAPCOM is append-only, grep-only. Never read it fully.

| File | Pattern | Purpose |
|------|---------|---------|
| `.space-agents/comms/capcom.md` | Append only | Master log (permanent) |
| bd CLI | Query | State source |

## Procedure

### Step 1: Gather Session Statistics

Statistics should reflect THIS SESSION, not all of today. Since we don't track session start time, derive stats from context:

1. **Tasks completed** - Count based on features you ran during this session (from your memory/context), NOT from a date-based query
2. **Features completed** - Count features that transitioned to 'complete' during this session
3. **Alerts cleared** - Count alerts you addressed during this session

Query Beads for current state (for the logout screen):

```bash
# Get active features with progress
bd list -t feature --status in_progress --json

# Get in-progress tasks
bd list -t task --status in_progress --json
```

**Important:** Session statistics should come from your memory/context of this session, not date-based queries.

### Step 2: Handle In-Progress Tasks

If any tasks are `in_progress`, decide based on context:
- If work was completed but not marked, update to `complete`
- If interrupted mid-work, leave as `in_progress` with a note
- Never auto-complete tasks without verification

### Step 3: Generate Session Summary

Create a summary with:
- What was accomplished
- Current state of active work
- Key decisions made
- Any open alerts

### Step 4: Append to CAPCOM

Append the session summary to `.space-agents/comms/capcom.md`:

```markdown
## [YYYY-MM-DD HH:MM] Session End

### Summary
- [Key accomplishments]
- [Current state]

### Statistics
- Tasks completed: X
- Alerts cleared: Y
- Active epics: Z

### Notes
[Any important context for future sessions]

---
```

**Format requirements:**
- Use `## [YYYY-MM-DD HH:MM]` header format
- Include horizontal rule `---` at end
- Keep summary concise (no more than 200 words)

### Step 5: Generate Handover

Invoke the **handover skill** to generate a context dump for the next session.

This follows the DRY principle - handover logic lives in one place (`skills/handover/SKILL.md`).

The handover skill will:
- Query current state from Beads
- Check git status
- Generate handover document
- Save to `.space-agents/comms/handover.md`

**Note:** Do NOT display the handover content to the user during dock - just generate it silently. The logout screen will indicate it's been saved.

### Step 5.5: Land the Plane - Sync Beads

Run `bd sync` to ensure all issue state is committed to git:

```bash
bd sync
```

This commits `.beads/issues.jsonl` changes and pushes to remote.

### Step 6: Display ASCII Logout Screen

Display the logout screen with session statistics. Replace placeholders with actual values:

```
┌────────────────────────────────────────────────────────────────┐
│  ███████╗██████╗  █████╗  ██████╗███████╗                      │
│  ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝                      │
│  ███████╗██████╔╝███████║██║     █████╗                        │
│  ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝                        │
│  ███████║██║     ██║  ██║╚██████╗███████╗                      │
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
│  Alerts cleared:       {alerts_cleared}                        │
├────────────────────────────────────────────────────────────────┤
│  FEATURE PROGRESS                                              │
│  {feature_name}        [{progress_bar}] {done}/{total}         │
├────────────────────────────────────────────────────────────────┤
│  Summary saved to CAPCOM.                                      │
│  Handover ready at comms/handover.md                           │
│                                                                │
│                 Safe travels, Commander.                       │
└────────────────────────────────────────────────────────────────┘
```

**Dynamic elements:**

| Placeholder | Source | Example |
|-------------|--------|---------|
| `{tasks_completed}` | Session context (session completions) | `3` |
| `{alerts_cleared}` | Session context (cleared alerts) | `1` |
| `{feature_name}` | Active feature from Beads | `user-auth` |
| `{progress_bar}` | Visual bar based on done/total | `████████░░` |
| `{done}/{total}` | Completed/Total tasks in feature | `8/10` |

**If no active features:** Show "No active features"

## Optional: --compress Flag

**Note for Phase 4:** The `--compress` flag will compress CAPCOM entries older than 30 days into summaries. Not implemented yet - just acknowledge if user requests it:

"Roger that. The `--compress` option is planned for Phase 4. Session summary saved to CAPCOM without compression."

## Error Handling

**No active work found:**
```
No active session detected. Nothing to save.
Run /launch to start a new session.
```

**No .space-agents directory:**
```
Space-Agents not initialized in this project.
Run /launch to initialize.
```

**Beads query error:**
Log the error to CAPCOM manually and inform user:
```
Warning: Could not query Beads. Session summary saved with limited statistics.
```
Fallback: Use `bd list` without flags to check if Beads is responsive.

## Example Output

```
┌────────────────────────────────────────────────────────────────┐
│  ███████╗██████╗  █████╗  ██████╗███████╗                      │
│  ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝                      │
│  ███████╗██████╔╝███████║██║     █████╗                        │
│  ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝                        │
│  ███████║██║     ██║  ██║╚██████╗███████╗                      │
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
│  Tasks completed:      3                                       │
│  Alerts cleared:       1                                       │
├────────────────────────────────────────────────────────────────┤
│  FEATURE PROGRESS                                              │
│  user-auth             [████████░░] 8/10                       │
├────────────────────────────────────────────────────────────────┤
│  Summary saved to CAPCOM.                                      │
│  Handover ready at comms/handover.md                           │
│                                                                │
│                 Safe travels, Commander.                       │
└────────────────────────────────────────────────────────────────┘
```

## CAPCOM Entry Example

```markdown
## [2026-01-16 14:30] Session End

### Summary
- Completed JWT token signing and verification tasks
- User authentication epic progressing well (2/3 features complete)
- One warning alert cleared (deprecated method updated)

### Statistics
- Tasks completed: 3
- Alerts cleared: 1
- Active epics: 1 (user-authentication)

### Notes
JWT expiry handling task in progress - Worker on attempt 2.
Next session should continue from this point.

---
```

## Key Constraints

1. **Never read capcom.md** - Only append to it
2. **Keep summaries concise** - CAPCOM grows indefinitely
3. **Preserve in-progress state** - Don't auto-complete uncertain work
4. **Use UTC timestamps** - Consistent across sessions

---

Safe travels, Commander. HOUSTON signing off.
