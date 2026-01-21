# Beads CLI Patterns - Verified 2026-01-21

Reference for beads-helpers.sh implementation.

## JSON Field Names

From `bd list --json` and `bd ready --json`:

```json
{
  "id": "test-beads-w6f.1.1",
  "title": "Task One",
  "status": "open",
  "priority": 2,
  "issue_type": "task",
  "owner": "fraserbrown@live.com",
  "created_at": "2026-01-21T15:30:22.3020367+11:00",
  "created_by": "thebrownproject",
  "updated_at": "2026-01-21T15:30:22.3020367+11:00",
  "dependency_count": 1,
  "dependent_count": 0
}
```

**Key field:** `issue_type` (NOT `type`)

## Valid Types (-t flag)

- `epic`
- `feature`
- `task`
- `bug`

## Valid Statuses

- `open`
- `in_progress`
- `closed`

Note: No `blocked` status. Blocking is handled via dependencies.

## Core Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `bd init` | Initialize beads | `bd init` |
| `bd create` | Create issue | `bd create "Title" -t task --parent ID` |
| `bd list` | List issues | `bd list -t task --json` |
| `bd ready` | Unblocked issues only | `bd ready -t task --json` |
| `bd show` | Single issue details | `bd show ID --json` |
| `bd update` | Modify issue | `bd update ID --status in_progress` |
| `bd close` | Close issue | `bd close ID` |
| `bd dep add` | Add dependency | `bd dep add CHILD BLOCKER` |
| `bd dep tree` | Show hierarchy | `bd dep tree ID` |
| `bd sync` | Commit to JSONL | `bd sync` |

## Filtering

```bash
# By type
bd list -t task --json
bd ready -t task --json

# By status
bd list --status open --json
```

## Blocking Pattern

To block a task with a bug:

```bash
# Create bug under same parent
bd create "Bug description" -t bug --parent FEATURE_ID

# Link as dependency (task depends on bug)
bd dep add TASK_ID BUG_ID

# Task won't appear in bd ready until bug is closed
bd ready -t task --json  # Returns []

# Close bug to unblock
bd close BUG_ID
bd ready -t task --json  # Task now appears
```

## ID Format

Hierarchical: `prefix-hash.N.N`
- Epic: `test-beads-w6f`
- Feature: `test-beads-w6f.1`
- Task: `test-beads-w6f.1.1`

## Notes

- `bd comment` does NOT exist - use description or labels
- Closed issues don't appear in default `bd list` output
- `bd show ID --json` includes `dependencies` array and `parent` field
- No jq needed - use `bd list -t TYPE --json` for filtering
