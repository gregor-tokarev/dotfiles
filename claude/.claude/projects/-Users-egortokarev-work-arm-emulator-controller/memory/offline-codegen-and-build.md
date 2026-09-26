---
name: offline-codegen-and-build
description: How to regenerate protobuf and build arm-emulator-controller without network access to gitlab.wildberries.ru
metadata: 
  node_type: memory
  type: project
  originSessionId: 97f3808e-e55d-41e4-9d31-6d67f5b02d51
---

`gitlab.wildberries.ru` is unreachable in this environment, so the normal `make proto` / `make deps` / `go mod tidy` all fail (they try to reinstall the scratch toolchain or fetch private modules).

**Regenerate protobuf (bypass `scratch init`):**
1. Symlink the vendored tools into `~/go/bin` (wbuff looks for them there):
   `for t in buf wbuff protoc-gen-go protoc-gen-go-grpc protoc-gen-grpc-gateway protoc-gen-wb-openapiv2; do ln -sf "$PWD/bin/$t" ~/go/bin/$t; done`
2. Run wbuff directly: `PATH="$PWD/bin:$HOME/go/bin:$PATH" ./bin/wbuff generate "$PWD" --with-bin-dir "$PWD/bin"`

**Build/test/add deps:** use the module cache only — `GOPRIVATE='gitlab.wildberries.ru/*' GOPROXY=off go build|test|vet ./...`. To add a public dep already in cache (e.g. goproxy): `GOPROXY=off GOFLAGS=-mod=mod go get <mod>@<ver>`.

Note: the vendored `bin/golangci-lint` is v1 but `.golangci.yaml` is v2 format — the linter errors on version mismatch. Pre-existing scaffold issue; rely on `gofmt`/`go vet` locally.

Related: [[business-logic-under-internal-modules]]
