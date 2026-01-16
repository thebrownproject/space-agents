---
name: maintenance
description: Use when cleaning up completed missions, archiving old work, or performing housekeeping on the control-centre folder structure.
---

# Maintenance

*Keeping the control centre tidy.*

## Overview

Maintenance handles cleanup and housekeeping:
- Move completed missions to `complete/`
- Archive old missions to `archive/`
- Clean up stale data
- Report on folder status

## When to Use

Invoke `/maintenance` when:
- A mission has been completed
- You want to archive old missions
- The folder structure needs cleanup
- You want a status report on all missions

## Maintenance Tasks

### 1. Complete a Mission

Move a finished mission from `active/` to `complete/`:

```
control-centre/missions/active/user-auth/
                    ↓
control-centre/missions/complete/user-auth/
```

### 2. Archive Old Missions

Move old completed missions to dated archive folders:

```
control-centre/missions/complete/old-feature/
                    ↓
control-centre/missions/archive/2024-01/old-feature/
```

### 3. Status Report

Show all missions and their status:

```
Mission Status Report

Active:
├─ user-auth          (3 pods, 2 complete)
└─ api-refactor       (2 pods, 0 complete)

Complete:
└─ onboarding-flow    (completed 2 days ago)

Archive:
└─ 2024-01/           (3 missions)
```

### 4. Cleanup

Remove empty folders, orphaned files, or stale data.

## Commands

| Command | Purpose |
|---------|---------|
| `/maintenance` | Run interactive maintenance |
| `/maintenance status` | Show mission status report |
| `/maintenance complete <mission>` | Move mission to complete |
| `/maintenance archive <mission>` | Move mission to archive |
| `/maintenance cleanup` | Remove empty folders |

## Safe Cleanup Rules

Maintenance will NOT delete:
- Active missions
- Recently modified files (< 24h)
- Anything without confirmation

When in doubt, archive rather than delete.
