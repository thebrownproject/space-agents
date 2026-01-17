# Space-Agents Plans Inventory Analysis

**Analysis Date:** 2026-01-17
**Participants:** HOUSTON F-Thread (Research, Architecture, Risk agents)
**Goal:** Inventory check - understand what's documented vs what's missing

---

## Documents Inventory

**Location:** `/Users/fraserbrown/Documents/space-agents/docs/plans/`

| # | Document | Title | Status | Purpose |
|---|----------|-------|--------|---------|
| 1 | `SPACE-AGENTS-DESIGN.md` | Core Framework Design | Complete | Foundational design - NASA hierarchy, computing model, research foundations |
| 2 | `2026-01-16-space-agents-plugin-design.md` | Plugin Design | Phase 1 Complete | Full plugin spec - skills, agents, scripts, 4-phase roadmap |
| 3 | `2026-01-16-architecture-refactor.md` | Architecture Refactor | 8/9 Tasks Done | Refactor checklist - 1 remaining: "Test full flow" |
| 4 | `HANDOVER-2026-01-16.md` | Session Handover | Reference | Context dump from Phase 1 completion session |
| 5 | `2026-01-16-f-thread-planning-architecture.md` | F-Thread Architecture | Design Phase | Two-tier system design (F-Thread + Ralph) |
| 6 | `2026-01-16-brainstorming-forward-deployed-fthread.md` | Brainstorming F-Thread | Design Phase | Forward-deployed parallel agents for brainstorming |
| 7 | `2026-01-16-planning-forward-deployed-fthread.md` | Planning F-Thread | Design Phase | Forward-deployed parallel agents for planning |

---

## Implementation Status

### Phase 1: Core MVP (95% Complete)

**Implemented:**
- [x] Plugin structure (`plugin.json`, skills/, agents/)
- [x] SQLite schema (voyages, missions, objectives, messages, alerts)
- [x] `/install` - Creates `.space-agents/` directory and database
- [x] `/launch` - Session start with HOUSTON persona
- [x] `/dock` - Session end with CAPCOM logging
- [x] HOUSTON persona (embedded in `/launch` skill)
- [x] Ralph loop (`skills/mission/scripts/ralph.sh` - 522 lines)
- [x] Pod orchestration (spawns Worker/Inspector/Analyst)
- [x] Airlock validation (`skills/airlock/`)

**Missing:**
- [ ] Hooks configuration (`hooks.json`) - notification flow broken
- [ ] Notification scripts (`notify.sh`, `check-notifications.sh`, `on-agent-complete.sh`)

### Phase 2: Planning & Status (100% Documented, Skills Exist)

**Implemented:**
- [x] `/brainstorming` - Forward-deployed F-Thread exploration
- [x] `/planning` - Mission/objective breakdown
- [x] `/capcom` - Status reporting via subagent
- [x] `/handover` - Mid-session context dump

### Phase 3: Alerts & Notifications (50% Complete)

**Implemented:**
- [x] Alert schema in SQLite (severity levels 0-3)
- [x] Alert creation in Ralph loop
- [x] `/capcom` displays alerts

**Missing:**
- [ ] Hooks for in-session notification pickup
- [ ] macOS notification integration
- [ ] Hook-based alert escalation

### Phase 4: Polish (10% Complete)

**Implemented:**
- [x] Basic documentation in CLAUDE.md

**Missing:**
- [ ] `/maintenance` skill - archive/cleanup
- [ ] `/dock --compress` - CAPCOM log compression
- [ ] Launch UI improvements
- [ ] Comprehensive documentation

---

## Agents Inventory

**Location:** `/Users/fraserbrown/Documents/space-agents/agents/`

| Agent File | Used By | Purpose |
|------------|---------|---------|
| `mission-pod.md` | Ralph loop | Orchestrates crew for single objective |
| `mission-worker.md` | Pod | Implements code changes |
| `mission-inspector.md` | Pod | Reviews against requirements |
| `mission-analyst.md` | Pod | Reviews code quality |
| `brainstorming-research.md` | `/brainstorming` | Explores codebase for patterns |
| `brainstorming-architecture.md` | `/brainstorming` | Proposes architectural approaches |
| `brainstorming-risk.md` | `/brainstorming` | Identifies risks and estimates effort |
| `planning-task-planner.md` | `/planning` | Breaks feature into missions/objectives |
| `planning-sequencer.md` | `/planning` | Sequences missions, identifies dependencies |
| `planning-implementer.md` | `/planning` | Creates detailed TDD task breakdown |

**Note:** `houston.md` is missing - HOUSTON persona is embedded in `/launch` SKILL.md

---

## Key Decisions Documented

| Decision | Choice | Reference |
|----------|--------|-----------|
| Installation method | Plugin install via marketplace | Plugin design line 19 |
| Project structure | Everything in `.space-agents/` | Plugin design line 21 |
| Session management | Explicit `/launch` and `/dock` | Plugin design line 22 |
| HOUSTON role | Plans, coordinates, never codes | SPACE-AGENTS-DESIGN lines 48-57 |
| Pod orchestration | Pod is orchestrator (no separate Commander) | SPACE-AGENTS-DESIGN line 81 |
| Memory system | 3-tier (staging/CAPCOM/SQLite) | Plugin design lines 206-213 |
| Script distribution | Embedded in skills (not separate files) | Architecture refactor lines 11-12 |
| Planning architecture | Two-tier: F-Thread for planning, Ralph for execution | F-Thread architecture lines 12-15 |
| Agent spawning | Forward-deployed (ahead of conversation) | Brainstorming F-Thread lines 32-34 |

---

## Gaps Analysis

### Category 1: Documented but Not Implemented

| Component | Documented In | Severity | Effort |
|-----------|---------------|----------|--------|
| `/maintenance` skill | Plugin design line 73 | Medium | 2-3 hours |
| Hooks configuration | Plugin design lines 97-125 | High | 2-4 hours |
| Notification scripts | Plugin design lines 86-88 | Medium | 1-2 hours |
| CAPCOM compression | Plugin design line 214, 574 | Low | 2-3 hours |

### Category 2: Naming Inconsistencies

| Location | Says | Should Be |
|----------|------|-----------|
| Docs | `/mission-run` | `/mission` (actual) |
| Docs | `pod.md` | `mission-pod.md` (actual) |
| Docs | `worker.md` | `mission-worker.md` (actual) |

### Category 3: Missing Design Details

| Area | Gap | Risk |
|------|-----|------|
| Error Recovery | No rollback procedures documented | Medium |
| Git Worktrees | Phase 2 mentioned but no detailed design | Low (future) |
| Multi-User | No concurrent session handling | Medium |
| Cost Management | No budget controls for F-Threading | High |
| Testing | No test suite for skills | Medium |

---

## Updates

### 2026-01-17: /brainstorming Skill Redesigned

The `/brainstorming` skill was completely rewritten based on this session's feedback:

**Old pattern (broken):**
- Spawn 3 agents immediately
- Ask 1 question
- Dump results as report

**New pattern (conversational):**
- Multi-round dialogue (5-10 rounds)
- Suggest agents when useful, don't auto-spawn
- Agents run in background while conversation continues
- Weave in results naturally
- HOUSTON guides with opinions
- Natural endings, documentation optional

See: `skills/brainstorming/SKILL.md`

---

## Recommended Actions

### Immediate (Before Production Use)
1. Implement hooks system for notifications
2. Create `/maintenance` skill for cleanup
3. Standardize command naming in documentation

### Short-Term (1-2 Weeks)
1. Add cost estimation/warnings to brainstorming
2. Document error recovery procedures
3. Add basic integration tests

### Medium-Term (Phase 2)
1. Design git worktree integration in detail
2. Add session ID for multi-user support
3. Consider metrics/observability

---

## Next Steps

1. Run `/planning` to break gap-closing work into missions
2. Prioritize hooks implementation (blocks notification flow)
3. Consider creating a "Documentation Cleanup" voyage

---

**Generated by:** HOUSTON F-Thread Brainstorming Session
**Agents Used:** Research, Architecture, Risk
