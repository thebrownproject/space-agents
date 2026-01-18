---
name: mission-brief
description: "Write mission plan with objectives. HOUSTON convenes planning council, synthesizes their input, and guides user through approval stages."
---

# /mission-brief - Mission Planning

Turn an exploration report into an executable mission with objectives. HOUSTON reviews the exploration, convenes a planning council for input, then synthesizes everything into a plan for user approval.

**Hierarchy:**
- Project = the codebase (one per installation)
- Mission = Feature (designed in /exploration)
- Objectives = Tasks (created here)

## The Process

1. **Check exploration folder** - list available reports in `.space-agents/exploration/`
2. **Confirm with user** - "I found X. Is this what you want to plan?"
3. **Read and analyze** - HOUSTON reads the exploration report
4. **Ask to convene council** - "Ready to send out the planning council?"
5. **Spawn council** - 3 agents analyze in parallel
6. **Synthesize** - HOUSTON combines own analysis + council input
7. **Present stages** - user approves each stage
8. **Write plan** - SQLite records + markdown file
9. **Handoff** - offer `/mission` to begin execution

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
- How to break this into missions
- What the dependencies might be
- Key implementation considerations

This gives you context to evaluate the council's input.

## Step 3: Convene the Council

After user confirms, ask before spawning:
```
Ready to convene the planning council? I'll send out three agents to analyze:
- Task Planner (mission/objective structure)
- Sequencer (dependencies, execution order)
- Implementer (TDD task breakdown)

They'll report back while we continue talking. Proceed?
```

## The Council

The council are **advisors**, not decision makers. They provide analysis, HOUSTON synthesizes and can override if their recommendations don't fit.

- `space-agents:planning-task-planner` - Breaks feature into missions/objectives
- `space-agents:planning-sequencer` - Analyzes dependencies, execution order
- `space-agents:planning-implementer` - Creates TDD task breakdown per objective

Spawn all 3 in parallel with `run_in_background: true`. Continue conversation while they work.

## Approval Stages

Present each stage, get user approval before continuing:

**Stage 1: Mission Structure**
```
Council analysis complete. Proposed mission:

MISSION: [Feature Name]
Goal: [One sentence]

Objectives:
  1. [Name] (~X min) - [Brief description]
  2. [Name] (~Y min) - [Brief description]
  3. [Name] (~Z min) - [Brief description]

Does this structure look right?
```

**Stage 2: Sequence**
```
Execution sequence:

1. Objective 1 (no dependencies)
2. Objective 2 (depends on Obj 1)
3. Objective 3 (depends on Obj 2)

Any concerns with this order?
```

**Stage 3: Implementation Details**
```
Implementation approach for first objective:

Objective 1: [Name]
Files: [list]
Tasks:
  1. Write failing test
  2. Verify test fails
  3. Implement
  4. Verify test passes
  5. Commit

This pattern applies to all objectives. Ready to write the plan?
```

## Output

After all approvals:

1. **Create mission folder:** `.space-agents/missions/staged/<mission-id>/`
2. **Move exploration:** Copy `exploration.md` into mission folder, delete exploration folder
3. **Write _mission.md:** Mission context (goal, objectives list, key files)
4. **Write implementation-plan.md:** Detailed plan with TDD tasks per objective
5. **Insert SQLite records:**
   ```sql
   INSERT INTO missions (id, title, status) VALUES ('<mission_id>', '<title>', 'staged');
   INSERT INTO objectives (mission_id, id, title, description, status, priority)
   VALUES ('<mission_id>', 'OBJ-001', '<title>', '<desc>', 'pending', 1);
   ```
6. **Confirm:** "Mission ready. Run `/mission` to begin execution."

**Mission ID format:** `MSN-001-Short-description`
**Objective ID format:** `OBJ-001`, `OBJ-002`... (resets per mission, composite key)

**Folder lifecycle:** `staged/` → `active/` (on /mission) → `complete/` (on finish)

## _mission.md Structure

```markdown
# MSN-XXX-Description: [Feature Name]

**Status:** Staged
**Created:** [timestamp]

## Goal
[One sentence]

## Objectives
1. OBJ-001 - [Name]
2. OBJ-002 - [Name]

## Key Files
[List of files to create/modify]
```

## implementation-plan.md Structure

```markdown
# [Feature] Implementation Plan

**Mission:** MSN-XXX-Description
**Created:** [timestamp]

## Objectives

| # | Objective | Est. | Status |
|---|-----------|------|--------|
| 1 | [Name] | X min | pending |
| 2 | [Name] | Y min | pending |

## Sequence

[Dependencies and execution order]

---

## Objective 1: [Name]

**Goal:** [One sentence]
**Files:** [Create/Modify/Test]

**Tasks:**
1. Write failing test - [code snippet]
2. Run test - [command + expected output]
3. Implement - [code snippet]
4. Run test - [command + expected output]
5. Commit - [command]

---

[Continue for all objectives]
```

## Remember

- Mission = feature (one per /exploration report)
- Objectives = tasks (3-5 per mission, Pod-sized chunks)
- Mission IDs are descriptive: `MSN-001-Schema-v2`
- Create in `staged/`, moves to `active/` on execution
- Council are advisors - HOUSTON synthesizes and can override
- User approves each stage before anything is written
