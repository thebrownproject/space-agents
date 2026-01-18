#!/bin/bash
# POC: Ralph spawning INTERACTIVE Claude Code sessions (full TUI)

PROJECT_ROOT="/Users/fraserbrown/Documents/space-agents"

echo "Ralph starting..."
echo ""
echo "═══════════════════════════════════════════════════"
echo "Spawning INTERACTIVE Claude Pod (full TUI)..."
echo "═══════════════════════════════════════════════════"
echo ""

# Spawn interactive Claude - NO -p flag = full TUI
mprocs --ctl "{c: add-proc, cmd: \"cd $PROJECT_ROOT && claude --dangerously-skip-permissions 'Read .space-agents/capcom.md and give a 2 sentence summary'\", name: \"Pod-Interactive\"}"

echo "Pod spawned!"
echo ""
echo "Press 'j' to switch to Pod-Interactive and watch Claude work!"
echo ""
echo "Ralph waiting... Press Enter when done."
read
