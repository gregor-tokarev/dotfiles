# Global Instructions

Plugins are loaded from ~/.claude/plugins/











## Memory

You are one session among many. Past conversations contain valuable context about decisions, patterns, and prior work. Search proactively and liberally - when starting tasks, debugging issues, or when the user references previous work. Parallelize searches when exploring multiple topics.

```bash
# Search & Browse (default: team scope from current directory)
cast search "auth"                # team-wide search
cast search "auth" --mine         # only my sessions
cast search "auth" -m samvit      # specific member
cast search "auth" -g -s 7d       # all teams, last 7 days
cast feed                         # team feed
cast feed --mine                  # only my sessions
cast feed -m samvit               # specific member
cast read <id> 15:25              # read messages 15-25

# Analysis
cast diff <id>                    # files changed, commits, tools used
cast diff --today                 # aggregate today's work
cast summary <id>                 # goal, approach, outcome, files
cast context "implement auth"     # find relevant prior sessions
cast ask "how does X work"        # query across sessions

# Handoff & Tracking
cast handoff                      # generate context transfer doc
cast bookmark <id> <msg> --name x # save shareable link
cast decisions list               # view architectural decisions
cast decisions add "title" --reason "why"
```

Common options: --mine (just me), -m <name> (member), -g (all teams), -s/-e (time range), -p (page), -n (limit)
<!-- /codecast-memory -->

## Tasks & Plans

You operate within a structured work tracking system. A human monitors your progress through a dashboard — communicate status through the system, not through chat.

### When to create structure

**Create a task** when your work will change code, fix a bug, or produce a deliverable. Run `cast task create "Title" -p <priority>` before you start implementing. This is the default — skip it only for simple questions, explanations, or quick lookups that don't produce changes.

**Create a plan** when the user describes work with multiple distinct parts — a feature with frontend and backend changes, a refactor that touches several subsystems, a bug that needs investigation then fixing. Run `cast plan create "Title" -g "goal"` and add tasks with `cast task create "Title" --plan <plan_id>`. Don't create plans for single-task work.

**Check existing work first.** Your context includes an overview of active tasks and plans. Before creating new ones, check if your work already has a task (`cast task ready`) or fits under an existing plan. Claim existing tasks with `cast task start <id>` rather than creating duplicates.

### Working on tasks

Once you have a task:
1. `cast task start <id>` — claim it and bind your session
2. Work on the implementation
3. `cast task comment <id> "progress" -t progress` — log milestones as you go
4. `cast task done <id> -m "summary"` — mark complete with what you verified

If bound to a plan, keep the bigger picture coherent:
- Task larger than expected? Suggest splitting it.
- Your work creates a dependency? Flag it.
- Making a directional decision? Record it with `cast plan comment <plan_id> "decision" -d -r "rationale"`.
- Acceptance criteria ambiguous? Ask before assuming.

If blocked, say so explicitly:
- **BLOCKED: <reason>** — flags for human intervention
- **NEEDS_CONTEXT: <what>** — escalates to the user
- **DONE_WITH_CONCERNS: <concern>** — completed but flagged for review

### Referencing sessions

When you reference another session in your messages, include its short ID (e.g. `jx7c6zk`). These render as interactive cards in the UI showing title, status, message count, and project. Find session IDs via `cast search`, `cast feed`, or `cast context`. Use bare IDs for inline references or `@[Session Title jx7c6zk]` for explicit mentions.

### After compaction

When your context gets compacted, re-read your task or plan context (`cast task context --current` / `cast plan context --current`) to reground yourself. Don't rely on memory of earlier conversation alone.

### Commands

```bash
cast task ready                             # Find available work
cast task start/done/comment <id>           # Task lifecycle
cast task create "Title" -t task -p high    # Create task
cast task create "Title" --plan <plan_id>   # Create task bound to plan
cast task update <id> --plan <plan_id>      # Bind existing task to plan
cast task context <id>                      # Full context for a task
cast task context --current                 # Context for session's current task
cast plan create "Title" -g "goal" -b "body"  # Create plan with inline body
cast plan create "Title" --body-file plan.md  # Create plan from file
cast plan bind/unbind <plan_id>             # Bind/unbind session to plan
cast plan show/status <plan_id>            # Plan details
cast plan context <plan_id>                # Full context for a plan (for agents)
cast plan context --current                # Context for session's current plan
cast plan comment <plan_id> "note"         # Add comment (progress by default)
cast plan comment <plan_id> "x" -d -r "y" # Decision with rationale
cast plan done/drop <plan_id>             # Close or abandon a plan
cast doc create "Title" [-c content] [-t type]
cast doc show/ls/edit/search/comment
```
<!-- /codecast-work -->
