# Planning with Forward-Deployed F-Threading

**Date:** 2026-01-16
**Status:** Design Phase
**Pattern:** Forward-Deployed F-Thread + Bite-Sized Tasks + TDD Enforcement

---

## Executive Summary

HOUSTON coordinates planning sessions using **forward-deployed F-Threading**: spawn planning agents AHEAD of conversation, ask validation questions WHILE agents run, progressively decompose from high-level missions → detailed objectives.

**Input:** Design document from `/brainstorming` (selected approach)
**Output:**
- SQLite records (voyages, missions, objectives)
- Markdown plan with bite-sized tasks (2-5 min each)
- TDD structure enforced (test → fail → implement → pass → commit)

---

## The Forward-Deployment Pattern

```
Task Planning Agents (spawn immediately)
    ↓ [agents run]
Validation Q1 (asked while agents run - "Does this mission structure work?")
    ↓ [user answers]
Phase Planning Agents (spawn after Q1 + task results)
    ↓ [agents run]
Validation Q2 (asked while agents run - "Does this sequencing work?")
    ↓ [user answers]
Implementation Agents (spawn after Q2 + phase results)
    ↓ [agents run]
Validation Q3 (asked while agents run - "Ready to write this plan?")
    ↓ [user answers]
Synthesis (create SQLite records + markdown plan)
```

**Critical insight:** Agents decompose WHILE HOUSTON validates with user.

---

## Four Phases

### Phase 0: Context Loading

**HOUSTON receives:** Command `/planning` or transition from `/brainstorming`

**Load design document:**
```
HOUSTON: "Loading design from docs/plans/2026-01-16-[topic]-design.md..."

[Read design doc]

Context loaded:
- Selected approach: [Name]
- User requirements: [From Q&A]
- Technical details: [From architecture]
- Risks: [From risk agent]
- Estimate: [From implementation agent]
```

---

### Phase 1: Task Planning (Forward-Deployed)

**HOUSTON receives:** Design document context

**Immediate action:**
```
HOUSTON: "Deploying task planning team to break this down..."

[SPAWN IN PARALLEL - NO WAIT:]
  - Task Planning Agent A: "Break into missions and objectives"
  - Task Planning Agent B: "Break into missions and objectives (alternative structure)"
```

**Then ask Validation Q1 (while agents run):**
```
HOUSTON: "While they work, quick question:

Should we prioritize for:
  A) Fastest delivery (MVP first, enhancements later)
  B) Lowest risk (foundational work first)
  C) User value (highest-impact features first)

[Task planning agents running in background...]"
```

**Agent prompts include:**
- Design document (full text)
- Selected approach details
- "Break into 2-4 missions, each with 2-5 objectives"
- "Each objective should be achievable in 1-3 hours"

**Timing:**
- Spawn: T=0s
- Ask Q1: T=5s
- User answers: T=20s (typical)
- Agents complete: T=30-45s

---

### Phase 2: Phase Planning (Forward-Deployed)

**HOUSTON receives:**
- Validation Q1 answer
- Task planning results (2 agent outputs)

**Immediate action:**
```
HOUSTON: "Perfect. My task planning team proposed:

Mission 1: [Name] - [X objectives]
Mission 2: [Name] - [Y objectives]
Mission 3: [Name] - [Z objectives]

Now analyzing dependencies and sequencing..."

[SPAWN IN PARALLEL - NO WAIT:]
  - Phase Planning Agent A: "Sequence missions, identify dependencies"
  - Phase Planning Agent B: "Sequence missions, identify dependencies (alternative view)"
```

**Then ask Validation Q2 (while agents run):**
```
HOUSTON: "Can any of these missions run in parallel, or must they be sequential?

  A) All sequential (Mission 1 → 2 → 3)
  B) Some parallel (1 first, then 2 & 3 together)
  C) Mostly parallel (independent work)

[Phase planning agents running in background...]"
```

**Agent prompts include:**
- Design document
- Task planning results (both outputs)
- Validation Q1 answer
- "Identify dependencies: what must complete before what?"
- "Look for parallelization opportunities"

**Timing:**
- Spawn: T=45s
- Ask Q2: T=50s
- User answers: T=70s
- Agents complete: T=75-90s

---

### Phase 3: Implementation Detail (Forward-Deployed)

**HOUSTON receives:**
- Validation Q1 + Q2 answers
- Task + Phase planning results (4 agent outputs)

**Immediate action:**
```
HOUSTON: "Got it. My phase planning team identified:

Dependencies:
- [Mission X must complete before Mission Y]
- [Mission A and B can run parallel]

Critical path: [Mission sequence]

Now drafting implementation details..."

[SPAWN IN PARALLEL - NO WAIT:]
  - Implementation Agent A: "Detailed steps for each objective (TDD structure)"
  - Implementation Agent B: "Detailed steps for each objective (alternative approach)"
```

**Then ask Validation Q3 (while agents run):**
```
HOUSTON: "One more preference:

For test-driven development, should we:
  A) Write all tests first, then implement (TDD strict)
  B) Test-implement-test per objective (TDD incremental)
  C) Implementation-focused with test coverage (flexible)

[Implementation agents running in background...]"
```

**Agent prompts include:**
- Design document
- All previous planning results (4 outputs)
- Validation Q1 + Q2 answers
- "Break each objective into 2-5 minute tasks"
- "Enforce TDD: test → fail → implement → pass → commit"
- "Include exact file paths, commands, expected outputs"

**Timing:**
- Spawn: T=90s
- Ask Q3: T=95s
- User answers: T=115s
- Agents complete: T=120-135s

---

### Phase 4: Synthesis & Persistence

**HOUSTON receives:**
- All validation answers (Q1, Q2, Q3)
- All agent results (6 agents total: 2 Task + 2 Phase + 2 Implementation)

**Synthesis approach:**
1. Read all 6 agent outputs
2. Merge mission structures (resolve conflicts)
3. Finalize sequencing (respect dependencies)
4. Compile bite-sized tasks (2-5 min each)
5. Enforce TDD structure throughout

**Present mission-by-mission:**

```
HOUSTON: "All planning teams reporting. Here's the proposed voyage structure:

─── VOYAGE: [Feature Name] ───

**Goal:** [One sentence from design doc]
**Approach:** [Selected approach name]
**Estimated Duration:** [X days based on agent estimates]

─── MISSION 1: [Name] ───

**Objectives:**
1. [Objective 1.1 name] - [X min]
2. [Objective 1.2 name] - [Y min]
3. [Objective 1.3 name] - [Z min]

**Dependencies:** None (can start immediately)

Does this first mission structure look right?
```

**Validation loop:**
- User: "yes" → continue to Mission 2
- User: "adjust X" → HOUSTON modifies, re-presents
- User: "add Y" → HOUSTON adds objective, re-presents

**After all missions validated:**

```
HOUSTON: "Perfect. Writing to SQLite and docs..."

[Write SQLite records:]
- Voyage record
- Mission records (linked to voyage)
- Objective records (linked to missions)

[Write markdown plan:]
- docs/plans/YYYY-MM-DD-[topic]-implementation-plan.md
- Includes bite-sized tasks with TDD structure
- Exact file paths, commands, expected outputs

[Commit both]

"Voyage VOY-XXX created with M missions and N objectives.
Ready for /mission-run when you are."
```

---

## Agent Specifications

### Task Planning Agents (Phase 1)

**Count:** 2 agents

**Context provided:**
- Design document (full)
- Selected approach

**Agent A Prompt:**
```
You are a Task Planning Agent for Space-Agents.

DESIGN DOCUMENT: {design_doc}
SELECTED APPROACH: {approach_name}

TASK: Break this feature into missions and objectives.

STRUCTURE:
- Voyage: Top-level feature
- Missions: 2-4 major phases (e.g., "Database Schema", "API Layer", "Testing")
- Objectives: 2-5 per mission, each achievable in 1-3 hours

REQUIREMENTS:
- Each objective should be concrete and testable
- Use TDD: tests before implementation
- Objectives should have clear success criteria
- Consider the risks from design doc

OUTPUT FORMAT:
**VOYAGE: [Feature Name]**

**MISSION 1: [Name]**
- Objective 1.1: [Name and description]
  Estimate: [X min]
  Success: [How to verify complete]

- Objective 1.2: [Name and description]
  Estimate: [Y min]
  Success: [How to verify complete]

**MISSION 2: [Name]**
[Same structure]

**MISSION 3: [Name]**
[Same structure]

**RATIONALE:**
[Why this breakdown makes sense]
```

**Agent B:** Same prompt, instructed to propose ALTERNATIVE breakdown.

---

### Phase Planning Agents (Phase 2)

**Count:** 2 agents

**Context provided:**
- Design document
- Task planning results (both outputs)
- Validation Q1 answer

**Agent A Prompt:**
```
You are a Phase Planning Agent for Space-Agents.

DESIGN DOCUMENT: {design_doc}
TASK PLANNING RESULTS: {task_results}
USER PRIORITY: {q1_answer}

TASK: Sequence missions and identify dependencies.

FOCUS ON:
- Which missions depend on others?
- Which missions can run in parallel?
- What's the critical path?
- Where are the risks in sequencing?

OUTPUT FORMAT:
**SEQUENCING:**

**Phase 1:**
- Mission: [Name]
- Why first: [Rationale]
- Blocks: [What depends on this]

**Phase 2:**
- Missions: [Name A], [Name B] (parallel if possible)
- Why now: [Rationale]
- Depends on: [Phase 1 completion]

**DEPENDENCIES:**
- [Mission X] must complete before [Mission Y] because [reason]
- [Mission A] and [Mission B] are independent

**CRITICAL PATH:**
[Mission sequence that determines total duration]

**RISKS:**
- [Sequencing risk 1]
- [Sequencing risk 2]
```

**Agent B:** Same prompt, instructed to propose ALTERNATIVE sequencing.

---

### Implementation Agents (Phase 3)

**Count:** 2 agents

**Context provided:**
- Design document
- All previous planning results (4 outputs)
- Validation Q1 + Q2 answers

**Agent A Prompt:**
```
You are an Implementation Agent for Space-Agents.

DESIGN DOCUMENT: {design_doc}
PLANNING RESULTS: {all_planning_results}
USER PREFERENCES: {q1_answer}, {q2_answer}

TASK: Create detailed bite-sized tasks for each objective.

REQUIREMENTS:
- Each task is 2-5 minutes (one action)
- TDD structure: test → fail → implement → pass → commit
- Exact file paths (not "update the file")
- Exact commands with expected outputs
- Code snippets where helpful

OUTPUT FORMAT:
**MISSION 1: [Name]**

**Objective 1.1: [Name]**

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Task 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Task 2: Run test to verify it fails**

```bash
pytest tests/path/test.py::test_name -v
```

Expected output: `FAIL - function not defined`

**Task 3: Write minimal implementation**

```python
def function(input):
    # Minimal code to pass test
    return expected
```

**Task 4: Run test to verify it passes**

```bash
pytest tests/path/test.py::test_name -v
```

Expected output: `PASS`

**Task 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```

[Repeat for all objectives in all missions]
```

**Agent B:** Same prompt, instructed to propose ALTERNATIVE task breakdown.

---

## Orchestration Logic

### HOUSTON's Role

**Coordinator, not implementer:**
- Load design doc context
- Spawn planning agents ahead of validation
- Ask validation questions while agents run
- Merge agent outputs (resolve conflicts)
- Present mission-by-mission
- Write to SQLite + markdown
- Commit to git

**Synthesis decisions:**
- When agents agree (4/6 or 5/6), use consensus
- When agents disagree, present both options to user
- Default to simpler breakdown (YAGNI)
- Prioritize based on user's Q1 answer

### Question Design

**Q1 (Priority):**
- How should we prioritize?
- Asked while task planning agents run
- Informs mission ordering

**Q2 (Sequencing):**
- Sequential or parallel execution?
- Asked while phase planning agents run
- Informs dependency analysis

**Q3 (TDD Style):**
- Strict TDD or incremental?
- Asked while implementation agents run
- Informs task breakdown detail level

### Timing Management

**If agents complete before user answers:**
```
HOUSTON: "Quick preview while you're deciding:

Mission 1: [Name] - [X objectives]
Mission 2: [Name] - [Y objectives]

Take your time with the question."
```

**If user answers before agents complete:**
```
HOUSTON: "Got it. Finalizing plan based on your priority...

[Brief wait - typically 10-20 seconds]

Perfect. Here's the structure..."
```

**Typical timeline:**
- Phase 0: 0-5s (load design doc)
- Phase 1: 5-45s (spawn task planning, ask Q1, user answers)
- Phase 2: 45-90s (spawn phase planning, ask Q2, user answers)
- Phase 3: 90-135s (spawn implementation, ask Q3, user answers)
- Phase 4: 135-180s (synthesis, validation, persistence)

**Total: ~3 minutes for full planning session**

---

## Output Formats

### SQLite Schema

**Voyages table:**
```sql
INSERT INTO voyages (title, status, created_at)
VALUES ('[Feature Name]', 'planned', CURRENT_TIMESTAMP);
```

**Missions table:**
```sql
INSERT INTO missions (voyage_id, title, status, created_at)
VALUES
  (voyage_id, 'Mission 1: [Name]', 'planned', CURRENT_TIMESTAMP),
  (voyage_id, 'Mission 2: [Name]', 'planned', CURRENT_TIMESTAMP),
  (voyage_id, 'Mission 3: [Name]', 'planned', CURRENT_TIMESTAMP);
```

**Objectives table:**
```sql
INSERT INTO objectives (mission_id, title, description, status, priority, created_at)
VALUES
  (mission1_id, 'Objective 1.1: [Name]', '[Description]', 'pending', 1, CURRENT_TIMESTAMP),
  (mission1_id, 'Objective 1.2: [Name]', '[Description]', 'pending', 2, CURRENT_TIMESTAMP),
  -- ... etc
```

---

### Markdown Plan Structure

**File:** `docs/plans/YYYY-MM-DD-[topic]-implementation-plan.md`

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence from design doc]

**Architecture:** [Selected approach from brainstorming]

**Tech Stack:** [Key technologies from design]

**Voyage ID:** VOY-XXX (see SQLite)

---

## Mission Overview

**Mission 1: [Name]** - [X objectives] - [Estimated duration]
**Mission 2: [Name]** - [Y objectives] - [Estimated duration]
**Mission 3: [Name]** - [Z objectives] - [Estimated duration]

**Dependencies:**
- Mission 1 must complete before Mission 2
- Mission 2 and Mission 3 can run in parallel (if desired)

**Critical Path:** Mission 1 → Mission 2 → Complete

---

## MISSION 1: [Name]

**Objective 1.1: [Name]**

**Goal:** [One sentence objective]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Task 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Task 2: Run test to verify it fails**

```bash
pytest tests/path/test.py::test_name -v
```

Expected output:
```
FAIL - function not defined
```

**Task 3: Write minimal implementation**

In `exact/path/to/file.py`:

```python
def function(input):
    # Minimal code to pass test
    return expected
```

**Task 4: Run test to verify it passes**

```bash
pytest tests/path/test.py::test_name -v
```

Expected output:
```
PASS - 1 test passed
```

**Task 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat(objective-1.1): add specific feature"
```

---

**Objective 1.2: [Name]**

[Same detailed structure]

---

**Objective 1.3: [Name]**

[Same detailed structure]

---

## MISSION 2: [Name]

[Same structure as Mission 1]

---

## MISSION 3: [Name]

[Same structure as Mission 1]

---

## Execution Options

**Option 1: Ralph Loop (Recommended)**
```bash
/mission-run VOY-XXX
```

HOUSTON will spawn fresh Pods for each objective.
Pods cycle: Worker → Inspector → Analyst → Airlock

**Option 2: Subagent-Driven (Interactive)**

Use superpowers:subagent-driven-development in this session.
HOUSTON dispatches fresh subagent per task, reviews between tasks.

**Option 3: Manual Execution**

Follow this plan step-by-step manually.
Refer to tasks for exact commands and expected outputs.

---

## Testing Strategy

**Unit Tests:**
- Written BEFORE implementation (TDD)
- One test per objective
- Run after each implementation task

**Integration Tests:**
- Written at end of each mission
- Verify mission objectives work together

**End-to-End Tests:**
- Written at end of voyage
- Verify complete feature works

**Test Commands:**
```bash
# Run all tests
pytest

# Run specific mission tests
pytest tests/mission1/

# Run specific objective test
pytest tests/path/test.py::test_name
```

---

## Rollback Plan

**If objective fails:**
1. Review error output
2. Fix issue in implementation
3. Re-run tests
4. Do NOT move to next objective until passing

**If mission blocked:**
1. Mark mission as blocked in SQLite
2. Create alert with blocker details
3. HOUSTON investigates or escalates to user

**If voyage needs restart:**
1. Rollback git commits to last stable state
2. Mark voyage as failed in SQLite
3. Run /brainstorming again with lessons learned

---

## Success Criteria

**Objective complete when:**
- ✅ All tests pass
- ✅ Code committed to git
- ✅ No linter errors
- ✅ Inspector approved (requirements met)
- ✅ Analyst approved (code quality)

**Mission complete when:**
- ✅ All objectives complete
- ✅ Integration tests pass
- ✅ Mission marked complete in SQLite

**Voyage complete when:**
- ✅ All missions complete
- ✅ End-to-end tests pass
- ✅ Feature works as designed
- ✅ Documentation updated

---

## Notes

- DRY: Don't repeat yourself
- YAGNI: You aren't gonna need it
- TDD: Test-driven development (RED → GREEN → REFACTOR)
- Frequent commits: After every passing test

**Estimated Total Duration:** [X days]

**Created:** [timestamp]
**Design Reference:** docs/plans/YYYY-MM-DD-[topic]-design.md
```

---

## State Management

### Staging.md

**Append throughout planning session:**
```markdown
## Planning Session: [Topic]
**Started:** [timestamp]
**Design Doc:** docs/plans/YYYY-MM-DD-[topic]-design.md

### Task Planning Phase
**Validation Q1:** [Question text]
**Answer:** [User answer]

**Task Planning Results:**
[Agent A mission breakdown]
[Agent B mission breakdown]

### Phase Planning Phase
**Validation Q2:** [Question text]
**Answer:** [User answer]

**Phase Planning Results:**
[Dependencies identified]
[Sequencing proposed]

### Implementation Detail Phase
**Validation Q3:** [Question text]
**Answer:** [User answer]

**Implementation Details:**
[Bite-sized tasks created]
[TDD structure enforced]

### Persistence
**Voyage ID:** VOY-XXX
**Missions:** M missions created
**Objectives:** N objectives created
**Plan File:** docs/plans/YYYY-MM-DD-[topic]-implementation-plan.md

**Next Action:** /mission-run VOY-XXX
```

### SQLite Writes

**After user validates final structure:**

1. Write voyage record
2. Write mission records (linked to voyage)
3. Write objective records (linked to missions)
4. Set all statuses to 'planned' (not 'pending' until mission-run)

---

## Integration with /mission-run

**After planning completes:**

```
User: /mission-run VOY-XXX

HOUSTON: "Loading voyage VOY-XXX: [Feature Name]...

Missions:
1. Mission 1: [Name] - [X objectives] - Status: planned
2. Mission 2: [Name] - [Y objectives] - Status: planned
3. Mission 3: [Name] - [Z objectives] - Status: planned

Execution mode:
  A) Attended (you review after each objective)
  B) Background (Ralph runs until blocked or complete)

Which mode?"
```

See: Ralph loop documentation for mission execution.

---

## Example Session

**User:** `/planning` (after brainstorming rate limiting)

**HOUSTON (T=0s):**
```
"Loading design from docs/plans/2026-01-16-api-rate-limiting-design.md...

Context loaded:
- Selected approach: Redis + Token Bucket
- Requirements: Per-user + per-IP, tier enforcement
- Estimate: ~2 days

Deploying task planning team..."

[SPAWN: Task Planning Agent A, B]

"While they work, quick question:

Should we prioritize for:
  A) Fastest delivery (MVP first, enhancements later)
  B) Lowest risk (foundational work first)
  C) User value (highest-impact features first)

[Task planning agents running...]"
```

**User (T=20s):** "B - lowest risk"

**HOUSTON (T=45s):**
```
"Perfect. My task planning team proposed:

Mission 1: Redis Setup & Token Bucket Core - 3 objectives
Mission 2: Rate Limiting Integration - 4 objectives
Mission 3: Testing & Validation - 3 objectives

Now analyzing dependencies and sequencing..."

[SPAWN: Phase Planning Agent A, B]

"Can any of these missions run in parallel, or must they be sequential?

  A) All sequential (Mission 1 → 2 → 3)
  B) Some parallel (1 first, then 2 & 3 together)
  C) Mostly parallel (independent work)

[Phase planning agents running...]"
```

**User (T=70s):** "A - all sequential"

**HOUSTON (T=90s):**
```
"Got it. My phase planning team identified:

Dependencies:
- Mission 1 (Redis setup) must complete first
- Mission 2 (integration) depends on Mission 1
- Mission 3 (testing) depends on Mission 2

Critical path: Mission 1 → 2 → 3 (sequential)

Now drafting implementation details..."

[SPAWN: Implementation Agent A, B]

"One more preference - for test-driven development:

  A) Write all tests first, then implement (TDD strict)
  B) Test-implement-test per objective (TDD incremental)
  C) Implementation-focused with test coverage (flexible)

[Implementation agents running...]"
```

**User (T=115s):** "B - TDD incremental"

**HOUSTON (T=135s):**
```
"All planning teams reporting. Here's the proposed structure:

─── VOYAGE: API Rate Limiting ───

**Goal:** Add Redis-based token bucket rate limiting with per-user and per-IP tracking

**Estimated Duration:** 2 days

─── MISSION 1: Redis Setup & Token Bucket Core ───

**Objectives:**
1. Set up Redis connection and configuration - 45 min
2. Implement token bucket algorithm - 60 min
3. Add per-user rate limit tracking - 45 min

**Dependencies:** None (can start immediately)

Does this first mission structure look right?"
```

**User:** "Yes"

**HOUSTON:**
```
─── MISSION 2: Rate Limiting Integration ───

**Objectives:**
1. Add per-IP rate limit tracking - 45 min
2. Create rate limit middleware - 60 min
3. Integrate tier enforcement (free/pro/enterprise) - 45 min
4. Add fallback to in-memory on Redis failure - 45 min

**Dependencies:** Mission 1 must complete first

Does this second mission structure look right?"
```

**User:** "Yes"

**HOUSTON:**
```
─── MISSION 3: Testing & Validation ───

**Objectives:**
1. Write integration tests for rate limiting - 60 min
2. Load test with multiple tiers - 45 min
3. Test Redis failure scenarios - 45 min

**Dependencies:** Mission 2 must complete first

Does this final mission structure look right?"
```

**User:** "Yes"

**HOUSTON:**
```
"Perfect. Writing to SQLite and docs..."

[Writes SQLite: 1 voyage, 3 missions, 10 objectives]
[Writes markdown: docs/plans/2026-01-16-api-rate-limiting-implementation-plan.md]
[Commits both]

"Voyage VOY-003 created with 3 missions and 10 objectives.

Implementation plan: docs/plans/2026-01-16-api-rate-limiting-implementation-plan.md

Ready for /mission-run VOY-003 when you are."
```

---

## Key Principles

1. **Agents ahead of validation** - Always forward-deployed
2. **Zero user wait time** - Agents run while user validates
3. **Mission-by-mission validation** - Present incrementally, adjust before SQLite writes
4. **Bite-sized tasks** - 2-5 minutes per task (one action)
5. **TDD enforced** - Test → Fail → Implement → Pass → Commit
6. **Exact commands** - No "update the file", full paths and code
7. **Dual output** - SQLite (for Ralph) + Markdown (for humans)
8. **YAGNI throughout** - Simplest breakdown that works

---

## Success Metrics

**Quality:**
- ✅ Plan matches design doc intent
- ✅ Tasks are truly 2-5 minutes (not 30 min "tasks")
- ✅ TDD structure enforced throughout
- ✅ Dependencies correctly identified

**Speed:**
- ✅ Full session: ~3 minutes (vs 15-20 min manual)
- ✅ User wait time: 0 seconds

**Executability:**
- ✅ Ralph can execute plan without confusion
- ✅ Subagents can execute plan without clarification
- ✅ Manual execution possible (if needed)

---

## Next Steps

1. Implement `/planning` skill with this pattern
2. Test integration with `/brainstorming` output
3. Verify SQLite writes work correctly
4. Test markdown plan format with Ralph execution
5. Tune agent counts and task granularity

**Related:**
- See `2026-01-16-brainstorming-forward-deployed-fthread.md` for design phase
- See Ralph loop documentation for mission execution
