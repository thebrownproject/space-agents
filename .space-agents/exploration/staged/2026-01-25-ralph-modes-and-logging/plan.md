# Feature: Ralph Modes and Logging

**Goal:** Add lightweight mode (default) to ralph.sh and implement file logging for debugging.

## Overview

Currently ralph.sh only supports pod mode with full agent crew. We need:
1. Lightweight mode as default (Pathfinder scouts, HOUSTON executes directly)
2. --pod flag for full crew when needed
3. File logging for debugging and audit trail

**Token savings:** Lightweight mode uses ~50k tokens/task vs ~150k+ for pod mode.

## Tasks

### Task: Add --pod Flag and Lightweight Mode

**Goal:** Add --pod flag to ralph.sh that defaults to lightweight HOUSTON-direct execution.
**Files:**
- Modify: skills/mission-ralph/scripts/ralph.sh
**Depends on:** None

**Steps:**
1. Add POD_MODE=false variable after VISIBLE_MODE
2. Add --pod case to argument parsing (sets POD_MODE=true)
3. Update usage message to document --pod flag
4. Modify spawn_pod() to check POD_MODE:
   - If true: use existing /mission-pod prompt
   - If false: use lightweight prompt (Pathfinder scout → HOUSTON direct → Airlock)
5. Test both modes with a simple task

### Task: Add File Logging

**Goal:** Add file logging that captures all ralph.sh output to timestamped log file.
**Files:**
- Modify: skills/mission-ralph/scripts/ralph.sh
- Create: .space-agents/comms/logs/.gitkeep
**Depends on:** None

**Steps:**
1. Create .space-agents/comms/logs/ directory
2. Add LOG_DIR and LOG_FILE variables in main() after FEATURE_ID
3. Add exec > >(tee -a "$LOG_FILE") 2>&1 to redirect output
4. Log the log file path at startup
5. Verify logs appear in .space-agents/comms/logs/ralph-{feature_id}-{timestamp}.log

### Task: Update Documentation

**Goal:** Document both modes in skill files and mission router.
**Files:**
- Modify: skills/mission-ralph/SKILL.md
- Modify: skills/mission/SKILL.md
**Depends on:** Add --pod Flag and Lightweight Mode, Add File Logging

**Steps:**
1. Update mission-ralph description to mention default lightweight mode
2. Add Modes section with table comparing lightweight vs pod
3. Add token comparison (~50k vs ~150k)
4. Update launch command examples to show --pod flag
5. Add Logging section documenting log file location
6. Update mission router table to include Ralph --pod as separate row

## Sequence

1. Add --pod Flag and Lightweight Mode (no dependencies)
2. Add File Logging (no dependencies, parallel with 1)
3. Update Documentation (depends on 1-2)

**Parallelization:** Tasks 1-2 can run in parallel. Task 3 is sequential after both complete.

## Success Criteria

- [ ] `ralph.sh FEATURE_ID` runs lightweight mode (default)
- [ ] `ralph.sh FEATURE_ID --pod` runs full pod crew
- [ ] `ralph.sh FEATURE_ID --visible` works with lightweight mode
- [ ] `ralph.sh FEATURE_ID --visible --pod` works with pod mode
- [ ] Logs created at .space-agents/comms/logs/ralph-{feature_id}-{timestamp}.log
- [ ] All ralph output captured in log file
- [ ] SKILL.md documents both modes with token comparison
- [ ] Mission router shows Ralph vs Ralph --pod distinction
