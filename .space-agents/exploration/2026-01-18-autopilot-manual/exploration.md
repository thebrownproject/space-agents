# Exploration: Autopilot & Manual Modes

**Date:** 2026-01-18
**Status:** Ready for implementation

---

## Overview

Two complementary operating modes that complete the Space-Agents control spectrum:

| Mode | Metaphor | Description |
|------|----------|-------------|
| **Missions** | Flight plan | Structured work with objectives and Ralph loop |
| **Manual** | Hands on stick | User-directed work without mission overhead |
| **Autopilot** | Cruise control | Autonomous agents working while you're away |

---

## Feature 1: `/manual` - Manual Mode

### Purpose
Lightweight coding without mission ceremony. For quick fixes, experimentation, and user-guided work.

### Entry/Exit

| Action | Command |
|--------|---------|
| Enter manual mode | `/manual` |
| Exit to dock | `/dock` |
| Switch to missions | `/mission-brief` or `/mission-go` (auto-switches) |

### Characteristics

- **No missions/objectives** - Work isn't tracked in mission structure
- **HOUSTON as copilot** - Same personality, but follows user's lead instead of directing
- **Light logging** - Session summary saved to CAPCOM on exit (same as normal `/dock`)
- **Optional guardrails** - User can run `/airlock` but it's not automatic

### Escalation

If work grows complex, HOUSTON offers: "This is getting involved - want to plan this as a mission?"

### Use Cases

- Quick bug fixes
- Config changes
- Experimentation/prototyping
- User wants to direct Claude step-by-step
- Any work that doesn't need mission overhead

---

## Feature 2: `/autopilot` - Autonomous Agents

### Purpose
Agents work overnight (or while you're away) running analysis, generating findings, and drafting missions. You wake up to a briefing, not a blank slate.

### The Vision

> "What if you could get a swarm of agents to rip through your codebase and make suggestions for features, or do a code review every morning before you get to work?"

Key insight: **Read-only autonomy is safe autonomy**. Agents analyze and suggest, but never change production code.

### What Autopilot Produces

| Output Type | Description |
|-------------|-------------|
| **Feature suggestions** | Ideas for improvements based on codebase analysis |
| **Code reviews** | Quality, security, performance findings |
| **Draft missions** | Pre-planned missions ready for approval |
| **Tech debt inventory** | Catalogued and prioritized debt |
| **Test gap analysis** | Untested code paths, suggested test cases |
| **Dependency health** | Security vulns, outdated packages |
| **Documentation drafts** | Generated docs for undocumented code |
| **Architecture drift** | Patterns that have diverged from standards |
| **Dead code detection** | Unused exports, orphaned files |
| **Learning suggestions** | "This pattern could benefit from X" |

### Execution Model

Autonomous work uses the **full Ralph loop / agent swarm machinery**, but outputs findings instead of code changes.

Configurable analysis types:
- "Run code review swarm nightly"
- "Run feature discovery loop weekly"
- "Run tech debt analysis on Mondays"

### Runtime: Hybrid Approach

| Environment | Use Case |
|-------------|----------|
| **CI/CD (GitHub Actions)** | Scheduled overnight runs while machine is off |
| **Local (cron/launchd)** | On-demand "deep analysis while I'm at lunch" |

**CI/CD → Local sync:**
1. GitHub Action runs on schedule (e.g., 2am)
2. Writes findings to `.space-agents/briefings/`
3. Commits directly to main branch
4. When you `git pull` and `/launch`, findings are there

### Morning Briefing UX

**Step 1: Dashboard on `/launch`**
```
┌────────────────────────────────────────────────────────────────┐
│  OVERNIGHT BRIEFING                                            │
│  3 feature ideas | 2 security findings | 1 draft mission       │
│  Run /briefing to review                                       │
└────────────────────────────────────────────────────────────────┘
```

**Step 2: `/briefing` command**
- HOUSTON walks you through findings interactively
- Discuss each finding
- Triage: accept to backlog, dismiss, or act now

### Findings Lifecycle

```
Autonomous run produces findings
    ↓
Findings stored in .space-agents/briefings/<date>/
    ↓
User runs /briefing
    ↓
Triage: Accept → Backlog | Dismiss | Act now
    ↓
Backlog items pulled into missions when ready
```

**Retention:** Findings accumulate forever (cleanup mode TBD later)

### Configuration: `/autopilot-setup`

Interactive setup command:
1. Which analysis types to run (from templates or custom)
2. Schedule (nightly, weekly, specific days)
3. Resource limits (time caps per analysis)

### Templates

Ship predefined templates:
- `nightly-review` - Code quality scan
- `weekly-features` - Feature/improvement ideas
- `monday-tech-debt` - Technical debt inventory
- Custom templates supported

### Containment

**Convention-based:** Agents instructed to only read code and write to findings directory. No technical sandboxing in v1.

The `.space-agents/briefings/` directory is the safe zone for autonomous output.

### Resource Limits

Time-based limits per analysis type:
- Nightly review: 30 mins
- Feature discovery: 1 hour
- Deep analysis: 2 hours

Token/cost limits: Future refinement

### Notifications

None in v1. Findings wait in `.space-agents/briefings/` until you `/launch`.

---

## How Modes Interact

```
┌─────────────────────────────────────────────────────────────┐
│                    Space-Agents Modes                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   /autopilot ──────► .space-agents/briefings/               │
│   (overnight)              │                                 │
│                            ▼                                 │
│                      /briefing ──────► Backlog              │
│                                           │                  │
│                                           ▼                  │
│   /manual ◄─────────────────────► /mission-brief            │
│   (hands-on)                      (planning)                │
│        │                              │                      │
│        │                              ▼                      │
│        │                        /mission-go                  │
│        │                        (execution)                  │
│        │                              │                      │
│        └──────────────────────────────┘                      │
│              (can switch between modes)                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Structures

### Briefings Directory
```
.space-agents/briefings/
├── 2026-01-18-nightly-review/
│   ├── summary.md
│   ├── findings/
│   │   ├── security-001.md
│   │   ├── performance-002.md
│   │   └── ...
│   └── draft-missions/
│       └── refactor-auth-flow.md
├── 2026-01-15-feature-discovery/
│   └── ...
└── backlog.md  # Accepted findings awaiting action
```

### Autopilot Config
```yaml
# .space-agents/autopilot.yaml
schedules:
  - name: nightly-review
    template: code-review
    cron: "0 2 * * *"  # 2am daily
    timeout: 30m

  - name: weekly-features
    template: feature-discovery
    cron: "0 3 * * 1"  # 3am Mondays
    timeout: 60m

custom_templates:
  - name: security-audit
    objectives:
      - "Scan for OWASP Top 10 vulnerabilities"
      - "Check dependency security advisories"
      - "Review authentication flows"
```

---

## GitHub Actions Integration

Example workflow for overnight runs:

```yaml
# .github/workflows/space-agents-autopilot.yml
name: Space Agents Autopilot

on:
  schedule:
    - cron: '0 2 * * *'  # 2am UTC daily
  workflow_dispatch:  # Manual trigger

jobs:
  nightly-review:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Run Space Agents Analysis
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          npx claude-code --autopilot-run nightly-review

      - name: Commit Findings
        run: |
          git config user.name "Space Agents"
          git config user.email "autopilot@space-agents"
          git add .space-agents/briefings/
          git commit -m "chore: autopilot findings $(date +%Y-%m-%d)" || true
          git push
```

---

## Open Questions

1. **Backlog management** - How do backlog items get prioritized and pulled into missions?
2. **Finding deduplication** - How to handle similar findings across multiple runs?
3. **Template customization** - What's the format for custom analysis templates?
4. **Cost tracking** - Should autopilot track/report API costs per run?

---

## Next Steps

When ready to implement:
1. Start with `/manual` - simpler, immediate value
2. Then `/autopilot-setup` and local execution
3. Then CI/CD integration
4. Then `/briefing` interactive triage

Consider: `/manual` could ship in next release, `/autopilot` as a later milestone.
