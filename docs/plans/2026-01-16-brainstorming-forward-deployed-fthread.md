# Brainstorming with Forward-Deployed F-Threading

**Date:** 2026-01-16
**Status:** Design Phase
**Pattern:** Forward-Deployed F-Thread + Superpowers Interactive Validation

---

## Executive Summary

HOUSTON coordinates brainstorming sessions using **forward-deployed F-Threading**: spawn exploration agents AHEAD of conversation, ask questions WHILE agents run, progressively refine from generic → specific.

**Key innovation:** User never waits for agents. Agents are always running in background, one phase ahead of conversation.

---

## The Forward-Deployment Pattern

```
Research Agents (spawn immediately)
    ↓ [agents run]
Question 1 (asked while research runs - generic)
    ↓ [user answers]
Architecture Agents (spawn after Q1 + research results)
    ↓ [agents run]
Question 2 (asked while architecture runs - grounded)
    ↓ [user answers]
Risk/Implementation Agents (spawn after Q2 + architecture results)
    ↓ [agents run]
Question 3 (asked while risk runs - specific)
    ↓ [user answers]
Synthesis (all agents complete, all questions answered)
```

**Critical insight:** Agents are AHEAD of conversation, not behind.

---

## Five Phases

### Phase 1: Research (Forward-Deployed)

**HOUSTON receives:** User's initial request

**Immediate action:**
```
HOUSTON: "Roger that. Deploying research team to explore your codebase..."

[SPAWN IN PARALLEL - NO WAIT:]
  - Research Agent A: "Find relevant code patterns, existing implementations"
  - Research Agent B: "Analyze architecture, identify constraints"
  - Research Agent C: "Review recent changes, related features"
```

**Then ask Q1 (generic, while agents run):**
```
HOUSTON: "Question 1: What's driving this need?
  A) [Context-appropriate option]
  B) [Context-appropriate option]
  C) [Context-appropriate option]
  D) Other (please specify)

[Research agents running in background...]"
```

**Agent prompts include:**
- User's initial request
- Current codebase context
- "Focus on: existing patterns, constraints, related features"

**Timing:**
- Spawn: T=0s
- Ask Q1: T=5s (after spawn confirmation)
- User answers: T=30s (typical)
- Agents complete: T=20-40s (usually before user answers)

---

### Phase 2: Architecture (Forward-Deployed)

**HOUSTON receives:**
- Q1 answer
- Research results (3 agent outputs)

**Immediate action:**
```
HOUSTON: "Perfect. My research team found:
  - [Key finding 1]
  - [Key finding 2]
  - [Key finding 3]

Now exploring architectural approaches..."

[SPAWN IN PARALLEL - NO WAIT:]
  - Architecture Agent A: "Approach 1: [Informed by research]"
  - Architecture Agent B: "Approach 2: [Informed by research]"
  - Architecture Agent C: "Approach 3: [Informed by research]"
```

**Then ask Q2 (grounded in research, while agents run):**
```
HOUSTON: "Question 2: [Informed by research results]
  A) [Grounded option based on research]
  B) [Grounded option based on research]
  C) [Grounded option based on research]

[Architecture agents running in background...]"
```

**Agent prompts include:**
- User's initial request + Q1 answer
- Research results (all 3 outputs)
- "Propose specific architectural approach with trade-offs"

**Timing:**
- Spawn: T=35s (after research + Q1 answer)
- Ask Q2: T=40s
- User answers: T=60s (typical)
- Agents complete: T=55-70s

---

### Phase 3: Risk/Implementation (Forward-Deployed)

**HOUSTON receives:**
- Q1 + Q2 answers
- Research + Architecture results (6 agent outputs)

**Immediate action:**
```
HOUSTON: "Got it. My architecture team converged on:
  - [Architecture consensus or options]
  - [Key trade-off identified]
  - [Recommendation with reasoning]

Checking risks and implementation details..."

[SPAWN IN PARALLEL - NO WAIT:]
  - Risk Agent: "Identify failure modes, gotchas, complexity"
  - Implementation Agent: "Estimate effort, dependencies, phases"
```

**Then ask Q3 (specific, informed by architecture, while agents run):**
```
HOUSTON: "Question 3: [Specific to chosen architecture]
  A) [Specific option]
  B) [Specific option]
  C) [Specific option]

[Risk agents running in background...]"
```

**Agent prompts include:**
- User's initial request + Q1 + Q2 answers
- Research + Architecture results (all 6 outputs)
- "Focus on: failure modes, effort estimation, dependencies"

**Timing:**
- Spawn: T=65s (after architecture + Q2 answer)
- Ask Q3: T=70s
- User answers: T=90s (typical)
- Agents complete: T=85-95s

---

### Phase 4: Synthesis & Validation

**HOUSTON receives:**
- All questions answered (Q1, Q2, Q3)
- All agent results (8 agents total: 3 Research + 3 Architecture + 2 Risk/Implementation)

**Synthesis approach:**
1. Read all 8 agent outputs
2. Identify 2-3 viable approaches
3. Extract consensus (if 4+ agents agree on approach)
4. Compile trade-offs, risks, estimates
5. Rank by recommendation strength

**Present section-by-section (Superpowers style):**

```
HOUSTON: "All teams reporting. Here's what we found.

I'll present the approaches section by section. Let me know
if you need clarification on any part before we move forward.

─── Approach A: [Name] (RECOMMENDED) ───

[200-300 word description]

**Why recommended:** [Consensus from agents or reasoning]
**Pros:** [From architecture agents]
**Cons:** [From architecture agents]
**Risks:** [From risk agent]
**Effort:** [From implementation agent]

Does this approach make sense so far?
```

**Validation loop:**
- User responds: "yes" → continue to next section
- User responds: "clarify X" → HOUSTON elaborates, asks again
- User responds: "what about Y?" → HOUSTON addresses, may spawn clarification agent

**Continue for all approaches (typically 2-3).**

**YAGNI enforcement:**
- During validation, HOUSTON strips unnecessary features
- "Do you really need X? It adds complexity without clear benefit."
- User can override, but HOUSTON challenges scope creep

---

### Phase 5: Documentation

**After user selects approach:**

```
HOUSTON: "Perfect. Documenting the design..."

[Write to: docs/plans/YYYY-MM-DD-<topic>-design.md]

Structure:
  # [Feature Name] Design

  **Selected Approach:** [Name]
  **Decision Date:** [Today]
  **Participants:** [User] + HOUSTON F-Thread brainstorming

  ## Context
  [User answers + research findings]

  ## Approaches Considered
  [All 2-3 approaches with trade-offs]

  ## Selected Approach: [Name]
  [Detailed design from validation phase]

  ## Risks & Mitigations
  [From risk agent]

  ## Implementation Estimate
  [From implementation agent]

  ## Next Steps
  - Run /planning to break into missions/objectives
  - Run /mission-run to execute via Ralph

[Commit to git]
```

**Then offer:**
```
HOUSTON: "Design documented and committed.

Ready to move to /planning? I'll break this into
missions and objectives for Ralph to execute."
```

---

## Agent Specifications

### Research Agents (Phase 1)

**Count:** 3 agents

**Agent A Prompt:**
```
You are a Research Agent for Space-Agents brainstorming.

USER REQUEST: {user_request}

TASK: Find relevant code patterns and existing implementations.

FOCUS ON:
- Existing features similar to this request
- Code patterns currently used in this area
- Libraries/frameworks already in use
- Related configuration or infrastructure

OUTPUT FORMAT:
**Findings:**
- [Finding 1 with file references]
- [Finding 2 with file references]
- [Finding 3 with file references]

**Constraints:**
- [Constraint 1 - technical limitation]
- [Constraint 2 - existing pattern to follow]

**Recommendations:**
- [What to build on]
- [What to avoid]
```

**Agent B Prompt:**
```
You are a Research Agent for Space-Agents brainstorming.

USER REQUEST: {user_request}

TASK: Analyze architecture and identify constraints.

FOCUS ON:
- Current system architecture
- Database schema (if relevant)
- API design patterns
- Integration points

OUTPUT FORMAT:
**Architecture Overview:**
- [Key component 1]
- [Key component 2]
- [Key component 3]

**Constraints:**
- [Technical constraint 1]
- [Technical constraint 2]

**Integration Points:**
- [Where this feature connects]
```

**Agent C Prompt:**
```
You are a Research Agent for Space-Agents brainstorming.

USER REQUEST: {user_request}

TASK: Review recent changes and related features.

FOCUS ON:
- Recent commits related to this area
- In-progress work that might conflict
- Similar features added recently
- Lessons from past implementations

OUTPUT FORMAT:
**Recent Activity:**
- [Recent change 1 with commit ref]
- [Recent change 2 with commit ref]

**Related Features:**
- [Related feature 1]
- [Related feature 2]

**Lessons Learned:**
- [Insight from past work]
```

---

### Architecture Agents (Phase 2)

**Count:** 3 agents

**Context provided:**
- User request + Q1 answer
- All research results (3 agent outputs)

**Agent A Prompt:**
```
You are an Architecture Agent for Space-Agents brainstorming.

USER REQUEST: {user_request}
USER CONTEXT: {q1_answer}
RESEARCH FINDINGS: {research_results}

TASK: Propose Approach A for implementing this feature.

REQUIREMENTS:
- Use research findings to inform design
- Prefer simplest viable approach (YAGNI)
- Consider constraints from research
- Provide concrete technical details

OUTPUT FORMAT:
**Approach A: [Name]**

**Design:**
[200-300 word description of approach]

**Trade-offs:**
- Pro: [Benefit 1]
- Pro: [Benefit 2]
- Con: [Drawback 1]
- Con: [Drawback 2]

**Technical Details:**
- [Component/file changes]
- [Database changes if needed]
- [API changes if needed]
```

**Agents B and C:** Same prompt, instructed to propose DIFFERENT approaches.

---

### Risk Agent (Phase 3)

**Count:** 1 agent

**Context provided:**
- User request + Q1 + Q2 answers
- All research + architecture results (6 agent outputs)

**Prompt:**
```
You are a Risk Agent for Space-Agents brainstorming.

USER REQUEST: {user_request}
USER CONTEXT: {q1_answer}, {q2_answer}
RESEARCH FINDINGS: {research_results}
ARCHITECTURE OPTIONS: {architecture_results}

TASK: Identify risks, failure modes, and gotchas for each approach.

FOCUS ON:
- Failure modes (what breaks?)
- Performance impact
- Migration complexity
- Edge cases
- Operational risks

OUTPUT FORMAT:
**Approach A: [Name]**
- Risk: [Risk 1] - Severity: [Critical/High/Medium/Low]
  Mitigation: [How to address]
- Risk: [Risk 2] - Severity: [...]
  Mitigation: [...]

**Approach B: [Name]**
[Same format]

**Approach C: [Name]**
[Same format]

**Recommendation:**
[Which approach has lowest risk profile and why]
```

---

### Implementation Agent (Phase 3)

**Count:** 1 agent

**Context provided:**
- User request + Q1 + Q2 answers
- All research + architecture results (6 agent outputs)

**Prompt:**
```
You are an Implementation Agent for Space-Agents brainstorming.

USER REQUEST: {user_request}
USER CONTEXT: {q1_answer}, {q2_answer}
RESEARCH FINDINGS: {research_results}
ARCHITECTURE OPTIONS: {architecture_results}

TASK: Estimate implementation effort and identify dependencies.

FOCUS ON:
- Tasks required for each approach
- Dependencies (must X happen before Y?)
- Effort estimates (hours/days)
- Phasing options (can we ship incrementally?)

OUTPUT FORMAT:
**Approach A: [Name]**
- Effort: [X hours/days]
- Phases:
  1. [Phase 1] - [effort]
  2. [Phase 2] - [effort]
- Dependencies:
  - [Dependency 1]
  - [Dependency 2]

**Approach B: [Name]**
[Same format]

**Approach C: [Name]**
[Same format]

**Recommendation:**
[Which approach has best effort/value ratio and why]
```

---

## Orchestration Logic

### HOUSTON's Role

**Coordinator, not implementer:**
- Spawn agents with right context
- Ask questions while agents run
- Read agent outputs when complete
- Synthesize into coherent narrative
- Present section-by-section
- Validate with user
- Document decisions

**Keep context lean:**
- Don't re-implement agent work
- Don't guess when agents can research
- Don't over-explain (agents provide details)

### Question Design

**Q1 (Generic):**
- Broad intent ("What's driving this?")
- Multiple choice preferred
- Options: A, B, C, D (Other)
- Asked ~5s after research agents spawn

**Q2 (Grounded):**
- Informed by research results
- References specific findings
- Multiple choice preferred
- Asked ~5s after architecture agents spawn

**Q3 (Specific):**
- Informed by architecture results
- Technical details
- Multiple choice preferred
- Asked ~5s after risk agents spawn

### Timing Management

**If agents complete before user answers:**
```
HOUSTON: "Quick update while you're thinking:
  - [Brief summary of findings]
  - [Key insight]

Take your time with the question."
```

**If user answers before agents complete:**
```
HOUSTON: "Got it. Processing your answer while agents complete...

[Brief wait - typically 10-30 seconds]

[Agents return]

Perfect. My team found..."
```

**Typical timeline:**
- Phase 1: 0-40s (spawn research, ask Q1, user answers)
- Phase 2: 40-70s (spawn architecture, ask Q2, user answers)
- Phase 3: 70-95s (spawn risk, ask Q3, user answers)
- Phase 4: 95-120s (synthesis, validation)
- Phase 5: 120-150s (documentation, commit)

**Total: ~2.5 minutes for full brainstorming session**

---

## State Management

### Staging.md

**Append throughout session:**
```markdown
## Brainstorming Session: [Topic]
**Started:** [timestamp]

### Research Phase
**Question 1:** What's driving this need?
**Answer:** [User answer]

**Research Findings:**
[Agent A output summary]
[Agent B output summary]
[Agent C output summary]

### Architecture Phase
**Question 2:** [Question text]
**Answer:** [User answer]

**Architecture Options:**
[Agent A output summary]
[Agent B output summary]
[Agent C output summary]

### Risk/Implementation Phase
**Question 3:** [Question text]
**Answer:** [User answer]

**Risk Analysis:** [Risk agent summary]
**Implementation Estimate:** [Implementation agent summary]

### Decision
**Selected Approach:** [Name]
**Rationale:** [Why user selected this]

**Next Action:** /planning to break into missions
```

### SQLite

**No writes during brainstorming.**

Brainstorming produces design doc, not executable records. `/planning` writes to SQLite.

---

## Integration with /planning

**After brainstorming completes:**

```
User: /planning

HOUSTON: "Loading design from docs/plans/2026-01-16-[topic]-design.md..."

[Uses selected approach as input to /planning F-Thread]
```

See: `2026-01-16-planning-forward-deployed-fthread.md`

---

## Example Session

**User:** `/brainstorming "Add rate limiting to API"`

**HOUSTON (T=0s):**
```
"Roger that. Deploying research team to explore your codebase..."

[SPAWN: Research Agent A, B, C]

"Question 1: What's driving the need for rate limiting?
  A) Preventing abuse from bad actors
  B) Managing infrastructure costs
  C) SLA guarantees for paid tiers
  D) Other

[Research agents running in background...]"
```

**User (T=30s):** "C - SLA guarantees"

**HOUSTON (T=35s):**
```
"Perfect. My research team found:
  - 3 user tiers: free (1000 req/day), pro (10k), enterprise (unlimited)
  - Current auth uses JWT in middleware/auth.ts:45-67
  - /api/search endpoint is 60% of all traffic
  - No existing rate limiting detected

Now exploring rate limiting architectures..."

[SPAWN: Architecture Agent A, B, C]

"Question 2: Should different tiers have different rate limits?
  A) Yes - enforce the 1000/10k/unlimited tiers
  B) No - same limits for everyone
  C) Only limit free tier

[Architecture agents running in background...]"
```

**User (T=60s):** "A - enforce the tiers"

**HOUSTON (T=65s):**
```
"Got it. My architecture team converged on Redis + token bucket (3/3 consensus):
  - Token bucket handles burst traffic better than sliding window
  - Redis provides distributed state (works across multiple servers)
  - Lua scripts for atomic operations (no race conditions)

Checking risks and implementation details..."

[SPAWN: Risk Agent, Implementation Agent]

"Question 3: Should limits apply per-user, per-IP, or both?
  A) Per-user only (must be authenticated)
  B) Per-IP (catches unauthenticated abuse)
  C) Both (per-user for authenticated, per-IP for anon)

[Risk agents running in background...]"
```

**User (T=90s):** "C - both"

**HOUSTON (T=95s):**
```
"Perfect. All teams reporting. Here's the synthesis:

─── Approach A: Redis + Token Bucket (RECOMMENDED) ───

Use Redis for distributed rate limiting with token bucket algorithm.
Supports per-user and per-IP limits, handles tier differentiation,
survives single-node failures with Redis Sentinel. For your 3-tier
system with /api/search hotspot, this provides <5ms overhead.

**Why recommended:** 3/3 architecture agents + risk agent consensus
**Pros:**
  - Battle-tested pattern (used by Stripe, GitHub, Cloudflare)
  - Handles burst traffic (token bucket refills over time)
  - Distributed state (works across multiple API servers)
  - Atomic operations (Lua scripts prevent race conditions)

**Cons:**
  - Redis dependency (adds infrastructure)
  - Slightly more complex than in-memory (but proven libraries exist)

**Risks:**
  - Redis failure → recommend fallback to in-memory (degraded mode)
  - Race conditions → mitigated by Lua scripts (atomic operations)
  - Performance impact → <5ms overhead per request (negligible)

**Effort:** ~2 days
  - Day 1: Redis setup, token bucket implementation, per-user tracking
  - Day 2: Per-IP tracking, tier enforcement, fallback logic, tests

Does this approach make sense so far?"
```

**User:** "Yes, looks good"

**HOUSTON:**
```
[Continues with Approach B and C if relevant, then documents]

"Design documented to docs/plans/2026-01-16-api-rate-limiting-design.md
and committed to git.

Ready for /planning? I'll break this into missions and objectives."
```

---

## Key Principles

1. **Agents ahead of conversation** - Always forward-deployed
2. **Zero user wait time** - Agents run while user thinks
3. **Progressive refinement** - Generic → Grounded → Specific
4. **Parallel exploration** - Multiple agents per phase
5. **Consensus signals** - When agents agree, note it
6. **Section validation** - Present incrementally, catch issues early
7. **YAGNI ruthlessly** - Challenge scope creep during validation
8. **Document decisions** - Write design doc, commit to git

---

## Success Metrics

**Quality:**
- ✅ Design addresses user need
- ✅ Trade-offs clearly articulated
- ✅ Risks identified with mitigations
- ✅ Implementation effort estimated

**Speed:**
- ✅ Full session: ~2.5 minutes (vs 10-15 min manual)
- ✅ User wait time: 0 seconds

**Experience:**
- ✅ Feels like coordinating research teams
- ✅ Questions grounded in codebase reality
- ✅ Multiple perspectives considered
- ✅ User stays in control (HOUSTON recommends, user decides)

---

## Next Steps

1. Implement `/brainstorming` skill with this pattern
2. Test with real scenarios (multi-tenancy, rate limiting, dark mode)
3. Tune agent counts (currently 3+3+2 = 8 agents)
4. Measure timing (research phase, architecture phase, synthesis)
5. Iterate based on user feedback

**Related:** See `2026-01-16-planning-forward-deployed-fthread.md` for next phase.
