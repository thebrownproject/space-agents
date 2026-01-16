# Loom-Inspired Improvements for Space-Agents

**Date:** 2026-01-16
**Status:** Recommendations
**Source:** Analysis of Jeff Huntley's Loom project
**Context:** Features we can adopt within Claude Code CLI constraints

---

## Executive Summary

After analyzing Loom (Jeff Huntley's agent-first infrastructure project), we've identified 7 features that Space-Agents can adopt to improve orchestration capabilities. These are organized by priority and filtered for feasibility within Claude Code CLI constraints.

**Related:** See `docs/research/loom-autonomous-software-infrastructure.md` for full Loom analysis.

---

## Priority 1: High Impact, Low Effort

### 1. Thread Reuse System

**Problem:** Each mission/objective operates in isolation. Context from previous work is lost.

**Loom's Solution:** Threads = saved context windows that agents can load and reuse.

**For Space-Agents:**

**Current:**
```
Mission 1: Research auth patterns → Complete → Context lost
Mission 2: Implement auth → Starts from scratch
```

**With Thread Reuse:**
```
Mission 1: Research auth patterns → Thread saved to capcom.log
Mission 2: Loads Mission 1 thread → Continues with full context
```

**Implementation:**

**Phase 1: Explicit Thread Loading**
```markdown
# In objective description
**Context:** Load thread from Objective 1.1 (auth patterns research)
```

Worker/Inspector/Analyst reads specified capcom.log before starting.

**Phase 2: Crew Meta-Loops**
```
Worker: Implements → Thread saved to .space-agents/staging.md
Inspector: Explicitly loads Worker's thread → Reviews requirements
Analyst: Explicitly loads Inspector's thread → Reviews code quality
```

**Phase 3: Cross-Mission Context**
```sql
-- objectives table
ALTER TABLE objectives ADD COLUMN depends_on_objective_id INTEGER;
ALTER TABLE objectives ADD COLUMN load_thread_from TEXT;

-- When objective starts, load context from dependency
```

**Files to Modify:**
- `skills/mission-execute/` - Add thread loading logic
- SQLite schema - Add dependency tracking
- CAPCOM - Add thread retrieval function

**Benefit:** Meta-loops enable Crew members to build on each other's work without re-discovery.

---

### 2. Logs Before/After Pattern

**Problem:** Airlock validates tests pass, but misses subtle breakage (performance degradation, new warnings, error rate changes).

**Loom's Solution:** Check system state before changes, check after, diff the results.

**For Space-Agents:**

**Current:**
```
Airlock: Run tests → Pass/Fail
```

**With Before/After:**
```
Airlock: Capture state (logs, metrics, warnings) → BEFORE snapshot
Worker: Makes changes
Airlock: Capture state (logs, metrics, warnings) → AFTER snapshot
Airlock: Diff snapshots → Report anomalies to Inspector
```

**Implementation:**

**State to Capture:**
- Build warnings count
- Test execution time
- Lint warning count
- Error log entries (if server running)
- Memory usage (if applicable)
- File count / line count (detect sprawl)

**Example Flow:**
```bash
# Before
Airlock: npm run build 2>&1 | tee /tmp/build_before.log
Airlock: Count warnings: 3
Airlock: Count errors: 0
Airlock: Build time: 2.3s

# After Worker changes
Airlock: npm run build 2>&1 | tee /tmp/build_after.log
Airlock: Count warnings: 7 (+4 new warnings ⚠️)
Airlock: Count errors: 0
Airlock: Build time: 2.8s (+0.5s slower ⚠️)

Airlock → Inspector: "4 new warnings introduced, build 0.5s slower"
```

**Files to Modify:**
- `skills/airlock-validate/` - Add state capture logic
- Create `.space-agents/snapshots/` directory
- Airlock captures before Pod execution
- Airlock captures after Pod execution
- Airlock diffs and reports to Inspector

**Benefit:** Catches regressions that tests don't detect.

---

### 3. CAPCOM Index System

**Problem:** Agents make redundant tool calls searching for same patterns. "Cache misses" slow execution.

**Loom's Solution:** Maintain `index.md` lookup table for common patterns. Optimize for "cache hits."

**For Space-Agents:**

**Current:**
```
Research Agent A: Searches for "auth patterns" → Takes 30s
Research Agent B: Searches for "auth patterns" → Takes 30s (duplicate)
Architecture Agent: Searches for "auth patterns" → Takes 30s (duplicate)
```

**With CAPCOM Index:**
```
Research Agent A: Searches → Updates index
Research Agent B: Reads index → Instant
Architecture Agent: Reads index → Instant
```

**Implementation:**

**File:** `.space-agents/capcom_index.md`

**Structure:**
```markdown
# CAPCOM Index - Updated: 2026-01-16 14:32

## Code Patterns
- **Authentication:** middleware/auth.ts:45-67 (JWT-based)
- **Rate Limiting:** middleware/rate_limit.ts:12-89 (Redis + token bucket)
- **Database:** lib/db.ts:100-250 (Prisma ORM)
- **API Routes:** pages/api/*.ts (Next.js API routes)

## Common Failures
- **TypeScript Errors:** Usually missing type imports from `@types/*`
- **Test Failures:** Usually async timing issues, add `await`
- **Lint Errors:** Usually unused variables, run `eslint --fix`
- **Build Errors:** Usually missing dependencies, run `npm install`

## Recent Changes
- **2026-01-16:** Added rate limiting (Mission 3, Objectives 2.1-2.4)
- **2026-01-15:** Refactored auth middleware (Mission 2, Objective 1.3)
- **2026-01-14:** Updated database schema (Mission 1, Objectives 1.1-1.2)

## Key Files
- **Entry Point:** src/index.ts
- **Config:** config/app.config.ts
- **Tests:** tests/ (Jest)
- **Docs:** docs/

## Dependencies
- TypeScript 5.3
- Next.js 14
- Prisma 5.7
- Redis (for rate limiting)
```

**Update Triggers:**
- Research agents append findings
- Architecture agents add patterns
- Risk agents add common failures
- Implementation agents add recent changes

**Read by:**
- All F-Thread agents during brainstorming/planning
- All Crew members during execution
- CAPCOM when filtering context

**Files to Create:**
- `.space-agents/capcom_index.md` (generated, not committed)
- `scripts/update_index.sh` (helper for agents)

**Benefit:** Faster agent execution, fewer redundant searches, better context.

---

## Priority 2: High Impact, Medium Effort

### 4. Airlock Testing Loops (Loom Mode 3)

**Problem:** Airlock only runs existing tests. Doesn't generate missing tests, doesn't analyze failures deeply.

**Loom's Solution:** Mode 3 Ralph - System verification loops that generate test plans and execute them.

**For Space-Agents:**

**Current:**
```
Airlock: Run tests
Airlock: 3 tests failed
Airlock: BLOCKED (reports to HOUSTON)
```

**With Testing Loops:**
```
Airlock: Run tests
Airlock: 3 tests failed
Airlock: Spawn analysis agent → Diagnose failures → Report findings
Airlock: "Failure cause: Missing type import on line 45"
Airlock: Spawn fix agent → Fix issue → Re-run tests
Airlock: Tests pass → APPROVED
```

**Three Modes:**

**Mode A: Test Generation**
```
Airlock: Check coverage → 60% (below threshold)
Airlock: Identify uncovered files:
  - user_service.ts (0% coverage)
  - auth_helper.ts (30% coverage)
Airlock: Spawn test-gen agent → Generate tests → Run tests
Airlock: Coverage now 85% → APPROVED
```

**Mode B: Failure Analysis**
```
Airlock: 5 tests failing
Airlock: Spawn analysis agent:
  - Read test failures
  - Read implementation
  - Identify root cause
  - Suggest fix
Airlock: Report to Inspector with diagnosis + suggestion
```

**Mode C: System Verification** (Loom-style)
```
Airlock: Generate verification plan:
  - Test all API endpoints
  - Check database connectivity
  - Verify authentication
  - Check rate limiting
Airlock: Spawn verification agent:
  - Execute curl tests
  - Check logs before/after
  - Report health status
```

**Implementation:**

**Airlock becomes decision tree:**
```python
def airlock_validate():
    # Phase 1: Run existing tests
    results = run_tests()

    if results.failed > 0:
        # Mode B: Analyze failures
        diagnosis = spawn_analysis_agent(results)
        report_to_inspector(diagnosis)

        if auto_fix_enabled:
            spawn_fix_agent(diagnosis)
            results = run_tests()  # Re-run

    if results.coverage < threshold:
        # Mode A: Generate missing tests
        spawn_test_gen_agent(uncovered_files)
        results = run_tests()

    if mission_complete:
        # Mode C: System verification
        spawn_verification_agent()

    return results.all_passed
```

**Files to Modify:**
- `skills/airlock-validate/` - Add testing loops
- Create subagent prompts for test-gen, analysis, verification
- Add configuration for thresholds and auto-fix

**Benefit:** Airlock becomes active participant, not passive validator. Catches and fixes issues autonomously.

---

### 5. System Verification Skill (`/verify`)

**Problem:** No easy way to run full health check on codebase. Manual verification is tedious.

**Loom's Solution:** Run Ralph loop that tests entire system, generates report.

**For Space-Agents:**

**New Command:** `/verify`

**Usage:**
```
User: /verify

HOUSTON: "Launching verification agents...

[SPAWN: Verification Agent]

Agent: Testing all components...
  ✅ All tests pass (127/127)
  ✅ No lint errors
  ✅ Build succeeds (2.3s)
  ⚠️  2 security vulnerabilities found (low severity)
  ❌ API endpoint /api/users returns 500

HOUSTON: "Verification complete. Found 1 critical issue:
  - /api/users endpoint failing (missing database connection)

Create mission to fix?"
```

**Implementation:**

**Verification Plan:**
```markdown
# System Verification Plan

## Phase 1: Static Analysis
- Run linter (eslint/prettier)
- Run type checker (tsc)
- Check for security vulnerabilities (npm audit)
- Check for outdated dependencies

## Phase 2: Build & Test
- Run build (ensure no errors)
- Run all tests (unit, integration, e2e)
- Measure test coverage
- Check for flaky tests (run 3x)

## Phase 3: Runtime Checks (if applicable)
- Test API endpoints (curl/fetch)
- Check database connectivity
- Verify authentication flows
- Test rate limiting
- Check error logging

## Phase 4: Code Quality
- Measure code complexity
- Check for code smells
- Verify documentation exists
- Check commit message quality (recent)
```

**Agent executes plan, reports findings.**

**Files to Create:**
- `skills/verify-system/SKILL.md`
- Agent prompt for verification
- Report template

**Benefit:** Continuous system health monitoring. Proactive issue detection.

---

## Priority 3: Future Work

### 6. Permission Levels

**Problem:** Unclear what agents can do in attended vs background modes. Risk of unintended actions.

**Loom's Solution:** Explicit permission system. Agents declare what they need.

**For Space-Agents:**

**Permission Levels:**

| Permission | Attended | Background | Background + Deploy |
|------------|----------|------------|---------------------|
| Read codebase | ✅ | ✅ | ✅ |
| Write code | ✅ | ✅ | ✅ |
| Run tests | ✅ | ✅ | ✅ |
| Delete files | ⚠️ Confirm | ❌ | ✅ |
| Git commit | ✅ | ✅ | ✅ |
| Git push | ⚠️ Confirm | ❌ | ✅ |
| Deploy server | ❌ | ❌ | ✅ |
| Modify DB schema | ⚠️ Confirm | ❌ | ✅ |

**Skill Declaration:**
```markdown
---
name: mission-execute
permissions:
  - read:codebase
  - write:code
  - run:tests
  - git:commit
  - git:push (if background)
---
```

**HOUSTON checks:**
```python
def can_execute_skill(skill, mode):
    required = skill.permissions
    allowed = PERMISSIONS[mode]

    if not all(p in allowed for p in required):
        ask_user_for_override()
```

**Implementation:**

**Files to Create:**
- `config/permissions.yaml` - Define permission levels
- HOUSTON skill validation
- User override prompts

**Benefit:** Clear boundaries, safer autonomous operation.

---

### 7. Gradual Rollout Mode

**Problem:** Background missions deploy all objectives at once. If something breaks, entire mission fails.

**Loom's Solution:** Deploy incrementally, monitor health, rollback if issues detected.

**For Space-Agents:**

**New Mode:** `/mission-run --mode gradual`

**Flow:**
```
HOUSTON: "Rolling out objectives gradually..."

Objective 1.1: Add rate limit middleware
  → Complete
  → Airlock: Run tests → Pass
  → Monitor: Wait 5 min, check logs/metrics
  → Status: Healthy ✅
  → Continue to 1.2

Objective 1.2: Add per-user tracking
  → Complete
  → Airlock: Run tests → Pass
  → Monitor: Wait 5 min, check logs/metrics
  → Status: 3 errors detected ❌
  → HOUSTON: "Rollback objective 1.2? Or investigate?"

User: "Investigate"

HOUSTON: Spawn analysis agent → Diagnose errors
HOUSTON: "Issue found: Missing Redis connection. Fix?"

User: "Yes"

HOUSTON: Spawn fix agent → Fix Redis config → Re-deploy 1.2
  → Monitor: Wait 5 min
  → Status: Healthy ✅
  → Continue to 1.3
```

**Implementation:**

**Config:**
```yaml
gradual_rollout:
  enabled: true
  monitor_duration: 300  # 5 minutes
  health_checks:
    - run_tests
    - check_logs_for_errors
    - check_metrics (if available)
  rollback_on_failure: ask_user  # or "auto"
```

**Files to Modify:**
- `skills/mission-execute/` - Add gradual mode
- Airlock - Add health monitoring
- HOUSTON - Add rollback logic

**Benefit:** Safer autonomous deployments. Early detection of issues.

---

## Implementation Roadmap

### Phase 1: Foundation (1-2 weeks)

**Milestone: Thread Reuse + Logs Before/After**

- [ ] Add thread loading to objective execution
- [ ] Crew members explicitly load previous threads
- [ ] Airlock captures state before/after
- [ ] Airlock diffs and reports anomalies

**Deliverable:** Missions can build on previous mission context. Airlock detects regressions.

---

### Phase 2: Intelligence (2-3 weeks)

**Milestone: CAPCOM Index + Airlock Testing Loops**

- [ ] Generate capcom_index.md from agent findings
- [ ] Agents read index to optimize searches
- [ ] Airlock spawns test-gen agent for coverage
- [ ] Airlock spawns analysis agent for failures

**Deliverable:** Faster agent execution. Airlock becomes active participant.

---

### Phase 3: Verification (1-2 weeks)

**Milestone: System Verification Skill**

- [ ] Implement `/verify` command
- [ ] Spawn verification agent
- [ ] Generate verification report
- [ ] Optionally spawn fix mission

**Deliverable:** Continuous system health monitoring.

---

### Phase 4: Safety (2-3 weeks)

**Milestone: Permissions + Gradual Rollout**

- [ ] Define permission levels
- [ ] HOUSTON validates skill permissions
- [ ] Implement gradual rollout mode
- [ ] Add health monitoring between objectives
- [ ] Add rollback capability

**Deliverable:** Safer autonomous operation.

---

## Key Validations from Loom

**What Loom confirms we're doing RIGHT:**

### ✅ Forward-Deployed F-Threading

Jeff spawns weavers AHEAD of work:
- Research agents spawn before questions
- Architecture agents spawn while user answers
- Risk agents spawn while user validates

**Space-Agents already does this in our planning specs.**

---

### ✅ Thread/Audit Trail Pattern

Loom's "threads" = Space-Agents' logs:
- Save context for reuse
- Agents read other agents' context
- Full audit trail

**Space-Agents has staging.md + capcom.log + mission logs. We need to enable reuse.**

---

### ✅ Meta-Loops

Loom's weaver-to-weaver communication:
- Weaver A produces thread
- Weaver B reads Weaver A's thread
- Weaver C reads both threads

**Space-Agents' Crew pattern (Worker → Inspector → Analyst) is meta-loops. We need to make thread reading explicit.**

---

### ✅ Feel Failures, Engineer Away

Jeff's philosophy:
- Don't over-engineer upfront
- Let systems fail, capture why
- Ralph loop to fix classes of failures
- Airlock provides back pressure

**Space-Agents already follows this. Airlock is our back pressure mechanism.**

---

### ✅ Orchestration vs Infrastructure

Space-Agents focuses on planning/coordination (HOUSTON).
Loom focuses on execution substrate (weavers, networking).

**Different layers, both needed. We're building the right abstraction.**

---

## Constraints

**We're building within Claude Code CLI:**

**What we CAN'T do (Loom does):**
- Remote Kubernetes pods
- Wireguard networking
- Custom SSH access
- eBPF instrumentation
- Bare metal infrastructure

**What we CAN do:**
- Spawn Claude Code subagents (Task tool)
- Save/load context (files)
- Run tests/lint (Bash)
- SQLite state management
- Bash scripts for orchestration

**Our scope:** Orchestration layer on top of Claude Code, not infrastructure layer.

---

## Success Metrics

**Phase 1 (Thread Reuse + Logs Before/After):**
- ✅ Missions load previous mission context without re-research
- ✅ Airlock detects performance regressions
- ✅ Inspector gets anomaly reports from Airlock

**Phase 2 (CAPCOM Index + Testing Loops):**
- ✅ Agent searches 50% faster (fewer cache misses)
- ✅ Test coverage increases automatically
- ✅ Airlock diagnoses failures without human intervention

**Phase 3 (System Verification):**
- ✅ `/verify` command runs full health check
- ✅ Proactive issue detection before user notices

**Phase 4 (Permissions + Gradual Rollout):**
- ✅ Zero accidental deletions in background mode
- ✅ Issues caught within 5 minutes of deployment
- ✅ Automatic rollback on health degradation

---

## Related Documents

- **Loom Research:** `docs/research/loom-autonomous-software-infrastructure.md`
- **F-Thread Brainstorming:** `docs/plans/2026-01-16-brainstorming-forward-deployed-fthread.md`
- **F-Thread Planning:** `docs/plans/2026-01-16-planning-forward-deployed-fthread.md`
- **Thread-Based Engineering:** `docs/research/thread-based-engineering.md`

---

## Final Thoughts

**Loom validates our direction.** We're building orchestration (HOUSTON coordinates missions), they're building infrastructure (weavers execute remotely). Both are needed.

**Priority 1 features have highest ROI:**
- Thread reuse enables meta-loops
- Logs before/after catches subtle issues
- CAPCOM index speeds up all agents

**Start with Priority 1, ship incrementally, feel the failures, engineer away.**

**HOUSTON standing by for implementation orders.**
