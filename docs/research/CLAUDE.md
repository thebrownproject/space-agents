# Research Collection

Reference material gathered for SAL-9000 development. Each folder documents a pattern or system relevant to agent orchestration.

## Files

### ghuntley-ralph-wiggum-loop.md
**Problem solved**: Context rot (LLM effectiveness degrades as context fills)

Fresh context windows via bash loop. Each task runs in a new Claude session - state persists in files (PRD.json, progress.txt), context stays at 0 tokens. Key insight: externalize the inference loop to bash, reset between tasks.

**Key patterns**: Kanban over dependency graphs, one goal per iteration, attended→unattended progression, backpressure via tests/lint.

### obra-superpowers.md
**Problem solved**: Behavioral drift (agent skips verification, makes assumptions)

Skill injection via SKILL.md files. Claude checks for relevant skills before every action - mandatory checkpoints that block rationalizations. Skills cascade to subagents.

**Key patterns**: Three-agent review (Implementer→Spec Reviewer→Quality Reviewer), TDD iron law, discipline-enforcing skills tested under pressure scenarios.

### yegge-beads.md
**Problem solved**: Context amnesia (every session starts fresh, no memory)

Persistent queryable state via SQLite + Git. Addressable work items with IDs, priorities, explicit dependencies. `bd ready` returns only unblocked tasks - query what's needed instead of loading everything.

**Key patterns**: Hash-based IDs for multi-agent safety, Land the Plane protocol, memory decay via compaction, three-layer architecture (CLI→SQLite→JSONL+Git).

### yegge-gastown.md
**Problem solved**: Swarm coordination (managing 20-30+ parallel agents)

Multi-agent orchestration via role hierarchy + tmux + Beads. Agents coordinate through Git-native state, not direct calls. The Mayor orchestrates, Witness monitors, Refinery merges, Polecats execute.

**Key patterns**: GUPP (propulsion principle), MEOW (molecular workflows), Git worktree isolation, mail-based routing, ephemeral workers, watchdog recursion (Dog monitors Deacon).

### tmux-orchestration.md
**Problem solved**: Session ephemerality (agents die when terminal closes, no real-time visibility)

Terminal multiplexer as infrastructure for agent swarms. Each agent runs in a named tmux session that persists across disconnects. Orchestrator can spawn sessions, capture output, send input, and monitor state - all without the agents knowing they're being managed.

**What tmux provides**:
- **Persistence**: Sessions survive terminal close, SSH drops, system sleep
- **Multiplexing**: Multiple agents run in parallel, each in isolated sessions
- **Observability**: Capture pane output in real-time without interrupting the agent
- **Control**: Send keystrokes to sessions programmatically
- **Organization**: Named sessions, windows, and panes create clear hierarchy

**Key patterns**:

| Pattern | Description |
|---------|-------------|
| Session-per-agent | Each agent gets `tmux new-session -d -s agent-name` |
| Output capture | `tmux capture-pane -t session -p` reads without interrupting |
| Input injection | `tmux send-keys -t session "command" Enter` for guidance |
| State polling | Check if agent is idle, running, or waiting for input |
| Detach/reattach | Human can attach to any agent session to observe or intervene |

**Existing tools**:
- **claunch**: Project-based Claude CLI manager with tmux, auto-resumes sessions
- **agent-of-empires**: Rust TUI for spawning/monitoring agent sessions
- **tmux-mcp-server**: MCP server giving AI direct tmux control
- **Tmux Session Orchestrator**: Claude skill for tmux automation

**Why it matters for orchestration**: The Task tool spawns subagents that return results and die. tmux spawns agents that persist, can be monitored in real-time, and survive the orchestrator itself. Combined with file/SQLite coordination, you get agents that are both autonomous and observable.

### sal-v2-pattern-comparison.md
**Purpose**: How SAL-9000 v2 incorporates (or defers) each research pattern

Systematic comparison showing what was adopted, what was simplified, and what was intentionally skipped. Includes grades for each pattern and gap analysis.

**Key finding**: SAL v2 is Ralph + hierarchical subagents + SQLite coordination. Gets fresh context AND structure by putting the hierarchy INSIDE the Ralph loop.

---

## How They Combine

| Pattern | Mechanism | When |
|---------|-----------|------|
| Ralph | Fresh sessions | Between tasks |
| Superpowers | Skill checkpoints | Within sessions |
| Beads | Persistent state | Across sessions |
| Gas Town | Role hierarchy + merge coordination | Multi-agent swarms |
| tmux | Session persistence + real-time monitoring | Agent infrastructure |

**The synthesis**: Gas Town combines all three patterns into a production orchestration system. Polecats are Ralph-style fresh sessions. GUPP is a Superpowers-style forcing function. Beads provides the persistent state layer. The role hierarchy (Mayor/Witness/Refinery) adds what the others lack: coordination at scale.

SAL-9000 integration:
- **Pods/Crew** = fresh context (Ralph) + ephemeral polecats (Gas Town) + persistent sessions (tmux)
- **CAPCOM** = skill injection (Superpowers) + message routing (Gas Town mail)
- **SQLite** = dependency tracking (Beads) + hook-based assignment (Gas Town)
- **Airlock** = quality gates (Ralph backpressure) + merge coordination (Gas Town Refinery)
- **Infrastructure** = tmux sessions enable real-time monitoring, output capture, and human intervention
- **Future**: GUPP-style propulsion, watchdog recursion, Git worktree isolation
