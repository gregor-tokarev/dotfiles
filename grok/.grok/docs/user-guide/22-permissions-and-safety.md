# Permissions and Safety Controls

Grok can read files, search code, edit files, and run shell commands. The permission system gives you fine-grained control over what the agent is allowed to do, with multiple layers you can combine for strong safety.

This guide explains how permissions work, the available locked-down modes (especially `dontAsk`), how to configure them via CLI, native config, or Claude settings, and how to use **PreToolUse hooks** to create hard allow-lists such as "only `git` and `gh` commands".

---

## Decision Flow (How a Tool Call Is Authorized)

When the model requests a tool, the following checks happen in order:

1. **PreToolUse Hooks** (if any) — Registered hooks can deny a tool call before any other checks. See [10-hooks.md](10-hooks.md) for how to write and install them. Hooks run earliest and take precedence.

2. **Policy Rules** (from config, Claude settings, or `--allow`/`--deny` flags)
   - Explicit `deny` rules win (even over allow rules).
   - `allow` rules short-circuit to approval.
   - `ask` rules request a prompt — but note the built-in fast paths below still auto-approve read-class, grep-class, and safe shell commands, so an `ask` rule effectively takes hold only for tools that would otherwise prompt (such as MCP tools or non-safe shell commands). `deny` always wins.

3. **Built-in Fast Paths** (no prompt needed)
   - Read-class tools (`read_file`, `list_dir`, `web_search`, `todo_write`, skills, subagent control, etc.)
   - Grep-class tools
   - A curated set of safe, read-only shell commands (see below)

4. **Prompt Policy** (set by `defaultMode` in `.claude/settings.json` — see the wiring note under [Permission Modes](#permission-modes))
   - `default` → prompt the user for anything not pre-approved
   - `dontAsk` → silently deny anything not pre-approved
   - `bypassPermissions` → auto-approve tool calls (explicit `deny` rules and `PreToolUse` hooks still apply)
   - `acceptEdits` → auto-allow file edits
   - `plan` → special behavior for plan mode

5. **User Prompt** (in interactive TUI) or denial (under `dontAsk`)

This layered approach lets you combine broad policy with very specific hooks.

---

## Always-Safe Operations (Never Prompt)

Certain operations are intentionally side-effect-free and are **always allowed** without prompting, even under `dontAsk`.

### Read-Class Tools

The following tools are auto-approved because they are considered read-only:

- `read_file`
- `list_dir`
- `web_search`
- `todo_write`
- `get_command_or_subagent_output` / `wait_commands_or_subagents` / `kill_command_or_subagent` (subagent control)
- Invoking skills
- Various IDE extension and plugin read operations
- Most future plugin / dynamic tools (treated conservatively as reads)

### Grep-Class Tools

- `grep` (ripgrep content search)

### Safe Shell Commands

After parsing and splitting chained commands (for `&&`, `||`, `;`, pipes, etc.), the following commands are recognized as safe when they appear as the **primary command** (word-boundary matched, so `ls` does not match `lsof` or `less`).

**Filesystem (read-only viewing):**
- `ls`, `cat`, `pwd`, `date`, `whoami`, `hostname`, `uptime`, `ps`
- `head`, `tail`, `wc`, `sort`, `uniq`, `tr`, `cut`

**Git (read-only):**
- `git status`, `git branch`, `git log`, `git diff`, `git ls-files`, `git show`, `git rev-parse`

**Search & Inspection:**
- `grep`, `rg` (not `rg --pre` / `rg --pre=…`, which spawn a preprocessor per file)

**Build & Check (read-only):**
- `cargo check`

**Kubernetes (read-only):**
- `kubectl get`, `kubectl logs`, `kubectl describe`

**Note:** `tee` is not included in the safe list because it can write its input to arbitrary files.

These checks are applied **per segment**. In a command like `ls && rm -rf /`, the `ls` segment is recognized as safe, but the `rm` segment is not on the safe list. In `default` mode that `rm` segment is prompted; under `dontAsk` (set via `defaultMode`) it is denied.

---

## Permission Modes

The prompt policy is named by one of these modes:

| Mode                | Behavior                                                                 | Typical Use                     |
|---------------------|--------------------------------------------------------------------------|---------------------------------|
| `default`           | Normal prompting for anything not pre-approved                           | Daily interactive use           |
| `dontAsk`           | Silently deny anything without an explicit allow rule or fast-path       | Headless, CI, high-security     |
| `bypassPermissions` | Auto-approves tool calls (explicit `deny` rules and hooks still apply)   | Trusted environments            |
| `acceptEdits`       | Auto-approve file edits (`search_replace`, `write`, etc.)                | "Accept edits" workflows        |
| `plan`              | Plan-mode specific behavior                                              | Structured planning sessions    |

> **Wiring note:** Today the prompt policy is driven by `defaultMode` in `.claude/settings.json`. To get deny-by-default (`dontAsk`) or auto-accept-edits (`acceptEdits`), set `defaultMode` there. The CLI `--permission-mode` flag and the TUI mode toggle currently take effect only for `bypassPermissions` / always-approve (and `default`); other values are accepted but not yet enforced. Explicit `--allow`/`--deny` rules and `PreToolUse` hooks work regardless of mode.

### Locking Always-Approve (YOLO) Off

Administrators can pin always-approve (`bypassPermissions` / `--always-approve`) **off** so it cannot be enabled from the CLI, the TUI toggle, or the `/always-approve` command. Set the dedicated key in `requirements.toml`:

```toml
[ui]
disable_bypass_permissions_mode = true   # default: false. true = locked off.
```

Do **not** use `permission_mode` for this; it is a user-switchable default, not a lock. (Legacy `[ui] yolo = false` in `requirements.toml` still locks for back-compat; in `config.toml` it stays a togglable preference.)

This lock **fails open** on the user-writable `~/.grok/requirements.toml`: a developer can edit that file to remove it. Tamper-resistant enforcement requires a root-owned tier — a system-dir `/etc/grok/requirements.toml`. (Claude Code's `managed-settings.json` `disableBypassPermissionsMode` is **not** applied to grok's always-approve — grok honors that file's permission rules but not its bypass lock, so it does not inherit a host's Claude Code lockdown; use grok's `requirements.toml` to disable always-approve.) See [Enterprise → Locking Always-Approve (YOLO) Mode](../internal/25-enterprise.md) for the trust tiers and deployment details.

---

## Configuring Permissions

Grok supports three compatible configuration sources. They are merged with well-defined precedence.

### 1. CLI Flags

```bash
grok -p "Review the API changes" \
  --permission-mode dontAsk \
  --allow 'Bash(git *)' \
  --allow 'Bash(gh *)' \
  --allow 'Read' \
  --allow 'Grep' \
  --deny 'Bash(rm -rf *)'
```

- `--allow RULE` and `--deny RULE` can be repeated and are always enforced
- `--permission-mode` names the base policy, but see the [wiring note](#permission-modes): only `bypassPermissions` currently takes effect via this flag. For deny-by-default, set `defaultMode: "dontAsk"` in `.claude/settings.json` or use a `PreToolUse` hook (below)

Rule syntax examples:
- `Bash(git *)` — any command starting with `git `
- `Bash(npm run build)` — exact command (or prefix)
- `Bash(git commit:*)` — Claude Code's `cmd:*` idiom, accepted as equivalent to prefix matching on `git commit`
- `Read(src/**)` — read access under `src/`
- `Edit(**/*.rs)` — edit any Rust file
- `Grep` — all grep operations
- `MCPTool(my-server__*)` — MCP tools from a specific server

### 2. Native Configuration (`~/.grok/config.toml` and `.grok/config.toml`)

```toml
[permission]
rules = [
  { action = "allow", tool = "bash", pattern = "git *" },
  { action = "allow", tool = "bash", pattern = "gh *" },
  { action = "allow", tool = "read" },
  { action = "allow", tool = "grep" },
  { action = "deny",  tool = "bash", pattern = "rm -rf *" },  # block a dangerous pattern
  { action = "ask",   tool = "edit" },
]
```

Because `deny` always wins (see below), you cannot combine these `allow` rules with a catch-all `deny` on `bash` to mean "only allow git/gh" — a `deny tool = "bash"` rule would block `git`/`gh` too. For deny-by-default, use a `PreToolUse` hook (below) or `.claude/settings.json` `defaultMode: "dontAsk"`.

Rules from the global `~/.grok/config.toml` and every project `.grok/config.toml` (from the repo root down to your working directory) are merged into one rule set, alongside any `.claude/settings.json` rules.

Managed config files also contribute `[permission]` rules: the system `/etc/grok/managed_config.toml` and the user `~/.grok/managed_config.toml`, which the team deployment-config sync writes. These are team defaults for `allow` rules: your own `deny` and `ask` rules win over a managed `allow`, a managed `deny` or `ask` wins like one from any other file, and a catch-all `allow` from a managed config file is ignored when always-approve is locked off. For rules that users cannot edit away, use the root-owned system `/etc/grok/requirements.toml`; the user-level `~/.grok/requirements.toml` is user-editable.

Permission rules from every source are read once, when a session starts. Changes apply to the next session.

The native `[permission]` section also accepts the compact `allow` / `deny` / `ask` string-array form — the same rule strings used by the `--allow` / `--deny` flags and `.claude/settings.json`:

```toml
[permission]
deny = [
  "Read(/Users/you/private/**)",
  "Edit(/Users/you/private/**)",
  "Bash(rm -rf *)",
]
allow = [
  "Bash(git *)",
  "Bash(gh *)",
]
```

`deny` always wins over `allow` (evaluation is `deny` > `ask` > `allow`), regardless of order or source. (To hard-block reads of paths *outside* your project regardless of tool, combine this with the `strict` sandbox profile — see [18-sandbox.md](18-sandbox.md).)

### 3. Claude Code Compatibility (`.claude/settings.json`)

Grok reads `~/.claude/settings.json` and `~/.claude/settings.local.json`, plus the project-level `<project>/.claude/settings.json` and `settings.local.json` (walking up to the repo root). The native `.grok` source for permission rules is `config.toml`, described in the section above.

Example:

```json
{
  "defaultMode": "dontAsk",
  "permissions": {
    "allow": [
      "Read",
      "Grep",
      "Bash(git *)",
      "Bash(gh *)"
    ],
    "deny": [
      "Bash(rm -rf *)"
    ]
  }
}
```

Supported `defaultMode` values are `default`, `acceptEdits`, `bypassPermissions`, `dontAsk`, and `plan`.

`permissions.allow` and `permissions.deny` entries are translated into native rules. You can import existing Claude settings interactively with **Ctrl+I** ("Import Claude settings").

---

## Restrictive Hooks — The `git + gh` Only Example

For the strongest control, use a `PreToolUse` hook that acts as a hard allow-list on the `Bash` tool. Hooks are evaluated before the permission system.

### Global `git-gh-only` Hook

This example only permits `git` and `gh` commands:

**`~/.grok/hooks/git-gh-only.json`**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "git-gh-only.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**`~/.grok/hooks/git-gh-only.sh`**

```bash
#!/bin/sh
# Allow only commands whose first word is "git" or "gh".

set -eu

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.toolInput.command // empty' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$CMD" ]; then
  echo '{"decision": "deny", "reason": "Empty command is not allowed"}'
  exit 2
fi

FIRST_WORD=$(echo "$CMD" | awk '{print $1}')

case "$FIRST_WORD" in
  git|gh)
    echo '{"decision": "allow"}'
    exit 0
    ;;
  *)
    echo '{"decision": "deny", "reason": "Only git and gh commands are permitted. Blocked: '"$CMD"'"}'
    exit 2
    ;;
esac
```

```bash
chmod +x ~/.grok/hooks/git-gh-only.sh
```

This hook is the hard enforcer: it denies every `Bash` command except `git`/`gh` regardless of permission mode. Combine it with narrow allow rules for read tools and you have a tight allow-list that does not depend on `dontAsk` being wired.

For full details on hook installation, the JSON format, trust model for project hooks, and other events, see [10-hooks.md](10-hooks.md) (which also contains a complementary "block dangerous patterns" example).

---

## Example Configurations

### Headless "git + gh only" (recommended for CI / automation)

```bash
grok -p "Implement the feature using only git and GitHub CLI" \
  --allow 'Read' \
  --allow 'Grep' \
  --allow 'Bash(git *)' \
  --allow 'Bash(gh *)'
```

Install the `git-gh-only` hook above — it is the hard enforcer that denies any
other `Bash` command. For deny-by-default on *all* tools, also set
`{"defaultMode": "dontAsk"}` in `.claude/settings.json` (the wired path for
`dontAsk`).

### Read-only code reviewer

```toml
# .grok/config.toml
[permission]
rules = [
  { action = "allow", tool = "read" },
  { action = "allow", tool = "grep" },
  { action = "deny",  tool = "edit" },
  { action = "deny",  tool = "bash" },
]
```

### Daily driver

Use `default` mode plus narrow `Bash(...)` allow rules for common safe commands (`git`, `cargo test`, `rg`, etc.).

---

## Combining with Sandbox

Permissions control *what the model is allowed to request*. The OS-level sandbox (see [18-sandbox.md](18-sandbox.md)) controls what the actual process can do even if a command is approved.

Recommended stack for untrusted code:

1. `dontAsk` + narrow allow rules or restrictive hook
2. `--sandbox strict` or a custom profile
3. Project trust + careful review of any `SessionStart` hooks

---

## Managing Permissions in the TUI

- **Ctrl+L** (non–VS Code family) — Open the Extensions modal (Plugins tab by default). On **VS Code / Cursor / Windsurf / Zed**, `Ctrl+L` is mid-turn interject; use **`/plugins`** or **`/hooks`** instead. Run `/hooks` to open directly on the Hooks tab. See [10-hooks.md](10-hooks.md) for details, including how to trust project hooks.
- Permission decisions appear in the transcript.
- The current permission mode can be changed and saved from within the TUI.

---

## Best Practices

1. **Prefer narrow patterns** — `Bash(git *)` is much safer than a broad `Bash` allow rule.
2. **Combine layers** — `dontAsk` + explicit narrow allows + restrictive hook + sandbox provides strong restrictions.
3. **Review project hooks** — See the security notes in [10-hooks.md](10-hooks.md). Never blindly trust hooks from untrusted repositories.
4. **Test your policy** — With `defaultMode: "dontAsk"` in `.claude/settings.json` (or your `PreToolUse` hook installed), run representative commands and observe what gets blocked.
5. **The safe-bash list is for convenience, not a security boundary.**

---

## Summary

- Multiple independent layers (hooks → policy → fast-paths → prompt policy) work together.
- `dontAsk` + explicit narrow allow rules is the most common way to run the agent safely in non-interactive contexts.
- The `git-gh-only` hook pattern is a minimal example of a positive allow-list for shell.
- Native TOML, Claude JSON, and CLI flags all work together.

Use these controls to run the agent with only the privileges it needs.

---

Cross-references:
- [10-hooks.md](10-hooks.md) — Full hook authoring guide
- [14-headless-mode.md](14-headless-mode.md) — All headless flags including permission-related ones
- [18-sandbox.md](18-sandbox.md) — OS-level isolation profiles
- [05-configuration.md](05-configuration.md) — Native `config.toml` structure