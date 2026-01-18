# MSN-001-Schema-v2: SQLite Schema Update

**Status:** Active
**Created:** 2026-01-18

## Goal

Update SQLite schema for MVP hierarchy (Mission → Objective) and add mission_id to alerts table.

## Objectives

1. **OBJ-001** - Update init-db.sql schema
2. **OBJ-002** - Update agent alert INSERTs
3. **OBJ-003** - Update skill queries

## Context

- Database is currently empty (0 data rows), so no migration needed
- After changes, re-run `/install` to recreate database with new schema

## Key Files

- `skills/install/scripts/init-db.sql` - Schema definition
- `skills/mission/scripts/ralph.sh` - Alert creation function
- `agents/mission-pod.md` - Alert INSERT statements
- `agents/mission-analyst.md` - Alert INSERT statements
- `skills/capcom/SKILL.md` - Alert queries
- `skills/handover/SKILL.md` - Alert queries

## Exploration Report

See: `.space-agents/exploration/2026-01-18-schema-hierarchy/exploration.md`
