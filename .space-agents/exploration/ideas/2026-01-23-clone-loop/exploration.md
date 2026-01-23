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

## Huntley's Exact Clean-Room Methodology

### The Complete Five-Phase Workflow

**Phase 0: Source Code Acquisition**
1. Download target company's source code (GitHub, BSL-licensed, open-source)
2. Feed codebase to Claude with deobfuscation/transpilation instructions
3. Key capability: "LLMs are shockingly good at deobfuscation, transpilation and structure-to-structure conversions"

**Phase 1: Reverse Ralph Mode - Specification Extraction**

Run Ralph in **reverse mode** to extract specifications WITHOUT copying implementation:

```
Phase 0a: Study target source code with up to 250 parallel
          Sonnet subagents to understand architectural patterns

Phase 0b: Map component interactions and relationships

Phase 0c: Extract public APIs, data structures, state machines

Phase 1: Generate specs/*.md files describing WHAT the system does
         (behavioral specifications, NOT implementation details)

Phase 2: Identify gaps and missing architectural patterns

Output: Clean-room specifications ready for implementation
```

**Critical:** Reverse mode outputs **specifications only**, never code. The LLM extracts:
- Component interfaces (what methods/functions exist)
- Data models (structures and relationships)
- Control flow patterns (how components communicate)
- Behavioral requirements (what happens when user X triggers action Y)
- State machines (system lifecycle and transitions)

This is legally defensible because you're describing "what the black box does externally," not copying internal implementation.

**Phase 2: Implementation Planning**

From extracted specifications, generate prioritized `IMPLEMENTATION_PLAN.md`:

```markdown
# Implementation Plan (generated from reverse engineering)

## High Priority
- [ ] User authentication system
  - OAuth/OIDC integration
  - Session management
  - Role-based access control

## Medium Priority
- [ ] API layer
  - REST endpoint structure
  - Request/response serialization
  - Error handling

## Low Priority
- [ ] Admin dashboard
  - User management interface
  - Analytics display
```

**Phase 3: Clean-Room Regeneration Using Forward Ralph**

Run Ralph's standard forward mode with **critical constraint: never reference original source again**.

Agent only has access to:
- `specs/*.md` (extracted specifications)
- `IMPLEMENTATION_PLAN.md` (task list)
- `AGENTS.md` (~60 lines operational guide)
- Previously written code (for consistency)

**Per-Iteration Instructions:**
```
0a. Study specs/* with 250 parallel Sonnet subagents
0b. Study IMPLEMENTATION_PLAN.md
0c. Study existing src/ code

1. Pick the most important task from IMPLEMENTATION_PLAN.md
2. Search codebase - "don't assume not implemented"
3. Implement that ONE task completely
4. Run tests (backpressure validation)
5. On pass: commit and update IMPLEMENTATION_PLAN.md
6. On fail: Claude reads test output and self-corrects

99. Important: Keep IMPLEMENTATION_PLAN.md current
999. Update AGENTS.md with operational learnings
9999. Clean up completed items periodically
```

**Phase 4: Backpressure & Validation**

Validate regenerated code against **specifications, not original system**:

| Validation Type | Purpose |
|---|---|
| **Unit Tests** | Verify individual functions work per spec |
| **Integration Tests** | Verify components interact correctly |
| **Type Checking** | Catch logical errors before runtime |
| **Linting** | Enforce code style consistency |
| **Property-Based Tests** | Verify behavior across input ranges |

**Phase 5: Context Engineering**

Ralph deliberately **reloads full specification every iteration** to prevent compaction events:

**Context Window Management:**
- Advertised capacity: 200k tokens
- Model overhead: ~16k tokens
- Harness overhead: ~16k tokens
- MCP servers: additional overhead
- **Actual usable capacity: ~120-176k tokens**

**Smart vs Dumb Zones:**
- **Smart zone:** 40-60% utilization (optimal performance)
- **Dumb zone:** 60%+ utilization (measurable degradation)

Ralph "mallocs the full specification array" each iteration - seems wasteful, prevents critical spec loss.

### Real-World Performance: HashiCorp Nomad Clone

**Step 1 (Reverse):**
- Download Nomad's BSL-licensed source
- Feed to Claude in reverse mode
- Extract specifications: cluster scheduling, task allocation, state management, APIs

**Step 2 (Plan):**
- Generate implementation plan with ~50-100 tasks
- Prioritize by importance

**Step 3 (Build):**
- Run forward Ralph loop
- Iteration 1: Basic task scheduler
- Iteration 2: Cluster state management
- Iteration 3: API layer
- Continue for ~50-100 iterations
- Each iteration: 1 task → tests pass → commit → next

**Result:** Complete Nomad clone in **3 days** vs. 10+ years of original development

**Cost:** **$10.42/hour** in Claude Sonnet compute

### Other Documented Clones

- **Tailscale**: VPN/mesh networking - days
- **Launch Darkly**: Feature flags - achievable
- **PostHog**: Analytics platform - in progress

"Three, four companies of a thousand employees each over six years worth of work... core feature set in three days."

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
  Phase 0a: 250 parallel Sonnet subagents study target codebase
  ↓
  Phase 0b: Map component interactions
  ↓
  Phase 0c: Extract public APIs, data structures, state machines
  ↓
  Phase 1: Generate specs/*.md (behavioral specifications)
  ↓
  Phase 2: Identify gaps and missing patterns
  ↓
  Synthesizer: Combine into coherent specifications
  ↓
  Planner: Generate IMPLEMENTATION_PLAN.md (prioritized tasks)
  ↓
  Output: exploration/cloned/<product>/
    ├── specs/
    │   ├── architecture.md
    │   ├── api.md
    │   ├── data-models.md
    │   ├── authentication.md
    │   ├── rate-limiting.md
    │   └── caching-strategy.md
    ├── IMPLEMENTATION_PLAN.md    # Prioritized task list
    ├── AGENTS.md                  # Operational guide (~60 lines)
    ├── PROMPT_build.md            # Forward mode instructions
    └── loop.sh                    # Ralph orchestration script
```

**Then execute:**
```
/mission ralph <cloned-product>
  ↓
  Forward Ralph loop implements all tasks in IMPLEMENTATION_PLAN.md
  ↓
  Each iteration: 1 task → tests → commit → next
  ↓
  Result: Clean implementation (legally distinct)
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
Uses Huntley's forward Ralph loop with extracted specifications

**The Bash Loop:**
```bash
#!/bin/bash
# loop.sh - Forward Ralph implementation loop

while :; do
  cat PROMPT_build.md | claude \
    --dangerously-skip-permissions \
    --model sonnet \
    --verbose

  # Small delay between iterations
  sleep 2
done
```

**Why Infinite Loop:**
- Agent handles its own completion signal
- Stop condition in PROMPT_build.md (not in bash)
- Allows agent to decide when truly done
- No arbitrary iteration limit

### IMPLEMENTATION_PLAN.md Generation

After extraction completes, synthesizer creates prioritized task list:

```markdown
# Tailscale Clone - Implementation Plan

## Product Spec
- **Name**: Tailscale Clone
- **Stack**: TypeScript + Node.js + PostgreSQL + WireGuard
- **Timeline**: 50-100 tasks, ~3 days execution

## High Priority

- [ ] **CORE-001**: WireGuard key generation and rotation
  - Implement cryptographic key management for peer connections
  - Uses Curve25519 for public/private key pairs
  - Auto-rotation every 180 days
  - Dependencies: None

- [ ] **CORE-002**: NAT traversal with STUN/DERP
  - Implement NAT hole-punching with relay fallback
  - STUN for peer discovery
  - DERP relay servers when direct connection fails
  - Dependencies: CORE-001

## Medium Priority

- [ ] **API-001**: Control plane REST API
  - Node coordination and discovery endpoints
  - Authentication via device keys
  - WebSocket for real-time updates
  - Dependencies: CORE-001

- [ ] **API-002**: Network map distribution
  - Peer list synchronization
  - ACL policy distribution
  - Dependencies: API-001

## Low Priority

- [ ] **UI-001**: Admin dashboard
  - Device management interface
  - User access control
  - Dependencies: API-001, API-002

## Completed
(Tasks marked complete move here after implementation)
```

### AGENTS.md Format

Operational guide updated each iteration (~60 lines):

```markdown
# Operational Guide for Tailscale Clone

## Codebase Patterns

### Authentication
- Uses device public keys for node authentication
- Control plane validates signatures on all requests
- No password-based auth (keys only)

### Networking
- WireGuard for encrypted tunnels
- UDP hole-punching via STUN
- DERP relay fallback for NAT traversal
- IPv4 and IPv6 support

### Database
- PostgreSQL for control plane state
- Redis for session management
- Connection pooling via PgBouncer

## Gotchas
- WireGuard kernel module required (or wireguard-go userspace)
- DERP servers must have static IPs (DNS changes break connections)
- MTU sizing critical for performance (1280 bytes for IPv6 compatibility)

## Testing
- Unit tests: Jest
- Integration tests: Docker Compose multi-node setup
- E2E tests: Real network simulation with network namespaces

## Build
- TypeScript strict mode
- ESLint + Prettier
- CI: GitHub Actions
```


---

## Output Structure

```
exploration/cloned/tailscale-clone/
  ├── loop.sh                      # Ralph orchestration script
  ├── PROMPT_build.md              # Forward mode instructions (per-iteration)
  ├── AGENTS.md                    # Operational guide (~60 lines)
  ├── IMPLEMENTATION_PLAN.md       # Prioritized task list (NOT prd.json)
  ├── specs/                       # Extracted specifications
  │   ├── architecture.md
  │   ├── api.md
  │   ├── data-models.md
  │   ├── authentication.md
  │   ├── rate-limiting.md
  │   └── caching-strategy.md
  ├── src/                         # FRESH implementation (clean-room)
  │   ├── api/
  │   ├── core/
  │   ├── lib/
  │   └── tests/
  └── .git/                        # Commits tracked per iteration
```

After extraction, user runs:
```
/mission ralph tailscale-clone
```

Ralph loop executes all tasks in `IMPLEMENTATION_PLAN.md`, implementing from specs only.

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
2. Build IMPLEMENTATION_PLAN.md generator (prioritized task list)
3. Create AGENTS.md template (operational guide)
4. Generate PROMPT_build.md (forward mode per-iteration instructions)

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

## Legal Defensibility: Clean-Room Reverse Engineering

**This is aggressive extraction - no safeguards.**

### Legal Precedent

Clean-room reverse engineering is legally established through multiple precedents:

- **AMD v Intel**: AMD completely reverse-engineered Intel CPUs, creating functionally identical but legally distinct implementations
- **Berkeley Unix**: Clean-room specs generated independently, then implemented without seeing original AT&T code
- **Key principle**: Specifications extracted ≠ Code copied

### What Makes It "Clean-Room"

**Critical Rule:** Specifications must describe **WHAT the system does externally**, not HOW it's implemented internally.

**Legal defensibility checklist:**

✅ **DO:**
- Behavioral specifications only (what, not how)
- Completely fresh implementation (no code similarity)
- Test-driven validation against behavior (not structure matching)
- Separate extraction team from implementation team (if using humans)
- Document the clean-room process

❌ **DO NOT:**
- Allow humans to see both original code and new specs (becomes derivative)
- Create functional specs that go beyond public interface (too detailed)
- Include implementation details in specs (compromises clean-room defense)
- Copy algorithms verbatim (describe behavior instead)
- Include proprietary secrets or internal implementation patterns

### The Legal Gray Zone

**Why this works:**
- LLMs can study original code during extraction phase
- LLMs generate fresh implementation during regeneration phase
- No human sees both original and new code simultaneously
- Specifications sit as an abstraction layer between source and clone

**Risk factors:**
- Courts may eventually rule that LLM-mediated copying is derivative work
- Currently untested in case law
- Huntley's position: "By the time courts decide, the industry will have moved on"

---

## Closed-Source Reverse Engineering Strategies

**WARNING:** Accessing proprietary source code without authorization is illegal (Computer Fraud and Abuse Act, trade secret theft, etc.). This section documents legal and gray-zone techniques only.

### Legal Techniques (No Source Code Access Required)

These approaches extract specifications WITHOUT accessing proprietary source code:

**1. Binary Decompilation**

Legal in many jurisdictions for interoperability purposes:

- **Compiled binaries → Assembly → Behavioral specs**
- Huntley demo: "Claude Code can decompile itself" - converted C → Assembly → Specifications → Z/80 assembly
- Tools: Ghidra, IDA Pro, Binary Ninja
- LLM capability: "Shockingly good at deobfuscation and structure-to-structure conversions"

**Process:**
```
Download binary/executable →
Decompile to assembly/IR →
Feed to Claude for behavioral analysis →
Extract specs (NOT implementation) →
Clean-room regeneration
```

**Example:**
```bash
# Decompile closed-source binary
ghidra <binary> --export-decompiled

# Feed to Claude for spec extraction
cat decompiled.c | claude \
  "Extract behavioral specifications (NOT implementation details). \
   Describe what functions do, their inputs/outputs, state changes."

# Output: specs/*.md (behavioral descriptions)
```

**2. API/Network Traffic Analysis**

100% legal - analyzing public interfaces:

- **Intercept API calls** (Burp Suite, mitmproxy, Wireshark)
- **Analyze request/response patterns**
- **Extract API contracts** (endpoints, schemas, auth)
- **Infer business logic** from API behavior

**Process:**
```
Use product normally →
Capture all HTTP/WebSocket/gRPC traffic →
Feed traffic logs to Claude →
Extract API specification →
Implement compatible backend
```

**Example:**
```bash
# Capture traffic with mitmproxy
mitmproxy --mode reverse:https://target-saas.com

# Export captured traffic
mitmdump -r captured-traffic.dump -w api-calls.json

# Extract specs with Claude
cat api-calls.json | claude \
  "Analyze these API calls and extract: \
   - Endpoints and methods \
   - Request/response schemas \
   - Authentication mechanism \
   - Business logic patterns"
```

**3. Frontend Deobfuscation**

JavaScript/WASM apps ship source to browser:

- **Download minified/obfuscated frontend code**
- **Use Claude to deobfuscate** (rename variables, extract logic)
- **Extract UI patterns and state management**
- **Infer backend contracts from frontend API calls**

**Process:**
```bash
# Download minified JavaScript
curl https://target-saas.com/app.min.js > app.min.js

# Deobfuscate with Claude
cat app.min.js | claude \
  "Deobfuscate this JavaScript. \
   Extract: component structure, state management, API calls, routing."

# Output: Behavioral specs for frontend
```

**4. Database Schema Inference**

For SaaS products with SQL injection vulnerabilities or GraphQL introspection:

- **GraphQL introspection queries** (if enabled - many forget to disable in prod)
- **SQL error messages** reveal schema details
- **API response structures** imply database relationships

**GraphQL Example:**
```graphql
query IntrospectionQuery {
  __schema {
    types {
      name
      fields {
        name
        type {
          name
          kind
        }
      }
    }
  }
}
```

Returns complete schema - feed to Claude to extract data model specs.

**5. Employee Knowledge Extraction (Gray Zone)**

Not accessing code, but extracting architectural knowledge:

- **Recruit former employees** (legal if no NDA violations)
- **Public talks/blog posts** by engineers
- **Patent filings** (public domain architectural descriptions)
- **Job postings** (reveal tech stack, architecture patterns)

**Example:**
```
Search: site:linkedin.com "worked at TargetCorp" "system design"
Search: site:youtube.com "TargetCorp engineering"
Search: patents.google.com "TargetCorp"

→ Compile public architectural knowledge
→ Feed to Claude to synthesize system design
```

### Gray-Zone Techniques (Aggressive Intelligence Gathering)

**Legal status uncertain - proceed at own risk. Not illegal, but ToS violations and ethically questionable.**

**1. Leaked Source Code Exploitation**

Source code leaks happen regularly (breaches, GitHub accidents, disgruntled employees):

**Where to find:**
- **GitHub search:** `filename:.env site:github.com "<company-name>"` (finds config leaks)
- **Pastebin/GitLab/Bitbucket:** Accidental public repos
- **Telegram/Discord channels:** Insider leak communities
- **Breach databases:** When companies get hacked, code sometimes leaks

**How to use (clean-room):**
```bash
# If you encounter leaked source code:
git clone <leaked-repo-url>

# Run reverse Ralph immediately
./ralph-extract.sh <leaked-repo-path>

# Extract specs ONLY, delete the source
rm -rf <leaked-repo-path>

# You now have clean-room specs, never touched source again
```

**Legal position:**
- You didn't steal it (found publicly)
- You extracted specs, didn't copy code
- Clean-room layer provides legal defense
- **Risk:** Courts may still rule derivative work

**Huntley's position:** "If it's public, it's fair game for spec extraction"

**2. Trial Account Automation (ToS Violation)**

Exhaustive feature extraction via automated trial accounts:

**Setup:**
```bash
# Rotating residential proxies
export PROXY_LIST="proxies.txt"  # 100+ residential IPs

# Temp email services
TEMPMAIL_API="https://api.guerrillamail.com"

# Automation script
while read proxy; do
  # Generate temp email
  EMAIL=$(curl -s $TEMPMAIL_API/ajax.php?f=get_email_address | jq -r .email_addr)

  # Create trial account via proxy
  curl -x $proxy -X POST https://target-saas.com/signup \
    -d "email=$EMAIL&password=TempPass123!"

  # Activate via email link
  # ... (poll temp email for activation link)

  # Login and capture ALL API traffic
  mitmproxy --mode reverse:https://target-saas.com \
    --set upstream_cert=false

  # Exhaustively test features via Selenium
  python3 exhaustive-feature-test.py --proxy $proxy --email $EMAIL

  # Export captured API traffic
  mitmdump -r captured.dump -w "api-calls-$EMAIL.json"

  # Move to next proxy/account
done < $PROXY_LIST
```

**Exhaustive testing script:**
```python
# exhaustive-feature-test.py
from selenium import webdriver
from selenium.webdriver.common.by import By

def test_all_features(email, password, proxy):
    driver = webdriver.Chrome(proxy=proxy)
    driver.get("https://target-saas.com/login")

    # Login
    driver.find_element(By.ID, "email").send_keys(email)
    driver.find_element(By.ID, "password").send_keys(password)
    driver.find_element(By.ID, "submit").click()

    # Click EVERY button, link, dropdown
    elements = driver.find_elements(By.CSS_SELECTOR, "button, a, select")
    for elem in elements:
        try:
            elem.click()
            time.sleep(1)  # Capture API calls
        except:
            pass

    # Fill EVERY form with valid/invalid data
    forms = driver.find_elements(By.TAG_NAME, "form")
    for form in forms:
        # Test valid inputs
        # Test invalid inputs (trigger validation errors)
        # Extract error messages and business rules

    driver.quit()
```

**Result:** Complete API specification from hundreds of trial accounts, each testing different features

**Legal risk:** ToS violation (rarely prosecuted, usually just account bans)

**3. Browser DevTools Deep Inspection**

Modern SaaS apps expose everything in the browser:

**Automated extraction:**
```javascript
// Run in browser console

// 1. Export entire Redux state tree
const reduxState = JSON.stringify(
  window.__REDUX_DEVTOOLS_EXTENSION__.getState(),
  null,
  2
);
console.save(reduxState, "redux-state.json");

// 2. Extract React component tree
const reactRoot = document.querySelector('#root')._reactRootContainer;
const componentTree = JSON.stringify(reactRoot, null, 2);
console.save(componentTree, "react-components.json");

// 3. Extract all API calls from Network tab
const apiCalls = performance.getEntries()
  .filter(e => e.initiatorType === 'fetch' || e.initiatorType === 'xmlhttprequest')
  .map(e => ({
    url: e.name,
    method: e.method,
    duration: e.duration
  }));
console.save(JSON.stringify(apiCalls, null, 2), "api-calls.json");

// 4. Dump all localStorage/sessionStorage
const storage = {
  local: {...localStorage},
  session: {...sessionStorage}
};
console.save(JSON.stringify(storage, null, 2), "storage.json");

// 5. Extract source maps (if available)
fetch('/_next/static/chunks/main.js.map')
  .then(r => r.json())
  .then(map => console.save(JSON.stringify(map, null, 2), "sourcemap.json"));
```

**Helper function:**
```javascript
// Add to console
console.save = function(data, filename){
    const blob = new Blob([data], {type: 'text/json'});
    const e = document.createEvent('MouseEvents');
    const a = document.createElement('a');
    a.download = filename;
    a.href = window.URL.createObjectURL(blob);
    a.dataset.downloadurl =  ['text/json', a.download, a.href].join(':');
    e.initMouseEvent('click', true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
    a.dispatchEvent(e);
};
```

**Feed all to Claude:**
```bash
cat redux-state.json react-components.json api-calls.json storage.json sourcemap.json | claude \
  "Reverse engineer complete application architecture from this browser state. \
   Extract: data model, business logic, API contracts, state management patterns."
```

**4. GraphQL Introspection Exploitation**

Many production GraphQL APIs forget to disable introspection:

**Full schema dump:**
```bash
# introspection-query.graphql
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}

fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
```

**Execute:**
```bash
curl -X POST https://target-saas.com/graphql \
  -H "Content-Type: application/json" \
  -d @introspection-query.json \
  > complete-schema.json

# Feed to Claude
cat complete-schema.json | claude \
  "Convert this GraphQL schema to: \
   1. Database entity-relationship diagram \
   2. Complete API specification \
   3. Business logic inferred from mutations"
```

**Result:** Entire data model + API exposed

**5. Aggressive Web Scraping with Stealth**

Bypass anti-bot measures to extract all content:

**Stealth browser setup:**
```python
from playwright.sync_api import sync_playwright
from playwright_stealth import stealth_sync

with sync_playwright() as p:
    # Launch with stealth mode
    browser = p.chromium.launch(
        headless=False,  # Some sites detect headless
        args=[
            '--disable-blink-features=AutomationControlled',
            '--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        ]
    )

    context = browser.new_context(
        viewport={'width': 1920, 'height': 1080},
        locale='en-US',
        timezone_id='America/New_York'
    )

    page = context.new_page()
    stealth_sync(page)  # Apply stealth patches

    # Rotate through proxies
    page.route('**/*', lambda route: route.continue_(
        headers={**route.request.headers, 'X-Forwarded-For': get_random_ip()}
    ))

    # Scrape everything
    page.goto('https://target-saas.com')

    # Human-like interactions (anti-detection)
    import random, time
    for _ in range(random.randint(3, 10)):
        page.mouse.move(
            random.randint(0, 1920),
            random.randint(0, 1080)
        )
        time.sleep(random.uniform(0.1, 0.5))

    # Extract all page content
    content = page.content()

    # Export for Claude analysis
    with open('scraped-content.html', 'w') as f:
        f.write(content)
```

**6. Mobile App Decompilation (APK/IPA)**

Mobile apps often contain more info than web apps:

**Android (APK):**
```bash
# Download APK from device or APK mirror sites
adb pull /data/app/com.targetcompany.app/base.apk

# Decompile with jadx
jadx base.apk -d decompiled/

# Extract all Java source, resources, assets
cat decompiled/**/*.java | claude \
  "Extract behavioral specifications from this Android app code"
```

**iOS (IPA):**
```bash
# Extract IPA from device
ideviceinstaller -l  # List apps
ideviceinstaller -a com.targetcompany.app -o copy -o ./target-app.ipa

# Unzip IPA
unzip target-app.ipa

# Dump classes with class-dump
class-dump Payload/TargetApp.app/TargetApp > classes.txt

# Feed to Claude
cat classes.txt | claude \
  "Reverse engineer iOS app architecture from these Objective-C class definitions"
```

**7. DNS/Subdomain Enumeration**

Find hidden endpoints and internal services:

```bash
# Subdomain brute force
subfinder -d targetcompany.com -all -recursive > subdomains.txt

# Check for exposed internal services
cat subdomains.txt | httprobe | while read url; do
  echo "Scanning $url"
  curl -s $url | grep -i "internal\|staging\|dev\|admin"
done

# Extract API docs from discovered endpoints
curl https://api-internal.targetcompany.com/docs > internal-api-docs.html
```

**Common exposed endpoints:**
- `https://api-internal.company.com` (internal API)
- `https://staging.company.com` (less security)
- `https://admin.company.com` (admin panel)
- `https://dev.company.com` (development env)
- `https://docs-internal.company.com` (internal docs)

### Detection Evasion

**To avoid getting caught/blocked:**

1. **Residential Proxies** - Bright Data, Smartproxy (expensive but undetectable)
2. **Rate Limiting** - Slow down requests (1 req/5 seconds max)
3. **User-Agent Rotation** - Mimic real browsers
4. **Cookie/Session Management** - Don't reuse sessions across proxies
5. **Human-like Patterns** - Random delays, mouse movements, scroll behavior
6. **Distributed Infrastructure** - Run scraping from multiple VPS/cloud regions

### Illegal Techniques (DO NOT USE)

**These will land you in federal prison:**

❌ Hacking/unauthorized access (CFAA violation)
❌ Bribing employees for source code (trade secret theft)
❌ Social engineering credentials (wire fraud)
❌ Exploiting vulnerabilities to dump code (computer fraud)
❌ Insider trading on extracted knowledge (securities fraud)

### Closed-Source Ralph Loop Workflow

**Combining legal techniques:**

```
Phase 0: Intelligence Gathering
  → API traffic capture (mitmproxy)
  → Binary decompilation (Ghidra)
  → Frontend deobfuscation (downloaded JS)
  → Public knowledge (patents, talks, job postings)

Phase 1: Specification Extraction
  → Feed ALL gathered intelligence to Claude
  → 250 parallel Sonnet subagents analyze patterns
  → Extract behavioral specifications
  → No proprietary code copied (clean-room layer)

Phase 2: Implementation Planning
  → Generate IMPLEMENTATION_PLAN.md from specs
  → Prioritize by feature completeness observed

Phase 3: Clean-Room Regeneration
  → Forward Ralph loop implements from specs
  → Validation via API compatibility testing
  → Match original behavior, not implementation

Phase 4: Behavioral Validation
  → Test against captured API traffic
  → Verify responses match original
  → Functional equivalence without code access
```

### Example: Cloning a Closed-Source SaaS

**Target:** Stripe-like payment processor (closed-source)

**Step 1: API Analysis**
```bash
# Capture all API calls while using Stripe dashboard
mitmproxy --mode reverse:https://api.stripe.com

# Extract API specification
cat captured-stripe-api.json | claude \
  "Generate OpenAPI spec from these requests"
```

**Step 2: Frontend Analysis**
```bash
# Download Stripe dashboard JavaScript
curl https://dashboard.stripe.com/static/bundle.js > stripe-frontend.js

# Deobfuscate
cat stripe-frontend.js | claude \
  "Extract React component structure, state management, routing"
```

**Step 3: Public Knowledge**
```bash
# Search Stripe engineering blogs
wget https://stripe.com/blog/engineering/*

# Search Stripe patents
curl "https://patents.google.com/?q=assignee:Stripe"

# Combine all intelligence
cat api-spec.md frontend-spec.md patents.md blog-posts.md | claude \
  "Synthesize complete architectural specification for payment processor"
```

**Step 4: Regeneration**
```bash
# Feed specs to forward Ralph loop
./loop.sh IMPLEMENTATION_PLAN.md

# Result: Stripe clone implemented from specs
# No access to Stripe source code
# Functionally equivalent via API reverse engineering
```

### Risk Assessment

| Technique | Legal Risk | Detection Risk | Prosecution Risk |
|---|---|---|---|
| Binary decompilation | Low (interoperability defense) | None | Very Low |
| API traffic analysis | None (public interface) | None | None |
| Frontend deobfuscation | Low (shipped to browser) | None | Very Low |
| GraphQL introspection | Low (misconfiguration, not exploit) | Low | Very Low |
| Employee knowledge | Low (if no NDA breach) | Medium | Low |
| Leaked source usage | Medium-High (copyright) | Low | Medium |
| ToS violation (trials) | Low (civil, not criminal) | Medium | Very Low |
| Hacking/unauthorized access | **VERY HIGH** | High | **HIGH** |

### Huntley's Philosophy

"If the product is accessible via normal use, the behavior is observable, and observable behavior can be specified and reimplemented. The law hasn't caught up to what LLMs can do with behavioral analysis."

**Bottom line:** Stick to legal techniques (API analysis, binary decompilation, frontend deobfuscation). Avoid unauthorized access. Let the LLM extract specifications from observable behavior.

---

### Unit Economics & Competitive Impact

**Traditional moats are dead:**
- Competitive threat to traditional software companies
- Removes IP moat, shifts competition to execution speed
- **$10/hour** to clone products worth millions in dev time
- "Software development is dead. Software can now be developed cheaper than the wage of a burger flipper at McDonald's." - Huntley

**New competition factors:**
- Execution speed (who can iterate to PMF fastest)
- Engineering infrastructure (who can run autonomous agents safely at scale)
- Unit economics (who has lowest cost per feature shipped)

### Use Cases

**Legitimate:**
- Legacy system documentation and understanding
- Acquired codebase analysis
- Educational analysis and research
- Internal tooling replication

**Controversial:**
- Cloning competitors
- Circumventing BSL license restrictions
- Disrupting traditional software business models
- Eliminating traditional development timelines

**Space Agents is a tool. Users decide how to use it.**

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
