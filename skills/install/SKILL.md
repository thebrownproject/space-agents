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
mkdir -p .space-agents/missions/todo
mkdir -p .space-agents/missions/active
mkdir -p .space-agents/missions/complete
```

**Directory structure:**

```
.space-agents/
├── space-agents.db          # SQLite database (Step 3)
├── capcom.md                # Master CAPCOM log (append-only)
├── staging.md               # Session buffer
├── notifications            # Cross-session alerts
└── missions/
    ├── todo/                # Planned voyages
    ├── active/              # In-progress work
    └── complete/            # Archived work
```

---

### Step 3: Initialize SQLite Database

Create the database using the schema file:

```bash
sqlite3 .space-agents/space-agents.db < init-db.sql
```

The schema creates:
- `voyages` - Epics/major initiatives
- `missions` - Features within a voyage
- `objectives` - Stories/tasks within a mission
- `messages` - CAPCOM structured queries
- `alerts` - Severity-tracked notifications

---

### Step 4: Create Initialization Files

Create empty/default files:

**`.space-agents/capcom.md`:**
```markdown
# CAPCOM Master Log

*Append-only. Grep-only. Never read fully.*

---

## [YYYY-MM-DD HH:MM] System Initialized

Space-Agents installed. HOUSTON standing by.

---
```

**`.space-agents/staging.md`:**
```markdown
# Space-Agents Staging

*Session buffer - cleared on /dock*

---

[No active session]
```

**`.space-agents/notifications`:**
```
# Space-Agents Notifications
# Format: [timestamp] title: message
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
|    [x] SQLite database with schema                               |
|    [x] CAPCOM master log                                         |
|    [x] Session staging buffer                                    |
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
2. Creates directory structure
3. Initializes SQLite database with schema
4. Creates initialization files (capcom.md, staging.md)
5. Displays installation complete screen
6. Guides user to run `/launch`

Run once per project. After installation, use `/launch` to start sessions.
