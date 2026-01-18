#!/bin/bash
# POC: Ralph spawning real Claude Code sessions via mprocs

PROJECT_ROOT="/Users/fraserbrown/Documents/space-agents"

echo "Ralph starting..."
echo "Project: $PROJECT_ROOT"
sleep 2

echo ""
echo "═══════════════════════════════════════════════════"
echo "Ralph: Spawning Pod for test objective..."
echo "═══════════════════════════════════════════════════"

# Spawn a real Claude session as a Pod
# Simple task: read a file and summarize it
mprocs --ctl "{c: add-proc, cmd: \"cd $PROJECT_ROOT && claude --dangerously-skip-permissions -p 'Read the file .space-agents/experiments/mprocs-poc/mprocs.yaml and explain what it does in 2-3 sentences. Then exit.'\", name: \"Pod-Test\"}"

echo "Ralph: Pod spawned! Watch the Pod-Test process in the sidebar."
echo ""
echo "Ralph: Waiting for Pod to complete..."
sleep 30

echo ""
echo "═══════════════════════════════════════════════════"
echo "Ralph: Test complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Press Enter to exit mprocs..."
read
