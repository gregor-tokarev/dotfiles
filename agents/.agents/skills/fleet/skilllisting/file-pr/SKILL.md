---
name: file-pr
description: Apply when user asks you to create/file pr.
---

Before filing, check whether a PR for this branch already exists. Review the diff locally against default branch to make sure its contents match the goal:
- Remove debug leftovers, secrets and changes unrelated to the goal.
If you are on the default branch, create a new branch first. Commit all changes and push the branch before creating the PR.

Open the description with a simple explanation of the problem based on the user's original prompt, then briefly explain the solution. Do not lead with an implementation inventory:

BAD

❌ Removed implicit workspace carry-over from every "new thread" entry point (cmd+n / cmd+shift+o, sidebar v1/v2 buttons, command palette). New threads inherit only the project from context; branch, worktree, and env mode always come from the configured defaults. Deleted buildContextualThreadOptions, startNewThreadInProjectFromContext, and the v1 sidebar's seed-context machinery.

GOOD

✅ My "new worktree" default was ignored when starting new threads on existing worktrees. Super unintuitive. Now your preferences always apply.
