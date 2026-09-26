# Worker configuration

Use this reference when enrolling a new worker or configuring an existing one. It describes the worker target state; it does not apply that role to the cockpit.

## Software

- Rust and Cargo
- OpenSSH server, enabled at boot
- Codex CLI, authenticated for the intended user
- Claude Code CLI (`claude`), available in the intended user's terminal and SSH sessions; verify installation and report whether sign-in is still required
- OpenCode, with its intended provider configured
- Go
- Bun
- Vite+
- Node.js LTS, managed by Vite+
- Python
- T3 Code backend running as a persistent background service
- Git, with the intended user identity configured
- GitHub CLI, authenticated for the intended account
- curl, jq, rg, rsync, tar, and unzip
- C/C++ compiler, make, and pkg-config, using the OS equivalents where necessary
- kache, configured globally for Rust and C/C++ build caching.

## Network and access

- Give each worker its own Amnezia profile, unique peer identity, and private IP. Do not copy another machine's peer credentials.
- Start the VPN automatically and provide both outgoing and incoming fleet connectivity.
- Allow inbound TCP and UDP ports `2000–12000` on workers through the fleet VPN, from the cockpit and other fleet workers. Persist any firewall rules across reboots. This requirement does not expose the range on public interfaces or allow workers to initiate connections to the cockpit.
- Services intended for fleet access must listen on the worker's fleet address rather than only `127.0.0.1`. Verify reachability from another fleet device; opening firewall ports alone does not make a localhost-only service reachable.
- Assign a unique(ask user about name) `<hostname>.fleet` DNS record and configure the worker to resolve other fleet names.
- Allow SSH without a password or SSH key on the trusted fleet network, as required by the fleet owner's policy. Do not expose this unauthenticated access on public or unrelated network interfaces.
- Grant the intended worker user passwordless sudo.
- Keep background jobs running after the initiating SSH session disconnects. On Linux, enable user lingering when needed by user services.
- Configure sleep behavior so unattended work and remote access remain available while the worker is expected to operate.
