---
name: fleet
description: Access or run work on one or more fleet workers connected through Amnezia VPN, troubleshoot fleet connectivity and .fleet DNS, enroll new workers, or configure existing workers. Machine names: sokolov, corpbook, vds
---

Cockpit - the control machine from which work is delegated. It has no `.fleet` domain and is not a worker.
Worker - a machine that receives delegated work through T3 Code, Codex, or another orchestrator.

## Connection policy

- The cockpit may initiate connections to workers.
- Workers may initiate connections to other workers.
- Workers must not initiate connections to the cockpit. Replies on connections initiated by the cockpit are allowed.
- Do not expose cockpit services to workers or create reverse tunnels or relays that let workers reach the cockpit.
- Keep worker jobs, required files, and services on workers so they do not depend on connections back to the cockpit.

This is the required access policy, not proof of the current firewall configuration. When configuring networking, verify that the actual rules enforce it; the absence of a `.fleet` name alone does not block access.

## Machines

Read [machines.md](machines.md) only when the task needs machine inventory, connection details, or host-specific services.

## Worker configuration

Read [box_setup.md](box_setup.md) when enrolling a new worker or configuring an existing worker. For existing workers, apply only the requested configuration changes unless asked to bring the whole machine into the documented target state.
