---
name: install
description: "Use to install Space-Agents in a project. Creates .space-agents/ directory and SQLite database. Run once per project."
---

# /install - Space-Agents Installation

Install Space-Agents in the current project. Creates the directory structure and SQLite database.

---

## Trigger

User runs `/install` or is prompted from `/launch` when system not found.

## Prerequisites

- `sqlite3` must be available on the system
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
1. Check if `space-agents.db` exists and has tables
2. Ask user: **Reinstall/upgrade** or **Cancel**
3. If reinstall: backup existing db, proceed with fresh install
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
│   ├── space-agents.db      # SQLite database (Step 3)
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

### Step 3: Initialize SQLite Database

Create the database using the schema file:

```bash
sqlite3 .space-agents/comms/space-agents.db < scripts/init-db.sql
```

The schema creates:
- `voyages` - Epics/major initiatives
- `missions` - Features within a voyage
- `objectives` - Stories/tasks within a mission (with `worker_attempts` for retry tracking)
- `alerts` - Severity-tracked notifications

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
|    [x] comms/ folder with SQLite database                        |
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

**If sqlite3 not found:**
```
ERROR: sqlite3 is required but not found.

Please install SQLite:
  macOS: brew install sqlite
  Ubuntu: sudo apt install sqlite3
  Windows: Download from sqlite.org/download.html
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
3. Initializes SQLite database with schema
4. Creates initialization files (capcom.md, handover.md, notifications.md)
5. Displays installation complete screen
6. Guides user to run `/launch`

Run once per project. After installation, use `/launch` to start sessions.
