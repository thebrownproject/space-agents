# Visible Pod Sessions Implementation Plan

**Mission:** MSN-002-Visible-Pods
**Created:** 2026-01-18

## Objectives

| # | Objective | Status |
|---|-----------|--------|
| 1 | Create mprocs Wrapper | pending |
| 2 | Add Signal File Infrastructure | pending |
| 3 | Modify spawn_pod for Visible Mode | pending |
| 4 | Wire Up Completion & Flag | pending |

## Sequence

```
OBJ-001 → OBJ-002 → OBJ-003 → OBJ-004
   │         │         │         │
   └─ Foundation: mprocs server   │
             └─ Signal paths/functions
                       └─ Core spawn logic
                                 └─ Final integration
```

---

## Objective 1: Create mprocs Wrapper

**Goal:** Create ralph-visible.sh that sets up mprocs with Ralph as first process

**Files:**
- Create: `skills/mission/scripts/ralph-visible.sh`

**Implementation:**

```bash
#!/bin/bash
# ralph-visible.sh - Launch Ralph inside mprocs for visible Pod sessions

MISSION_ID="$1"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
SCRIPT_DIR="$(dirname "$0")"

if [[ -z "$MISSION_ID" ]]; then
    echo "Usage: ralph-visible.sh <mission_id>"
    exit 2
fi

# Generate mprocs config
CONFIG_FILE="/tmp/mprocs-${MISSION_ID}.yaml"
cat > "$CONFIG_FILE" << EOF
server: 127.0.0.1:4050

procs:
  ralph:
    shell: "${SCRIPT_DIR}/ralph.sh ${MISSION_ID} --visible-internal"
    autostart: true
EOF

# Launch mprocs
exec mprocs -c "$CONFIG_FILE"
```

**Test:**
```bash
./ralph-visible.sh MSN-002-Visible-Pods
# Verify: mprocs opens with ralph panel
```

---

## Objective 2: Add Signal File Infrastructure

**Goal:** Create functions for signal-based completion detection

**Files:**
- Modify: `skills/mission/scripts/ralph.sh`

**Add to Configuration section:**
```bash
SIGNAL_DIR="${SPACE_AGENTS_DIR}/missions/active/${MISSION_ID}/signals"
```

**Add new functions:**
```bash
create_signal_dir() {
    local mission_id="$1"
    local signal_dir="${SPACE_AGENTS_DIR}/missions/active/${mission_id}/signals"
    mkdir -p "$signal_dir"
    echo "$signal_dir"
}

wait_for_signal() {
    local signal_file="$1"
    local timeout="${2:-180}"
    local waited=0

    while [[ ! -f "$signal_file" ]] && [[ $waited -lt $timeout ]]; do
        sleep 2
        waited=$((waited + 2))
    done

    [[ -f "$signal_file" ]]
}

cleanup_signals() {
    local mission_id="$1"
    local signal_dir="${SPACE_AGENTS_DIR}/missions/active/${mission_id}/signals"
    rm -rf "$signal_dir"
}
```

**Test:**
```bash
# Manual test in bash
source ralph.sh
create_signal_dir "test-mission"
touch /path/to/signals/test.done &
wait_for_signal "/path/to/signals/test.done" 10
echo $?  # Should be 0
```

---

## Objective 3: Modify spawn_pod for Visible Mode

**Goal:** When --visible, spawn via mprocs instead of claude -p

**Files:**
- Modify: `skills/mission/scripts/ralph.sh` (spawn_pod function)

**Add variable at top of script:**
```bash
VISIBLE_MODE=false
```

**Modify spawn_pod function:**
```bash
spawn_pod() {
    local objective_id="$1"
    local objective_title="$2"
    local objective_description="$3"
    local mission_id="$4"

    log INFO "Spawning Pod for objective: $objective_title"

    # Build prompt (same as before)
    local pod_prompt
    pod_prompt=$(cat <<EOF
... existing prompt content ...

## Completion Signal

When your objective is COMPLETE, you MUST run:
touch ${SIGNAL_DIR}/${objective_id}.done

This signals Ralph to continue to the next objective.
EOF
)

    local pod_agent="${PROJECT_ROOT}/agents/mission-pod.md"
    local exit_code=0

    if [[ "$VISIBLE_MODE" == "true" ]]; then
        # Visible mode: spawn via mprocs
        spawn_pod_visible "$objective_id" "$pod_prompt" "$pod_agent"
        exit_code=$?
    else
        # Headless mode: existing behavior
        if [[ -f "$pod_agent" ]]; then
            echo "$pod_prompt" | claude -p --system-prompt "$(cat "$pod_agent")" \
                --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Task" 2>&1 || exit_code=$?
        else
            echo "$pod_prompt" | claude -p \
                --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Task" 2>&1 || exit_code=$?
        fi
    fi

    return $exit_code
}

spawn_pod_visible() {
    local objective_id="$1"
    local pod_prompt="$2"
    local pod_agent="$3"
    local mission_dir="${SPACE_AGENTS_DIR}/missions/active/${MISSION_ID}"

    # Write prompt to file (avoids quoting issues)
    local prompt_file="${mission_dir}/prompts/${objective_id}.txt"
    mkdir -p "$(dirname "$prompt_file")"
    echo "$pod_prompt" > "$prompt_file"

    # Build command
    local cmd="cd ${PROJECT_ROOT} && claude --dangerously-skip-permissions \"\$(cat ${prompt_file})\""
    if [[ -f "$pod_agent" ]]; then
        cmd="cd ${PROJECT_ROOT} && claude --dangerously-skip-permissions --system-prompt \"\$(cat ${pod_agent})\" \"\$(cat ${prompt_file})\""
    fi

    # Spawn via mprocs
    mprocs --ctl "{c: add-proc, cmd: \"$cmd\", name: \"Pod-${objective_id}\"}"

    # Wait for signal
    local signal_file="${SIGNAL_DIR}/${objective_id}.done"
    log INFO "Waiting for Pod completion signal..."

    if wait_for_signal "$signal_file" 300; then
        log SUCCESS "Pod signaled completion"
        return 0
    else
        log ERROR "Pod timed out waiting for signal"
        return 1
    fi
}
```

**Test:**
```bash
# With test mission staged
./ralph-visible.sh MSN-test
# Verify: Pod appears in mprocs, signal file created on completion
```

---

## Objective 4: Wire Up Completion & Flag

**Goal:** Add --visible flag parsing and finalize integration

**Files:**
- Modify: `skills/mission/scripts/ralph.sh` (main function)

**Update main() function:**
```bash
main() {
    local mission_id=""
    local visible_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --visible)
                visible_flag=true
                shift
                ;;
            --visible-internal)
                # Called by ralph-visible.sh, already inside mprocs
                VISIBLE_MODE=true
                shift
                ;;
            --attended)
                # Legacy flag, kept for compatibility
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                exit 2
                ;;
            *)
                if [[ -z "$mission_id" ]]; then
                    mission_id="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$mission_id" ]]; then
        echo "Usage: ralph.sh <mission_id> [--visible]"
        echo ""
        echo "Options:"
        echo "  --visible    Run in visible mode (mprocs TUI)"
        exit 2
    fi

    # If --visible and not already internal, launch wrapper
    if [[ "$visible_flag" == "true" ]] && [[ "$VISIBLE_MODE" != "true" ]]; then
        exec "${SCRIPT_DIR}/ralph-visible.sh" "$mission_id"
    fi

    # ... rest of existing main() logic ...
}
```

**Test:**
```bash
# Run with --visible flag
./ralph.sh MSN-002-Visible-Pods --visible
# Verify: Opens mprocs, Pods spawn and complete, signals work
```

---

## Verification Checklist

- [ ] `ralph-visible.sh` launches mprocs with Ralph panel
- [ ] Signal directory created per mission
- [ ] `wait_for_signal()` returns correctly on signal/timeout
- [ ] Pods spawn via `mprocs --ctl` in visible mode
- [ ] Pod prompts include signal touch command
- [ ] `--visible` flag recognized and routes to wrapper
- [ ] Full mission runs to completion in visible mode
