# SAL-9000 v2: Pattern Comparison

How the v2 architecture incorporates (or intentionally defers) patterns from the research collection.

---

## 1. Ralph Wiggum Loop

**Problem solved**: Context rot (LLM effectiveness degrades as context fills)

| Pattern Element | SAL v2 Implementation | Status |
|-----------------|----------------------|--------|
| Fresh context windows | Pods are ephemeral, spawned fresh each iteration | ✅ Fully adopted |
| Bash loop externalizes inference | `ralph.sh` wraps the Pod spawning | ✅ Fully adopted |
| State in files | SQLite + CAPCOM log | ✅ Fully adopted |
| One goal per iteration | Pod handles one task, then exits | ✅ Fully adopted |
| Backpressure via tests/lint | Airlock runs validation | ✅ Fully adopted |
| Kanban over dependency graphs | Pod picks highest priority, no complex deps | ✅ Fully adopted |
| Attended → unattended progression | Not explicitly designed | ⚠️ Could add |

**Grade: A** - Ralph is the backbone of the design. The core insight (externalize the loop, fresh context each iteration) is fully implemented.

**What we took**: The entire execution model. SAL v2 IS Ralph with hierarchical subagents inside.

---

## 2. Superpowers (obra)

**Problem solved**: Behavioral drift (agent skips verification, makes assumptions)

| Pattern Element | SAL v2 Implementation | Status |
|-----------------|----------------------|--------|
| Three-agent review | Worker → Inspector → Analyst | ✅ Fully adopted |
| Skill injection / forcing functions | GUPP-like: Pod executes autonomously | ✅ Partially adopted |
| Behavioral discipline | Pod must execute assigned work | ✅ Adopted via GUPP |
| Skills cascade to subagents | Not explicitly designed | ❌ Gap |
| TDD iron law | Not enforced | ⚠️ Could add to Airlock |

**Grade: B+** - Review cycle adopted, but skill injection mechanism not formalized.

**What we took**:
- Three-agent review pattern (Worker → Inspector → Analyst)
- GUPP as a forcing function (execute without asking)

**Gap**: Workers receive prompts but not formal skill files. Could formalize `scripts/prompts/*.md` as skill-like documents with behavioral rules.

**Potential improvement**: Add explicit behavioral checkpoints to prompts:
```markdown
## Worker Behavioral Rules
- NEVER mark task complete without running tests
- ALWAYS update CAPCOM log before exiting
- If stuck for 3 attempts, mark task 'failed' and exit
```

---

## 3. Beads (yegge)

**Problem solved**: Context amnesia (every session starts fresh, no memory)

| Pattern Element | SAL v2 Implementation | Status |
|-----------------|----------------------|--------|
| SQLite for coordination | `.sal/sal.db` with missions/tasks/messages | ✅ Fully adopted |
| Addressable work items with IDs | Task IDs in database | ✅ Fully adopted |
| Query what's needed | `SELECT ... WHERE status = 'pending'` | ✅ Fully adopted |
| Hash-based IDs | Not implemented (using simple IDs like `t-001`) | ⚠️ Gap for multi-agent |
| Land the Plane protocol | Not explicit | ⚠️ Could add |
| Dependency tracking (`blocks`) | Pod decides ordering (no explicit blocks) | ⚠️ Simplified |
| Memory decay / compaction | Not implemented | ❌ Gap |
| Git-backed JSONL persistence | CAPCOM log is markdown, not JSONL | ⚠️ Partial |

**Grade: B** - Core SQLite pattern adopted, missing robustness features.

**What we took**:
- SQLite as coordination layer
- Addressable work items with status tracking
- Query-based task selection (`bd ready` equivalent)

**Gaps**:
- **Hash-based IDs**: Simple IDs (`t-001`) work for sequential Pods but could collide with parallel execution
- **Land the Plane**: No explicit "session end" checklist for Pods
- **Compaction**: Old completed tasks accumulate (fine for small projects)

**When to address**: If you scale to parallel Pods or long-running missions with hundreds of tasks.

---

## 4. Gas Town (yegge)

**Problem solved**: Swarm coordination (managing 20-30+ parallel agents)

| Pattern Element | SAL v2 Implementation | Status |
|-----------------|----------------------|--------|
| Role hierarchy | SAL → Pod → Worker/Inspector/Analyst | ✅ Fully adopted |
| Ephemeral workers (Polecats) | Workers spawned fresh by Pod | ✅ Fully adopted |
| GUPP propulsion principle | Pod executes without waiting for confirmation | ✅ Adopted |
| Coordination through state, not calls | SQLite + CAPCOM log | ✅ Fully adopted |
| Witness (health monitoring) | Not implemented | ❌ Deferred |
| Refinery (merge coordination) | Not implemented | ❌ Deferred |
| Watchdog recursion (Dog → Deacon) | Not implemented | ❌ Deferred |
| Git worktree isolation | Not implemented | ❌ Deferred |
| Mail system with priorities | SQLite messages table (simpler) | ⚠️ Simplified |
| MEOW molecular workflows | Not implemented | ❌ Deferred |

**Grade: C+** - Adopted hierarchy and ephemeral workers, deferred swarm features.

**What we took**:
- Role hierarchy (SAL = Mayor, Pod = orchestrator, Workers = Polecats)
- Ephemeral workers with fresh context
- GUPP: "If there's work assigned, execute it"
- State-based coordination (no direct agent calls)

**What we intentionally skipped**:
- **Witness/Refinery**: Health monitoring and merge coordination are for 20-30+ agents
- **Git worktrees**: File isolation matters when parallel agents modify same codebase
- **Watchdog recursion**: Monitoring the monitor is for complex systems
- **MEOW workflows**: Molecular task chains are for sophisticated pipelines

**This is the right call** - Gas Town's complexity serves swarm scale. SAL v2 targets 1-3 agents where this overhead isn't justified.

**When to revisit**: If you hit Stage 7+ (10+ agents) and need real coordination.

---

## 5. tmux Orchestration

**Problem solved**: Session ephemerality (agents die when terminal closes, no real-time visibility)

| Pattern Element | SAL v2 Implementation | Status |
|-----------------|----------------------|--------|
| Session persistence | Using Task tool (fire-and-forget) | ❌ Deferred |
| Real-time observability | Not implemented | ❌ Deferred |
| Output capture | Not implemented | ❌ Deferred |
| Detach/reattach for human intervention | Not implemented | ❌ Deferred |
| Session-per-agent isolation | Not implemented | ❌ Deferred |

**Grade: N/A** - Explicitly deferred by design.

**Why we skipped it**:
- Task tool works now with zero setup
- tmux adds value at scale when monitoring multiple agents matters
- The architecture is runtime-agnostic - can swap later

**When to revisit**: When you need to:
- Monitor long-running agents in real-time
- Attach to agent sessions to observe/intervene
- Run agents that survive your terminal session

**Evolution path**:
```
Phase 1: Task tool (current) - simple, works today
Phase 2: tmux for long-running workers
Phase 3: Full tmux orchestration at swarm scale
```

---

## Summary Scorecard

| Pattern | Grade | Adoption Level |
|---------|-------|----------------|
| **Ralph Wiggum** | A | Core architecture |
| **Superpowers** | B+ | Review cycle yes, skill injection informal |
| **Beads** | B | SQLite yes, missing robustness features |
| **Gas Town** | C+ | Hierarchy yes, swarm features deferred |
| **tmux** | N/A | Intentionally deferred |

---

## Gaps Worth Addressing

### Near-term (before v1.0)

1. **Formalize worker prompts as skills**
   - Add behavioral rules to `scripts/prompts/*.md`
   - Include explicit checkpoints and failure modes

2. **Land the Plane protocol for Pods**
   - Checklist before Pod exits
   - Ensure state is clean, CAPCOM log updated

### Future (when scaling)

3. **Hash-based task IDs**
   - Prevent collisions if running parallel Pods
   - Use content-based hashing like Beads

4. **Attended mode flag**
   - `./ralph.sh mission-id --attended`
   - Pause after each Pod for human review

5. **tmux integration**
   - Swap Task tool for tmux sessions
   - Enable real-time monitoring

---

## What SAL v2 Got Right

| Strength | Why It Matters |
|----------|----------------|
| Fresh context at every execution level | Maximum "smart zone" operation |
| SAL outside the loop | Persistent interface without context rot |
| CAPCOM as infrastructure, not agent | Simpler, no AI overhead for routing |
| SQLite + file hybrid | Fast queries + human-readable audit trail |
| Deliberate simplicity | Not over-engineering for scale we don't need |
| Runtime-agnostic design | Can swap Task tool for tmux later |

---

## The Synthesis

SAL v2 is essentially:

```
Ralph Wiggum Loop
    + Hierarchical subagents (Gas Town roles)
    + Three-agent review (Superpowers pattern)
    + SQLite coordination (Beads state management)
    - Swarm complexity (deferred)
    - tmux infrastructure (deferred)
```

**The breakthrough insight**: You can have hierarchical structure AND fresh context by putting the hierarchy INSIDE the Ralph loop. Each Pod iteration is fresh, but within that iteration you get the full Worker → Inspector → Analyst review cycle.

This avoids the main failure mode of both approaches:
- Pure Ralph: No structure for complex multi-step work
- Pure hierarchy: Long-lived coordinators accumulate context rot

SAL v2 gets the best of both.
