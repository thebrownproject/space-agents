# Space-Agents Roadmap

*Living document tracking features, priorities, and future vision.*

**Last Updated:** 2026-01-18
**Version:** 1.0.17

---

## Priority Legend

| Priority | Meaning |
|----------|---------|
| **P0** | Do next |
| **P1** | High value, near-term |
| **P2** | Medium priority |
| **P3** | Future phases |

---

## P0 - Do Next

### `/manual` - Manual Mode

**Status:** Explored, ready to implement
**Exploration:** `2026-01-18-autopilot-manual/exploration.md`

Escape hatch from mission ceremony. Quick fixes, experimentation, user-directed coding.

| Aspect | Design |
|--------|--------|
| Entry | `/manual` command |
| Exit | `/dock` or auto-switch via `/mission-brief`, `/mission-go` |
| HOUSTON role | Helpful copilot, follows user's lead |
| Tracking | Light - CAPCOM summary on exit, no missions/objectives |
| Guardrails | Optional `/airlock` |
| Escalation | HOUSTON offers to create mission if work grows |

**Why P0:** Simplest new feature, immediate value, completes the control spectrum.

---

## P1 - High Priority

### `/code-review` - Code Review Skill

**Status:** Explored, ready to implement
**Exploration:** `2026-01-18-review-debug/exploration.md`

Review code quality with agent swarms. Post-mission or on-demand.

| Aspect | Design |
|--------|--------|
| Triggers | Auto-suggest after `/mission-go` + on-demand anytime |
| Targets | Codebase sections, recent features, mission handovers |
| Execution | Agent swarm - aspect reviewers (security, performance, maintainability) |
| Output | Review report → conversation → fix now / create alerts / do nothing |

**Why P1:** Quality feedback loop. Catches issues before they accumulate.

---

### `/debug` - Systematic Debugging Skill

**Status:** Explored, ready to implement
**Exploration:** `2026-01-18-review-debug/exploration.md`

Structured debugging integrated with alerts system.

| Aspect | Design |
|--------|--------|
| Entry | Show active alerts + choose: fix existing / report new bug |
| Process | Brainstorm to gather info → choose executor |
| Execution | HOUSTON / subagent / agent swarm (strategy based on bug type) |
| Swarm strategies | Component focus, parallel hypotheses, research swarm |
| Integration | Updates alerts, optional escalation to mission |

**Why P1:** Systematic > random fixes. Builds on existing alerts infrastructure.

---

## P2 - Medium Priority

### `/autopilot` - Autonomous Overnight Agents

**Status:** Explored, needs more design
**Exploration:** `2026-01-18-autopilot-manual/exploration.md`

Agents work while you sleep. Wake up to findings, not a blank slate.

| Aspect | Design |
|--------|--------|
| Output | Feature suggestions, code reviews, draft missions, tech debt inventory |
| Runtime | Hybrid - CI/CD for overnight, local for on-demand |
| Storage | `.space-agents/briefings/` (direct commit to main) |
| UX | Dashboard on `/launch` → `/briefing` for interactive triage |
| Config | `/autopilot-setup` with templates (nightly-review, weekly-features) |

**Why P2:** High value but complex. Needs CI/CD integration, more moving parts.

---

### `/maintenance` - System Cleanup

**Status:** Empty folder exists, no SKILL.md

| Capability | Description |
|------------|-------------|
| Archive completed missions | Move old missions to archive |
| Cleanup empty folders | Remove empty directories |
| Database maintenance | Vacuum, integrity checks |
| Log rotation | Archive old CAPCOM entries |

**Why P2:** Nice-to-have. Manual cleanup works for now.

---

## P3 - Future Phases (Gas Town Evolution)

These are patterns from Gas Town and Beads to adopt as Space-Agents scales.

### Parallel Execution

| Item | Description |
|------|-------------|
| Git worktrees | File isolation for parallel Pods |
| Refinery | Merge queue, sequential rebasing |
| Parallel Ralph | Multiple instances via mprocs |
| Hash-based IDs | Multi-agent collision safety (Beads pattern) |

**When needed:** When sequential execution feels slow for large missions.

---

### Dependency Tracking (Beads Pattern)

| Item | Description |
|------|-------------|
| `depends_on` column | Track which objectives block others |
| Ready-state query | `SELECT * FROM objectives WHERE unblocked` |
| Smarter Ralph | Pick any ready objective, not just next sequential |

**When needed:** Prerequisite for parallel execution. Sequential works fine until then.

**Reference:** `docs/research/yegge-beads.md` - ready-state semantics

---

### Health Monitoring

| Item | Description |
|------|-------------|
| Witness | Pod health monitoring, detect stuck agents |
| Deacon | System health daemon, patrol cycles |
| Dog | Watchdog for the watchdog |

**When needed:** When running many parallel agents. Overhead until then.

---

### Advanced Workflows (MEOW)

| Item | Description |
|------|-------------|
| Molecules | Chained workflow templates |
| Handoff Protocol | Context-full mid-task session swap |
| Sophisticated Mail | Priority queues, fan-out, claiming |

**When needed:** When missions/objectives pattern feels limiting.

**Reference:** `docs/research/yegge-gastown.md` - MEOW patterns

---

## Completed

### Phase 1 Core (v1.0.x)

- [x] `/install` - Project setup, SQLite init
- [x] `/launch` - Session start, HOUSTON persona, dashboard
- [x] `/dock` - Session end, CAPCOM logging, logout screen
- [x] `/exploration` - Conversation-first idea exploration
- [x] `/mission-brief` - Mission planning with F-Thread agents
- [x] `/mission-go` - Ralph loop execution (bash + mprocs)
- [x] `/pod` - Objective execution (Worker/Inspector/Analyst)
- [x] `/airlock` - Test/lint validation gate
- [x] `/capcom` - Status check via subagent
- [x] `/handover` - Mid-session context dump
- [x] SQLite schema - voyages, missions, objectives, alerts, messages
- [x] CAPCOM selective loading - grep-based in `/launch`, SQLite in `/capcom`
- [x] 3-tier memory - staging (session) / CAPCOM (permanent) / SQLite (queryable)
- [x] mprocs integration - visible mode for Pod execution

### Solved Differently

| Concept | Original Idea | How We Solved It |
|---------|---------------|------------------|
| GUPP (propulsion) | Force agents to never stop | Ralph loop spawns fresh agents |
| Context death | Agent hits token limit | Ephemeral Pods, state in SQLite |
| Session boundaries | Clean exit protocol | `/handover` + `/dock` |
| tmux orchestration | Session-per-agent | mprocs already integrated |

---

## Architecture Comparison

### Space-Agents vs Beads

| Beads | Space-Agents | Notes |
|-------|--------------|-------|
| SQLite + JSONL + Git | SQLite only | Simpler - single user, not distributed |
| Hash-based IDs | Sequential IDs | Only matters for parallel multi-agent |
| `bd ready` (unblocked tasks) | Sequential by order | P3 - when parallel added |
| `bd compact` (memory decay) | Grep-based selective loading | Similar outcome |
| Epics/Tasks/Subtasks | Missions/Objectives | Same hierarchy |
| Comments/Events | Messages table | Same pattern |

**Verdict:** Space-Agents is a simplified Beads. Core benefit (queryable state) without distributed complexity.

---

## Research Foundation

| Pattern | Source | What We Use |
|---------|--------|-------------|
| **Ralph Wiggum** | Geoffrey Huntley | Fresh sessions via bash loop |
| **Superpowers** | Jesse Vincent | Skill injection, forcing functions |
| **Beads** | Steve Yegge | SQLite state, queryable work items |
| **Gas Town** | Steve Yegge | Role hierarchy, future parallel patterns |

**Full research:** `docs/research/`

---

## Implementation Order

```
Now:     /manual (P0)
Next:    /code-review, /debug (P1)
Later:   /autopilot, /maintenance (P2)
Future:  Parallel execution, dependency tracking (P3)
```

---

*Vision reference: `2026-01-17-gas-town-vision/exploration.md`*
