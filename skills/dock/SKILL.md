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
1. Querying session statistics from SQLite
2. Reading staging buffer for context
3. Generating and appending session summary to CAPCOM
4. Generating handover for next session
5. Clearing the staging buffer
6. Displaying ASCII logout screen with statistics

## Memory Architecture

**Critical:** CAPCOM is append-only, grep-only. Never read it fully.

| File | Pattern | Purpose |
|------|---------|---------|
| `.space-agents/capcom.md` | Append only | Master log (permanent) |
| `.space-agents/staging/buffer.md` | Full read, then clear | Session buffer |
| `.space-agents/space-agents.db` | Query | State source |

## Procedure

### Step 1: Query Session Statistics

Query SQLite for session activity:

```bash
# Get completed objectives count (today)
sqlite3 .space-agents/space-agents.db "SELECT COUNT(*) FROM objectives WHERE status = 'complete' AND date(completed_at) = date('now');"

# Get cleared alerts count (today)
sqlite3 .space-agents/space-agents.db "SELECT COUNT(*) FROM alerts WHERE status = 'cleared' AND date(cleared_at) = date('now');"

# Get active voyages with progress
sqlite3 .space-agents/space-agents.db "
SELECT v.title,
       (SELECT COUNT(*) FROM objectives o
        JOIN missions m ON o.mission_id = m.id
        WHERE m.voyage_id = v.id AND o.status = 'complete') as done,
       (SELECT COUNT(*) FROM objectives o
        JOIN missions m ON o.mission_id = m.id
        WHERE m.voyage_id = v.id) as total
FROM voyages v WHERE v.status = 'active';"

# Get in-progress objectives (may need status update)
sqlite3 .space-agents/space-agents.db "SELECT o.id, o.title, m.title as mission FROM objectives o JOIN missions m ON o.mission_id = m.id WHERE o.status = 'in_progress';"
```

### Step 2: Read Staging for Context

Read `.space-agents/staging/buffer.md` fully to understand session activity.

This file contains:
- Session start time
- Key decisions made
- Active work context
- Notes from the session

### Step 3: Handle In-Progress Objectives

If any objectives are `in_progress`, decide based on context:
- If work was completed but not marked, update to `complete`
- If interrupted mid-work, leave as `in_progress` with a note
- Never auto-complete objectives without verification

### Step 4: Generate Session Summary

Create a summary with:
- What was accomplished
- Current state of active work
- Key decisions made
- Any open alerts

### Step 5: Append to CAPCOM

Append the session summary to `.space-agents/capcom.md`:

```markdown
## [YYYY-MM-DD HH:MM] Session End

### Summary
- [Key accomplishments]
- [Current state]

### Statistics
- Objectives completed: X
- Alerts cleared: Y
- Active voyages: Z

### Notes
[Any important context for future sessions]

---
```

**Format requirements:**
- Use `## [YYYY-MM-DD HH:MM]` header format
- Include horizontal rule `---` at end
- Keep summary concise (no more than 200 words)

### Step 6: Generate Handover

Invoke the **handover skill** to generate a context dump for the next session.

This follows the DRY principle - handover logic lives in one place (`skills/handover/SKILL.md`).

The handover skill will:
- Query current state from SQLite
- Read session context from buffer.md
- Check git status
- Generate handover document
- Save to `.space-agents/staging/handover.md`

**Note:** Do NOT display the handover content to the user during dock - just generate it silently. The logout screen will indicate it's been saved.

### Step 7: Clear Staging

Overwrite `.space-agents/staging/buffer.md` with empty state:

```markdown
# Space-Agents Staging

*Session buffer - cleared on logout*

---

[No active session]
```

### Step 8: Display ASCII Logout Screen

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
│  Objectives completed: {objectives_completed}                  │
│  Alerts cleared:       {alerts_cleared}                        │
├────────────────────────────────────────────────────────────────┤
│  MISSION PROGRESS                                              │
│  {mission_name}        [{progress_bar}] {done}/{total}         │
├────────────────────────────────────────────────────────────────┤
│  Summary saved to CAPCOM. Staging cleared.                     │
│  Handover ready at staging/handover.md                         │
│                                                                │
│                 Safe travels, Commander.                       │
└────────────────────────────────────────────────────────────────┘
```

**Dynamic elements:**

| Placeholder | Source | Example |
|-------------|--------|---------|
| `{objectives_completed}` | SQLite query (today's completions) | `3` |
| `{alerts_cleared}` | SQLite query (today's cleared alerts) | `1` |
| `{mission_name}` | Active mission title from SQLite | `user-auth` |
| `{progress_bar}` | Visual bar based on done/total | `████████░░` |
| `{done}/{total}` | Completed/Total objectives in mission | `8/10` |

**If no active missions:** Show "No active missions"

## Optional: --compress Flag

**Note for Phase 4:** The `--compress` flag will compress CAPCOM entries older than 30 days into summaries. Not implemented yet - just acknowledge if user requests it:

"Roger that. The `--compress` option is planned for Phase 4. Session summary saved to CAPCOM without compression."

## Error Handling

**No buffer.md found:**
```
No active session detected. Nothing to save.
Run /launch to start a new session.
```

**No .space-agents directory:**
```
Space-Agents not initialized in this project.
Run /launch to initialize.
```

**SQLite connection error:**
Log the error to CAPCOM manually and inform user:
```
Warning: Could not query SQLite. Session summary saved with limited statistics.
```

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
│  Objectives completed: 3                                       │
│  Alerts cleared:       1                                       │
├────────────────────────────────────────────────────────────────┤
│  MISSION PROGRESS                                              │
│  user-auth             [████████░░] 8/10                       │
├────────────────────────────────────────────────────────────────┤
│  Summary saved to CAPCOM. Staging cleared.                     │
│  Handover ready at staging/handover.md                         │
│                                                                │
│                 Safe travels, Commander.                       │
└────────────────────────────────────────────────────────────────┘
```

## CAPCOM Entry Example

```markdown
## [2026-01-16 14:30] Session End

### Summary
- Completed JWT token signing and verification objectives
- User authentication voyage progressing well (2/3 missions complete)
- One warning alert cleared (deprecated method updated)

### Statistics
- Objectives completed: 3
- Alerts cleared: 1
- Active voyages: 1 (user-authentication)

### Notes
JWT expiry handling objective in progress - Worker on attempt 2.
Next session should continue from this point.

---
```

## Key Constraints

1. **Never read capcom.md** - Only append to it
2. **Always clear buffer.md** - Fresh state for next session
3. **Keep summaries concise** - CAPCOM grows indefinitely
4. **Preserve in-progress state** - Don't auto-complete uncertain work
5. **Use UTC timestamps** - Consistent across sessions

---

Safe travels, Commander. HOUSTON signing off.
