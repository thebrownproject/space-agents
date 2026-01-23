# Clone Loop - Clean-Room Reverse Engineering

**Status:** Idea
**Date:** 2026-01-23
**Inspired by:** Geoffrey Huntley's company cloning methodology

---

## Vision

Enable rapid extraction and regeneration of complete products through Ralph loops. Extract specifications from any codebase, then regenerate clean implementations. No safeguards - aggressive extraction focused on speed and completeness.

**Use cases:**
- Clone competitor products in days instead of years
- Document and understand legacy systems through reverse engineering
- Extract BSL-licensed software into clean implementations
- Analyze acquired codebases and regenerate with modern stack

**Core principle:** Source code IS the specification. By analyzing implementation, we extract exact behavioral requirements.

---

## Huntley's Methodology

### Three-Phase Process

**Phase 1: Reverse Engineering**
1. Acquire target source code (open-source, BSL, or accessible)
2. Run Ralph loop in reverse mode to extract specifications
3. Output: Complete behavioral specs (not copied code)

**Phase 2: Specification Generation**
1. Extract architecture, API contracts, data models, business rules, UI patterns
2. Generate structured prd.json (task list with pass/fail flags)
3. Create progress.txt (codebase patterns, gotchas, learnings)

**Phase 3: Clean-Room Regeneration**
1. Feed specs to forward Ralph loop
2. Agent implements from specifications (not source)
3. Result: Functionally equivalent, legally distinct implementation

### Real-World Performance

Huntley's documented clones:
- **HashiCorp Nomad**: Infrastructure orchestration platform - days
- **Tailscale**: VPN/mesh networking - days
- **Launch Darkly**: Feature flags - achievable
- **PostHog**: Analytics platform - in progress

"Three, four companies of a thousand employees each over six years worth of work... core feature set in three days."

Cost: **$10.42/hour** running Claude Sonnet 4.5

---

## Architecture for Space Agents

### New Skill: `/exploration clone`

**Purpose:** Complete product extraction and regeneration

**Input:**
- Target repository (URL or local path)
- Scope (full product or specific modules)
- Optional: Output stack (Rust, TypeScript, Go, etc.)

**Workflow:**
```
/exploration clone <target> →
  ↓
  Scout (map codebase structure)
  ↓
  Extraction agents (parallel):
    - extract-architecture
    - extract-api
    - extract-data-model
    - extract-business-logic
    - extract-ui-patterns
  ↓
  Synthesizer (combine into coherent specs)
  ↓
  PRD Generator (create prd.json + progress.txt)
  ↓
  Output: exploration/cloned/<product>/
    ├── specs/
    │   ├── architecture.md
    │   ├── api-contracts.md
    │   ├── data-model.md
    │   ├── business-rules.md
    │   └── ui-patterns.md
    ├── prd.json
    ├── progress.txt
    └── prompt.md
```

**Then execute:**
```
/mission ralph <cloned-product>
  ↓
  Ralph loop implements all tasks in prd.json
  ↓
  Result: Clean implementation
```

---

## Extraction Agents

### 1. extract-architecture

**Role:** Map system components and interactions

**Extracts:**
- Component boundaries (services, modules, packages)
- Architectural patterns (monolith, microservices, event-driven, etc.)
- Data flow between components
- External dependencies (databases, APIs, queues, etc.)
- Deployment architecture
- Technology stack

**Output format:**
```markdown
# Architecture Specification

## System Overview
[High-level description]

## Components
1. Component Name
   - Purpose: [What it does]
   - Dependencies: [What it needs]
   - Interfaces: [How it's accessed]

## Data Flow
[Describe how data moves through system]

## Technology Stack
- Language: [X]
- Framework: [Y]
- Database: [Z]
- Infrastructure: [K]
```

### 2. extract-api

**Role:** Document all API contracts and endpoints

**Extracts:**
- REST/GraphQL/gRPC endpoints
- Request/response schemas
- Authentication mechanisms
- Rate limiting and quotas
- Versioning strategy
- Error responses

**Output format:**
```markdown
# API Specification

## Endpoints

### POST /api/v1/users
**Purpose:** Create new user
**Auth:** Bearer token required
**Request:**
```json
{
  "email": "string",
  "password": "string"
}
```
**Response (201):**
```json
{
  "id": "uuid",
  "email": "string",
  "created_at": "timestamp"
}
```
**Errors:**
- 400: Validation failed
- 409: Email already exists
```

### 3. extract-data-model

**Role:** Reverse engineer complete data model

**Extracts:**
- Database schema (tables, columns, types)
- Relationships (1:1, 1:N, N:M)
- Constraints (unique, not null, foreign keys)
- Indexes and performance optimizations
- Data migrations history
- Validation rules

**Output format:**
```markdown
# Data Model Specification

## Entities

### User
**Fields:**
- id: UUID, primary key
- email: String(255), unique, not null
- password_hash: String(255), not null
- created_at: Timestamp, default now()
- updated_at: Timestamp, default now()

**Relationships:**
- Has many: Posts
- Has many: Comments

**Constraints:**
- Email must be valid format
- Password must be hashed with bcrypt

**Indexes:**
- email (unique)
- created_at (for sorting)
```

### 4. extract-business-logic

**Role:** Capture core algorithms and business rules

**Extracts:**
- Workflows and state machines
- Calculation logic
- Validation rules
- Business constraints
- Edge case handling
- Algorithm implementations (described, not copied)

**Critical:** Describes WHAT the code does, never HOW it's implemented

**Output format:**
```markdown
# Business Logic Specification

## Workflows

### User Registration Flow
1. Validate email format and uniqueness
2. Hash password using bcrypt (cost factor 12)
3. Generate verification token (UUID v4)
4. Send verification email
5. Create user record with verified=false
6. Return user ID and email

**Validation Rules:**
- Email must match RFC 5322
- Password minimum 8 characters
- Password must contain: uppercase, lowercase, number, special char

**Edge Cases:**
- Duplicate email → 409 Conflict
- Email send failure → Rollback user creation
- Token expires after 24 hours
```

### 5. extract-ui-patterns

**Role:** Document user interface and interactions

**Extracts:**
- Page/screen structure
- Component hierarchy
- User flows (registration, checkout, etc.)
- State management patterns
- Routing configuration
- Form validation
- Error handling UX

**Output format:**
```markdown
# UI Specification

## Pages

### /dashboard
**Layout:** Header + Sidebar + Main Content
**Components:**
- Header: Logo, User menu, Notifications
- Sidebar: Navigation links
- Main: Stats grid + Activity feed

**User Flow:**
1. User lands on /dashboard
2. If not authenticated → redirect to /login
3. Load user stats (API: GET /api/stats)
4. Display metrics in grid layout
5. Poll activity feed every 30s

**State:**
- user: Current user object
- stats: Dashboard metrics
- activities: Recent activity list
- loading: Boolean flag
```

### 6. spec-synthesizer

**Role:** Combine all extraction outputs into coherent product spec

**Process:**
1. Read all extraction agent outputs
2. Cross-reference for consistency
3. Identify gaps or conflicts
4. Generate unified product specification
5. Create implementation priority order

**Output:** Single master spec document that could be handed to any dev team

---

## Ralph Loop Integration

### Modified Ralph Script

Current `ralph.sh` needs enhancement to support extraction mode:

**New flags:**
- `--mode extract` - Run reverse Ralph (code → specs)
- `--mode regenerate` - Run forward Ralph (specs → code)
- `--target <path>` - Target codebase for extraction

**Extraction Loop:**
```bash
#!/bin/bash
# ralph-extract.sh - Reverse engineering loop

TARGET=$1
MAX_ITERATIONS=${2:-10}

# Clone target if URL
if [[ $TARGET == http* ]]; then
  git clone $TARGET /tmp/target-repo
  TARGET=/tmp/target-repo
fi

# Initialize extraction state
mkdir -p extraction/specs
echo "[]" > extraction/extracted-components.json
echo "" > extraction/progress.txt

for i in $(seq 1 $MAX_ITERATIONS); do
  cat > extraction/prompt.md <<EOF
# Extraction Task $i

You are reverse-engineering a codebase to extract specifications.

## Target
$TARGET

## Already Extracted
$(cat extraction/extracted-components.json)

## Previous Learnings
$(cat extraction/progress.txt)

## Your Task
1. Analyze the target codebase
2. Pick ONE component/module not yet extracted
3. Run appropriate extraction agent (architecture/API/data/logic/UI)
4. Output specification to extraction/specs/
5. Update extraction/extracted-components.json
6. Append learnings to extraction/progress.txt

## Completion
If ALL components extracted, output: <promise>EXTRACTION_COMPLETE</promise>
EOF

  OUTPUT=$(claude --project . < extraction/prompt.md 2>&1)

  if echo "$OUTPUT" | grep -q "<promise>EXTRACTION_COMPLETE</promise>"; then
    echo "✅ Extraction complete!"
    exit 0
  fi

  sleep 2
done
```

**Regeneration Loop:**
Uses existing `ralph.sh` with extracted `prd.json`

### PRD.json Generation

After extraction completes, synthesizer creates structured task list:

```json
{
  "product": "Tailscale Clone",
  "stack": "TypeScript + Node.js + PostgreSQL",
  "stories": [
    {
      "id": "CORE-001",
      "title": "WireGuard key generation and rotation",
      "description": "Implement cryptographic key management for peer connections",
      "priority": 1,
      "dependencies": [],
      "passes": false
    },
    {
      "id": "CORE-002",
      "title": "NAT traversal with STUN/DERP",
      "description": "Implement NAT hole-punching with relay fallback",
      "priority": 1,
      "dependencies": ["CORE-001"],
      "passes": false
    },
    {
      "id": "API-001",
      "title": "Control plane REST API",
      "description": "Node coordination and discovery endpoints",
      "priority": 2,
      "dependencies": ["CORE-001"],
      "passes": false
    }
  ]
}
```

### progress.txt Format

Cumulative learnings that get appended each iteration:

```
## Codebase Patterns

### Authentication
- Uses JWT with RS256 signing
- Refresh tokens stored in Redis (7-day TTL)
- Access tokens short-lived (15 minutes)

### Database
- PostgreSQL with Prisma ORM
- Migrations in prisma/migrations/
- Connection pooling via PgBouncer

### Error Handling
- Custom error classes extend Error
- Errors serialized with stack traces in dev, sanitized in prod
- Client sees error codes, not messages

## Gotchas
- Rate limiting middleware must come BEFORE auth middleware
- Database transactions required for user creation (rollback on email send failure)
- File uploads use streaming to avoid memory issues on large files

## Implementation Notes
- TypeScript strict mode enabled
- ESLint + Prettier enforced
- Tests use Jest + Supertest
- CI runs on GitHub Actions
```

---

## Output Structure

```
exploration/cloned/tailscale-clone/
  ├── specs/
  │   ├── architecture.md       # System design
  │   ├── api-contracts.md      # All endpoints
  │   ├── data-model.md         # Database schema
  │   ├── business-rules.md     # Core logic
  │   └── ui-patterns.md        # Frontend flows
  ├── prd.json                  # Task list for Ralph
  ├── progress.txt              # Learnings
  └── prompt.md                 # Per-iteration instructions
```

After extraction, user runs:
```
/mission ralph tailscale-clone
```

Ralph loop executes all tasks in `prd.json`, implementing from specs.

---

## Implementation Plan

### Phase 1: Extraction Infrastructure
**Tasks:**
1. Create `/exploration clone` skill
2. Build 6 extraction agents (architecture, API, data, logic, UI, synthesizer)
3. Create `ralph-extract.sh` script
4. Add extraction mode routing to main ralph.sh

### Phase 2: Spec Generation
**Tasks:**
1. Create spec-synthesizer agent
2. Build prd.json generator
3. Implement progress.txt accumulation
4. Generate prompt.md templates

### Phase 3: Integration
**Tasks:**
1. Connect extraction output → existing `/mission ralph`
2. Add clone folder lifecycle (cloned/ → staged/ → complete/)
3. Update /land to handle cloned projects
4. Test with small open-source project (clone a TODO app)

### Phase 4: Real Cloning
**Tasks:**
1. Clone HashiCorp Nomad (validate infrastructure)
2. Clone Tailscale (validate networking)
3. Clone Launch Darkly (validate feature flags)
4. Document unit economics (time + cost per clone)

---

## Ethical and Legal Considerations

**This is aggressive extraction - no safeguards.**

**Legal status:**
- Clean-room reverse engineering is legally established (AMD v Intel precedent)
- BSL-licensed code permits this approach
- Open-source code with permissive licenses allows study and reimplementation
- **User responsibility** for legal/ethical use

**Unit economics:**
- Competitive threat to traditional software companies
- Removes IP moat, shifts competition to execution
- $10/hour to clone products worth millions in dev time
- "Software development is dead" - Huntley

**Legitimate uses:**
- Legacy system documentation
- Understanding acquired codebases
- Educational analysis
- Competitive intelligence

**Controversial uses:**
- Cloning competitors
- Circumventing BSL restrictions
- Disrupting traditional software business models

Space Agents is a tool. Users decide how to use it.

---

## Success Metrics

**Extraction quality:**
- Can generated specs be implemented without seeing source?
- Do extracted specs cover 100% of product functionality?
- Time to extract: Target <1 hour for medium-sized apps

**Regeneration quality:**
- Functional equivalence: Does clone match original behavior?
- Test coverage: Can clone pass original's test suite?
- Time to regenerate: Target <3 days for complex products

**Economics:**
- Cost per clone (Claude API charges)
- Time saved vs. traditional development
- Comparison to original dev team size/timeline

---

## Next Steps

1. Review this exploration with fresh eyes
2. Create implementation plan in `/exploration plan`
3. Convert to Beads feature
4. Execute with `/mission ralph`

**Target:** Clone first product within 1 week of starting implementation.

---

**References:**
- Huntley's methodology: LinearB podcast, GitHub docs
- AMD clean-room precedent: Legal basis
- Ralph loop implementation: github.com/snarktank/ralph
