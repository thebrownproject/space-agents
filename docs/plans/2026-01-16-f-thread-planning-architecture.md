# F-Thread Planning Architecture for Space-Agents

**Date:** 2026-01-16
**Status:** Design Phase
**Inspired by:** Andy Devdan's Thread-Based Engineering Framework

---

## Executive Summary

Implement **F-Thread (Fusion Thread)** architecture for Space-Agents' brainstorming and planning phases. This creates a two-tier system:

1. **Tier 1: Planning & Brainstorming** - F-Thread based (parallel exploration → synthesis)
2. **Tier 2: Execution** - Ralph Loop (proven sequential Pod execution)

The key insight: Use F-Threading for **planning quality**, not execution. Better plans = better Ralph outcomes.

---

## Thread-Based Engineering Background

From Andy Devdan's framework, a **thread** is a unit of engineering work over time:

```
[YOU: Prompt/Plan] → [AGENT: Tool Calls] → [YOU: Review/Validate]
```

### Six Thread Types

| Thread | Pattern | Use Case |
|--------|---------|----------|
| **Base** | Single agent, single task | Standard workflow |
| **P-Thread** | Parallel agents, independent tasks | Scale compute |
| **C-Thread** | Chained phases with checkpoints | High-risk production work |
| **F-Thread** | Parallel agents → synthesize results | **Rapid prototyping, planning** |
| **B-Thread** | Meta-structure (agents spawn agents) | Complex orchestration |
| **L-Thread** | Long-duration, high autonomy | Extended workflows |

### Key Principle

> **"F-Thread is the cream of the crop for rapid prototyping."**
> — Andy Devdan

**Why F-Threading for Planning:**
- Multiple perspectives on problem decomposition
- Higher confidence through consensus (4/5 agents agree = strong signal)
- Catch edge cases before coding starts
- Best-of-N or cherry-pick best ideas

---

## Space-Agents Current State

**Execution (Tier 2) is solid:**
- Ralph loop spawns fresh Pods sequentially
- Worker → Inspector → Analyst → Airlock
- State persists in SQLite
- No context rot

**Planning (Tier 1) is single-threaded:**
- HOUSTON plans manually (single perspective)
- No parallel exploration of approaches
- No synthesis of multiple architectural views

---

## Proposed Architecture

### Two-Tier System

```
USER GOAL
    ↓
╔══════════════════════════════════════════════════════════╗
║  TIER 1: PLANNING & BRAINSTORMING (F-Thread Based)      ║
╚══════════════════════════════════════════════════════════╝
    ↓
    ├── /brainstorming → Parallel exploration → Synthesis
    │     ├── Research Agent (×3)
    │     ├── Architecture Agent (×3)
    │     ├── Risk Agent (×2)
    │     └── HOUSTON synthesizes → Recommendations
    │
    └── /planning → Parallel decomposition → Unified plan
          ├── Task Planning Agent (×2)
          ├── Phase Planning Agent (×2)
          ├── Implementation Agent (×2)
          └── HOUSTON synthesizes → SQLite records
    ↓
╔══════════════════════════════════════════════════════════╗
║  TIER 2: EXECUTION (Ralph Loop - Proven Sequential)     ║
╚══════════════════════════════════════════════════════════╝
    ↓
    └── /mission-run → Ralph spawns Pods → Worker/Inspector/Analyst
```

---

## Specialized Planning Agents

### Agent Roster

| Agent Type | Purpose | When Used | Typical Count |
|------------|---------|-----------|---------------|
| **Research Agent** | Explore codebase, find patterns, constraints | `/brainstorming` initial phase | 2-3 |
| **Architecture Agent** | Propose system designs, compare approaches | `/brainstorming` | 2-3 |
| **Risk Agent** | Identify critical paths, blockers, gotchas | Both phases | 2 |
| **Task Planning Agent** | Break voyage into missions/objectives | `/planning` | 2 |
| **Phase Planning Agent** | Sequence work, identify dependencies | `/planning` | 2 |
| **Implementation Agent** | Draft technical approach, patterns to use | `/planning` | 2 |

### Design Principles

1. **Each agent gets a specialized prompt** - Research sees different instructions than Architecture
2. **Agents run in parallel** - All spawned simultaneously via Task tool
3. **HOUSTON synthesizes** - Reads all outputs, presents unified recommendations
4. **User chooses direction** - HOUSTON doesn't pick, Fraser does
5. **State persists** - Brainstorming notes go to staging.md, final plans to SQLite

---

## Workflow Examples

### Example 1: `/brainstorming` Flow

```
User: /brainstorming "Add multi-tenant support to the app"

HOUSTON: "Roger that. Launching exploration agents."

[Spawns in parallel:]
  - Research Agent A: "Find current auth/data patterns"
  - Research Agent B: "Identify tenant isolation requirements"
  - Research Agent C: "Review existing database schema"
  - Architecture Agent A: "Propose schema isolation approach"
  - Architecture Agent B: "Propose row-level security approach"
  - Architecture Agent C: "Propose separate database approach"
  - Risk Agent A: "Identify migration risks"
  - Risk Agent B: "Identify data leakage risks"

[HOUSTON reads all 8 agent outputs]

HOUSTON: "Exploration complete. Here are three approaches:

**Approach A: Schema Isolation**
- Pros: Simple, fast queries
- Cons: Complex migrations, schema sprawl
- Risk: Medium (migration complexity)

**Approach B: Row-Level Security (RLS)**
- Pros: Single schema, Postgres-native
- Cons: Query performance overhead
- Risk: Low (Postgres RLS is battle-tested)

**Approach C: Separate Databases**
- Pros: Total isolation, scales independently
- Cons: High operational complexity
- Risk: High (connection pooling, backups)

Recommendation: Approach B (RLS) - best balance of simplicity and security."

User: "Let's go with Approach B."

HOUSTON: "Roger that. Ready for /planning when you are."
```

### Example 2: `/planning` Flow

```
User: /planning "Row-level security for multi-tenancy"

HOUSTON: "Launching planning agents."

[Spawns in parallel:]
  - Task Planning Agent A: "Break into missions/objectives"
  - Task Planning Agent B: "Break into missions/objectives"
  - Phase Planning Agent A: "Sequence work, find dependencies"
  - Phase Planning Agent B: "Sequence work, find dependencies"
  - Implementation Agent A: "Draft Postgres RLS patterns"
  - Implementation Agent B: "Draft Postgres RLS patterns"

[HOUSTON reads all 6 agent outputs]

HOUSTON: "Plan synthesized. Here's the proposed voyage structure:

**VOYAGE: Multi-Tenant Support via RLS**

**Mission 1: Database Schema Updates** (5 objectives)
  - Add tenant_id column to all tables
  - Create tenants table
  - Add RLS policies for each table
  - Create helper functions for current_tenant()
  - Write migration rollback scripts

**Mission 2: Application Layer Integration** (4 objectives)
  - Update auth middleware to set tenant context
  - Add tenant_id to all queries via ORM
  - Create tenant switching helper
  - Add tenant validation to API endpoints

**Mission 3: Testing & Validation** (3 objectives)
  - Write RLS policy tests
  - Test tenant isolation (cross-tenant access attempts)
  - Load test with multiple tenants

**Dependencies:**
  - Mission 1 must complete before Mission 2
  - Mission 3 can run parallel to Mission 2 (test writing)

Estimated complexity: Medium
Critical path: RLS policy correctness (risk of data leakage)

Ready to write to SQLite?"

User: "Yes, create the voyage."

HOUSTON: [Writes voyage/missions/objectives to SQLite]
         "Voyage VOY-003 created. Run /mission-run when ready."
```

---

## Implementation Plan

### Phase 1: Foundation
- [ ] Design specialized agent prompts (Research, Architecture, Risk, etc.)
- [ ] Create agent configuration system (role → prompt mapping)
- [ ] Build F-Thread orchestration function (spawn N agents in parallel)

### Phase 2: Brainstorming Skill
- [ ] Implement `/brainstorming` skill
- [ ] Spawn Research Agents (2-3)
- [ ] Spawn Architecture Agents (2-3)
- [ ] Spawn Risk Agents (2)
- [ ] Build synthesis logic (HOUSTON reads all, presents unified view)
- [ ] Test with real scenario

### Phase 3: Planning Skill
- [ ] Implement `/planning` skill (or extend existing)
- [ ] Spawn Task Planning Agents (2)
- [ ] Spawn Phase Planning Agents (2)
- [ ] Spawn Implementation Agents (2)
- [ ] Build synthesis logic (merge → SQLite records)
- [ ] Test with real scenario

### Phase 4: Integration
- [ ] Update `/launch` skill to mention F-Thread planning
- [ ] Update CLAUDE.md with F-Thread concepts
- [ ] Write user documentation
- [ ] Create example walkthroughs

### Phase 5: Advanced Features (Future)
- [ ] User-configurable agent counts (env var: `RESEARCH_AGENTS=5`)
- [ ] Custom agent types (user defines their own specialists)
- [ ] F-Thread for code review (spawn 3-5 review agents)
- [ ] Z-Thread exploration (zero-touch planning)

---

## Technical Decisions

### Agent Spawning Mechanism

**Use Task tool with parallel invocations:**

```typescript
// Pseudocode
await Promise.all([
  spawnAgent('Research', 'Find auth patterns'),
  spawnAgent('Research', 'Review database schema'),
  spawnAgent('Architecture', 'Propose RLS approach'),
  spawnAgent('Risk', 'Identify migration risks'),
  // ... etc
]);
```

### Synthesis Approach

**HOUSTON reads all outputs, doesn't run another agent:**
- Keeps HOUSTON context lean
- Faster than spawning yet another synthesis agent
- HOUSTON presents options, user decides

**Alternative (future):** Spawn a "Synthesis Agent" to merge outputs programmatically.

### State Persistence

| Artifact | Location | Lifecycle |
|----------|----------|-----------|
| Brainstorming results | `staging.md` | Session-scoped |
| Planning results | SQLite (voyages/missions/objectives) | Permanent |
| Agent outputs (raw) | Temp files or in-memory | Discarded after synthesis |

---

## Benefits

### For Planning Quality
- **Multiple perspectives** - Architecture, risk, sequencing all explored in parallel
- **Higher confidence** - When 4/5 agents agree, strong signal
- **Catch edge cases** - Risk agents surface issues before coding starts
- **Better Ralph outcomes** - Good plans → fewer Pod failures

### For User Experience
- **Faster planning** - Parallel exploration vs sequential HOUSTON thinking
- **Transparent trade-offs** - See multiple approaches with pros/cons
- **User stays in control** - HOUSTON recommends, Fraser decides

### For System Evolution
- **Extensible** - Add new agent types easily (Performance Agent, Security Agent)
- **Configurable** - Users can tune agent counts
- **Scalable** - More compute = better plans, doesn't affect Ralph execution

---

## Open Questions

1. **Agent count tuning:** Should we default to 2-3 per type, or make it configurable from day one?
2. **Cost management:** Running 8-10 agents per brainstorm could be expensive. Should we add a budget flag?
3. **Synthesis format:** Should HOUSTON present markdown tables, or interactive questions?
4. **Custom agents:** Should users be able to define their own agent types in a config file?
5. **F-Thread for execution?** Could we use F-Thread for risky objectives (spawn 3 Pods, pick best)? Probably future work.

---

## Success Metrics

We'll know F-Threading works when:

1. **Planning is faster** - 3-5 minutes for complex voyage breakdown (vs 10-15 min manual)
2. **Fewer Pod failures** - Better plans = fewer Ralph blockers
3. **User confidence is higher** - Multiple perspectives catch edge cases
4. **Plans are more complete** - Risk agents surface issues HOUSTON would miss

---

## References

- Andy Devdan's Thread-Based Engineering video transcript
- Boris Churnney's setup (5 terminals + 5-10 web instances)
- Space-Agents current architecture (Ralph Loop, Pod/Crew system)
- `/launch` and `/mission-run` skill designs

---

## Next Steps

1. **Refine this design** - Review with Fraser, iterate
2. **Write agent prompts** - Research, Architecture, Risk, etc.
3. **Build F-Thread orchestration** - Spawn N agents in parallel
4. **Implement `/brainstorming`** - First F-Thread workflow
5. **Test with real scenario** - Multi-tenant support example
6. **Iterate based on results** - Tune agent counts, synthesis approach

---

**HOUSTON standing by for design review.**
