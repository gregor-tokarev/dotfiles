---
name: file-pr
description: Apply when user asks you to create/file pr.
---

Before filing, check whether a PR for this branch already exists. Review the diff locally against origin/main to make sure its contents match the goal.

Open the description with a simple explanation of the problem based on the user's original prompt, then briefly explain the solution. Do not lead with an implementation inventory:

BAD

❌ Removed implicit workspace carry-over from every "new thread" entry point (cmd+n / cmd+shift+o, sidebar v1/v2 buttons, command palette). New threads inherit only the project from context; branch, worktree, and env mode always come from the configured defaults. Deleted buildContextualThreadOptions, startNewThreadInProjectFromContext, and the v1 sidebar's seed-context machinery.

GOOD

✅ My "new worktree" default was ignored when starting new threads on existing worktrees. Super unintuitive. Now your preferences always apply.


After creating pr regardless of your current harness and model run codex with gpt-sol-6.1 on xhigh
Load review-pr skill to it and pass and provide pr link and current working directory. Do not monitor codex session unless asked to
