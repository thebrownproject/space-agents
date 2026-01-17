---
description: Bump plugin version, commit, push, and update marketplace
---

Bump the space-agents plugin version and push:

1. Read current version from `.claude-plugin/plugin.json`
2. Increment the patch version by 1 (e.g., 1.0.5 → 1.0.6)
3. Update both files with the new version:
   - `.claude-plugin/plugin.json` (top-level "version" field)
   - `.claude-plugin/marketplace.json` (plugins[0].version field)
4. Git add all files, commit with message "chore: bump version to X.X.X", and push
5. Tell the user to run the marketplace update manually:
   ```
   Run this command in the Claude Code box:
   /plugin marketplace update space-agents
   ```

Report the version change and prompt the user to run the marketplace update.
