---
name: ozon-traffic-capture-rpcs
description: Traffic capture gRPC handlers and their gotchas in macos-emulator-controller
metadata: 
  node_type: memory
  type: project
  originSessionId: ac949056-c529-45b9-b24a-6f8b5b43f8ff
---

The emulator-controller captures the app's network requests via an embedded goproxy MITM (`internal/proxy`). Handlers:
- `StreamTraffic` (server-stream, live) / `ListTraffic` (buffered history, ring buffer 1000, bodies capped 1 MiB). Both now gunzip/deflate-decode bodies before returning (still base64 in gRPC-JSON since the field is protobuf `bytes`).
- `CaptureTraffic{enable,output_dir,host_filter}` — persists every exchange to disk: `output_dir/index.jsonl` (metadata+headers+body-file paths) + `output_dir/bodies/` with full, gunzipped bodies (uncapped). Background writer goroutine; suits high throughput. This replaced an earlier OCR/screenshot idea (too slow for throughput).

App auto-launch + connectivity:
- `LaunchApp` auto-boots an emulator when no device is running (on by default; `-avd` picks one, else first from `emulator -list-avds`). Launcher (`internal/emulator`) starts it detached (Setsid) with `-writable-system -selinux permissive` so it survives server restarts and keeps the system CA. `LaunchApp` with no `activity` resolves the launcher activity via `cmd package resolve-activity --brief` (monkey is unreliable for Ozon).
- `LaunchApp` calls `reconcileProxy`: if the proxy is running it re-adds the `adb reverse` tunnel + sets `http_proxy 127.0.0.1:<port>`; if not, it clears a stale loopback proxy. This fixes the post-reboot "нет соединения" (reboot drops the reverse tunnel but keeps the http_proxy setting → app offline).

Gotchas that cause "nothing appears":
- `StreamTraffic`/`ListTraffic` only surface what a **running** proxy intercepts. If `StartProxy` was never called, they're silently empty. `StreamTraffic` now returns FailedPrecondition when the proxy isn't running.
- `StartProxy` auto-config now uses `adb reverse` + `http_proxy 127.0.0.1:<port>` + airplane-mode cycle. It short-circuits with "already running" if the proxy is up, so it will NOT reconfigure a newly-swapped device — restart the server (or StopProxy first) when switching emulators.
- grpcurl **reflection works but unary calls hang** in this environment (a grpcurl quirk, not the server). Use a native Go client / Postman for unary+streaming calls.

Device provisioning to actually decrypt Ozon HTTPS: see [[ozon-mitm-capture-setup]].
