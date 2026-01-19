# Space-Ralph: Lightweight Iteration Mode

**Created:** 2026-01-19
**Status:** Exploration

## Problem Statement

The current Space-Agents workflow (`/exploration` → `/mission-brief` → `/mission-go`) is powerful but heavy. It's designed for complex features with planning councils, SQLite tracking, and multi-objective missions.

But sometimes users just want to **quickly iterate on a simple task** without all the ceremony:
- Fix a bug
- Add a small feature
- Quick prototype
- Solo dev work that doesn't need full mission tracking

**The need:** A lightweight execution mode that skips the bloat but keeps the structure.

---

## Current Workflow (Heavy)

```
/exploration (5-10 rounds, spawn agents, create report)
    ↓
/mission-brief (convene 3-agent planning council, stage-by-stage synthesis)
    ↓
/mission-go (SQLite missions/objectives, Ralph loop with Pods)
```

**Characteristics:**
- SQLite database with missions/objectives schema
- Planning council (3 agents in parallel)
- Multi-objective sequencing
- Full Pod agents (Worker/Inspector/Analyst/Airlock)
- Great for: teams, complex features, tracking needed

---

## Proposed Solution: /ralph (Space-Ralph Mode)

A **lightweight alternative** that provides quick iteration without mission overhead.

### User Flow

1. **User runs `/launch`** - sees normal welcome screen
2. **User runs `/ralph`** - enters lightweight mode
3. **HOUSTON runs mini brainstorm** - 3-5 quick questions (not 10-round deep dive)
4. **Setup session folder** - creates dated folder with markdown files
5. **Launch simple loop** - spawns lightweight agent, iterates until done

### Added to Launch Welcome Screen

```
│  Execution                                                     │
│    /mission-go          Launch Pod loop for active mission     │
│    /ralph               Quick iteration mode (no missions)     │
```

---

## Architecture

### Folder Structure

```
.space-agents/ralph/
  2026-01-19-auth-jwt/
    prompt.md       (task description from brainstorm)
    status.md       (done/blocked/running)
    context.md      (agent notes between iterations)
  2026-01-18-fix-cache-bug/
    prompt.md
    status.md
    context.md
```

Each Ralph session gets its own dated folder: `YYYY-MM-DD-description/`

### The Mini Brainstorm

HOUSTON guides quick setup (3-5 questions):

1. What are you building?
2. Any constraints? (tech stack, existing patterns, etc.)
3. What's the scope? (single file? multiple? tests needed?)
4. Success criteria? (what does "done" look like?)
5. Any other context?

**Key difference from `/exploration`:**
- No deep multi-round dialogue
- No spawning research agents
- Just enough to write a clear `prompt.md`

### The Files

**prompt.md:**
```markdown
# Task: Add JWT Authentication

## Goal
Implement JWT token signing and verification for user sessions

## Constraints
- Use existing jsonwebtoken library (already in package.json)
- Follow auth patterns in src/auth/
- Add tests alongside implementation

## Success Criteria
- Token signing works
- Token verification works
- Tests pass
- No breaking changes to existing auth

## Context
User mentioned they want refresh token rotation in the future,
so keep that in mind when designing the interface.
```

**status.md:**
```markdown
Status: running
```

Agent updates this to `done` or `blocked` when appropriate.

**context.md:**
```markdown
(Empty initially - agent writes notes here between iterations)
```

---

## The Simple Loop

Based on the screenshot pattern:

```bash
#!/bin/bash
MAX_ITERATIONS=200
iteration=0

echo "Starting agent loop..."

while true; do
  iteration=$((iteration + 1))

  if [ "$iteration" -gt "$MAX_ITERATIONS" ]; then
    echo "Max iterations reached. Stopping."
    break
  fi

  # Check status file
  STATUS=$(grep -o 'Status: [a-zA-Z]*' ./ralph/status.md | cut -d' ' -f2)

  if [ "$STATUS" = "done" ] || [ "$STATUS" = "blocked" ]; then
    echo "Agent stopped with status: $STATUS"
    cat ./ralph/status.md
    break
  fi

  echo ""
  echo "=== Running iteration $iteration/$MAX_ITERATIONS at $(date) ==="
  echo "Current status: $STATUS"
  echo ""

  # Run agent with the prompt file
  prompt=$(cat ./ralph/prompt.md)
  codex exec "$prompt" --model gpt-5.2-codex --full-auto --config model_reasoning_effort="xhigh"

  # Small delay to avoid hammering the API
  sleep 2
done

echo ""
echo "Loop completed!"
```

---

## The Simple Agent

**NOT** the complex `mission-pod` with Worker/Inspector/Analyst ceremony.

**Instead:** A lightweight agent that:
- Reads `./ralph/prompt.md`
- Executes the task
- Writes progress to `context.md`
- Updates `status.md` when done/blocked
- Simple, focused, fast

Maybe call it: `ralph-agent.md` or `quick-executor.md`

---

## Key Differences

| Feature | Full Space-Agents | Ralph Mode |
|---------|-------------------|------------|
| **Entry point** | `/exploration` | `/ralph` |
| **Planning** | 10-round dialogue + 3-agent council | 3-5 question mini brainstorm |
| **State** | SQLite missions/objectives | Markdown files in dated folders |
| **Agent** | Complex Pod (Worker/Inspector/Analyst) | Simple executor |
| **Scope** | Multi-objective missions | Single task iteration |
| **Use case** | Teams, complex features, tracking | Solo dev, quick tasks, prototypes |
| **Ceremony** | High (planning council, stages) | Low (just do it) |

---

## Use Cases

**When to use Ralph mode:**
- "Fix this bug quickly"
- "Add this small feature"
- "Try out this idea"
- Solo developer iterating
- Don't need tracking/history
- Want to move fast

**When to use full Space-Agents:**
- Complex multi-part features
- Need planning council input
- Team collaboration
- Want full tracking in SQLite
- Multiple objectives with dependencies

---

## Implementation Plan

### 1. Create `/ralph` skill

Location: `skills/ralph/SKILL.md`

Sections:
- Purpose & when to use
- Mini brainstorm questions
- Folder setup process
- Loop script
- Agent integration

### 2. Create simple agent

Location: `agents/ralph-agent.md`

Simpler than mission-pod:
- No Worker/Inspector/Analyst roles
- Just read prompt, execute, update status
- Write progress notes to context.md

### 3. Update `/launch` welcome screen

Add Ralph to execution commands section.

### 4. Create loop script

Location: `skills/ralph/scripts/ralph-loop.sh`

Based on the screenshot pattern.

---

## Open Questions

1. **Should Ralph mode write to SQLite at all?**
   - Could track sessions in a lightweight `ralph_sessions` table
   - Or stay completely file-based?

2. **Can user switch from Ralph → full mission later?**
   - "This got complex, migrate to full Space-Agents"?

3. **Integration with /capcom?**
   - Should /capcom show Ralph sessions?
   - Or is Ralph completely separate?

4. **Should HOUSTON actually run the loop?**
   - Or just set it up and give user the command?
   - (Similar to mprocs --visible in mission-go)

---

## Next Steps

1. Draft `/ralph` SKILL.md
2. Draft `ralph-agent.md`
3. Create loop script
4. Test with simple task
5. Update `/launch` welcome screen
6. Document differences in main README

---

## Notes from Discussion

- User saw the lightweight loop pattern (codex exec with status checks)
- Wanted to capture that simplicity without missions bloat
- Each Ralph session in dated folder (like exploration reports)
- HOUSTON still helps with mini brainstorm (not totally hands-off)
- Simple agent, no Worker/Inspector/Analyst ceremony
- For solo devs who want to move fast

**Key insight:** Not everything needs the full mission framework. Sometimes you just need Ralph to get it done.
