---
name: exploration
description: "Select mode, delegate to analysis skill."
---

# /exploration - Analysis Mode Router

Route to the appropriate analysis mode. You select the mode, then delegate.

## The Process

1. **Ask which mode** - Use AskUserQuestion with options below
2. **Delegate** - Invoke the selected skill

## Modes

Use AskUserQuestion, then invoke the corresponding skill:

| Mode | Skill | Purpose |
|------|-------|---------|
| Brainstorm | `exploration-brainstorm` | Explore ideas → reports |
| Plan | `exploration-plan` | Structure work → plan.md |
| Create | `exploration-create` | Formalize → Beads |
| Review | `exploration-review` | Code review → bugs |
| Debug | `exploration-debug` | Investigate → bugs |

Invoke with: `Skill: exploration-brainstorm`, `exploration-plan`, `exploration-create`, `exploration-review`, or `exploration-debug`

**Not yet implemented:** create, review, debug
