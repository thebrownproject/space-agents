# Exploration: Visible Pod Sessions with mprocs

**Date:** 2026-01-18
**Status:** Spike Successful
**Topic:** Making Ralph loop Pod sessions visible to users

---

## Problem Statement

The Ralph execution loop spawns Claude Code sessions (Pods) to work on objectives. Currently, these run with `claude -p` (print mode) which streams text output but doesn't show the interactive TUI. Users want to:

1. **Watch Pods work in real-time** - See Claude thinking, using tools, making decisions
2. **Switch between sessions** - View any Pod while Ralph continues orchestrating
3. **Review completed work** - Scroll back through what a Pod did

---

## Solution Explored: mprocs

**Tool:** [mprocs](https://github.com/pvolok/mprocs) - Terminal multiplexer for running multiple commands with separate output panels.

### Why mprocs over tmux?

| Feature | mprocs | tmux |
|---------|--------|------|
| Purpose-built for multi-process | ✅ | ❌ (general purpose) |
| Process list sidebar | ✅ Built-in | ❌ Manual |
| Dynamic process spawning | ✅ Via TCP API | ⚠️ Scripting required |
| Complexity | Low | Higher |

---

## Key Findings

### 1. Dynamic Process Spawning Works

mprocs supports adding processes at runtime via TCP remote control:

```bash
# Start mprocs with server
mprocs --server 127.0.0.1:4050

# Add process dynamically from another script
mprocs --ctl '{c: add-proc, cmd: "claude --dangerously-skip-permissions", name: "Pod-OBJ-001"}'
```

**Validated:** Ralph can spawn Pods on-demand without pre-defining them in YAML.

### 2. Full Claude TUI Renders Correctly

Running `claude --dangerously-skip-permissions` (without `-p` flag) in mprocs shows:
- The Claude Code ASCII mascot
- Thinking animations
- Tool call displays
- Full interactive interface

**Validated:** Users can watch Claude work in real-time.

### 3. Completion Detection via Signal Files

Pods can signal completion by creating a file that Ralph watches:

```bash
# In Pod's task
"...When done, run: touch /path/to/signals/pod1.done"

# Ralph polls
while [ ! -f "$SIGNAL_FILE" ]; do sleep 2; done
```

**Validated:** Ralph detected completion for 2 sequential Pods correctly.

### 4. Process Panels Persist After Exit

When a Pod completes, its panel stays visible with exit code:
- `DOWN (0)` = Success
- `DOWN (1)` = Error

**Validated:** Users can review completed Pod output by clicking on it.

---

## Limitations Discovered

### 1. Bypass Permissions Requires Confirmation

Even with `--dangerously-skip-permissions`, Claude shows a one-time warning dialog requiring user to select "Yes, I accept".

**Workaround:** User accepts once per session. Could potentially be automated via:
- Pre-configuration in Claude settings
- Environment variable (needs investigation)

### 2. No Process Status Query API

mprocs cannot answer "what processes are running?" or "what's the exit code?" via remote control. Ralph must track state independently.

**Workaround:** Signal files + SQLite state tracking in Ralph.

### 3. Process ID for Removal is Internal

The `remove-proc` command requires an internal ID not exposed externally.

**Workaround:** Use `select-proc` by index + `term-proc`. Or just leave panels open (our current approach).

---

## Validated Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ mprocs (--server 127.0.0.1:4050)                                │
├─────────────────┬───────────────────────────────────────────────┤
│ Processes       │ Terminal                                      │
├─────────────────┤                                               │
│ > ralph     UP  │ [Active process output here]                  │
│   Pod-OBJ-001   │                                               │
│   Pod-OBJ-002   │ User can click any process to view its output │
│   Pod-OBJ-003   │                                               │
└─────────────────┴───────────────────────────────────────────────┘
```

### Flow

1. User runs `./ralph-visible.sh MSN-002-Feature` in terminal
2. Script launches mprocs with Ralph as first process
3. Ralph reads objectives from SQLite
4. For each objective:
   - Writes task to file (avoids quoting issues)
   - Spawns Pod via `mprocs --ctl '{c: add-proc, ...}'`
   - Polls for signal file
   - Updates SQLite on completion
   - Continues to next objective
5. User can switch between processes (j/k keys) to watch any Pod

---

## POC Artifacts

Location: `.space-agents/experiments/mprocs-poc/`

| File | Purpose |
|------|---------|
| `mprocs-multi.yaml` | mprocs config with server enabled |
| `ralph-multi-test.sh` | POC Ralph that spawns 2 Pods sequentially |
| `tasks/` | Task files for each Pod |
| `signals/` | Completion signal files |

---

## Recommendations for Production Integration

### 1. Create `ralph-visible.sh` wrapper

```bash
#!/bin/bash
# Wrapper that launches Ralph inside mprocs

MISSION_ID="$1"
PROJECT_ROOT="$(pwd)"

# Generate mprocs config
cat > /tmp/mprocs-mission.yaml << EOF
server: 127.0.0.1:4050
procs:
  ralph:
    shell: "./skills/mission/scripts/ralph.sh $MISSION_ID"
    autostart: true
EOF

# Launch
mprocs -c /tmp/mprocs-mission.yaml
```

### 2. Modify `ralph.sh` to spawn Pods via mprocs

Replace current:
```bash
echo "$pod_prompt" | claude -p --system-prompt "..."
```

With:
```bash
# Write prompt to file
echo "$pod_prompt" > "$MISSION_DIR/pod-$objective_id.prompt"

# Spawn via mprocs
mprocs --ctl "{c: add-proc, cmd: \"claude --dangerously-skip-permissions < $MISSION_DIR/pod-$objective_id.prompt\", name: \"Pod-$objective_id\"}"

# Wait for signal
while [ ! -f "$SIGNAL_DIR/$objective_id.done" ]; do sleep 2; done
```

### 3. Update Pod prompts to create signal files

Add to Pod system prompt:
```
When your objective is complete, you MUST run:
touch $SIGNAL_DIR/$objective_id.done
```

### 4. Add `--visible` flag to Ralph

```bash
./ralph.sh MSN-002-Feature           # Default: headless (-p mode)
./ralph.sh MSN-002-Feature --visible # Uses mprocs for TUI visibility
```

---

## Next Steps

1. **Create mission** - Implement the production integration above
2. **Test with real objectives** - Run a full mission with mprocs visibility
3. **Solve bypass permissions UX** - Investigate auto-accept options
4. **Consider parallel Pods** - mprocs can show multiple concurrent Pods

---

## Session Notes

- Spike took ~45 minutes
- mprocs installed via Homebrew: `brew install mprocs`
- Version tested: mprocs 0.8.2
- All tests run on macOS (Darwin 25.2.0)
