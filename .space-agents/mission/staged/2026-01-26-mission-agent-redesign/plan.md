# Feature: Mission Agent Redesign

**Goal:** Restructure mission agents with clearer responsibilities (Pathfinder/Builder/Inspector) and add spec-based exploration workflow.

## Overview

The current mission agent system has misaligned responsibilities:
- Worker does too much (planning + implementation)
- Inspector and Analyst split review concerns that belong together
- The explore→plan→execute→review pipeline isn't clear

This feature restructures agents with the principle: Pathfinder finds the path, Builder builds, Inspector inspects.

**New Pipeline:** Pathfinder → Builder → Inspector → Airlock

## Tasks

### Task: Create Pathfinder Agent

**Goal:** Create new agent that explores codebase and writes findings to bead comments.
**Files:**
- Create: agents/mission-pathfinder.md
**Depends on:** None

**Steps:**
1. Create agents/mission-pathfinder.md with role, inputs, outputs
2. Define Pathfinder Report format for bead comments (Codebase Context, Implementation Guidance, Risks)
3. Document that Pathfinder provides context, not code

### Task: Rename Worker to Builder

**Goal:** Rename Worker agent to Builder and update to use Pathfinder findings + Context7.
**Files:**
- Rename: agents/mission-worker.md → agents/mission-builder.md
**Depends on:** None

**Steps:**
1. Rename file from mission-worker.md to mission-builder.md
2. Strip planning responsibilities (Pathfinder handles that)
3. Add Context7 MCP reference for library documentation lookup
4. Update role description to "code writer that reads Pathfinder findings"

### Task: Expand Inspector

**Goal:** Expand Inspector to absorb Analyst's quality checks with two-pass mechanism.
**Files:**
- Modify: agents/mission-inspector.md
**Depends on:** None

**Steps:**
1. Add Pass 1: Requirements Check (compare implementation against task description)
2. Add Pass 2: Quality Check (code readability, patterns, security basics)
3. Merge severity guide and quality checklist from mission-analyst.md
4. Update output format to support both passes ([PASS]/[FAIL] for each)

### Task: Delete Analyst Agent

**Goal:** Remove Analyst agent after confirming all functionality merged into Inspector.
**Files:**
- Delete: agents/mission-analyst.md
**Depends on:** Expand Inspector

**Steps:**
1. Verify Inspector has all Analyst quality checks
2. Search codebase for references to mission-analyst
3. Delete agents/mission-analyst.md

### Task: Update Pod Dispatch

**Goal:** Update Pod to dispatch Pathfinder → Builder → Inspector → Airlock sequence.
**Files:**
- Modify: skills/mission-pod/SKILL.md
**Depends on:** Create Pathfinder Agent, Rename Worker to Builder, Expand Inspector, Delete Analyst Agent

**Steps:**
1. Update crew table: replace Worker/Inspector/Analyst with Pathfinder/Builder/Inspector
2. Update execution flow diagram
3. Change mission-worker references to mission-builder
4. Add Pathfinder as first crew member before Builder
5. Remove Analyst from sequence

### Task: Create exploration-write-spec Skill

**Goal:** Create skill that produces structured spec.md from brainstorm conversations.
**Files:**
- Create: skills/exploration-write-spec/SKILL.md
**Depends on:** None

**Steps:**
1. Create skills/exploration-write-spec/ directory
2. Create SKILL.md with spec.md template
3. Define sections: Problem, Solution, Requirements, Non-Requirements, Architecture, Constraints, Success Criteria, Open Questions, Next Steps
4. Document output location: exploration/ideas/<topic>/spec.md

### Task: Update Exploration Skills

**Goal:** Update brainstorm to call write-spec and plan to read spec.md with task descriptions.
**Files:**
- Modify: skills/exploration-brainstorm/SKILL.md
- Modify: skills/exploration-plan/SKILL.md
**Depends on:** Create exploration-write-spec Skill

**Steps:**
1. Update brainstorm Output section to offer spec writing via /exploration-write-spec
2. Update plan Mode 1 to read spec.md (with exploration.md fallback)
3. Update plan Mode 3 to include -d flag with Goal, Files, Steps when creating beads
4. Update plan Folder Lifecycle to show new structure

### Task: Folder Restructure

**Goal:** Create mission/ folder structure and migrate existing content.
**Files:**
- Create: .space-agents/mission/staged/
- Create: .space-agents/mission/complete/
- Modify: skills/exploration-plan/SKILL.md (folder paths)
- Modify: skills/land/SKILL.md (folder paths)
**Depends on:** None

**Steps:**
1. Create .space-agents/mission/staged/ and .space-agents/mission/complete/
2. Add .gitkeep files to preserve empty folders
3. Update exploration-plan Mode 3 to move folders to mission/staged/
4. Update land skill folder paths to use mission/staged/ and mission/complete/
5. Migrate any existing exploration/staged/ and exploration/complete/ content
6. Remove old folders if empty

## Sequence

1. Create Pathfinder Agent (no dependencies)
2. Rename Worker to Builder (no dependencies, parallel with 1)
3. Expand Inspector (no dependencies, parallel with 1-2)
4. Create exploration-write-spec Skill (no dependencies, parallel with 1-3)
5. Folder Restructure (no dependencies, parallel with 1-4)
6. Delete Analyst Agent (depends on 3)
7. Update Pod Dispatch (depends on 1-4, 6)
8. Update Exploration Skills (depends on 4)

**Parallelization:** Tasks 1-5 can all run in parallel. Tasks 6-8 are sequential.

## Success Criteria

- [ ] Pathfinder can read a task and produce findings in bead comments
- [ ] Builder can read Pathfinder findings and implement without needing to explore itself
- [ ] Inspector catches both requirements gaps and quality issues (two-pass)
- [ ] `/brainstorm` → `/exploration-write-spec` produces consistent spec.md
- [ ] `/plan` successfully parses spec.md into plan.md
- [ ] `/plan` creates beads with full task descriptions (Goal, Files, Steps)
- [ ] Pod dispatches: Pathfinder → Builder → Inspector → Airlock
- [ ] Folder structure: exploration/ for planning, mission/ for execution
- [ ] Folder moves work: ideas/ → planned/ → mission/staged/ → mission/complete/
