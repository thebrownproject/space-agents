# obra/superpowers

Reference material for SAL-9000 development.

**Sources**:
- https://github.com/obra/superpowers (Jesse Vincent / obra)
- https://blog.fsck.com/2025/10/16/skills-for-claude/
- https://colinmcnamara.com/blog/stop-babysitting-your-ai-agents-superpowers-breakthrough

---

## The Core Insight

> "Skills are magic words that make your agent behave differently, even without you asking directly."

Superpowers encodes development workflows as **SKILL.md files** that Claude loads and follows autonomously. Instead of repeating instructions, you define a workflow once and the agent applies it whenever relevant.

### Why Not Just Prompts?

Traditional approach: Tell Claude what to do each time, hope it follows your preferred workflow.

**Problems**:
- Must repeat instructions constantly
- Agent makes assumptions instead of asking
- Skips verification steps under "time pressure"
- Quality varies based on how tired/rushed you are

**Superpowers approach**: Skills inject mandatory workflows. Claude checks for relevant skills before every action.

```
Manual prompting:             Skills system:

  "Use TDD"                   ┌─────────────────────┐
       ↓                      │  SKILL.md files     │
  Claude implements           │  - TDD              │
       ↓                      │  - Debugging        │
  "Wait, write test first"    │  - Brainstorming    │
       ↓                      └──────────┬──────────┘
  Claude: "oh right"                     │
       ↓                      Agent checks skills
  "No really, RED first"      BEFORE every action
       ↓                              │
  Claude does it correctly    Workflow enforced
                              automatically
```

---

## First Principles (From the Creator)

> "Skills aren't immune to prompt injection—they essentially ARE prompt injection."
> — Jesse Vincent

### Bootstrap Mechanism

The `using-superpowers` skill is the meta-skill that teaches Claude to use other skills:

1. **Before ANY response** (including clarifying questions), check if skills might apply
2. **Even 1% chance** → invoke the skill to check
3. **Announce usage**: "Using [skill] to [purpose]"
4. **Follow skill exactly** (rigid skills) or adapt principles (flexible skills)

The key insight: Claude's natural tendency is to skip formal processes. The bootstrap skill creates a **mandatory checkpoint** that overrides this.

### Skill Types

| Type | Behavior | Examples |
|------|----------|----------|
| **Rigid** | Follow exactly, no shortcuts | TDD, debugging |
| **Flexible** | Adapt principles to context | Patterns, brainstorming |
| **Discipline-Enforcing** | Tested under pressure scenarios | Verification, code review |

### CSO (Claude Search Optimization)

The `description` field in skill frontmatter is critical:

```yaml
# BAD - Claude follows the summary instead of reading the skill
description: "A TDD workflow that enforces RED-GREEN-REFACTOR cycles"

# GOOD - Describes WHEN to use, not WHAT it does
description: "Use when implementing any feature or bugfix, before writing implementation code"
```

> "When a description summarizes the skill's workflow, Claude may follow the description instead of reading full skill content."

---

## Relation to Agent Inference Loops

Superpowers operates **inside** the inference loop, not around it. Unlike Ralph (which spawns fresh sessions), superpowers injects discipline at each decision point within a session.

| Aspect | Ralph | Superpowers |
|--------|-------|-------------|
| Problem solved | Context rot | Behavioral drift |
| Mechanism | Fresh sessions | Skill checkpoints |
| State transfer | Files (PRD, progress) | Skill invocations |
| When to use | Long multi-task projects | All agent interactions |

These are **complementary**. Use both: Ralph for fresh context, superpowers for disciplined behavior within each session.

---

## The Core Workflow

Superpowers enforces a **seven-stage mandatory process**:

```
1. BRAINSTORMING ──────────► Socratic design refinement
        │
2. GIT WORKTREES ──────────► Isolated workspace
        │
3. PLAN WRITING ───────────► 2-5 minute tasks with specs
        │
4. EXECUTION ──────────────► Subagent-driven with reviews
        │
5. TDD ────────────────────► RED-GREEN-REFACTOR (mandatory)
        │
6. CODE REVIEW ────────────► Severity-based issue reporting
        │
7. BRANCH FINISHING ───────► Test verification + merge decision
```

### The TDD Iron Law

> "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"

The TDD skill explicitly blocks common rationalizations:

| Excuse | Counter |
|--------|---------|
| "Too simple to test" | Simple code breaks; testing takes 30 seconds |
| "I'll test after" | Tests-after pass immediately—proving nothing |
| "Already manually tested" | Ad-hoc lacks systematicity |
| "X hours wasted if deleted" | Sunk cost fallacy; delete means delete |

### Skill Cascade

When Claude dispatches subagents, **those subagents inherit the same skills**. This ensures TDD isn't just followed by the coordinator—every worker follows it too.

---

## SKILL.md Format

```markdown
---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

## Core Principle

"Write the test first. Watch it fail. Write minimal code to pass."

## When to Use

[Triggers, not workflow summary]

## Implementation

[The actual workflow]

## Red Flags (STOP and Start Over)

[Rationalizations to block]

## Verification Checklist

[Success criteria]
```

Key fields:
- `name`: Letters, numbers, hyphens (for lookup)
- `description`: **WHEN to use**, not what it does (CSO critical)

---

## Testing Skills with TDD

> "Writing skills IS Test-Driven Development applied to process documentation."

Skills are tested by simulating realistic agent pressure:

```
RED (baseline):
├── Run pressure scenarios WITHOUT skill
├── Agent skips steps, makes assumptions
└── Document actual violations

GREEN (skill):
├── Write minimal skill addressing failures
├── Run same scenarios WITH skill
└── Verify compliance

REFACTOR:
├── Identify new rationalizations agent uses
├── Add explicit counters to skill
└── Re-test until compliant
```

**Pressure scenarios** combine stressors:
- Time pressure ("user is waiting")
- Sunk cost ("already wrote implementation")
- Exhaustion (long conversation)

The skill must hold up under all combinations.

---

## Parallel Agents

The `dispatching-parallel-agents` skill coordinates concurrent work through **domain isolation** (not locks/queues):

```
┌─────────────────────────────────────────────────┐
│              COORDINATOR (you)                  │
│                                                 │
│  Identify independent domains:                  │
│  ├── Domain A: auth tests                       │
│  ├── Domain B: API tests                        │
│  └── Domain C: UI tests                         │
│                                                 │
│  Dispatch agents IN PARALLEL:                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│  │ Agent A │ │ Agent B │ │ Agent C │            │
│  │ auth/   │ │ api/    │ │ ui/     │            │
│  └────┬────┘ └────┬────┘ └────┬────┘            │
│       │           │           │                 │
│       └───────────┼───────────┘                 │
│                   ▼                             │
│  Review & integrate (no conflicts if           │
│  domains properly separated)                    │
└─────────────────────────────────────────────────┘
```

**Independence requirements**:
- Each investigation is separate
- No shared state between agents
- Work doesn't interfere

---

## Subagent-Driven Development

The `subagent-driven-development` skill is a key orchestration pattern where the main agent acts as a **manager**, not an implementer.

### Core Principle

> "You are the MANAGER of subagents, not an implementer. Your job is coordination."
> "Subagents have fresh context windows - use this to your advantage. You coordinate, they execute."

### Three-Agent Review Pattern

Each task goes through **three agents** in sequence:

```
Task N
  │
  ▼
┌─────────────────────────────┐
│  1. IMPLEMENTER             │  frontend-developer or backend-developer
│     - Implement exactly     │
│     - Write tests           │
│     - Verify (run build)    │
│     - Commit                │
│     - Self-review           │
└───────────┬─────────────────┘
            │
            ▼
┌─────────────────────────────┐
│  2. SPEC REVIEWER           │  Same agent type as implementer
│     - Read actual code      │
│     - Check: Missing reqs?  │
│     - Check: Extra work?    │
│     - Check: Misunderstand? │
│     - ✅ or ❌ with refs    │
└───────────┬─────────────────┘
            │ (only if ✅)
            ▼
┌─────────────────────────────┐
│  3. CODE QUALITY REVIEWER   │  superpowers:code-reviewer
│     - Review code quality   │
│     - Verify against docs   │
│     - ✅ or ❌ with issues  │
└───────────┬─────────────────┘
            │ (only if ✅)
            ▼
        Next Task
```

**Order is mandatory**: Spec review MUST pass before code quality review.

### Review Loops

If reviewer finds ❌ → resume **implementer** to fix (never fix manually) → reviewer reviews again → repeat until ✅.

### Orchestrator Role

The orchestrator dispatches, tracks progress, and makes decisions. Subagents implement, test, and report. **Keep orchestrator context lean** - subagents have fresh context windows.

### Checkpoint Rule

Pause for human review after completing each **phase** (group of related tasks).

---

## SAL-9000 Relevance

### What Superpowers Solves

| Problem | Superpowers Solution |
|---------|---------------------|
| Agent skips verification | Mandatory skill checkpoints |
| Subagents drift | Skill cascade (inheritance) |
| Ad-hoc assumptions | Brainstorming skill forces questions |
| "Just this once" shortcuts | Explicit rationalization blocking |

### Direct Applicability to SAL

**1. Three-Agent Review = Engineer → Inspector → Analyst**

Superpowers' pattern maps directly to SAL's Crew types:

| Superpowers Role | SAL Crew Type | Purpose |
|-----------------|---------------|---------|
| Implementer | Engineer | Does the work |
| Spec Reviewer | Inspector | Verifies requirements |
| Code Quality Reviewer | Analyst | Reviews code quality |

**SAL already has this structure**. The key insight is the **mandatory sequence**:

```
Engineer → Inspector (✅?) → Analyst (✅?) → Done
                ↓ ❌              ↓ ❌
          Engineer fixes    Engineer fixes
```

**2. Pod as Orchestrator**

The subagent-driven-development pattern says:

> "You are the MANAGER of subagents, not an implementer."

This is exactly what a Pod should do:
- Dispatch Crew (Engineer, Inspector, Analyst)
- Track progress via SQLite
- Make decisions when Crew surface questions
- Keep context lean (let Crew do the work)

**3. CAPCOM as Skill Enforcer**

CAPCOM already filters context. It could also inject skills based on task type (implementation → TDD, bug fix → debugging, design → brainstorming).

**4. Crew Type → Skill Mapping**

| Crew Type | Relevant Skills |
|-----------|----------------|
| Engineer | TDD, debugging, execution |
| Inspector | Verification, spec review |
| Analyst | Systematic debugging, code review |

### Key Insight for SAL

> "Skills are prompt injection that makes agents follow workflows."

CAPCOM is perfectly positioned for this. Instead of just filtering context, inject workflow instructions based on task type, project standards, and past failures.

### What SAL Could Add

1. **Mandatory review sequence** - Engineer → Inspector → Analyst, with loops on ❌
2. **Skill injection at CAPCOM** - route skills to Crew based on task type
3. **Phase checkpoints** - pause for human review after completing feature chunks

---

## Summary

Superpowers and Ralph solve different problems:
- **Ralph**: Context rot (fresh sessions)
- **Superpowers**: Behavioral drift (skill checkpoints)

SAL could combine both:
- Pods/Crew provide fresh context (Ralph)
- CAPCOM injects skills for disciplined behavior (Superpowers)

**Key patterns to adopt**:

1. **Mandatory checkpoints** that block rationalizations and enforce verification before completion
2. **Three-agent review sequence** (Implementer → Spec Reviewer → Quality Reviewer) maps perfectly to SAL's Engineer → Inspector → Analyst
3. **Review loops** that return to implementer on failure, never let orchestrator fix
4. **Orchestrator as manager** - Pods dispatch and coordinate, Crew executes
5. **Phase checkpoints** - pause for human review after completing feature chunks
