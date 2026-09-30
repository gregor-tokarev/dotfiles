---
name: review-pr
description: Review a GitHub PR. Only run when explicitly invoked via /review-pr.
disable-model-invocation: true
---

# Required inputs
PR link
Working directory linked with pr

Make single pass of codereview on given pull request.
Interact with github with authenticated `gh` cli

Before you start search for comment like
```
Pull request review status:
review | status | commit | trigger
📝 Code Review:	✅ Approved	d751e5e	PR opened
```

Status can be: pending, running, approved, wait for changes
Triggers: PR opened, PR updated

If there is no comment create new with PR opened trigger and running status

For actually reviewing files go to working directory on current machine.

If you find something worth fixing leave review comment with `gh pr review` on specific code sections


# Review Instructions
You goal is to test pr against:
1) Does code diff implement what is specified in pull request description?
2) Does feature implemented in pr works? You can understand it by just looking at code or you might want to manual test it youself with agent-browser if pr is related to website or webapp, computer-use if it's desktop app
3) Performance issues n+1, inefficient algorithms, potential large repaint delays
4) Does code follows clean architecture practices like SOLID, YAGNI, KISS, DRY. When they conflict, YAGNI and KISS win.
5) Unit test on pr does have impact and not here just to be
6) Identify exploitable security vulnerabilities in code. Report only HIGH CONFIDENCE findings—clear vulnerable patterns with attacker-controlled input.

Spawn subagents for each target

If one of your previous comments marked as resolved and no changes were made to fix it do not bring this comment back.

Change pinned comment status when you are finished
