---
name: exploration-plan
description: "Write feature plan with tasks. HOUSTON convenes planning council, synthesizes their input, and guides user through approval stages."
---

# /exploration-plan - Feature Planning

Turn an exploration report into an executable feature with tasks. HOUSTON reviews the exploration, convenes a planning council for input, then synthesizes everything into a plan for user approval.

**Hierarchy:**
- Project = the codebase (one per installation)
- Feature = scope of work (designed in /exploration)
- Tasks = implementation units (created here)

## The Process

1. **Check exploration folder** - list available reports in `.space-agents/exploration/`
2. **Confirm with user** - "I found X. Is this what you want to plan?"
3. **Read and analyze** - HOUSTON reads the exploration report
4. **Ask to convene council** - "Ready to send out the planning council?"
5. **Spawn council** - 3 agents analyze in parallel
6. **Synthesize** - HOUSTON combines own analysis + council input
7. **Present stages** - user approves each stage
8. **Write plan** - Beads records + markdown file
9. **Handoff** - offer `/mission-go` to begin execution

## Step 1: Check What's Available

List exploration reports:
```
.space-agents/exploration/YYYY-MM-DD-*/exploration.md
```

Present to user:
```
Found exploration reports:
  [1] 2026-01-18-auth-system - "User authentication with JWT"
  [2] 2026-01-15-caching-layer - "Redis caching for API"

Which one should we plan? (or describe something new)
```

## Step 2: HOUSTON's Own Analysis

Before spawning agents, read the exploration report yourself. Form your own view on:
- How to break this into tasks
- What the dependencies might be
- Key implementation considerations

This gives you context to evaluate the council's input.

## Step 3: Convene the Council

After user confirms, ask before spawning:
```
Ready to convene the planning council? I'll send out three agents to analyze:
- Task Planner (feature/task structure)
- Sequencer (dependencies, execution order)
- Implementer (TDD task breakdown)

They'll report back while we continue talking. Proceed?
```

## The Council

The council are **advisors**, not decision makers. They provide analysis, HOUSTON synthesizes and can override if their recommendations don't fit.

- `space-agents:plan-task-planner` - Breaks feature into tasks
- `space-agents:plan-sequencer` - Analyzes dependencies, execution order
- `space-agents:plan-implementer` - Creates TDD task breakdown per task

Spawn all 3 in parallel with `run_in_background: true`. Continue conversation while they work.

## Approval Stages

Present each stage, get user approval before continuing:

**Stage 1: Feature Structure**
```
Council analysis complete. Proposed feature:

FEATURE: [Feature Name]
Goal: [One sentence]

Tasks:
  1. [Name] (~X min) - [Brief description]
  2. [Name] (~Y min) - [Brief description]
  3. [Name] (~Z min) - [Brief description]

Does this structure look right?
```

**Stage 2: Sequence**
```
Execution sequence:

1. Task 1 (no dependencies)
2. Task 2 (depends on Task 1)
3. Task 3 (depends on Task 2)

Any concerns with this order?
```

**Stage 3: Implementation Details**
```
Implementation approach for first task:

Task 1: [Name]
Files: [list]
Steps:
  1. Write failing test
  2. Verify test fails
  3. Implement
  4. Verify test passes
  5. Commit

This pattern applies to all tasks. Ready to write the plan?
```

## Output

After all approvals:

1. **Create feature folder:** `.space-agents/features/staged/<feature-slug>/`
2. **Move exploration:** Copy `exploration.md` into feature folder, delete exploration folder
3. **Write _feature.md:** Feature context (goal, tasks list, key files)
4. **Write implementation-plan.md:** Detailed plan with TDD steps per task
5. **Create Beads records:**
   ```bash
   # Get active epic
   EPIC_ID=$(bd list -t epic --status open --json | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

   # Create feature under epic
   bd create "Feature title" -t feature --parent "$EPIC_ID" -p 1

   # Get the feature ID just created
   FEATURE_ID=$(bd list -t feature --status open --json | grep -o '"id":"[^"]*"' | tail -1 | cut -d'"' -f4)

   # Create tasks under feature
   bd create "Task 1 title" -t task --parent "$FEATURE_ID" -p 1
   bd create "Task 2 title" -t task --parent "$FEATURE_ID" -p 2
   bd sync
   ```
6. **Confirm:** "Feature ready. Run `/mission` to begin execution."

**Note:** Beads auto-generates IDs for features and tasks.

**Folder lifecycle:** `staged/` → `active/` (on /mission) → `complete/` (on finish)

## _feature.md Structure

```markdown
# {feature-slug}: [Feature Name]

**Status:** Staged
**Created:** [timestamp]

## Goal
[One sentence]

## Tasks
1. [Task ID] - [Name]
2. [Task ID] - [Name]

## Key Files
[List of files to create/modify]
```

## implementation-plan.md Structure

```markdown
# [Feature] Implementation Plan

**Feature:** {feature-slug}
**Created:** [timestamp]

## Tasks

| # | Task | Est. | Status |
|---|------|------|--------|
| 1 | [Name] | X min | pending |
| 2 | [Name] | Y min | pending |

## Sequence

[Dependencies and execution order]

---

## Task 1: [Name]

**Goal:** [One sentence]
**Files:** [Create/Modify/Test]

**Steps:**
1. Write failing test - [code snippet]
2. Run test - [command + expected output]
3. Implement - [code snippet]
4. Run test - [command + expected output]
5. Commit - [command]

---

[Continue for all tasks]
```

## Remember

- Feature = scope of work (one per /exploration report)
- Tasks = implementation units (3-5 per feature, Pod-sized chunks)
- Beads auto-generates IDs for features and tasks
- Create in `staged/`, moves to `active/` on execution
- Council are advisors - HOUSTON synthesizes and can override
- User approves each stage before anything is written
