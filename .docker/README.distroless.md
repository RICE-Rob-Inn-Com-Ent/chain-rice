# Distroless policy (KING / `.docker`)

## Rice-owned binaries (SMITH, BARD stubs, SAGE)

- **Go (CGO_ENABLED=0):** final stage `gcr.io/distroless/static-debian12:nonroot`.
- **Go + libc:** `gcr.io/distroless/base-debian12:nonroot` (only if cgo required).
- **Node / Next.js:** `gcr.io/distroless/nodejs22-debian12` with `output: "standalone"`.
- **Python:** prefer `gcr.io/distroless/python3-debian12` + venv copy, or Chainguard Wolfi images.

Shared stub: `.docker/Dockerfile.rice-distroless-stub` + `.docker/rice-healthd` — keeps `docker compose` healthy until real binaries ship.

Health checks in distroless **must not** use `curl`/`sh`; use `["/rice-healthd", "-healthcheck"]` or gRPC health protos.

## Vendor / data plane (not distroless today)

| Service   | Image rationale                                      |
| --------- | ---------------------------------------------------- |
| YugabyteDB| JVM — upstream does not publish distroless           |
| Valkey    | `valkey/valkey:*-alpine` — smallest official tag     |
| NATS      | `nats:*-alpine`                                      |
| Qdrant    | Official static binary image (minimal, not Google DL) |
| Temporal  | `temporalio/auto-setup` — needs shell + CLI         |
| Ollama    | GPU / CUDA — upstream Debian-based                   |
| vLLM      | NVIDIA CUDA stack                                  |
| Postal    | Full Ruby mail stack — stub uses distroless Go      |

Renovate / CUE should pin versions; edit `infra/configs/docker/*.cue`, then `cue export` (MASON), not hand-edit generated ROOT files when policy applies.
