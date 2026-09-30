# Machine configuration

Use this reference when enrolling a new worker, configuring an existing one, or setting up the cockpit. It describes the target state.

- Workers: every section applies.
- Cockpit: Software, Codex sign-in, and Skills and agents apply. Network and access does not, and items marked worker only are skipped. Nothing on the cockpit may be reachable from workers (see the connection policy).

## Software

- Rust/Cargo, Go, Bun, and Python
- OpenSSH server, enabled at boot (worker only)
- Codex CLI, authenticated for the intended user
- Claude Code CLI (`claude`), available in the intended user's terminal and SSH sessions; verify installation and report whether sign-in is still required
- OpenCode, with its intended provider configured
- Vite+ with Node.js LTS managed by Vite+
- T3 Code backend running as a persistent background service (on the cockpit, listening on localhost only)
- Git with the intended user identity configured; GitHub CLI authenticated for the intended account
- curl, jq, rg, rsync, tar, and unzip
- C/C++ compiler, make, and pkg-config, using the OS equivalents where necessary
- kache configured globally for Rust and C/C++ build caching
- Cargo parallelism capped at half the CPU cores (`jobs` under `[build]` in `~/.cargo/config.toml`), so parallel agent builds don't starve SSH (worker only)
- Cloudflare CLI (`cf`) and Railway CLI

Sign in to supported tools with the intended account, using the cockpit's browser session when appropriate. Report any remaining sign-in blockers.

## Codex sign-in

Complete routine Codex sign-in without asking the user to run commands, enter a device code, or approve each step.

1. Check `codex login status` as the intended user. Keep a working sign-in unless the user requests reauthentication.
2. If needed, run `codex login --device-auth` on the machine and keep it running. Use browser automation on the cockpit to open its verification URL in the intended account's session, enter its device code, and complete sign-in. Reject codes from third-party pages; do not copy the cockpit's authentication cache.
3. Verify `codex login status` on the machine after it reports success. Browser success alone is insufficient.

Ask the user only for blockers requiring their participation: unavailable credentials, MFA, an ambiguous account, or mandatory confirmation. Do not bypass security checks, save codes or tokens in notes or final messages, or initiate a worker-to-cockpit connection.

## Network and access (worker only)

- Give each worker its own Amnezia profile, unique peer identity, and private IP. Do not copy another machine's peer credentials.
- Start the VPN automatically and provide both outgoing and incoming fleet connectivity.
- Allow inbound TCP and UDP ports `2000–12000` on workers through the fleet VPN, from the cockpit and other fleet workers. Persist any firewall rules across reboots. This requirement does not expose the range on public interfaces or allow workers to initiate connections to the cockpit.
- Services intended for fleet access must listen on the worker's fleet address rather than only `127.0.0.1`. Verify reachability from another fleet device; opening firewall ports alone does not make a localhost-only service reachable.
- Ask for a worker name if none was provided, assign a unique `<hostname>.fleet` DNS record, and configure the worker to resolve other fleet names.
- Allow SSH without a password or SSH key on the trusted fleet network, as required by the fleet owner's policy. Do not expose this unauthenticated access on public or unrelated network interfaces.
- Grant the intended worker user passwordless sudo.
- Keep background jobs running after the initiating SSH session disconnects. On Linux, enable user lingering when needed by user services.
- Configure sleep behavior so unattended work and remote access remain available while the worker is expected to operate.


## Skills and agents

files that you should copy over to ~/.agents directory and symbolic link it with ~/.claude

./skilllisting over to .agents/skills
setupfiles to ~/.agents in AGENTS.md dynamic segments {{}} are presented, resolve them before setting up on machine

On the cockpit, symlink each skill from ./skilllisting into ~/.agents/skills instead of copying, so dotfiles edits apply immediately.
