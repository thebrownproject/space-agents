# Plan: Space-Agents Architecture Refactor

**Date:** 2026-01-16
**Status:** In Progress

## Summary

Refactor Space-Agents plugin architecture based on brainstorming session:
1. ~~Split `/launch` into `/install` + `/launch`~~ ✅ `/install` created
2. Distribute scripts via skills (ralph→mission-run, airlock→own skill)
3. Merge houston.md into `/launch` skill
4. Update worker to report to Pod (Pod handles alerts)
5. Add ASCII logout screen to `/dock`

---

## Progress

| Task | Status |
|------|--------|
| Create `/install` skill | ✅ DONE |
| Refactor `/launch` skill | ✅ DONE |
| Create `/airlock` skill | ✅ DONE |
| Implement `/mission-run` skill | ✅ DONE |
| Update `agents/worker.md` | ✅ DONE |
| Update `agents/pod.md` | ✅ DONE |
| Update `/dock` skill | ✅ DONE |
| Delete redundant files | ✅ DONE |
| Test full flow | ⏳ TODO |

---

## Remaining Changes

### 1. Refactor `/launch` Skill

**File:** `skills/launch/SKILL.md`

**Remove:**
- Directory creation logic
- SQLite initialization logic

**Add:**
- Installation check (does `.space-agents/space-agents.db` exist?)
- If not installed: Show "HOUSTON OFFLINE" screen + AskUserQuestion with choices:
  - Install system
  - Debug existing system
  - Cancel
- Merge full HOUSTON persona from `agents/houston.md`

**Keep:**
- Welcome screen display
- Staging load
- Alert display
- Session start behavior

---

### 2. Create `/airlock` Skill

**New file:** `skills/airlock/SKILL.md`

**Purpose:** Standalone validation gate (test + lint)

**Contents:**
- Embed airlock.sh script (from `scripts/airlock.sh` - 376 lines)
- Instructions for Pod to invoke
- Can also be invoked directly by user (`/airlock` to run tests)

---

### 3. Implement `/mission-run` Skill

**File:** `skills/mission-run/SKILL.md` (currently empty)

**Contents:**
- Embed ralph.sh script (from `scripts/ralph.sh` - 522 lines)
- Mode selection (Attended vs Background)
- Launch instructions
- Exit code handling

---

### 4. Update `agents/worker.md`

**Remove:** Direct SQLite alert insertion

**Add:** Structured output format for reporting issues to Pod:
```
[ALERT:severity] Description
```
Where severity is: critical, blocker, warning, info

Pod parses this output and creates alerts in SQLite.

---

### 5. Update `agents/pod.md`

**Add:**
- Parse Worker output for `[ALERT:*]` patterns
- Create alerts in SQLite based on parsed output
- Handle all state management (alerts, messages, status updates)

---

### 6. Update `/dock` Skill

**File:** `skills/dock/SKILL.md`

**Add:** ASCII art logout screen showing:
- Session duration
- Objectives completed
- Alerts cleared
- Active voyage progress
- NASA-style signoff ("Safe travels, Commander")

---

### 7. Delete Redundant Files

| File | Reason |
|------|--------|
| `agents/houston.md` | Merged into `/launch` skill |
| `scripts/ralph.sh` | Moved into `/mission-run` skill |
| `scripts/airlock.sh` | Moved into `/airlock` skill |
| `scripts/init-db.sql` | Moved into `/install` skill |

---

## Key Reference Files

For the next session, these files contain the content to embed:

- `scripts/ralph.sh` → embed in `/mission-run`
- `scripts/airlock.sh` → embed in `/airlock`
- `agents/houston.md` → merge into `/launch`

---

## Verification

1. **Fresh install test:**
   - Remove any existing `.space-agents/` directory
   - Run `/launch` → should show "HOUSTON OFFLINE" + install prompt
   - Select "Install system" → should trigger `/install`
   - Run `/launch` again → should show welcome screen

2. **Existing install test:**
   - With `.space-agents/` present, run `/launch`
   - Should skip install check, show welcome immediately

3. **Airlock standalone test:**
   - Run `/airlock` directly
   - Should execute tests and linting

4. **Mission-run test:**
   - Create a test voyage/mission/objective in SQLite
   - Run `/mission-run`
   - Verify ralph.sh executes and spawns Pod

5. **Worker alert flow test:**
   - Simulate Worker encountering blocker
   - Verify structured output format
   - Verify Pod parses and creates alert

6. **Dock screen test:**
   - Run `/dock`
   - Verify ASCII art displays with session stats

---

## Implementation Order

1. ~~Create `/install` skill~~ ✅
2. ~~Refactor `/launch` skill~~ ✅ (installation check, HOUSTON OFFLINE screen, merged persona)
3. Create `/airlock` skill (standalone)
4. Implement `/mission-run` skill
5. Update `agents/worker.md` (structured output)
6. Update `agents/pod.md` (alert parsing)
7. Update `/dock` skill (ASCII screen)
8. Delete redundant files
9. Test full flow
