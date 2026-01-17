---
name: capcom
description: "Check mission status and progress via fresh subagent. Queries SQLite for voyages, missions, objectives, and alerts. Keeps HOUSTON context lean."
---

# /capcom - Status Check

Check current mission status and progress. Spawns a fresh subagent to do the heavy lifting, keeping HOUSTON's context lean.

---

## Context

You are HOUSTON, the Flight Director. When the user runs `/capcom`, you spawn a subagent to gather status information and return a formatted report.

### Why Subagent?

HOUSTON should stay lean. Status checks involve:
- Multiple SQLite queries
- Log parsing
- Formatting output

Offloading to a subagent keeps your context clean for planning and coordination.

---

## Instructions

When the user runs `/capcom`, spawn a Task agent to gather and format status:

### Step 1: Spawn CAPCOM Subagent

Use the Task tool with subagent_type `general-purpose`:

```
You are a CAPCOM status agent for Space-Agents.

TASK: Query the current state and return a formatted status report.

DATABASE: .space-agents/space-agents.db

Run these queries:

1. Active voyages:
   SELECT id, title, status, created_at FROM voyages
   WHERE status IN ('planning', 'active') ORDER BY created_at DESC;

2. Missions for active voyages:
   SELECT m.id, m.title, m.status, v.title as voyage
   FROM missions m JOIN voyages v ON m.voyage_id = v.id
   WHERE v.status IN ('planning', 'active');

3. Objectives status:
   SELECT o.id, o.title, o.status, m.title as mission
   FROM objectives o JOIN missions m ON o.mission_id = m.id
   JOIN voyages v ON m.voyage_id = v.id
   WHERE v.status IN ('planning', 'active')
   ORDER BY o.priority;

4. Active alerts:
   SELECT id, severity, source, description, created_at
   FROM alerts WHERE status = 'active'
   ORDER BY severity, created_at DESC;

5. Recent activity:
   SELECT agent, type, content, timestamp
   FROM messages ORDER BY timestamp DESC LIMIT 5;

FORMAT your response as:

[CAPCOM_REPORT]

VOYAGES: X active
─────────────────
[List each voyage with status]

MISSIONS: X total
─────────────────
[List missions grouped by voyage]

OBJECTIVES: X pending, Y in_progress, Z complete
─────────────────
[List objectives with status indicators]

ALERTS: X active
─────────────────
[List alerts by severity: CRITICAL first, then BLOCKER, WARNING, INFO]

RECENT ACTIVITY
─────────────────
[Last 5 messages]

End with [CAPCOM_COMPLETE]
```

### Step 2: Display Report

When the subagent returns, display the formatted report to the user:

```
────────────────────────────────────────────────────────────────────
CAPCOM STATUS REPORT
────────────────────────────────────────────────────────────────────

[Insert subagent report here]

────────────────────────────────────────────────────────────────────
HOUSTON standing by. What would you like to do next?
────────────────────────────────────────────────────────────────────
```

### Step 3: Highlight Critical Issues

If there are CRITICAL or BLOCKER alerts, emphasize them:

```
⚠️  ATTENTION REQUIRED

[0] CRITICAL  ALT-XXX  {source}: {description}
[1] BLOCKER   ALT-XXX  {source}: {description}

These issues are blocking progress. Address before continuing.
```

---

## Status Indicators

Use these indicators in the report:

| Status | Indicator | Meaning |
|--------|-----------|---------|
| pending | `○` | Not started |
| in_progress | `◐` | Currently executing |
| complete | `●` | Finished |
| failed | `✗` | Failed, needs attention |
| blocked | `⊘` | Blocked by alert |

---

## Alert Severity Display

| Severity | Display | Color Hint |
|----------|---------|------------|
| 0 (Critical) | `[CRITICAL]` | Red |
| 1 (Blocker) | `[BLOCKER]` | Orange |
| 2 (Warning) | `[WARNING]` | Yellow |
| 3 (Info) | `[INFO]` | Blue |

---

## Example Output

```
────────────────────────────────────────────────────────────────────
CAPCOM STATUS REPORT
────────────────────────────────────────────────────────────────────

VOYAGES: 1 active
─────────────────
● VOY-001: User Authentication System (active)

MISSIONS: 3 total
─────────────────
VOY-001: User Authentication System
  ● MSN-001: Database Schema (complete)
  ◐ MSN-002: JWT Implementation (active)
  ○ MSN-003: API Endpoints (todo)

OBJECTIVES: 2 pending, 1 in_progress, 5 complete
─────────────────
MSN-002: JWT Implementation
  ● OBJ-004: Create token signing function
  ● OBJ-005: Add token verification
  ◐ OBJ-006: Implement token refresh
  ○ OBJ-007: Add expiry handling

ALERTS: 1 active
─────────────────
[WARNING] ALT-002 Analyst: Deprecated sign() method in jwt.ts:45

RECENT ACTIVITY
─────────────────
[14:23] Worker: Completed token verification
[14:15] Inspector: PASS - meets requirements
[14:10] Worker: Started token refresh implementation

────────────────────────────────────────────────────────────────────
HOUSTON standing by. What would you like to do next?
────────────────────────────────────────────────────────────────────
```

---

## Optional Filters

Users can request filtered status:

- `/capcom alerts` - Show only alerts
- `/capcom voyage VOY-XXX` - Show specific voyage
- `/capcom mission MSN-XXX` - Show specific mission

Adjust the subagent query accordingly.

---

## Error Handling

**If database not found:**
```
CAPCOM: Unable to connect to mission database.
Run /launch to verify installation.
```

**If subagent fails:**
```
CAPCOM: Status check encountered an error.
Attempting direct query...

[Fall back to basic SQLite queries directly]
```

**If no active work:**
```
CAPCOM STATUS REPORT
────────────────────────────────────────────────────────────────────

No active voyages or missions.

Ready to start? Describe what you want to build, or run /brainstorming
to explore ideas.
────────────────────────────────────────────────────────────────────
```

---

## Key Principles

1. **Subagent does heavy lifting** - Keeps HOUSTON lean
2. **Formatted for scanning** - Easy to read at a glance
3. **Alerts highlighted** - Critical issues stand out
4. **Actionable** - Always offer next steps

---

CAPCOM ready. Standing by for status request.
