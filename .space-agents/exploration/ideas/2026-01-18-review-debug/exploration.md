# Exploration: Code Review & Debugging Skills

**Date:** 2026-01-18
**Status:** Ready for implementation

---

## Overview

Two new investigative skills for Space-Agents that share a common pattern: brainstorming → agent execution → actionable output with optional escalation to missions.

---

## Feature 1: `/code-review`

### Purpose
Review code quality, patterns, and implementation decisions. Can target recent mission output, specific files, or features.

### Triggers

| Mode | Description |
|------|-------------|
| **Auto-suggest** | After `/mission-go` completes, HOUSTON asks "Want me to review what was built?" |
| **On-demand** | User explicitly calls `/code-review` anytime |

### Review Targets

1. **Codebase section** - User specifies files/directories
2. **Recent feature** - User describes what to review
3. **Mission handover** - Review what Ralph built by examining `.space-agents/missions/complete/<mission>/handovers/`

### Execution Model

**Agent Swarm: Aspect Reviewers**
- Security agent - vulnerabilities, input validation, auth issues
- Performance agent - inefficiencies, N+1 queries, memory leaks
- Maintainability agent - code clarity, coupling, test coverage
- (Extensible - could add more aspects)

### Output Flow

```
Review executes
    ↓
Review report generated (.space-agents/reviews/<date>-<topic>/review.md)
    ↓
Post-review conversation with user
    ↓
User chooses:
    → Fix now (HOUSTON or mission)
    → Create alerts (for later)
    → Do nothing
```

### Integration

- **Standalone** - Does not create missions by default
- **Optional escalation** - If fixes needed, offer to create a mission

---

## Feature 2: `/debug`

### Purpose
Systematic debugging with structured investigation. Integrates with alerts system for tracking known issues.

### Entry Screen

When user runs `/debug`:

1. **Display active alerts** (from SQLite, grouped by severity)
2. **Ask user to choose:**
   - Fix existing alert (pick from list)
   - Report new bug (enters brainstorming)

### Report Bug Flow

```
User selects "Report new bug"
    ↓
Brainstorming session (gather context, reproduce, understand scope)
    ↓
User chooses:
    → Create alert (document for later)
    → Debug now (proceed to execution)
    → Document only (exploration report, no alert)
```

### Debugging Process

**User-facing:** Brainstorming conversation to gather information
**Under the hood:** Claude follows 4-phase systematic debugging (user abstracted from phases)

#### The Four Phases (Internal)

| Phase | Activity | Goal |
|-------|----------|------|
| 1. Root Cause Investigation | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| 2. Pattern Analysis | Find working examples, compare differences | Identify what's different |
| 3. Hypothesis & Testing | Form theory, test minimally, one variable at a time | Confirm or reject |
| 4. Implementation | Create failing test, fix root cause, verify | Bug resolved |

**Iron Law:** No fixes proposed until root cause investigation complete.

### Execution Options

After brainstorming, user chooses executor:

| Option | Description |
|--------|-------------|
| **HOUSTON** | Main conversation handles it directly |
| **Subagent** | Single background agent investigates |
| **Agent swarm** | Multiple agents in parallel |

### Swarm Strategies

HOUSTON proposes strategy based on bug type:

| Bug Type | Strategy | Rationale |
|----------|----------|-----------|
| "Crashes somewhere in auth flow" | **Component focus** | One agent per layer in call stack |
| "Could be X, Y, or Z" | **Parallel hypotheses** | Test multiple theories simultaneously |
| "No idea, just broken" | **Research swarm** | Gather evidence from logs, state, changes |

User approves or tweaks the proposed strategy.

### Alerts Integration

- `/debug` shows alerts at entry
- Debugging can update alert status as it progresses
- Alert cleared when root cause found and fixed
- New issues can become alerts via "Report bug" flow

### Output

- Debugging report with findings
- Updated alert status
- Optional: Escalate to mission if fixes are complex

---

## Shared Patterns

Both skills follow this structure:

```
Entry (show context)
    ↓
Brainstorming (gather information)
    ↓
Execution (HOUSTON / subagent / swarm)
    ↓
Report (documented findings)
    ↓
Action choice (fix / alert / mission / nothing)
```

### Why This Works

1. **Information first** - Brainstorming ensures Claude has context before acting
2. **User control** - User chooses execution method and follow-up action
3. **Traceability** - Reports and alerts create paper trail
4. **Escalation path** - Standalone by default, missions when needed

---

## Data Structures

### Review Report Location
```
.space-agents/reviews/<date>-<topic>/review.md
```

### Mission Handovers (for review targets)
```
.space-agents/missions/complete/<mission-id>/handovers/
```

### Alerts Table (existing)
```sql
CREATE TABLE alerts (
    id TEXT PRIMARY KEY,
    timestamp DATETIME,
    severity INTEGER,  -- 0=critical, 1=blocker, 2=warning, 3=info
    mission_id TEXT,
    objective_id TEXT,
    source TEXT,
    description TEXT,
    status TEXT  -- 'active' or 'cleared'
);
```

---

## Open Questions

1. **Review aspects** - What specific checks should each aspect reviewer perform?
2. **Swarm coordination** - How do parallel agents report back and merge findings?
3. **Alert lifecycle** - Should debugging auto-clear alerts or require user confirmation?

---

## Next Steps

When ready to implement:
1. `/mission-brief` to plan the implementation
2. Consider implementing `/code-review` first (simpler, fewer states)
3. Then `/debug` (more complex, alerts integration)
