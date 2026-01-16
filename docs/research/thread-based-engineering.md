# Thread-Based Engineering: A Framework for Measuring Agentic Progress

**Source:** Andy Devdan Video Transcript
**Date:** 2026-01-16
**Topic:** Mental framework for continuously improving engineering output with AI agents

---

## Core Insight

> **"Agents are compute, not memory."**

Agentic engineering is a new skill that requires new frameworks to measure progress. If you don't measure it, you can't improve it.

---

## What is a Thread?

A **thread** is a unit of work over time driven by you and your agents.

```
[YOU: Prompt/Plan] → [AGENT: Tool Calls] → [YOU: Review/Validate]
```

**Key components:**
- **Beginning:** You show up for the prompt or plan
- **Middle:** Your agent does work (string of tool calls)
- **End:** You show up for review or validation

**Example:** Every time you hit enter in Claude Code, you're starting a thread of work.

---

## The Six Thread Types

### 1. Base Thread (Foundation)
**Pattern:** Single agent, single line of work

```
Prompt → Tool Calls → Review
```

- Most basic unit of engineering work
- Tool calls roughly equal impact (assuming useful prompting)
- Pre-2023: You were the tool calls
- Post-2023: Agents make the tool calls

### 2. P-Thread (Parallel)
**Pattern:** Multiple threads running simultaneously

```
Prompt A → Work → Review A
Prompt B → Work → Review B
Prompt C → Work → Review C
```

**Example:** Boris Churnney's setup
- 5 Claude Code instances in terminal (tabs 1-5)
- 5-10 additional instances in web interface
- Defaults to running multiple agents, not single

**Benefits:**
- More compute = more output
- Can't review everything at once, so threads shift over time
- Scales engineering capacity

### 3. C-Thread (Chained)
**Pattern:** Work broken into intentional phases with checkpoints

```
Prompt → Phase 1 → Review → Phase 2 → Review → Phase 3 → Review
```

**When to use:**
- Work can't fit in single agent's context window
- High-pressure production work requiring validation at each step
- Multi-phase migrations or sensitive operations

**Not because agent messed up** - this is intentional chunking for control.

**Tools:**
- Claude Code's `AskUserQuestion` tool
- System notifications to alert when phase complete
- Text-to-speech hooks for human-in-loop signals

**Trade-off:** Your time and energy. Question yourself: "Do I need to break this down?"

### 4. F-Thread (Fusion) ⭐
**Pattern:** Multiple agents work on same/similar prompt → aggregate results

```
Prompt → Agent A → Result A ↘
Prompt → Agent B → Result B → Synthesize/Merge → Final Result
Prompt → Agent C → Result C ↗
```

**Andy's favorite thread type.**

> **"The fusion thread is the cream of the crop for rapid prototyping."**

**Benefits:**
- **Best-of-N:** Choose the best result from multiple attempts
- **Cherry-pick:** Combine best ideas from multiple agents
- **Higher confidence:** 4/5 agents agree = strong signal
- **Fail-safe:** If one agent gets stuck, others finish

**Use cases:**
- Rapid prototyping
- Exploring solution space (see multiple architectural approaches)
- Code review (spawn 3-5 review agents for consensus)
- Research (multiple web searches aggregated)

**Example:** Run 3 Claude + 3 Gemini + 3 Codecs = 9 parallel attempts, then synthesize

> **"The future of rapid prototyping will be done with fusion threads."**

### 5. B-Thread (Big/Meta)
**Pattern:** Agents spawn other agents (meta-structure)

```
You: Prompt
  ↓
Primary Agent
  ↓
  ├→ Sub-agent A
  ├→ Sub-agent B
  └→ Sub-agent C
  ↓
You: Review
```

**Key insight:** From your perspective, it's just one thread (prompt → review). Under the hood, multiple threads run.

**Examples:**
- Plan agent → Build agent workflow
- Orchestrator → Team of specialists (scout, plan, build, review, staging)
- Claude Code's sub-agents (agent spawning agents)

**Why it matters:** Creates "thicker" threads - more tool calls happen in same unit of time by deploying more compute.

**Emerging pattern:** Ralph Wiggum loop
- AI engineers discovering: **agents + code > agents alone**
- Loop over agent to accomplish specific work
- Closed-loop systems with validation

### 6. L-Thread (Long-duration)
**Pattern:** High autonomy, extended execution without human intervention

```
Prompt → [hundreds/thousands of tool calls] → Review
```

**Characteristics:**
- Hours to days of runtime
- Hundreds/thousands of tool calls
- High autonomy throughout
- Same shape as Base Thread, just longer

**Example:** Boris's 1 day, 2 hour run with Ralph Wiggum plugin

**What enables L-Threads:**
- Better prompting (great planning = great prompting)
- Better models
- Better context management
- Better tools
- Agent stop hooks (validation loops)

**Boris's stop hook pattern:**
- Agent tries to stop
- Hook intercepts
- Runs validation/checks progress file
- Either continues loop or completes

**Key:** Stop hook = deterministic code + agents working together

---

## Four Ways to Improve

Andy's concrete framework for measuring progress:

### 1. Run MORE threads
**Scale through parallelism**

- Open more terminals
- Spin up more agent instances
- Boris: 5 terminals + 5-10 web instances = 10-15 parallel threads
- In-loop tools (terminals) + out-of-loop tools (web interface)

### 2. Run LONGER threads
**Increase autonomy**

- Better prompting → longer execution
- Better context management → fewer interruptions
- Better validation loops → self-correcting agents
- Measure: Can your agent run for hours instead of minutes?

### 3. Run THICKER threads
**Deploy meta-structures**

- Sub-agents
- Teams of agents
- Orchestrator patterns
- More tool calls happen in same time period
- Build specialized agents for specialized codebases

### 4. Run FEWER checkpoints
**Increase trust**

- Build systems you trust
- Give agents tools to validate their own work
- Reduce human-in-the-loop reviews
- Not vibe coding - this is maximum trust through great engineering

**Boris's advice:** "Most important thing for great results: give your agent a way to verify its work."

---

## The Hidden Seventh Thread: Z-Thread

**Z-Thread (Zero-touch):** Maximum trust, no review step required.

```
Prompt → [Work] → (No review needed)
```

**Not vibe coding.** This is:
- Very advanced agentic engineering
- Maximum trust through proven systems
- You know you don't have to review (but you can)
- The endgame

**Represents:** Living software that works while you sleep.

---

## Key Principles

### Thread = Compute Deployment
- Tool calls roughly equal impact
- More threads = more compute = more output
- You show up at beginning (prompt) and end (review)
- Agents do the work in between

### The Core Four
Everything boils down to:
1. **Context** - What the agent knows
2. **Model** - The agent's capability
3. **Prompt** - Your instructions
4. **Tools** - What the agent can do

Improve these → improve your threads.

### Measuring Progress
If you can't measure it, you can't improve it. Track:
- How many threads are you running?
- How long do they run?
- How thick are they (tool call density)?
- How often do you need to review?

---

## Real-World Examples

### Boris Churnney (Claude Code Creator)

**Setup:**
- 5 Claude Code instances in terminal (tabs 1-5)
- 5-10 additional instances in web interface
- Always uses Opus 4.5
- Claude in repo, doesn't let it get too large
- Specific permissions (not dangerously skip)
- System notifications for agent input needs

**His advice:**
- Default to multiple agents, not single
- Give agents tools to verify their work
- Use stop hooks for long-running tasks
- Either verify with background agent (C-Thread) or stop hook validation loop

### Andrew Karpathy Quote

> "I've never felt this much behind as a programmer."

**Why this matters:**
- Even great engineers feel the shift
- Agentic engineering is a **new skill**
- The gap is widening between engineers using agents vs not
- Self-awareness is key: "This feels like a skill issue" (it is)

---

## Implications for Space-Agents

### Current Architecture Mapping

| Thread Type | Space-Agents Equivalent |
|-------------|------------------------|
| Base Thread | Single Pod execution |
| C-Thread | Voyage → Missions → Objectives (intentional checkpoints) |
| B-Thread | Pod → Crew (Worker/Inspector/Analyst) |
| L-Thread | Ralph loop running full mission |

### Not Yet Implemented

| Thread Type | Potential Implementation |
|-------------|------------------------|
| P-Thread | Parallel Pod execution (Ralph runs sequential) |
| F-Thread | Multiple Pods solve same objective, merge results |
| Z-Thread | Zero-touch missions (though background runs exist) |

### Opportunity: F-Thread Planning

**Best use case for Space-Agents:**
- Use F-Threading for **brainstorming and planning**
- Spawn multiple specialized agents (Research, Architecture, Risk)
- Synthesize into unified plan
- Ralph executes sequentially (proven pattern)

**Why this works:**
- Better plans → better Ralph outcomes
- Multiple perspectives catch edge cases
- User stays in control (HOUSTON synthesizes, Fraser decides)
- Doesn't change proven execution layer

---

## Quotes to Remember

> "F-Thread is the cream of the crop for rapid prototyping."

> "Agents plus code outperforms agents alone."

> "The most important thing to get great results: give your agent a way to verify its work."

> "Software engineering has changed again and again and it will continue to. But by thinking in threads, you can know that you're improving."

> "If you want to scale your impact, you must scale your compute."

---

## Action Items for Agentic Engineers

1. **Audit your current threads** - How many are you running? How long? How thick?
2. **Start with P-Threads** - Open more terminals, run agents in parallel
3. **Experiment with F-Threads** - Rapid prototyping, multiple solution paths
4. **Build validation loops** - Let agents verify their own work
5. **Push toward L-Threads** - Better prompting → longer autonomous runs
6. **Measure progress** - Track tool calls, thread count, autonomy duration

---

## Resources

- **Ralph Wiggum pattern:** Loop-based execution with validation
- **Boris Churnney setup:** Multiple parallel instances, stop hooks
- **Core Four:** Context, Model, Prompt, Tools
- **ADWs (AI Developer Workflows):** Deterministic code + agents

---

**Bottom line:** Engineering with agents is a new skill. Thread-based thinking gives you a concrete framework to measure improvement and scale your impact.
