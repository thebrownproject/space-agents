# Space-Agents Handover

**Generated:** 2026-01-18
**Version:** 1.0.14

---

## Next Session: Full Integration Test

Test the complete workflow: `/exploration` → `/mission-brief` → `/mission`

### Key Changes This Session

- `/pod` skill replaces agents/mission-pod.md
- Composite primary key `(mission_id, id)` for objectives
- Per-mission objective IDs: OBJ-001 resets per mission
- Handovers in `.space-agents/missions/active/<mission>/handovers/`
- No messages table - using worker_attempts + file handovers
- Simplified Ralph prompt: `Run /pod OBJ-001 MSN-XXX`

### Test Focus

1. Does `/pod` skill load in fresh session?
2. Are composite key queries working?
3. Do handovers pass context between Pods?
4. Does visible mode work (mprocs)?

---

## To Start

```
/launch
```
