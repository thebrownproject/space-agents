```
███████╗██████╗  █████╗  ██████╗███████╗
██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
███████╗██████╔╝███████║██║     █████╗
╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝
███████║██║     ██║  ██║╚██████╗███████╗
╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝
         █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗
        ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔════╝
        ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ███████╗
        ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
        ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████║
        ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
```

Agent orchestration plugin for Claude Code, powered by [Beads](https://github.com/steveyegge/beads) and the [Ralph loop](https://ghuntley.com/ralph/).

## Features

- **Multi-session persistence** - Beads tracks issues, dependencies, and context across sessions
- **Structured exploration** - Brainstorm ideas, create plans, review code, debug issues
- **Agent orchestration** - Solo (direct), Orchestrated (agents per task), or Ralph loop (background automation)
- **Session logging** - CAPCOM log preserves decisions and progress for future sessions

## Prerequisites

- [Beads CLI](https://github.com/steveyegge/beads) (`npm install -g beads-cli`)
- Optional: [mprocs](https://github.com/pvolok/mprocs) (`npm install -g mprocs`) for watching Ralph loop live

## Install

**1. Add the plugin (in Claude Code):**

```
/plugin marketplace add thebrownproject/space-agents
/plugin install space-agents@thebrownproject-space-agents
```

**2. Initialize in your project:**

```
/install
```

This creates the `.space-agents/` directory structure and initializes Beads for issue tracking. Run once per project.

## Workflow

```
/launch → /exploration → /mission → /land
```

| Command | Purpose |
|---------|---------|
| `/launch` | Start session, see project status |
| `/exploration` | Brainstorm, plan, review, or debug |
| `/mission` | Execute work from Beads |
| `/land` | End session, save context to CAPCOM |

## Exploration Modes

| Mode | Output |
|------|--------|
| `brainstorm` | Ideas and analysis in `exploration/ideas/` |
| `plan` | Implementation plans in `exploration/planned/` |
| `review` | Code review findings as Beads |
| `debug` | Investigation results as Beads |

## Mission Modes

| Mode | Best for |
|------|----------|
| `solo` | Small work (1-3 tasks) - HOUSTON executes directly |
| `orchestrated` | Medium work (4-10 tasks) - Agent per task |
| `ralph` | Large work (10+ tasks) - Background automation |

## Multi-Agent Execution

In `orchestrated` and `ralph` modes, each task is executed by a 3-agent crew:

```
Pathfinder → Builder → Inspector
```

| Agent | Role |
|-------|------|
| **Pathfinder** | Explores codebase, gathers context, identifies patterns and risks |
| **Builder** | Implements the task using TDD approach |
| **Inspector** | Two-pass review: requirements verification, then quality/patterns/security |

The Ralph loop spawns these as **Pods** - fresh context each iteration, looping until all tasks complete or a blocker halts execution. When issues are found, bugs are inserted into Beads as blockers; Ralph resolves these before continuing to the next task.
