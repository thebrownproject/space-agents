# SAL-9000 Agent Roles

Themed after 2001: A Space Odyssey and NASA Mission Control.

## The Hierarchy

```
PROGRAM (Your Project)
    │
    └── MISSION (Epic)
            │
            └── POD (Feature)
                    │
                    └── CREW (Workers)
                            ├── Engineer
                            ├── Inspector
                            └── Analyst
```

## Role Overview

| Role | Type | Function | NASA Equivalent |
|------|------|----------|-----------------|
| **SAL** | Main Session | Mission coordination | Commander |
| **Pod** | Subagent | Feature coordination | Department Lead |
| **Crew** | Subagent | Task execution (category) | Astronauts |
| **CAPCOM** | Subagent | Message broker | Capsule Communicator |
| **Airlock** | Function | Validation | Release Manager |
| **Maintenance** | Skill | Cleanup | Ground Support |

### Crew Types (Workers)

| Crew Type | Role | NASA Equivalent |
|-----------|------|-----------------|
| **Engineer** | Does the work | Flight Engineer |
| **Inspector** | Verifies requirements | Quality Assurance |
| **Analyst** | Reviews code quality | Systems Analyst |
| *(future)* | More types can be added | - |

## Visual Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SAL-9000                                          │
│        "I am completely operational, and ready to assist."                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   YOU (Mission Control)                                                     │
│   └── Gives objectives, approves plans                                      │
│                         │                                                   │
│                         ▼                                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    SAL (Commander)                                  │   │
│   │                    THIS CONVERSATION                                │   │
│   └───────────────────────────┬─────────────────────────────────────────┘   │
│                               │                                             │
│            ┌──────────────────┼──────────────────┐                         │
│            ▼                  ▼                  ▼                          │
│      ┌──────────┐       ┌──────────┐       ┌──────────┐                    │
│      │  POD 1   │       │  POD 2   │       │  POD 3   │                    │
│      └────┬─────┘       └────┬─────┘       └────┬─────┘                    │
│           │                  │                  │                           │
│      ┌────┴────┐        ┌────┴────┐        ┌────┴────┐                     │
│      │  CREW   │        │  CREW   │        │  CREW   │                     │
│      │┌───────┐│        │┌───────┐│        │┌───────┐│                     │
│      ││Engineer│        ││Engineer│        ││Engineer│                     │
│      │├───────┤│        │├───────┤│        │├───────┤│                     │
│      ││Inspctor│        ││Inspctor│        ││Inspctor│                     │
│      │├───────┤│        │├───────┤│        │├───────┤│                     │
│      ││Analyst││        ││Analyst││        ││Analyst││                     │
│      │└───────┘│        │└───────┘│        │└───────┘│                     │
│      └────┬────┘        └────┬────┘        └────┬────┘                     │
│           │                  │                  │                           │
│           └──────────────────┴──────────────────┘                           │
│                              │                                              │
│                              ▼                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  CAPCOM (Message Broker)                                            │   │
│   │  - Receives reports via SQLite queue                                │   │
│   │  - Spawns Inspector + Analyst after Engineer                        │   │
│   │  - Runs Airlock validation                                          │   │
│   │  - Routes feedback to Pods, summaries to SAL                        │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   MAINTENANCE (Skill) - /maintenance for cleanup                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Detailed Role Descriptions

### SAL (Commander)

**Type**: Main Session (the conversation itself)

**Role**: Owns the entire mission

**Responsibilities**:
- Receive user objectives
- Create mission in SQLite + folder structure
- Break mission into Pods (features)
- Present Pod plan for approval
- Spawn Pod subagents
- Receive summaries from CAPCOM
- Report mission completion

**Does NOT**: Execute tasks directly, receive detailed task reports

**Context receives**: Mission-level summaries only

---

### Pod (Feature Orchestrator)

**Type**: Subagent (spawned by SAL)

**Role**: Department Lead - owns a feature within the mission

**Responsibilities**:
- Receive feature assignment from SAL
- Create pod folder and documentation
- Break feature into tasks
- Spawn Engineer for each task
- Receive filtered feedback from CAPCOM
- Resume Engineer if fixes needed
- Report feature completion to CAPCOM

**Context receives**: Task summaries and feedback for its tasks only

**Implementation**: `agents/pod.md`

---

### Crew (Workers)

**Type**: Subagent category (spawned by Pod or CAPCOM)

**Role**: Astronauts - execute tasks

Crew is the category of worker agents. There are currently three specialist types:

---

#### Engineer

**Type**: Crew (spawned by Pod)

**Role**: Does the actual work

**Responsibilities**:
- Receive task requirements
- Execute the task (write code, create files)
- Report completion to CAPCOM via messages table
- Accept feedback and make fixes if needed

**Context receives**: Task requirements, specific feedback from reviews

**Implementation**: `agents/crew/engineer.md`

---

#### Inspector

**Type**: Crew (spawned by CAPCOM after Engineer)

**Role**: QA Engineer - verifies requirements

**Responsibilities**:
- Receive implementation summary + original requirements
- Verify all requirements are met
- Report pass/fail with specific feedback
- Does NOT review code quality (that's Analyst's job)

**Context receives**: Requirements + implementation summary only

**Implementation**: `agents/crew/inspector.md`

---

#### Analyst

**Type**: Crew (spawned by CAPCOM after Engineer)

**Role**: Peer Reviewer - reviews code quality

**Responsibilities**:
- Receive implementation summary
- Review code quality, patterns, best practices
- Report pass/fail with specific feedback
- Does NOT verify requirements (that's Inspector's job)

**Context receives**: Implementation summary only

**Implementation**: `agents/crew/analyst.md`

---

### CAPCOM (Flight Controller)

**Type**: Subagent (spawned by hook on Crew completion)

**Role**: Message broker and context filter

**Responsibilities**:
- Read messages from SQLite queue
- Spawn Inspector and Analyst after Engineer completes
- Run Airlock validation (tests, lint)
- Aggregate results
- Route issues back to Pod with filtered feedback
- Summarize results to SAL

**Context receives**: All Crew reports (but filters before forwarding)

**Implementation**: `agents/capcom.md`

**Named after**: NASA's CAPCOM - the only voice that speaks directly to astronauts

---

### Airlock (Validation)

**Type**: Function (called by CAPCOM)

**Role**: Release Manager - validates work

**Responsibilities**:
- Run tests
- Run linter
- Check build
- Return pass/fail

**Not a subagent** - just a validation function CAPCOM calls

**Named after**: The airlock on Discovery - single point of entry/exit

---

### Maintenance (Cleanup)

**Type**: Skill (manually invoked)

**Role**: Ground Support - housekeeping

**Responsibilities**:
- Move completed missions to `complete/`
- Archive old missions to `archive/`
- Clean up stale data

**Implementation**: `skills/maintenance/SKILL.md` - invoke with `/maintenance`

## Context Filtering

The key to keeping agents efficient - each receives only what they need:

| Agent | Receives | Does NOT Receive |
|-------|----------|------------------|
| **SAL** | Pod summaries | Task details, code diffs, review logs |
| **Pod** | Task summaries, feedback | Other Pods' work, full review content |
| **Engineer** | Requirements, feedback | Other tasks, review process |
| **Inspector** | Requirements + implementation | Code style issues, other tasks |
| **Analyst** | Implementation summary | Requirements rationale, other tasks |
| **CAPCOM** | All reports | - (but summarizes before forwarding) |

## Communication Flow

```
                                        ┌─────────────────┐
                                        │      SAL        │
                                        │   (receives     │
                                        │   summaries)    │
                                        └────────▲────────┘
                                                 │
                              ┌──────────────────┴──────────────────┐
                              │            CAPCOM                   │
                              │  (message broker, context filter)   │
                              └──────────────────┬──────────────────┘
                                                 │
                    ┌────────────────────────────┼────────────────────────────┐
                    │                            │                            │
                    ▼                            ▼                            ▼
              ┌──────────┐                 ┌──────────┐                 ┌──────────┐
              │   POD    │                 │   POD    │                 │   POD    │
              │(receives │                 │(receives │                 │(receives │
              │ feedback)│                 │ feedback)│                 │ feedback)│
              └────┬─────┘                 └────┬─────┘                 └────┬─────┘
                   │                            │                            │
         ┌─────────┼─────────┐                  │                            │
         ▼         ▼         ▼                  ▼                            ▼
    ┌────────┐┌────────┐┌────────┐         ┌────────┐                  ┌────────┐
    │Engineer││Inspctor││Analyst │         │  ...   │                  │  ...   │
    └───┬────┘└───┬────┘└───┬────┘         └────────┘                  └────────┘
        │         │         │
        └─────────┴─────────┘
                  │
                  ▼
           SQLite messages
           (CAPCOM's inbox)
```

## Task Lifecycle

```
1. Pod spawns Engineer
   └── Engineer writes to messages: "task complete"

2. Hook triggers CAPCOM
   └── CAPCOM reads message queue
   └── Spawns Inspector → writes to messages
   └── Spawns Analyst → writes to messages

3. CAPCOM aggregates results
   └── Runs Airlock validation

4. CAPCOM decides:
   ├── All passed → Message to Pod: "task complete"
   └── Issues → Message to Pod: "feedback" with details

5. Pod handles result:
   ├── Complete → Next task
   └── Feedback → Resume Engineer with issues

6. Cycle repeats until task complete
```

## When to Use Each Agent

| Scenario | Primary Agent | Flow |
|----------|---------------|------|
| Start mission | SAL | SAL → creates mission → spawns Pods |
| Work on feature | Pod | Pod → spawns Engineer |
| Execute task | Engineer | Engineer → writes code |
| Verify requirements | Inspector | CAPCOM spawns → reviews → reports |
| Review code | Analyst | CAPCOM spawns → reviews → reports |
| Route messages | CAPCOM | Reads queue → routes → summarizes |
| Validate work | Airlock | Called by CAPCOM → runs tests |
| Cleanup | Maintenance | User invokes /maintenance |

## Adding New Crew Types

The Crew category is extensible. To add a new worker type:

1. Create `agents/crew/<type>.md` with the subagent definition
2. Update SQLite schema if needed (e.g., new review type)
3. Update CAPCOM to spawn the new type when appropriate

Example future types:
- **Researcher** - Gathers information before implementation
- **Documenter** - Writes documentation after implementation
- **Tester** - Writes additional test cases
