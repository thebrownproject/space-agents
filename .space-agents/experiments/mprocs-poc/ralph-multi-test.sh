#!/bin/bash
# POC: Ralph spawning multiple Claude sessions with completion detection
# Uses task files to avoid quoting hell

PROJECT_ROOT="/Users/fraserbrown/Documents/space-agents"
POC_DIR="$PROJECT_ROOT/.space-agents/experiments/mprocs-poc"
SIGNAL_DIR="$POC_DIR/signals"
TASKS_DIR="$POC_DIR/tasks"

# Clean up
rm -rf "$SIGNAL_DIR" "$TASKS_DIR"
mkdir -p "$SIGNAL_DIR" "$TASKS_DIR"

echo "Ralph starting..."
echo ""

# Write task files (avoids quoting issues)
cat > "$TASKS_DIR/task1.txt" << 'EOF'
List the files in .space-agents/staging/ directory and describe what you see in 1 sentence.
When completely done, you MUST run this exact command: touch /Users/fraserbrown/Documents/space-agents/.space-agents/experiments/mprocs-poc/signals/pod1.done
EOF

cat > "$TASKS_DIR/task2.txt" << 'EOF'
Count how many tables exist in the SQLite database at .space-agents/space-agents.db and name them.
When completely done, you MUST run this exact command: touch /Users/fraserbrown/Documents/space-agents/.space-agents/experiments/mprocs-poc/signals/pod2.done
EOF

NUM_TASKS=2

for POD_NUM in $(seq 1 $NUM_TASKS); do
    SIGNAL_FILE="$SIGNAL_DIR/pod${POD_NUM}.done"
    TASK_FILE="$TASKS_DIR/task${POD_NUM}.txt"

    echo "═══════════════════════════════════════════════════"
    echo "Ralph: Spawning Pod-$POD_NUM"
    echo "═══════════════════════════════════════════════════"
    echo ""

    # Read task from file
    TASK=$(cat "$TASK_FILE")
    echo "Task: $TASK"
    echo ""

    # Spawn the Pod - simpler command structure
    mprocs --ctl "{c: add-proc, cmd: \"cd $PROJECT_ROOT && claude --dangerously-skip-permissions \\\"\$(cat $TASK_FILE)\\\"\", name: \"Pod-$POD_NUM\"}"

    echo "Ralph: Pod-$POD_NUM spawned. Waiting for completion signal..."
    echo ""

    # Wait for completion signal
    WAITED=0
    while [ ! -f "$SIGNAL_FILE" ] && [ $WAITED -lt 180 ]; do
        sleep 3
        WAITED=$((WAITED + 3))
        printf "Ralph: ... waiting (%d seconds)\r" "$WAITED"
    done
    echo ""

    if [ -f "$SIGNAL_FILE" ]; then
        echo "Ralph: ✓ Pod-$POD_NUM completed! (signal received)"
    else
        echo "Ralph: ✗ Pod-$POD_NUM timed out"
    fi
    echo ""
    sleep 2
done

echo "═══════════════════════════════════════════════════"
echo "Ralph: All pods complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Press Enter to exit..."
read
