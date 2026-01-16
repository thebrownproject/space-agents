# Loom: Infrastructure for Autonomous Software Development

**Source:** Jeff Huntley livestream (2025-01-16)
**Context:** Creator of Ralph Wiggum technique reveals Loom project
**Relevance:** Infrastructure layer beneath Space-Agents orchestration

---

## Executive Summary

Jeff Huntley (creator of Ralph Wiggum) revealed **Loom** - a GitHub replacement designed for autonomous agents first, humans second. While Loom builds infrastructure (remote execution, networking, secrets), Space-Agents builds orchestration (planning, coordination, mission control). These are complementary layers.

**Key validation:** Our forward-deployed F-Threading, thread/audit patterns, and meta-loop concepts align with Loom's architecture. We're on the right path.

---

## What Loom Is

> "We can reimagine the last 40 years of computing and design it around autonomous agents first, humans second. But to do that, we are going to need to redesign the whole damn stack."
> — Jeff Huntley

**Loom = Agent-first development infrastructure**

**Core Components:**

| Component | Purpose |
|-----------|---------|
| **Weavers** | Agents that run remotely (Kubernetes pods) |
| **Threads** | Audit trails / saved context windows |
| **Spool** | Forked JJ source control (next-gen git) |
| **Remote Infrastructure** | E2B-style execution (reimplemented from scratch) |

**Built in 3 days** using Ralph Wiggum technique over New Year's Eve 2024.

---

## Core Concepts

### 1. Weavers (Agents)

**Weaver = Remote execution environment for agents**

**Two meanings:**
1. **Remote pod** - Kubernetes container running agent workload
2. **CLI tool** - Command-line interface for controlling agents

**Features:**
- Provision on-demand via API
- Full eBPF instrumentation (every syscall logged)
- Wireguard networking (connect via Tailscale DERP maps)
- SSH access for rescue operations
- Cross-platform CLI (Mac, Linux, Windows, all CPU architectures via Zig)

**Example:**
```bash
# Create remote weaver
loom weaver create

# SSH into running weaver
loom weaver ssh <id>

# Port forward from weaver to local machine
loom weaver port-forward <id> 8080:8080

# Destroy weaver
loom weaver delete <id>
```

### 2. Threads (Audit Trails)

**Thread = Saved context window + execution history**

> "Would it be great if you could just save that context window and reuse it? Threads."

**Purpose:**
- Audit trail of everything agent did
- Reusable context for other agents
- Troubleshooting (share thread with support)
- Meta-loops (Agent B reads Agent A's thread)

**Example workflow:**
```
Weaver A: Implements feature → Saves thread
Weaver B: Reads Weaver A's thread → Continues work
Weaver C: Reads both threads → Verifies both
```

**This is Space-Agents' staging.md/capcom.log concept.**

### 3. Spool (Source Control)

**Spool = Forked JJ with agent-first design**

- Based on Jujutsu (next-gen git alternative)
- Developed by Google/Meta engineers
- Loom forked it to add sync protocol
- No backward compatibility constraints

> "There is no limits to what I will fork to achieve this goal."

**Eventually:** Loom won't be on GitHub. View source code IN Loom itself.

---

## The Three Ralph Modes

**Jeff revealed Ralph Wiggum has three operational modes:**

### Mode 1: Forward (Build from Specs)
```
PRD → Generate specs → Ralph loop → Implementation
```

**Known pattern.** Building new features from requirements.

### Mode 2: Reverse (Clone Systems)
```
Existing system → Analyze → Ralph loop → Clone/document
```

**Known pattern.** Reverse engineering and analysis.

### Mode 3: Testing (System Verification) ⭐ NEW
```
System → Generate test plan → Ralph loop executes tests → Verify → Report
```

**NEW INSIGHT:**

> "I want you to come up with a plan that tests all the loom server API endpoints... Write the test plan as bullet points... Run via curl and CLI... Check logs before and after changes."

**Process:**
1. Agent generates test plan (markdown with bullet points)
2. Agent executes tests via curl/CLI
3. Agent checks server logs BEFORE changes
4. Agent makes changes (if needed, like adding logging)
5. Agent checks server logs AFTER changes
6. Agent diffs logs to identify issues
7. Agent updates test plan with results

**Permission granted:** Deploy server, add temporary logging, troubleshoot.

**Result:** Full system verification without manual clicking.

---

## Infrastructure Patterns

### 1. NixOS for Declarative Infrastructure

**Everything defined declaratively:**

```nix
services.fail2ban.enable = true;

services.loom = {
  enable = true;
  secrets = {
    apiKey = "/run/secrets/loom-api-key";
  };
};
```

**Benefits:**
- Same definition builds Docker image, VM, bare metal
- Reproducible deployments
- Only safe way to run agents with sudo (permission system)

**Auto-deploy script:**
- Git pull every 10 seconds
- Rebuild NixOS config
- Zero downtime switchover
- Push to main → deployed in 10 seconds

### 2. SOPS Secrets Management

**SOPS = Secrets encrypted with host SSH key**

```yaml
# loom.yaml (encrypted)
ANTHROPIC_API_KEY: ENC[...]
DATABASE_URL: ENC[...]
```

- Encrypted in repo
- Decrypted on host using host SSH key
- Useless without SSH key access
- Automatic provisioning on deploy

**Jeff's attitude:**
> "Let's have a look at my secrets. If you manage to break SOPS encryption, I have bigger problems. Plus, they're just vanilla API keys with spending caps."

### 3. Bare Metal Philosophy

**Reject cloud horizontal scaling:**

> "You can buy a bare metal machine now for $1,500/month with 192 cores and terabytes of memory. Same server on AWS would cost $10k+/month."

**Scale vertically, not horizontally:**
- Single beefy box (192 cores, TBs of RAM)
- Simple infrastructure stack
- No distributed systems complexity (yet)
- Keep it simple until you need more

**Historical context:**
- 2000s: Hardware slow → horizontal scaling necessary
- 2020s: Hardware fast → vertical scaling viable again
- Cloud vendors pushed horizontal (expensive) when vertical works

### 4. Wireguard Networking

**Problem:** Weaver pods have no direct network connectivity to control plane

**Solution:** Wireguard via Tailscale DERP maps

```
Developer laptop <--[wireguard]--> Loom server <--[wireguard]--> Weaver pod
```

**Three-way connectivity:**
- Laptop ↔ Loom server
- Loom server ↔ Weaver pod
- Laptop ↔ Weaver pod (via broker)

**Enables:**
- SSH into remote weavers
- Port forwarding from pod to laptop
- VS Code remote development into pod

### 5. eBPF Auditing

**Every syscall from weaver is logged:**

- eBPF programs attached to weaver containers
- Full audit trail sent to Loom server
- Event batching (buffers up to 100 events)
- Forwardable to SIEM systems

**Use cases:**
- Security auditing
- Debugging agent behavior
- Compliance (enterprise)

---

## Development Philosophy

### Push to Main, Zero Code Review

> "I just push to main. Zero code review. I get to feel the failure domains."

**Process:**
1. Push to main
2. Auto-deploy in 10 seconds
3. System fails (maybe)
4. **Feel the failure** (don't avoid it)
5. **Engineer away the failure class** (not just the instance)
6. Back pressure prevents recurrence

**Rationale:**
- Speed matters (fast iteration > avoiding failures)
- Failures are learning opportunities
- Engineer systemic solutions, not point fixes
- "If Ralph makes you want to ralph, listen to that feeling and engineer it away"

### Software is Clay

> "Software is now clay. Get it to a position, get it kind of working. When you find problems, run another Ralph loop."

**Old mindset:** Avoid all failures upfront (slow)
**New mindset:** Embrace failures, fix classes of failures (fast)

**Example:**
- Log streaming broken? Don't manually fix.
- Run Ralph loop to add logging + test
- Run Ralph loop to fix root cause
- Run Ralph loop to add test coverage
- Run Ralph loop to prevent recurrence

### Context = Cache

> "Every tool call failure is a cache miss. Every success is a cache hit. Optimize for hits."

**Technique:** `index.md` - optimized lookup table

- Search tools tuned for specific patterns
- Read tools targeted at specific files
- Context window pre-loaded with common patterns
- **Minimize cache misses** (failed tool calls)

**For Space-Agents:**
- Research agents create cache entries (findings)
- Architecture agents hit cache (research results)
- Risk agents hit cache (architecture results)
- Each phase builds cache for next phase

---

## Meta-Loops

> "Port forward from weaver A to weaver B. Weaver B tests, passes thread back to weaver A."

**Meta-loop = Agent reads another agent's context/output**

**Example 1: Testing Loop**
```
Weaver A: Builds web server → Thread saved → Exits
Weaver B: Reads Weaver A's thread → Port forwards → Tests → Thread saved
Weaver C: Reads both threads → Verifies → Reports
```

**Example 2: Review Loop**
```
Worker: Implements code → Thread saved
Inspector: Reads Worker's thread → Reviews requirements → Thread saved
Analyst: Reads Inspector's thread → Reviews code quality → Thread saved
```

**This is Space-Agents' Crew pattern.**

---

## Feature Flags (Planned)

**Automatic feature flag lifecycle:**

1. **Ralph loop adds feature flags** to new code
2. **Deploy with flag OFF**
3. **Ralph loop monitors telemetry** (metrics, errors)
4. **Auto-enable if metrics healthy**
5. **Auto-disable if metrics degrade**
6. **Ralph loop removes flags** after stabilization

**Replaces:**
- Manual feature flag implementation
- Manual rollout decisions
- Manual monitoring
- Manual cleanup

**Goal:** Autonomous deployment pipeline.

---

## Product Analytics (Implemented)

**Reimplemented PostHog-style analytics:**

**Purpose:**
- AB testing
- Product experiments
- Agents modify product features
- Agents monitor user behavior
- Agents adjust based on data

> "I want agents being able to modify product features and do AB experiments. It's not just if-then-else feature flags. No, it's full on product analytics."

**Future state:**
- Agent proposes feature change
- Agent implements behind feature flag
- Agent runs AB test
- Agent monitors metrics
- Agent decides to keep/revert

---

## Loom vs Space-Agents

### Layer Separation

| Aspect | Loom | Space-Agents |
|--------|------|--------------|
| **Focus** | Infrastructure | Orchestration |
| **Provides** | Execution substrate | Mission planning |
| **Primitives** | Weavers, threads, networking | Voyages, missions, objectives |
| **Scale** | Remote pods, Kubernetes | Local subagents (Claude Code) |
| **State** | Threads (audit logs) | SQLite + CAPCOM logs |
| **Personality** | Infrastructure tool | HOUSTON Flight Director |

### Complementary, Not Competitive

```
┌─────────────────────────────────────────────────┐
│  SPACE-AGENTS (Orchestration Layer)             │
│  - HOUSTON coordinates missions                 │
│  - F-Thread planning (brainstorming/planning)   │
│  - Voyage → Mission → Objective hierarchy       │
│  - SQLite state, CAPCOM logs                    │
│  - Worker → Inspector → Analyst review          │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  LOOM (Infrastructure Layer)                    │
│  - Remote weaver execution (Kubernetes)         │
│  - Wireguard networking                         │
│  - SOPS secrets management                      │
│  - eBPF auditing, thread reuse                  │
│  - Testing loops, feature flags                 │
└─────────────────────────────────────────────────┘
```

**Potential integration:**
- HOUSTON spawns Loom weavers (not just Claude Code subagents)
- Pods execute as remote weavers
- Threads sync to Loom's audit system
- CAPCOM integrates with Loom's logs

**For now:** Separate projects. Space-Agents constrained by Claude Code CLI.

---

## What Space-Agents Can Adopt

**Within Claude Code CLI constraints:**

### 1. Thread Reuse System ⭐

**Current:** Each mission isolated, context in staging.md

**Add:** Missions can load context from previous missions

```
HOUSTON: "Loading context from Mission 1 thread..."
HOUSTON: "Mission 2 will build on findings from Mission 1."

[Worker reads Mission 1 capcom.log as input context]
```

**Implementation:**
- Mission logs become reusable threads
- Objectives can reference previous objective threads
- Inspector reads Worker's thread explicitly
- Analyst reads Inspector's thread explicitly

**Benefit:** Meta-loops within Space-Agents.

---

### 2. Airlock Testing Loops ⭐

**Current:** Airlock runs existing tests/lint

**Add:** Airlock generates missing tests, analyzes failures

**Mode 1: Test Generation**
```
Airlock: "No tests found for user_service.py"
Airlock: Spawns agent → Generates tests → Runs them → Reports
```

**Mode 2: Failure Analysis**
```
Airlock: "3 tests failing"
Airlock: Spawns agent → Analyzes failures → Suggests fixes → Reports
```

**Mode 3: System Verification** (Loom Mode 3)
```
Airlock: "Running full system verification..."
Airlock: Spawns agent → Generates test plan → Executes via curl/CLI → Reports
```

**Implementation:**
- Airlock spawns test-generation agent (if coverage gaps)
- Airlock spawns failure-analysis agent (if tests fail)
- Airlock spawns verification agent (system health checks)

**Benefit:** Airlock becomes active participant, not passive validator.

---

### 3. Logs Before/After Pattern ⭐

**Current:** Airlock runs tests, passes/fails

**Add:** Check system state before and after changes

```
Airlock: Check logs/metrics → Before snapshot
Worker: Makes changes
Airlock: Check logs/metrics → After snapshot
Airlock: Diff snapshots → Report impact
```

**Implementation:**
- Airlock reads logs before Worker executes
- Airlock reads logs after Worker completes
- Airlock diffs and reports anomalies
- Inspector uses diff for requirement validation

**Benefit:** Catch subtle breakage (performance, errors, warnings).

---

### 4. CAPCOM Index System

**Current:** CAPCOM filters context, greps logs

**Add:** CAPCOM builds lookup tables for common patterns

```
# .space-agents/capcom_index.md

## Code Patterns
- Authentication: middleware/auth.ts:45-67
- Rate limiting: middleware/rate_limit.ts:12-89
- Database queries: lib/db.ts:100-250

## Common Failures
- TypeScript errors: Usually missing type imports
- Test failures: Usually async timing issues
- Lint errors: Usually unused variables

## Recent Changes
- 2026-01-16: Added rate limiting (Mission 3)
- 2026-01-15: Refactored auth (Mission 2)
```

**Implementation:**
- Research agents update index during exploration
- Architecture agents read index for context
- CAPCOM uses index to optimize tool calls
- Minimize "cache misses" (failed tool calls)

**Benefit:** Faster agent execution, fewer failed tool calls.

---

### 5. System Verification Skill

**New skill:** `/verify`

**Purpose:** Run health checks on codebase/system

```
User: /verify

HOUSTON: "Launching verification agents..."

[Spawns agents to:]
- Run all tests
- Check for lint errors
- Verify recent commits didn't break anything
- Check for security issues
- Test API endpoints (if applicable)

HOUSTON: "Verification complete. 2 issues found:
  - TypeScript error in user_service.ts:45
  - Test failure in auth.test.ts:123

Ready to fix?"
```

**Implementation:**
- Similar to Loom Mode 3 testing
- Spawns agent with verification plan
- Executes tests/lint/checks
- Reports findings
- Optionally spawns fix loop

**Benefit:** Continuous system health monitoring.

---

### 6. Permission Levels (Attended vs Background)

**Current:** /mission-run modes exist but permissions unclear

**Add:** Clarify what agents can do in each mode

**Attended mode:**
- ✅ Read codebase
- ✅ Write code
- ✅ Run tests
- ❌ Deploy
- ❌ Delete files without confirmation

**Background mode:**
- ✅ All of attended
- ✅ Deploy (if configured)
- ✅ Create PRs automatically
- ❌ Merge without review (unless configured)

**Implementation:**
- Skill frontmatter declares required permissions
- HOUSTON checks mode before allowing skill
- User can override per-mission

**Benefit:** Clear boundaries, safer autonomous operation.

---

### 7. Gradual Rollout Mode (Future)

**New mode for /mission-run:** Gradual

```
User: /mission-run VOY-003 --mode gradual

HOUSTON: "Rolling out objectives gradually..."

Objective 1 → Complete → Monitor 5 min → Healthy? → Continue
Objective 2 → Complete → Monitor 5 min → Healthy? → Continue
Objective 3 → Complete → Monitor 5 min → Unhealthy? → Rollback
```

**Implementation:**
- After each objective completion
- Airlock runs health checks
- Wait period (5-10 min)
- Check metrics/logs/tests
- Continue if healthy, rollback if not

**Benefit:** Safer autonomous deployments.

---

## Key Validations for Space-Agents

**What Loom confirms we're doing RIGHT:**

### ✅ Forward-Deployed F-Threading

Jeff spawns weavers AHEAD of work, exactly like our brainstorming flow:
- Research agents spawn before questions
- Architecture agents spawn while user answers
- Risk agents spawn while user validates

**We're aligned.**

### ✅ Thread/Audit Trail Pattern

Loom's "threads" = Space-Agents' staging.md + CAPCOM logs:
- Save context for reuse
- Agents read other agents' context
- Full audit trail

**We're aligned.**

### ✅ Meta-Loops

Loom's weaver-to-weaver communication = Space-Agents' Crew review:
- Worker produces thread
- Inspector reads Worker's thread
- Analyst reads Inspector's thread

**We're aligned.**

### ✅ Feel Failures, Engineer Away

Jeff's philosophy matches our approach:
- Don't over-engineer upfront
- Let Pods fail, capture why
- Ralph loop to fix classes of failures
- Airlock provides back pressure

**We're aligned.**

### ✅ Orchestration vs Infrastructure

Space-Agents focuses on planning/coordination (HOUSTON).
Loom focuses on execution substrate (weavers, networking).

**Different layers, both needed.**

---

## Recommendations for Space-Agents

**Priority 1 (High Value, Low Effort):**

1. **Thread Reuse** - Missions load previous mission logs as context
2. **Logs Before/After** - Airlock diffs system state before/after changes
3. **CAPCOM Index** - Build lookup table for code patterns

**Priority 2 (High Value, Medium Effort):**

4. **Airlock Testing Loops** - Generate missing tests, analyze failures
5. **System Verification Skill** - /verify runs health checks

**Priority 3 (Future Work):**

6. **Permission Levels** - Clarify attended vs background capabilities
7. **Gradual Rollout Mode** - Roll out objectives with monitoring

---

## Quotes to Remember

> "We can reimagine the last 40 years of computing and design it around autonomous agents first, humans second."

> "Software is now clay. Get it to a position, get it kind of working. When you find problems, run another Ralph loop."

> "Every tool call failure is a cache miss. Every success is a cache hit. Optimize for hits."

> "If Ralph makes you want to ralph, listen to that feeling and engineer it away."

> "There's no limits to what I will fork to achieve this goal."

> "Push to main. Zero code review. I get to feel the failure domains."

---

## Resources

- **Loom GitHub:** (Jeff mentioned it's available but not recommended for use)
- **Ralph Wiggum technique:** Jeff's YouTube videos on forward/reverse modes
- **NixOS:** Declarative infrastructure OS
- **JJ/Spool:** Next-gen source control
- **E2B:** Remote execution infrastructure (Loom reimplemented this)

---

## Final Thoughts

**Loom validates our approach.** We're building the right abstractions at the right layer. Jeff is solving infrastructure (remote execution, networking, secrets). We're solving orchestration (planning, coordination, mission control).

**Key insight:** Thread-based engineering applies to BOTH layers:
- Infrastructure threads (Loom weavers)
- Orchestration threads (Space-Agents missions)

**We're on the right path. Keep building.**
