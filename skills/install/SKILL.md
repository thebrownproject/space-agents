---
name: install
description: "Use to install Space-Agents in a project. Creates .space-agents/ directory and initializes Beads for issue tracking. Run once per project."
---

# /install - Space-Agents Installation

Install Space-Agents in the current project. Creates the directory structure and initializes Beads for issue tracking.

---

## Trigger

User runs `/install` or is prompted from `/launch` when system not found.

## Prerequisites

- `bd` CLI must be available on the system (v0.47.0+)
- Write permissions for current directory

---

## Installation Steps

### Step 1: Check for Existing Installation

```bash
if [ -d ".space-agents" ]; then
    # Check version or offer upgrade
fi
```

If `.space-agents/` already exists:
1. Check if `.beads/issues.jsonl` exists
2. Ask user: **Reinstall/upgrade** or **Cancel**
3. If reinstall: backup existing data, proceed with fresh install
4. If cancel: exit gracefully

---

### Step 2: Create Directory Structure

Create the full Space-Agents directory structure:

```bash
mkdir -p .space-agents/comms
mkdir -p .space-agents/exploration
mkdir -p .space-agents/missions/staged
mkdir -p .space-agents/missions/active
mkdir -p .space-agents/missions/complete
```

**Directory structure:**

```
.space-agents/
├── comms/
│   ├── capcom.md            # Master CAPCOM log (append-only)
│   ├── handover.md          # Context dump for fresh sessions
│   └── notifications.md     # Event notifications
├── exploration/             # Exploration sessions (/exploration output)
└── missions/
    ├── staged/              # Planned missions ready for execution
    ├── active/              # In-progress work
    └── complete/            # Archived work
```

---

### Step 3: Initialize Beads

Initialize Beads for issue tracking (if not already done):

```bash
# Initialize Beads if not already done
if [ ! -f ".beads/issues.jsonl" ]; then
    bd init
fi
```

Beads provides:
- Git-backed issue tracking with `.beads/issues.jsonl`
- Dependency management between tasks
- Context persistence across session compaction

---

### Step 4: Create Initialization Files

Create empty/default files:

**`.space-agents/comms/capcom.md`:**
```markdown
# CAPCOM Master Log

*Append-only. Grep-only. Never read fully.*

---

## [YYYY-MM-DD HH:MM] System Initialized

Space-Agents installed. HOUSTON standing by.

---
```

**`.space-agents/comms/handover.md`:**
```markdown
# Space-Agents Handover

*Context dump for fresh sessions*

---

[No handover pending]
```

**`.space-agents/comms/notifications.md`:**
```markdown
# Space-Agents Notifications

*Event log from Ralph loop*

---
```

---

### Step 5: Display Installation Complete

Show the installation success screen:

```
+------------------------------------------------------------------+
|                                                                  |
|     SPACE AGENTS                                                 |
|                                                                  |
|             INSTALLATION COMPLETE                                |
|                                                                  |
+------------------------------------------------------------------+
|                                                                  |
|  Created:                                                        |
|    [x] .space-agents/ directory structure                        |
|    [x] Beads initialized (.beads/)                               |
|    [x] CAPCOM master log                                         |
|    [x] Handover and notifications files                          |
|                                                                  |
+------------------------------------------------------------------+
|                                                                  |
|  Next steps:                                                     |
|    1. Run /launch to start a session                             |
|    2. Describe what you want to build                            |
|    3. HOUSTON will plan the voyage                               |
|                                                                  |
+------------------------------------------------------------------+
```

---

## Error Handling

**If bd CLI not found:**
```
ERROR: bd CLI is required but not found.

Please install Beads CLI (v0.47.0+):
  npm install -g beads-cli

Verify installation:
  bd --version
```

**If directory creation fails:**
```
ERROR: Could not create .space-agents/ directory.

Check that you have write permissions for the current directory.
```

**If already installed:**
```
Space-Agents is already installed in this project.

What would you like to do?
  [1] Reinstall (backup existing data)
  [2] Cancel
```

---

## Summary

The `/install` skill:
1. Checks for existing installation
2. Creates directory structure (comms/, exploration/, missions/)
3. Initializes Beads for issue tracking
4. Creates initialization files (capcom.md, handover.md, notifications.md)
5. Displays installation complete screen
6. Guides user to run `/launch`

Run once per project. After installation, use `/launch` to start sessions.
