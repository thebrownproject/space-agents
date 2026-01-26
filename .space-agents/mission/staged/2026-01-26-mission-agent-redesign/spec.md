# Exploration: Mission Agent Redesign & Spec Skill

**Date:** 2026-01-26
**Status:** Ready for planning

---

## Problem

The current mission agent system has two issues:

1. **Agent responsibilities are misaligned.** Worker does too much (planning + implementation). Inspector and Analyst split review concerns that belong together. The explore→plan→execute→review pipeline isn't clear.

2. **Brainstorm output is unstructured.** The `exploration.md` format is loose and inconsistent, making it hard for the planning phase to extract what it needs.

---

## Solution

### Part 1: Redesign Mission Agents

Restructure mission agents with clearer responsibilities:

| Agent | New Role | Source |
|-------|----------|--------|
| **Pathfinder** | Explore codebase + write findings to bead comments | New (formalizes Pod Phase 2.5) |
| **Builder** | Write code using Pathfinder findings + Context7 | Worker (renamed, stripped of planning) |
| **Inspector** | Requirements + quality check (two passes) | Expanded (absorbs Analyst) |

The pipeline becomes: **Pathfinder → Builder → Inspector → Airlock** (Pod orchestrates)

- **Pathfinder** finds the path (explore codebase, report context, set direction for Builder)
- **Builder** builds the code (read Pathfinder findings, use Context7, implement)
- **Inspector** inspects the work (Pass 1: requirements met? Pass 2: quality acceptable?)

### Part 2: Create exploration-write-spec Skill

New skill that produces structured `spec.md` from brainstorm conversations:

- Called at end of `/brainstorm` when user confirms ready
- Produces consistent format with clear sections
- Lives in `exploration/ideas/<topic>/spec.md`
- Feeds cleanly into `/plan` phase

### Part 3: Folder Restructure

Split the single `exploration/` folder into two top-level folders that match the skill categories:

**Exploration phase** (thinking/planning):
```
exploration/
  ideas/       ← /brainstorm creates spec.md
  planned/     ← /plan creates plan.md (moves from ideas/)
```

**Mission phase** (doing/executing):
```
mission/
  staged/      ← /plan creates beads (moves from exploration/planned/)
  complete/    ← /land archives (moves from staged/)
```

The handoff from `exploration/` to `mission/` happens when beads are created - that's the "ready for execution" boundary.

---

## Requirements

### Agent Redesign

**File changes:**
- [ ] **Create** `mission-pathfinder.md` - new agent formalizing Pod Phase 2.5 scouting
- [ ] **Rename** `mission-worker.md` → `mission-builder.md` - strip planning, add Context7 reference
- [ ] **Expand** `mission-inspector.md` - absorb Analyst's quality checks (two-pass: requirements then quality)
- [ ] **Delete** `mission-analyst.md` - merged into Inspector
- [ ] **Update** `mission-pod/SKILL.md` - change dispatch from `Worker → Inspector → Analyst` to `Pathfinder → Builder → Inspector`

**Agent roles:**
- [ ] Pathfinder: explore codebase, write findings to bead comments (structured format)
- [ ] Builder: read Pathfinder findings + bead description, use Context7 for library docs, write code
- [ ] Inspector Pass 1: requirements check (did it do what task asked?)
- [ ] Inspector Pass 2: quality check (is code well-written?)

### Spec Skill

- [ ] Create `exploration-write-spec` skill
- [ ] Skill produces `spec.md` with defined structure
- [ ] Update `exploration-brainstorm` to call write-spec when user confirms (replaces exploration.md creation)
- [ ] Update `exploration-plan` to read `spec.md` instead of `exploration.md`
- [ ] **Migration:** Existing exploration.md files remain (no conversion needed), new brainstorms create spec.md

### Exploration-Plan Fix

- [ ] Update bead creation to include task descriptions (currently only passes title)
- [ ] Format: Goal, Files, Steps from plan.md → bead description via `-d` flag
- [ ] Pathfinder and Builder can now read full task context from bead

### Folder Restructure

- [ ] Create `mission/` folder at `.space-agents/mission/`
- [ ] Create `mission/staged/` and `mission/complete/` subfolders
- [ ] Remove `staged/` and `complete/` from `exploration/` folder
- [ ] Update `exploration-plan` to move folders to `mission/staged/` when creating beads
- [ ] Update `land` skill to move folders to `mission/complete/`
- [ ] Update `exploration-brainstorm` folder paths
- [ ] Migrate existing `exploration/staged/` and `exploration/complete/` content to new locations

---

## Non-Requirements

- Not changing the Beads system or bead comments mechanism
- Not modifying ralph.sh execution loop (just agent names)
- Not adding new agents (repurposing existing three)

---

## Architecture

### Agent Communication Flow

```
Task arrives from Beads
    ↓
Pathfinder reads task, explores codebase
    ↓
Pathfinder writes findings to bead comments
    ↓
Builder reads Pathfinder findings from bead comments
Builder uses Context7 for library docs
Builder writes code, commits
    ↓
Inspector reads task + changed files
Inspector Pass 1: Requirements met?
  - If FAIL → [FAIL] with missing requirements, back to Builder
Inspector Pass 2: Quality acceptable?
  - If blocker → [FAIL], exit
  - If warning → [PASS] with notes, continue
    ↓
[PASS] → Airlock validation
```

### Inspector Two-Pass Mechanism

Inspector performs sequential checks in a single agent run:

**Pass 1 - Requirements Check:**
- Compare implementation against task description
- Check all acceptance criteria are met
- If any requirement missing → `[FAIL]` with specific gaps → retry Builder

**Pass 2 - Quality Check (only if Pass 1 succeeds):**
- Code readability, patterns, error handling
- Security basics (no hardcoded secrets, input validation)
- If blocker found → `[FAIL]`, exit pod
- If warning found → `[PASS]` with notes, continue to Airlock

### Pathfinder Output Format (Bead Comments)

Pathfinder writes findings to bead comments in this structure:

```markdown
## Pathfinder Report

### Codebase Context
- [What exists in the files we're modifying]
- [Relevant code patterns found]
- [Related code that might be affected]

### Implementation Guidance

**Approach:** [How to implement given what exists]

**Patterns to follow:**
- [Pattern 1 from existing code]
- [Pattern 2]

**Key interfaces:**
```typescript
// Existing interfaces/types to work with
```

### Risks
- [Anything unexpected discovered]
- None identified
```

### Bead Description Format (from plan.md)

When `/plan` creates beads, task description includes:

```markdown
**Goal:** [One sentence]

**Files:**
- Create: path/to/new.ts
- Modify: path/to/existing.ts

**Steps:**
1. [Step 1]
2. [Step 2]
```

### Folder Structure

```
.space-agents/
  exploration/
    ideas/       ← /brainstorm creates spec.md
    planned/     ← /plan creates plan.md (moves from ideas/)

  mission/
    staged/      ← /plan creates beads (moves from exploration/planned/)
    complete/    ← /land archives (moves from staged/)

  comms/
    capcom.md
    logs/
```

### Folder Lifecycle

```
/brainstorm → exploration/ideas/<topic>/spec.md
    ↓
/plan → exploration/planned/<topic>/plan.md (moves from ideas/)
    ↓
/plan (create beads) → mission/staged/<topic>/ (moves from exploration/)
    ↓
/mission executes (stays in staged/)
    ↓
/land → mission/complete/<topic>/ (moves from staged/)
```

### Spec Skill Flow

```
/brainstorm (conversation)
    ↓
User confirms "ready to write spec"
    ↓
/exploration-write-spec invoked
    ↓
spec.md created in exploration/ideas/<topic>/
    ↓
/plan reads spec.md → plan.md
```

### spec.md Structure

```markdown
# Exploration: [Topic]

**Date:** YYYY-MM-DD
**Status:** [Ready for planning | Needs discussion | Blocked]

## Problem
What problem are we solving? Why does this matter?

## Solution
High-level approach. The "what" not the "how".

## Requirements
Must-have functionality (checklist format)

## Non-Requirements
Explicitly out of scope

## Architecture
Components, data flow, key decisions

## Constraints
Technical limitations, patterns to follow, dependencies

## Success Criteria
How do we know it's done? (checklist format)

## Open Questions
Things still to be decided (blocks planning if unresolved)

## Next Steps
What happens after this exploration
```

---

## Constraints

- Agent names must match file names (e.g., `mission-scout` → `mission-scout.md`)
- Bead comments remain the communication layer between agents
- Spec skill must be invokable from brainstorm skill (skill chaining)
- Pod still orchestrates the agent sequence (Pathfinder → Builder → Inspector → Airlock)

### Context7 MCP

Context7 is an MCP server from Upstash that fetches current, version-specific documentation for libraries/frameworks and injects it into prompts. This ensures Builder agent has accurate API docs rather than relying on stale training data.

- **Prerequisite:** Context7 MCP must be installed and configured
- **Usage:** Builder agent includes "use context7" in prompts when working with external libraries
- **Benefit:** Reduces incorrect code from outdated training data

---

## Success Criteria

- [ ] Pathfinder can read a task and produce findings in bead comments
- [ ] Builder can read Pathfinder findings and implement without needing to explore itself
- [ ] Inspector catches both requirements gaps and quality issues (two-pass)
- [ ] `/brainstorm` → `/exploration-write-spec` produces consistent spec.md
- [ ] `/plan` successfully parses spec.md into plan.md
- [ ] `/plan` creates beads with full task descriptions (Goal, Files, Steps)
- [ ] Pipeline: brainstorm → spec → plan → beads works end-to-end
- [ ] Pod dispatches: Pathfinder → Builder → Inspector → Airlock
- [ ] Folder structure: exploration/ for planning, mission/ for execution
- [ ] Folder moves work: ideas/ → planned/ → mission/staged/ → mission/complete/

---

## Open Questions

1. ~~**Plan detail level** - How much should Pathfinder's findings include?~~ **RESOLVED:** Pathfinder provides codebase context, patterns, approach guidance. Not full code - that's Builder's job with Context7.

2. **Context7 integration** - Is Context7 MCP already installed? If not, needs setup step. (See Constraints section for details)

3. ~~**Skill chaining** - How does brainstorm invoke write-spec?~~ **RESOLVED:** Brainstorm asks "Ready to write spec?" → user confirms → brainstorm calls exploration-write-spec skill.

4. ~~**Pod relationship** - Does Pod still exist?~~ **RESOLVED:** Yes, Pod still orchestrates. Dispatch changes from `Worker → Inspector → Analyst` to `Pathfinder → Builder → Inspector`.

5. ~~**spec.md vs exploration.md** - Replacement or parallel?~~ **RESOLVED:** spec.md replaces exploration.md for new brainstorms. Existing exploration.md files remain unchanged.

---

## Next Steps

1. `/plan` to create implementation tasks
2. Implement agent file changes first (rename + rewrite)
3. Create `exploration-write-spec` skill
4. Update `exploration-brainstorm` to offer spec writing
5. Update `exploration-plan` to read spec.md
6. Test pipeline end-to-end
