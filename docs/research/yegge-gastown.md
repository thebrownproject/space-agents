# Gas Town

Reference material for SAL-9000 development.

**Sources**:
- https://github.com/steveyegge/gastown (Steve Yegge)
- https://myhub.ai/items/welcome-to-gas-town (Yegge blog post)
- https://justin.abrah.ms/blog/2026-01-05-wrapping-my-head-around-gas-town.html
- https://redmonk.com/sogrady/2026/01/08/tide-of-agents/

---

## The Core Insight

> "Gas Town is an industrialized coding factory manned by superintelligent chimpanzees."

Gas Town solves the **swarm coding problem**: what happens when you scale from one Claude Code agent to 20-30+ agents working in parallel? Manual coordination becomes impossible. Gas Town provides the orchestration layer.

### The Stage Model

Yegge describes an 8-stage evolution in AI-assisted development:

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

**Gas Town is for Stage 7+.** Most developers don't need it. If you're managing fewer than 10 agents, the complexity overhead exceeds benefits.

### The Three Problems

| Problem | Description |
|---------|-------------|
| **Context death** | Agent hits token limit, loses all memory |
| **Coordination chaos** | Multiple agents modify same files, create conflicts |
| **Visibility loss** | Can't track state across 20+ concurrent agents |

Gas Town solves all three through **persistent state** (Beads), **role hierarchy** (Mayor/Witness/Polecat), and **file isolation** (Git worktrees).

---

## Vibe Coding Philosophy

> "Work becomes fluid... Most work gets done; some work gets lost... creation and correction at the speed of thought."

Vibe coding embraces imperfection for throughput. The agent swarm churns through tasks faster than humans can create them. Some bugs get fixed multiple times. Some work gets lost and redone.

**This is a feature, not a bug.** When token costs are low and velocity matters more than precision, this tradeoff makes sense.

Key principles:

1. **Throughput over perfection** - Accept 85% quality for 10x velocity
2. **Work is disposable** - Agents can redo lost work quickly
3. **Errors are normal** - Build systems that recover, not prevent
4. **Feed the engine** - The bottleneck is work generation, not execution

---

## Architecture

### Two-Level Hierarchy

```
TOWN LEVEL (headquarters)
    │
    ├── Mayor (chief-of-staff, orchestrates)
    ├── Deacon (health monitor, runs patrol cycles)
    └── Dog (reminds Deacon to work)
           │
           ▼
RIG LEVEL (per-project)
    │
    ├── Witness (monitors polecats and refinery)
    ├── Refinery (manages merge queue)
    └── Polecats (ephemeral workers)
```

### Role Definitions

| Role | Level | Purpose |
|------|-------|---------|
| **Mayor** | Town | Breaks down work, coordinates across rigs, notifies user |
| **Deacon** | Town | Daemon beacon running patrol cycles, ensures activity |
| **Dog** | Town | Checks Deacon every 5 minutes (watchdog for the watchdog) |
| **Witness** | Rig | Monitors polecats, detects stuck agents, triggers recovery |
| **Refinery** | Rig | Manages merge queue, sequential rebasing, conflict resolution |
| **Polecat** | Rig | Ephemeral worker - spawns, completes task, disappears |
| **Crew** | Rig | Long-lived named agents for persistent collaboration |

### Why These Metaphors?

> "The metaphors encode actual relationships."

- **Piston** (polecat) fires and is done = ephemeral task completion
- **Pressure gauge** (witness) monitors bounds = observation without interference
- **Gearbox** (refinery) harmonizes motion = merging parallel changes

The Mad Max theme isn't just aesthetic - it guides component behavior.

---

## Key Concepts

### GUPP (Gas Town Universal Propulsion Principle)

> "If there is work on your Hook, YOU MUST RUN IT."

This is the foundational rule. A **Hook** is a pinned bead serving as each agent's personal work queue. When work appears, the agent must execute immediately - no waiting for confirmation, no asking questions.

**Why this matters**: Prevents the stalled system problem. Without GUPP, restarted agents pause indefinitely waiting for authorization. GUPP creates autonomous momentum.

### MEOW (Molecular Expression of Work)

Work decomposes into trackable, atomic units:

| Unit | Description |
|------|-------------|
| **Bead** | Atomic work item (like a Jira ticket) stored in Git |
| **Formula** | TOML template for reusable workflows |
| **Protomolecule** | Template class for workflow instantiation |
| **Molecule** | Live workflow - chained beads representing multi-step process |
| **Wisp** | Ephemeral bead destroyed after execution |

Molecules survive agent restarts. Each step is a bead that agents can claim, execute, and close.

### NDI (Nondeterministic Idempotence)

The reliability goal: useful outcomes despite unreliable processes. Persistent beads + oversight agents (Witness, Deacon) guarantee workflow completion even when individual agents fail.

---

## How It Works

### Git-Native State

Everything lives in Git:

```
.beads/
├── issues.jsonl       # Work items (committed)
├── beads.db          # SQLite cache (gitignored)
└── formulas/         # Workflow templates
```

- **JSONL** enables clean merges (one entity per line)
- **SQLite** provides fast local queries
- **Git** distributes state without a central server

When an agent crashes, the repository persists state. New agents pick up exactly where the old one left off.

### Git Worktrees for Isolation

Each polecat gets an isolated Git worktree on a unique branch:

```
/worktrees/
├── furiosa-branch/   # Polecat 1's workspace
├── nux-branch/       # Polecat 2's workspace
└── max-branch/       # Polecat 3's workspace
```

Agents can't interfere with each other's files. The Refinery sequentially merges completed work through rebasing.

### tmux Integration

Gas Town uses tmux for multi-agent session management:

- Each agent runs in an isolated tmux session
- Shared filesystem access for coordination
- The Mayor can spawn/monitor multiple sessions
- `gt mayor attach` starts the primary coordinator

**Minimal mode** (no tmux): Manual session management via `gt convoy create`, `gt sling`, `claude --resume`.

### The Flow

```
1. User tells Mayor the objective
2. Mayor breaks down into convoys (grouped beads)
3. Mayor slings work to polecats via hooks
4. Polecats spawn in isolated worktrees
5. Polecats complete work, send mail to Witness
6. Witness monitors progress, escalates issues
7. Refinery merges completed branches
8. Deacon runs patrol cycles, ensures activity
9. CAPCOM (mail system) routes messages
10. Mayor summarizes results to user
```

---

## Commands Reference

### Workspace Setup

```bash
go install github.com/steveyegge/gastown/cmd/gt@latest
gt install ~/gt --git
gt rig add myproject <repo-url>
gt crew add yourname --rig myproject
gt mayor attach
```

### Work Management

| Command | Purpose |
|---------|---------|
| `gt convoy create "Feature X" bd-123 bd-456` | Group related beads |
| `gt sling bd-123 myproject` | Assign work to agent |
| `gt convoy list` | View active convoys |
| `gt convoy show <id>` | Convoy details |
| `gt agents` | List active agents |
| `gt status` | System overview |
| `gt peek` | Examine agent work |

### Beads Integration

```bash
bd create "New feature" -p 1        # Create bead
bd ready --json                     # Get unblocked work
bd update <id> --status in_progress # Mark working
bd close <id> --reason "Done"       # Complete
bd formula list                     # View workflow templates
bd cook release --var version=1.2.0 # Execute formula
bd mol pour release --var version=1.2.0 # Trackable formula instance
```

---

## Coordination Mechanisms

### Mail System

Agents communicate through beads with `type=message`:

```
Addressing modes:
- Direct: mayor/, rig/witness
- Fan-out: @witnesses, @polecats/rig
- Queue: Any available agent claims
- Broadcast: List-based
```

Priority levels 0-4 affect processing order. Critical escalations before routine updates.

### Handoff Protocol

When context fills:

```
1. Agent executes /handoff
2. Work state persists to hook
3. New session spawns
4. New agent reads hook, continues
```

### Seance

Query previous sessions via `gt seance`:

```bash
gt seance --agent polecat-furiosa
# Returns decisions, context from prior sessions
```

---

## Comparison: Gas Town vs Ralph

| Aspect | Ralph Wiggum | Gas Town |
|--------|--------------|----------|
| **Scale** | Single agent, sequential | 20-30+ agents, parallel |
| **State** | Files (PRD.json, progress.txt) | Beads (SQLite + JSONL + Git) |
| **Loop** | External bash loop | Internal role hierarchy |
| **Coordination** | None needed (single agent) | Mayor/Witness/Refinery |
| **Isolation** | N/A | Git worktrees |
| **Recovery** | Start fresh | Resume via hooks |

Ralph externalized the inference loop to bash. Gas Town internalizes coordination while externalizing state to Git.

**They solve different problems**:
- Ralph: Context rot in single-agent sessions
- Gas Town: Coordination in multi-agent swarms

---

## Practical Challenges

From Justin Abrahms' experience:

### 1. Feeding the Engine

> "The system consumes implementation plans faster than humans can create them."

Gas Town's bottleneck is **work generation**, not execution. You need substantial upfront planning to keep agents productive.

### 2. Plate Spinning

Managing 9+ concurrent threads feels like cycling through tabs checking progress. Even with Gas Town, visibility across the swarm is challenging.

### 3. Change Friction Loss

Lower implementation costs risk unnecessary changes. Need strong stewardship to prevent churn.

### 4. Accountability

> "Sounds fun if you are accountable to nobody."

Vibe coding assumes errors are acceptable. Professional environments with quality requirements may struggle with the "some work gets lost" philosophy.

---

## Industry Context

From RedMonk's analysis:

> "Agents solve certain problems beautifully, but managing fleets of agents introduces coordination complexity."

Historical parallel:
- **Virtualization**: Physical machines → VMs (solved rigidity, created sprawl)
- **Microservices**: Monoliths → services (solved scaling, created mesh complexity)
- **Agents**: Single assistant → swarms (solves velocity, creates coordination chaos)

Gas Town is the first serious attempt at "Kubernetes for AI agents" - operational governance for unreliable workers.

---

## SAL-9000 Relevance

### What Gas Town Proves

| Insight | SAL Application |
|---------|-----------------|
| Role hierarchy works | SAL's Commander/Pod/Crew is validated |
| Git-native state is robust | SQLite + Git approach is sound |
| Fresh agents beat context accumulation | Pods/Crew as ephemeral workers |
| GUPP prevents stalls | CAPCOM should inject similar principles |
| Merge coordination is critical | SAL needs a Refinery equivalent |

### Architecture Mapping

| Gas Town | SAL-9000 |
|----------|----------|
| Town | Program |
| Rig | Mission |
| Mayor | SAL (Commander) |
| Witness | CAPCOM (monitoring aspect) |
| Refinery | Airlock + future merge layer |
| Polecat | Crew (workers) |
| Hook | SQLite `tasks` table |
| Convoy | Mission/Pod grouping |
| Bead | Task with status tracking |

### Key Patterns to Adopt

**1. GUPP Equivalent**

SAL's agents should have a propulsion principle:

```
If there is work assigned to you, execute it.
No waiting. No asking. Honor the assignment.
```

This prevents stalled subagents waiting for confirmation.

**2. Merge Coordination**

Gas Town uses the Refinery for sequential rebasing. SAL needs equivalent logic:
- Multiple crews working on same mission
- Sequential merge through CAPCOM or dedicated agent
- Conflict escalation to Pod or SAL

**3. Health Monitoring**

The Deacon/Dog pattern (watchdog for the watchdog) is clever. CAPCOM could:
- Run patrol cycles checking agent health
- Nudge stuck workers
- Escalate unresponsive agents

**4. Ephemeral by Default**

Polecats spawn, complete, disappear. SAL's Crew should follow the same pattern:
- Fresh context per task
- State persists in SQLite, not agent memory
- Clean up completed workers

**5. Mail-Based Coordination**

Gas Town's message system with addressing modes is more sophisticated than SAL's current `messages` table. Consider:
- Priority levels for processing order
- Fan-out addressing (@all-pods)
- Queue-based claiming for available workers

### What SAL Already Has

| Capability | SAL Implementation |
|------------|-------------------|
| Fresh subagents | Pods/Crew |
| Persistent state | SQLite coordination |
| Context filtering | CAPCOM |
| Quality gates | Airlock |
| Role hierarchy | Commander/Pod/Crew |

### Gaps to Address

1. **Merge coordination** - No Refinery equivalent for parallel crews
2. **Watchdog recursion** - No "Dog" monitoring CAPCOM
3. **Propulsion principle** - No GUPP-like forcing function
4. **Git worktree isolation** - Crews share workspace currently
5. **Formula/molecule workflows** - No reusable workflow templates

---

## Summary

Gas Town synthesizes three patterns:

| Pattern | Gas Town Implementation |
|---------|------------------------|
| Ralph (fresh context) | Ephemeral polecats, handoff protocol |
| Superpowers (skill injection) | GUPP, role-specific behaviors |
| Beads (persistent state) | Git-native work tracking |

The core insight: **Agents are infrastructure, not assistants.** Managing agent fleets requires the same rigor as managing Kubernetes clusters - role hierarchies, health monitoring, state persistence, and coordination protocols.

SAL-9000 already has much of this architecture. Gas Town validates the approach and reveals refinements: propulsion principles, merge coordination, watchdog recursion, and sophisticated message routing.

> "The question isn't whether to orchestrate agents. It's whether to do it manually or build systems that do it for you."

Gas Town chooses systems. SAL-9000 should too.
