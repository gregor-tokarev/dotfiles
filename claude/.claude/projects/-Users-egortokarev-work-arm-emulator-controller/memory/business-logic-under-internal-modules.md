---
name: business-logic-under-internal-modules
description: "In arm-emulator-controller, all business logic must live under internal/modules/"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 97f3808e-e55d-41e4-9d31-6d67f5b02d51
---

In the `arm-emulator-controller` project, all business-logic packages must live under `internal/modules/` (e.g. `internal/modules/adb`, `internal/modules/proxy`, `internal/modules/emulator`, `internal/modules/session`).

**Why:** Project structuring convention the user requires.

**How to apply:** Do not put domain/business packages directly under `internal/` (like the ported `macos-emulator-controller` layout). Nest them under `internal/modules/`. gRPC handlers stay in `internal/app/grpc/...` (scratch scaffold), but the logic they call belongs in `internal/modules/`.
