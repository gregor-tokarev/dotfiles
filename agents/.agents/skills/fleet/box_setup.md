# Machine configuration

Use this reference when enrolling a new worker, configuring an existing one, or setting up the cockpit. It describes the target state.

- Workers: every section applies.
- Cockpit: Software, Codex sign-in, and Skills and agents apply. Network and access does not, and items marked worker only are skipped. Nothing on the cockpit may be reachable from workers (see the connection policy).

## Software

- Rust/Cargo, Go, Bun, and Python
- OpenSSH server, enabled at boot (worker only)
- Codex CLI, authenticated for the intended user
- Claude Code CLI (`claude`), available in the intended user's terminal and SSH sessions; verify installation and report whether sign-in is still required. Auto memory is disabled: `"autoMemoryEnabled": false` in `~/.claude/settings.json`, merged into the existing settings
- OpenCode, with its intended provider configured
- Vite+ with Node.js LTS managed by Vite+
- T3 Code: each worker runs exactly one T3 server, the background service (`t3 service install`, unit `t3code.service`, enabled, with a `fleet.conf` drop-in setting `T3CODE_HOST=127.0.0.1` and `T3CODE_PORT=3773`). Workers are still added to the cockpit's T3 app as SSH environments. The app's launch script finds the service through `~/.t3/userdata/server-runtime.json`, reuses it as an `external` server, and never stops it. A server the app launches itself (`managed` in `~/.t3/ssh-launch/*/managed`) is killed whenever the app quits or its tunnel looks stale, and the app's launch script even kills a healthy managed server on reconnect, so every agent restarts and its working timer resets. Update the service from the app (it advertises `boot-service` self-update) or with `t3 update --yes`. The service must stay on loopback: the launch script only reuses servers whose origin is `127.0.0.1` or `localhost`; otherwise it starts a second server on the same `~/.t3`, which resumes the same threads and runs duplicate agents. To switch a worker from an app-launched server to the service, stop the managed PID, start the service, and kill any managed server the app relaunches during the gap, until the app's log shows `remoteServerKind: "external"`. On the cockpit, T3 listens on localhost only. For mobile clients on the fleet VPN, a `t3-fleet-proxy` user service runs socat on `<fleet IP>:3773` and forwards each connection to the port in `~/.t3/userdata/server-runtime.json`; pair phones with `http://<fleet IP>:3773/pair#token=<token from t3 pair>` (worker only).
- Git with the intended user identity configured; GitHub CLI authenticated for the intended account
- curl, jq, rg, rsync, tar, and unzip
- C/C++ compiler, make, and pkg-config, using the OS equivalents where necessary
- kache configured globally for Rust and C/C++ build caching
- Cargo parallelism capped at half the CPU cores (`jobs` under `[build]` in `~/.cargo/config.toml`), so parallel agent builds don't starve SSH (worker only)
- CPU priority, so heavy builds can't starve SSH or T3 Code (worker only):
  - `Nice=-10` and `CPUWeight=1000` drop-ins for every sshd unit. Sessions inherit this. `t3code.service` gets the same priority from its `priority.conf` drop-in (`fleet-renice-tree -10`).
  - `build.rustc-wrapper` points to `~/.local/lib/fleet/rustc-gate`, which then execs kache. It allows one cargo build at a time machine-wide: the first cargo process to compile holds the slot (`/run/user/<uid>/cargo-build-slot`), compilers from other cargo processes wait until it exits (logged to `cargo-build-slot.log`), and a cargo nested under the owner may proceed. Compilers run at nice 10 and in the idle I/O class. The worker's SSD saturates when several builds run at once, which freezes T3 and makes the cockpit restart it.
  - `[profile.dev] debug = "line-tables-only"` in `~/.cargo/config.toml`. Full debuginfo made a debug binary ~1 GB; linking and copying it are buffered writes that no I/O priority can hold back, and they stalled T3's database.
  - Disk-write cap for agent work: `fleetbuilds.slice` (system slice, `IOWriteBandwidthMax=/dev/sda 20M`; this SSD saturates at ~50 MB/s sustained, so the cap must leave T3 at least half, `IOWeight=10`) and `fleet-builds-mover.service`, a root loop (`/usr/local/libexec/fleet-builds-mover`) that moves `claude`, `codex`, cargo, rustc, linkers, kache and C compilers into the slice every second; everything they spawn inherits it. Only the T3 server and sshd stay uncapped. Without the cap, agents copying binaries or writing large files saturate the slow SSD, T3 misses the cockpit's 1-second readiness check, and the cockpit restarts it in a loop.
  - Small write-back batches: `vm.dirty_background_bytes = 16777216`, `vm.dirty_bytes = 67108864` in `/etc/sysctl.d/90-fleet-responsiveness.conf`. On ext4 a database fsync waits for every pending write in the same journal batch.
  - Delete large build trees one at a time with long pauses, and check the machine responds between them. Filesystem journal writes bypass the write cap: deleting ~220 GB of `target/` dirs back to back froze sokolov completely on 2026-10-01 and it needed a hard reset.
  - BFQ I/O scheduler on the system disk (udev rule `/etc/udev/rules.d/60-fleet-io-scheduler.rules`, `bfq` in `/etc/modules-load.d`), so the idle I/O class is enforced and T3's database syncs go ahead of build writes. `mq-deadline` doesn't enforce it for buffered writes. Don't shadow `cargo` on PATH instead; kache's cargo shim finds the shadow again and recurses forever.
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
