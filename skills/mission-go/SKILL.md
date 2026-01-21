---
name: mission-go
description: "Select feature, select mode, delegate to execution skill."
---

# /mission-go - Execution Mode Router

Route to the appropriate execution mode for a feature. You select the feature and mode, then delegate.

## The Process

1. **Load available features** - Run `bd list -t feature --status open` or query staged features
2. **Ask which feature** - Use AskUserQuestion with feature list
3. **Ask execution mode** - Use AskUserQuestion with options below
4. **Delegate** - Invoke the selected skill

## Mode Selection

Present with AskUserQuestion:

| Mode | Skill | Best For |
|------|-------|----------|
| **Solo** | `/mission-go-solo` | Small tasks, demos. Warning: context fills quickly. |
| **Orchestrated** | `/mission-go-orchestrated` | Recommended. HOUSTON spawns Worker/Inspector/Analyst per task. |
| **Ralph** | `/mission-go-ralph` | Automatic. Background script runs until done. |

## AskUserQuestion Prompts

**Feature selection:**
```
Which feature do you want to execute?
- [Feature A title]
- [Feature B title]
- Cancel
```

**Mode selection:**
```
Execution mode:
- Solo (direct, context fills fast - small tasks only)
- Orchestrated (recommended - spawns agents per task)
- Ralph (automatic background loop)
```

## Delegation

After mode selection, invoke the skill with the feature ID:

- Solo: `Skill: mission-go-solo, args: "FEATURE_ID"`
- Orchestrated: `Skill: mission-go-orchestrated, args: "FEATURE_ID"`
- Ralph: `Skill: mission-go-ralph, args: "FEATURE_ID"`

## If No Features

```
HOUSTON: No features ready for execution.
         Use /mission-brief to plan a feature first.
```
