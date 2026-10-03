---
name: babysit-pr
description: Apply when you are asked to babysit, watch, look after a pull request
---

Interact with GitHub through the authenticated `gh` cli.

Don't end your turn or ask me for confirmation between rounds. Only stop when done or at a give-up condition.

# Waiting
Reviews and CI take a long time. Never end your turn to wait for a background job or a notification: if the session restarts or sits idle, the job and the notification are lost and the loop dies.
- Start long jobs in the background (`nohup ... &`, note the PID), then wait in the foreground only with `sh <this skill's directory>/wait.sh`, as a Bash call with a 600000 ms timeout:
  - `wait.sh pid <pid>`: until a process exits (e.g. the codex review)
  - `wait.sh file <path> <regex>`: until a line appears in a log
  - `wait.sh checks <pr>`: until CI checks finish
- Each call blocks up to 9 minutes. Exit 3 means still running: call it again, without a status message in between. Don't write your own polling loops or use shorter waits.

# Setup
- No PR link given: create one with the file-pr skill, then skip straight to "Review".
- PR link given: make sure you are in a worktree checked out on the PR branch (`gh pr checkout` in a new worktree if not).

# Loop
1. **Fix.** Pull the branch first. Then go through unresolved review threads and failing checks.
   - review-pr threads: fix if it is a real issue worth fixing. Otherwise reply with a one-line reason and resolve without fixing.
   - Threads from humans or other bots: fix, or reply with your reasoning. Never resolve them yourself.
   - Failing CI checks: fix them. Tests are not run by the reviewer, CI is the only test signal.
   - Merge conflicts: merge the base branch into the PR branch. Never rebase or force-push.
   - Resolve threads with `gh api graphql` (`resolveReviewThread`).
2. **Push.** Commit and push all fixes. The reviewer only sees pushed commits.
3. **Review.** Run `codex exec --dangerously-bypass-approvals-and-sandbox -m gpt-6.1-sol -c model_reasoning_effort=xhigh` with a prompt that explicitly invokes the `$review-pr` skill and passes:
   1. Pull request link
   2. Absolute path to the worktree you are working in

   Do not edit the worktree while the review runs.
4. **Wait for review.** Wait for the codex process to exit (see Waiting). The run failed if codex errors, times out, or exits while the review-pr status comment (`<!-- review-pr-status -->`) is still 🔄 Running or doesn't show the current head SHA. Retry a failed run.
5. **Check.** Done when the status comment shows ✅ Approved for the current head SHA, CI is green, and no human threads are left unanswered. Otherwise go back to 1.

Stop after 15 rounds, or if codex fails twice in a row, and report to me: PR link, open threads, failing checks, and the codex error if any.

Do not merge yourself, if not asked otherwise.
