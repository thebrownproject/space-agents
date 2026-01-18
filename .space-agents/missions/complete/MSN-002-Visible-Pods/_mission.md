# MSN-002-Visible-Pods: Visible Pod Sessions

**Status:** Staged
**Created:** 2026-01-18

## Goal

Enable users to watch Pod execution in real-time via mprocs terminal multiplexer with `--visible` flag.

## Objectives

1. **OBJ-001** - Create mprocs Wrapper
2. **OBJ-002** - Add Signal File Infrastructure
3. **OBJ-003** - Modify spawn_pod for Visible Mode
4. **OBJ-004** - Wire Up Completion & Flag

## Key Files

**Create:**
- `skills/mission/scripts/ralph-visible.sh` - Wrapper that launches mprocs

**Modify:**
- `skills/mission/scripts/ralph.sh` - Add --visible flag, signal functions, mprocs spawn logic

## Context

Spike completed successfully using mprocs v0.8.2. POC artifacts in `.space-agents/experiments/mprocs-poc/` demonstrate:
- Dynamic process spawning via `mprocs --ctl`
- Signal file completion detection
- Full Claude Code TUI renders in mprocs

## Dependencies

- mprocs installed (`brew install mprocs`)
- Existing ralph.sh infrastructure
