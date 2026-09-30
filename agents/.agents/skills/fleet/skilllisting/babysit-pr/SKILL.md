---
name: babysit-pr
description: Apply when you are asked to babysit, watch, look after a pull request
---

If you arent given a pr link create new pr with file-pr skill

interactions with github should be done through `gh` cli

All repos we are working on have review agents from review-pr skill
I want you to monitor pr if you see review comments fix them if they are worth fixing and represent real issue otherwise just hit resolve without fixing.

after you finish with round of review invoke codex with gpt-sol-6.1 on xhigh with review-pr skill and 2 inputs:
1. Pull request link
2. Absolute path to worktree you are working on

Wait until it finishes review

Repeat this actions until reviewer approves.
