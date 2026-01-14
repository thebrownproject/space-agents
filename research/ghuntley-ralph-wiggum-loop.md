# Ralph Wiggum Loop

Reference material for SAL-9000 development.

**Sources**:
- https://github.com/ghuntley/how-to-ralph-wiggum (Geoffrey Huntley)
- Matt Pocock's implementation video

---

## The Core Insight

> "The power isn't iteration. The power is fresh context windows."

Ralph spawns **new Claude Code sessions** for each task. State persists in files, context stays fresh.

### Why Not Multi-Phase Plans?

Traditional approach: Create a big plan with arrows showing dependencies, figure out the exact path.

**Problems**:
- Hard to add new tasks (where does it fit?)
- Must figure out all dependencies upfront
- Doesn't reflect how engineers actually work

**Ralph's approach**: Kanban board. Grab highest priority task, complete it, repeat.

```
Multi-phase plan:          Kanban (Ralph):

  ┌───┐                    ┌───┬───┬───┬───┐
  │ 1 │──┐                 │ A │ B │ C │ D │  ← just a list
  └───┘  │   ┌───┐         └───┴───┴───┴───┘
         ├──▶│ 3 │──▶...
  ┌───┐  │   └───┘         Agent grabs one,
  │ 2 │──┘                 completes it,
  └───┘                    grabs next.

  Complex dependencies     No arrows needed
```

Adding a task to Ralph: just add it to the list. The agent figures out priority.

---

## First Principles (From the Creator)

> "Ralph is really just a malicking orchestrator that avoids context rot and compaction."
> — Geoffrey Huntley

### Context Windows Are Arrays

The context window is just an array. The less you use, the less the window needs to slide, the better outcomes you get.

**Compaction is the devil** - Anthropic's plugin keeps pounding the model until compaction triggers. Compaction is a lossy function that can lose "the pin" (your frame of reference).

Ralph avoids this by **deterministically malicking the array** - starting fresh each iteration instead of accumulating.

### The PIN (Frame of Reference)

The PIN is a lookup table that links to your specifications and gives hints to the search tool:

```markdown
# specs/README.md (the PIN)

| Feature | Spec File | Search Terms |
|---------|-----------|--------------|
| User Auth | auth.md | authentication, login, session, JWT |
| Analytics | analytics.md | metrics, tracking, events, posthog |
```

More descriptors = more search tool hits = less invention. You want it to find existing code, not invent new patterns.

### Specs Are Generated, Not Handcrafted

> "Would you believe I don't create my specs. I generate them. Then I review and edit them by hand."

The conversation creates specs. It's a dance - molding clay on a pottery wheel:

```
You: "I want to add product analytics like PostHog"
Claude: asks clarifying questions
You: steer with engineering knowledge ("use our existing SQL schema")
Claude: generates spec
You: review, edit, approve
```

Then you let Ralph rip on the approved spec.

### One Goal Per Loop

Each iteration should have **one objective**. This uses less of the array.

Instead of multi-step plans executed in one session, let the LLM decide the most important thing from the implementation plan each iteration.

> "Low control, high oversight"

### Back Pressure Engineering

> "Our job as software engineers is to keep the locomotive on the track. We are locomotive engineers now."

Your job is engineering **back pressure** to keep the generative function on rails:
- Type checking
- Tests (property-based or unit - let LLM decide)
- Linting
- Deployment gates

If it outputs something bad, that's just another Ralph loop to fix it.

### Attended → Unattended

Don't just let it rip immediately:

1. **Attended** - Watch it, see what it does
2. **Adjust** - Refine prompt/specs if something's weird
3. **Unattended** - Once you trust it, let it rip AFK

> "You don't just let it rip. You watch it. If something's wrong, go back to specifications, adjust the prompt engineering."

---

## Relation to Agent Inference Loops

Ralph is essentially an **externalized agent inference loop**.

A standard agent inference loop (like Claude Code) works internally:

```
┌─────────────────── SINGLE SESSION ───────────────────┐
│                                                      │
│  User prompt                                         │
│       ↓                                              │
│  ┌──────────────────────────────────────┐            │
│  │  Think → Tool call → Result          │            │
│  │    ↓                                 │            │
│  │  Think → Tool call → Result          │ ← loop     │
│  │    ↓                                 │            │
│  │  Think → Tool call → Result          │            │
│  └──────────────────────────────────────┘            │
│       ↓                                              │
│  Response (or continue looping)                      │
│                                                      │
│  Context accumulates throughout session              │
└──────────────────────────────────────────────────────┘
```

Ralph externalizes this loop to bash, splitting at **task boundaries**:

```
                    ┌──────────────────────┐
                    │      BASH LOOP       │
                    │   while true; do     │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   FRESH SESSION      │◄──── 0 tokens (smart zone)
                    │                      │
                    │  Read PRD, progress  │
                    │         ↓            │
                    │  ┌────────────────┐  │
                    │  │ Inference Loop │  │
                    │  │ Think → Tool   │  │
                    │  │ Think → Tool   │  │
                    │  │ ...            │  │
                    │  └────────────────┘  │
                    │         ↓            │
                    │  Update files        │
                    │  Git commit          │
                    │  EXIT                │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   FILES PERSIST      │
                    │  PRD.json, progress  │
                    └──────────┬───────────┘
                               │
                               └───────► next iteration (fresh session)
```

**Key insight**: The inner loop (think → tool → result) stays the same. Ralph just resets context between tasks by exiting and restarting the process. State transfers via files instead of context.

| Aspect | Internal Loop | Ralph (External) |
|--------|---------------|------------------|
| Loop mechanism | While processing request | Bash while loop |
| Context | Accumulates | Fresh each task |
| State transfer | In context window | Via files |
| Granularity | Tool calls | Task completion |
| When to use | Short/medium tasks | Long multi-task projects |

---

## Context Rot (The Problem)

LLM effectiveness degrades as context fills:

```
0 ──────────── 100k ──────────── 200k tokens
      SMART           DUMB
```

**Why it happens**:
- Attention spread thinner across more tokens
- "Lost in the middle" - LLMs struggle with mid-context info
- Accumulated errors compound

**Solution**: Fresh sessions. Always operate at 0 tokens.

---

## The Scripts

### OG Ralph (ghuntley)

```bash
#!/bin/bash
# Usage: ./loop.sh [plan] [max_iterations]
# Examples:
#   ./loop.sh              # Build mode, unlimited iterations
#   ./loop.sh 20           # Build mode, max 20 iterations
#   ./loop.sh plan         # Plan mode, unlimited iterations
#   ./loop.sh plan 5       # Plan mode, max 5 iterations

# Parse arguments
if [ "$1" = "plan" ]; then
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=$1
else
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=0
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mode:   $MODE"
echo "Prompt: $PROMPT_FILE"
echo "Branch: $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    # Run Ralph iteration with selected prompt
    # -p: Headless mode (non-interactive, reads from stdin)
    # --dangerously-skip-permissions: Auto-approve all tool calls (YOLO mode)
    # --output-format=stream-json: Structured output for logging/monitoring
    # --model opus: Primary agent uses Opus for complex reasoning
    # --verbose: Detailed execution logging
    cat "$PROMPT_FILE" | claude -p \
        --dangerously-skip-permissions \
        --output-format=stream-json \
        --model opus \
        --verbose

    # Push changes after each iteration
    git push origin "$CURRENT_BRANCH" || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH"
    }

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"
done
```

### Matt Pocock's Implementation

More structured with inline prompt and completion detection:

```bash
#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <iterations>"
    exit 1
fi

for ((i=1; i<=$1; i++)); do
    echo "Iteration $i"
    echo "--------------------------------------------"
    result=$(claude --permission-mode acceptEdits -p "@plans/prd.json @progress.txt \
        1. Find the highest-priority feature to work on and work only on that feature. \
        This should be the one YOU decide has the highest priority - not necessarily the first in the list. \
        2. Check that the types check via pnpm typecheck and that the tests pass via pnpm test. \
        3. Update the PRD with the work that was done. \
        4. Append your progress to the progress.txt file. \
        Use this to leave a note for the next person working in the codebase. \
        5. Make a git commit of that feature. \
        ONLY WORK ON A SINGLE FEATURE. \
        If, while implementing the feature, you notice the PRD is complete, output <promise>COMPLETE</promise>")

    echo "$result"

    if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
        echo "PRD complete, exiting."
        tt notify "CVM PRD complete after $i iterations"
        exit 0
    fi
done
```

Key differences:
- Uses `@file` syntax to pass files
- Inline prompt (no separate PROMPT.md)
- `<promise>COMPLETE</promise>` as exit signal
- Sends notification when done (`tt notify`)

---

## Key Files

| File | Purpose |
|------|---------|
| `prd.json` | User stories with `passes` flag - the todo list |
| `progress.txt` | Append-only log of learnings - sprint memory |
| `ralph.sh` | The loop script |

### PRD Format (JSON)

```json
{
  "userStories": [
    {
      "id": "US-001",
      "title": "Delete video shows confirmation",
      "acceptance": "Dialog appears before delete action",
      "passes": true
    },
    {
      "id": "US-002",
      "title": "Beats display as orange dots",
      "acceptance": "Three orange ellipses below clip",
      "passes": false
    }
  ]
}
```

The `passes` flag is the todo mechanism. Agent finds first `false`, works on it, marks `true`.

### progress.txt (Append-Only)

```
## Iteration 3 - US-002
Implemented beat indicator component.
Added to clip renderer at line 145.
Tests passing.

Note for next: Consider US-003 (beat playback) or US-007 (beat removal).
```

**Critical**: Append, don't overwrite. This is the agent's memory for the sprint. Delete it when sprint completes.

---

## Feedback Loops (Critical)

> "Claude has a tendency to mark features complete without proper testing."
> — Anthropic

Ralph only works with strong feedback:

- **Type checking** - `pnpm typecheck` must pass
- **Unit tests** - `pnpm test` must pass
- **CI stays green** - every commit must pass
- **Browser automation** - Playwright MCP for visual verification

**Why small tasks matter**: You need context budget left for feedback. Big task + tests + browser screenshots = context overflow. Small task leaves room for verification.

---

## The Loop Flow

```
1. NEW session (fresh context)
2. Read PRD → find highest priority task with passes: false
3. Read progress.txt → see sprint learnings
4. Implement the single feature
5. Run feedback loops (types, tests)
6. Update PRD (passes: true)
7. Append to progress.txt
8. Git commit
9. If PRD complete → output "promise complete here" → exit
10. Exit → bash loop restarts at step 1
```

---

## Two Modes

| Mode | What You Do | When |
|------|-------------|------|
| **Attended** | Watch it, adjust prompt/specs if something's weird | New features, learning, refining |
| **Unattended** | Let it rip AFK | Once you trust it, overnight batch |

The progression:
1. Start **attended** - watch what it does
2. Cancel if something's off, adjust specs or prompt
3. Once confident, switch to **unattended** and let it clear the backlog

---

## SAL-9000 Relevance

The architecture already embodies Ralph's core insight:

- **Pods/Crew are fresh subagents** - same as Ralph's new sessions
- **CAPCOM filters context** - prevents rot by limiting what each agent sees
- **SQLite + files for state** - like PRD.md/progress.txt pattern
- **Backpressure via Airlock** - tests/lint force fixes before proceeding

Key difference: SAL can run Pods in **parallel** (multiple features at once), while Ralph is sequential.
