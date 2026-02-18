# @rice/node — BFF Source Structure

API Gateway / Backend for Frontend: **Bun** + **ElysiaJS** + **ConnectRPC** (gRPC-Web).

## Directory layout

| Path | Role |
|------|------|
| `gen/` | **Generated** — Protobuf/Connect output from `bun run proto` (buf). Do not edit by hand. |
| `config/` | Env validation (Valibot) at startup; typed `loadEnv()`. |
| `infrastructure/` | gRPC transport factory, interceptors (logging, header propagation), `runWithGrpcContext`. |
| `clients/` | Per-service Connect clients (e.g. `getUserClient`) using the shared transport. |
| `services/` | Orchestration: call gRPC clients, map responses to frontend DTOs. |
| `http/` | Elysia controllers: validate input (Valibot), call services, map gRPC errors to HTTP. |

## Request flow

1. **HTTP** — Elysia route → Valibot validation → **runWithGrpcContext**(request.headers) → **service**
2. **Service** — get client from `clients/`, call gRPC inside the same context (headers/trace propagated)
3. **Infrastructure** — Interceptors add auth/trace headers to the gRPC request; transport uses Connect over HTTP/2

## Env

- `USER_SERVICE_URL` — Go UserService base URL (default: `http://localhost:8080`)
- `PORT` — BFF port (default: `3000`)
- Validated at startup via Valibot; app fails fast on invalid config.

## Proto / gen

- Proto definitions: `proto/` (e.g. `proto/user/v1/user.proto`).
- Generate: `bun run proto` (buf + protoc-gen-es + protoc-gen-connect-es) → `src/gen/`.
- If your monorepo uses **Bazel** for proto, point buf at the same sources or use the Bazel rule that outputs into `src/gen`.
