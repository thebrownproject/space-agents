# Gas Town Vision

*The philosophical foundation for Space-Agents, inspired by Steve Yegge's Gas Town.*

---

## North Star

Space-Agents aims to evolve toward **Gas Town parity** - a full swarm orchestration system for AI agents. This document captures the vision, philosophy, and long-term direction.

---

## Core Insight

> **"Agents are compute, not memory."**

You don't try to make agents remember - you give them clean state each time and let them process. Context rot happens when you treat agents like storage. Fresh agents + persistent state = indefinite scaling.

---

## The Stage Model

Steve Yegge describes an 8-stage evolution in AI-assisted development:

| Stage | Description |
|-------|-------------|
| 1 | Code completions, occasional chat queries |
| 2 | Narrow IDE agent with permission prompts |
| 3 | YOLO mode - permissions off |
| 4 | Agent fills the screen, diffs become primary |
| 5 | CLI mode - single agent at higher velocity |
| 6 | 3-5 parallel agents in YOLO mode |
| 7 | 10+ agents, manual management breaks down |
| 8 | Custom orchestration systems |

**Space-Agents targets Stage 6-8.** The goal is to provide the orchestration layer that makes Stage 7+ manageable.

---

## The Three Problems

| Problem | Description | Gas Town Solution | Space-Agents Approach |
|---------|-------------|-------------------|----------------------|
| **Context death** | Agent hits token limit, loses all memory | Persistent state (Beads) | SQLite + CAPCOM logs |
| **Coordination chaos** | Multiple agents modify same files, create conflicts | File isolation (Git worktrees) | Sequential execution (Phase 1), Worktrees (Phase 2) |
| **Visibility loss** | Can't track state across 20+ concurrent agents | Role hierarchy + tmux | HOUSTON + /capcom + future tmux |

---

## Vibe Coding Philosophy

> "Work becomes fluid... Most work gets done; some work gets lost... creation and correction at the speed of thought."

Vibe coding embraces imperfection for throughput. The agent swarm churns through tasks faster than humans can create them.

**Key principles:**

1. **Throughput over perfection** - Accept 85% quality for 10x velocity
2. **Work is disposable** - Agents can redo lost work quickly
3. **Errors are normal** - Build systems that recover, not prevent
4. **Feed the engine** - The bottleneck is work generation, not execution

---

## The Computing Model

Space-Agents maps directly to computer architecture:

| Traditional Computer | Space-Agents | Component |
|---------------------|--------------|-----------|
| **CPU** | Agents (stateless compute) | Pod, Worker, Inspector, Analyst |
| **OS / Kernel** | Orchestration layer | HOUSTON + Ralph loop |
| **Process** | Pod execution | Spawn -> execute -> exit |
| **Scheduler** | Ralph loop | Picks next objective, launches Pod |
| **RAM** | Session buffer | `staging.md` (cleared each session) |
| **Disk** | Persistent storage | SQLite + CAPCOM logs |
| **IPC** | Message passing | CAPCOM log, SQLite messages table |

### Memory Hierarchy

Like L1/L2/RAM/Disk in traditional computing:

| Tier | File | Speed | Persistence | Pattern |
|------|------|-------|-------------|---------|
| **L1 Cache** | Agent context | Instant | None (discarded) | Think fast, forget |
| **RAM** | `staging.md` | Fast read | Session | Full read, cleared on logout |
| **Disk** | CAPCOM logs | Grep | Permanent | Append-only, never full read |
| **Database** | SQLite | Query | Permanent | Structured queries |

---

## Gas Town Role Hierarchy

The full Gas Town architecture defines these roles:

| Role | Level | Purpose | Space-Agents Equivalent |
|------|-------|---------|------------------------|
| **Mayor** | Town | Breaks down work, coordinates across rigs | HOUSTON |
| **Deacon** | Town | Daemon beacon running patrol cycles | Future: Health daemon |
| **Dog** | Town | Checks Deacon every 5 minutes | Future: Watchdog |
| **Witness** | Rig | Monitors polecats, detects stuck agents | Future: Pod monitoring |
| **Refinery** | Rig | Manages merge queue, sequential rebasing | Future: Merge coordination |
| **Polecat** | Rig | Ephemeral worker - spawns, completes task, disappears | Pod + Crew |
| **Crew** | Rig | Long-lived named agents | Worker, Inspector, Analyst |

---

## Key Gas Town Patterns

### GUPP (Gas Town Universal Propulsion Principle)

> "If there is work on your Hook, YOU MUST RUN IT."

The foundational rule. When work appears, the agent must execute immediately - no waiting for confirmation, no asking questions.

**Why this matters**: Prevents stalled systems. Without GUPP, restarted agents pause indefinitely waiting for authorization.

*Space-Agents should adopt this as a forcing function in Pod prompts.*

### MEOW (Molecular Expression of Work)

Work decomposes into trackable, atomic units:

| Unit | Description | Space-Agents Equivalent |
|------|-------------|------------------------|
| **Bead** | Atomic work item | Objective |
| **Formula** | TOML template for reusable workflows | Future |
| **Protomolecule** | Template class for workflow instantiation | Future |
| **Molecule** | Live workflow - chained beads | Mission? |
| **Wisp** | Ephemeral bead destroyed after execution | Task within Pod |

### NDI (Nondeterministic Idempotence)

The reliability goal: useful outcomes despite unreliable processes. Persistent beads + oversight agents guarantee workflow completion even when individual agents fail.

---

## Phase Coverage

| Phase | Features | Gas Town Coverage |
|-------|----------|-------------------|
| Phase 1 (Sequential) | HOUSTON, Pods, Crew, SQLite, CAPCOM, Airlock | ~40% |
| Phase 2 (Parallel) | + Git Worktrees, Refinery | ~60% |
| Phase 3 (Monitored) | + Witness, Deacon, Dog | ~80% |
| Full Gas Town | + MEOW, Handoff, Seance | ~100% |

---

## What's Intentionally Deferred

| Component | Why Defer |
|-----------|----------|
| **MEOW Molecules** | Missions/Objectives cover this. Workflow templates are overkill until repeating complex patterns. |
| **Handoff Protocol** | Pods are short-lived. Mid-task handoff matters for long-running agents. |
| **Seance** | CAPCOM logs provide most of this. Structured session archaeology is a refinement. |
| **tmux Integration** | Task tool works. tmux adds value at scale for real-time visibility. |

---

## Research Foundation

Space-Agents synthesizes four major patterns:

| Pattern | Source | Problem Solved | Key Mechanism |
|---------|--------|----------------|---------------|
| **Ralph Wiggum** | Geoffrey Huntley | Context rot | Fresh sessions via bash loop |
| **Superpowers** | Jesse Vincent (obra) | Behavioral drift | Skill injection, forcing functions |
| **Beads** | Steve Yegge | Context amnesia | Queryable SQLite + Git |
| **Gas Town** | Steve Yegge | Swarm coordination | Role hierarchy, GUPP |

### The Synthesis

> "Gas Town combines all three patterns into a production orchestration system. Polecats are Ralph-style fresh sessions. GUPP is a Superpowers-style forcing function. Beads provides the persistent state layer."

Space-Agents integration:
- **Pods/Crew** = fresh context (Ralph) + ephemeral polecats (Gas Town)
- **CAPCOM** = skill injection (Superpowers) + message routing (Gas Town mail)
- **SQLite** = dependency tracking (Beads) + hook-based assignment (Gas Town)
- **Airlock** = quality gates (Ralph backpressure) + merge coordination (Gas Town Refinery)

---

## Industry Context

From RedMonk's analysis:

> "Agents solve certain problems beautifully, but managing fleets of agents introduces coordination complexity."

Historical parallel:
- **Virtualization**: Physical machines -> VMs (solved rigidity, created sprawl)
- **Microservices**: Monoliths -> services (solved scaling, created mesh complexity)
- **Agents**: Single assistant -> swarms (solves velocity, creates coordination chaos)

Gas Town is the first serious attempt at "Kubernetes for AI agents" - operational governance for unreliable workers.

---

## The Ultimate Goal

> "The question isn't whether to orchestrate agents. It's whether to do it manually or build systems that do it for you."

Gas Town chooses systems. Space-Agents should too.

---

*Sources: Steve Yegge's Gas Town (github.com/steveyegge/gastown), Beads (github.com/steveyegge/beads), and associated blog posts.*
