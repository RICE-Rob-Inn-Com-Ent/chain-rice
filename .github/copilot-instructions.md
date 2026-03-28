# .rice OS — GitHub Copilot Instructions

<!--
TODO:
- [ ] replace all Bazel references with Buck2 + pixi
- [ ] replace all /backend/ with /service/ (Go + Elixir)
- [ ] replace all /bots/ with /function/ (Python + Mojo)
- [ ] add .rice language section: *.rice in custom/ — compiled by base/mint/; never edit transpiled output
- [ ] add rice command reference: rice pour, rice forge, rice think, rice audit, rice cook, rice serve
- [ ] add role MDC reference: .cursor/rules/*.mdc — one per role
- [ ] add soft-coded placeholder note: RICE_GITHUB_ORG / RICE_GITHUB_REPO — never hardcode org/repo in workflows
- [ ] add model routing note for Copilot: no MCP — use static doc URL table in instructions/king.instructions.md
-->

You are working in the `.rice OS` monorepo — a sovereign programming language
and enterprise operating system. Seven roles own seven directories.
Every question belongs to a role. Every file belongs to a role.

---

## 🗺️ KINGDOM MAP

| Role | Directory | Command | Owns |
| ---- | --------- | ------- | ---- |
| 👷 MASON | `infra/` | `rice pour` | CUE templates, Protobuf schemas, Markdown docs |
| 🧑‍🏭 SMITH | `service/` | `rice forge` | Go microservices, Elixir immune system, observability |
| 👨‍💼 CLERK | `base/` | `rice audit` | Rust contracts, Haskell math, Zig defense, .rice compiler |
| 🧑‍🎤 BARD | `frontend/` | `rice perform` | TypeScript browser, Dart devices, Odin GPU/audio/video |
| 🧑‍🔬 SAGE | `function/` | `rice think` | Python AI/data, Mojo kernels, kingdom test orchestration |
| 👨‍🍳 CHIEF | `custom/` | `rice cook / rice serve` | Concrete `.rice` projects — hardcoded, not skeletons |
| 🫅 KING | ROOT | `rice rule` | Read-only sovereign — routes, never implements |

---

## 📚 DOCUMENTATION SOURCES

Since Copilot has no MCP, fetch documentation from these URLs before suggesting any implementation.
Do not rely on training memory for library versions or API shapes.

### 👷 MASON — infra/

- CUE: <https://cuelang.org/docs/>
- Protobuf / buf: <https://buf.build/docs/>
- Timoni: <https://timoni.sh/>
- MkDocs: <https://www.mkdocs.org/>

### 🧑‍🏭 SMITH — service/

- Go modules: <https://go.dev/ref/mod>
- Cosmos SDK: <https://docs.cosmos.network/>
- CometBFT: <https://docs.cometbft.com/>
- IBC: <https://ibc.cosmos.network/>
- pgx: <https://pkg.go.dev/github.com/jackc/pgx/v5>
- sqlc: <https://docs.sqlc.dev/>
- go-redis: <https://redis.uptrace.dev/>
- ConnectRPC Go: <https://connectrpc.com/docs/go/getting-started/>
- Gofiber: <https://docs.gofiber.io/>
- gocloud: <https://gocloud.dev/howto/>
- go-mail: <https://pkg.go.dev/github.com/wneessen/go-mail>
- Ory Kratos: <https://www.ory.sh/docs/kratos/>
- Ory Hydra: <https://www.ory.sh/docs/hydra/>
- OpenTelemetry Go: <https://opentelemetry.io/docs/languages/go/>
- Zap: <https://pkg.go.dev/go.uber.org/zap>
- Temporal: <https://docs.temporal.io/>
- NATS: <https://nats.io/documentation/>
- Phoenix: <https://hexdocs.pm/phoenix/>
- Broadway: <https://hexdocs.pm/broadway/>
- OTP: <https://www.erlang.org/doc/design_principles/des_princ.html>
- YugabyteDB: <https://docs.yugabyte.com/>

### 👨‍💼 CLERK — base/

- Rust / Cargo: <https://doc.rust-lang.org/cargo/>
- CosmWasm: <https://docs.cosmwasm.com/>
- ark-groth16: <https://docs.rs/ark-groth16/>
- logos: <https://docs.rs/logos/>
- chumsky: <https://docs.rs/chumsky/>
- rowan: <https://docs.rs/rowan/>
- salsa: <https://docs.rs/salsa/>
- miette: <https://docs.rs/miette/>
- tower-lsp: <https://docs.rs/tower-lsp/>
- Haskell / GHC: <https://www.haskell.org/documentation/>
- QuickCheck: <https://hackage.haskell.org/package/QuickCheck>
- hledger-lib: <https://hackage.haskell.org/package/hledger-lib>
- Zig: <https://ziglang.org/documentation/master/>
- ebpf: <https://ebpf.io/>
- OpenTofu: <https://opentofu.org/docs/>

### 🧑‍🎤 BARD — frontend/

- Next.js: <https://nextjs.org/docs>
- React: <https://react.dev/>
- TanStack Query: <https://tanstack.com/query/latest>
- Zustand: <https://docs.pmnd.rs/zustand/>
- Radix UI: <https://www.radix-ui.com/primitives/docs/overview/introduction>
- Tailwind CSS: <https://tailwindcss.com/docs/>
- ConnectRPC Web: <https://connectrpc.com/docs/web/getting-started/>
- Vitest: <https://vitest.dev/>
- Playwright: <https://playwright.dev/docs/intro>
- Flutter: <https://docs.flutter.dev/>
- Riverpod: <https://riverpod.dev/>
- ConnectRPC Dart: <https://connectrpc.com/docs/dart/getting-started/>
- Patrol: <https://pub.dev/packages/patrol>
- Odin: <https://odin-lang.org/docs/>
- wgpu: <https://wgpu.rs/>
- miniaudio: <https://miniaud.io/docs/>

### 🧑‍🔬 SAGE — function/

- FastAPI: <https://fastapi.tiangolo.com/>
- Pydantic: <https://docs.pydantic.dev/latest/>
- LiteLLM: <https://docs.litellm.ai/>
- LangGraph: <https://langchain-ai.github.io/langgraph/>
- instructor: <https://python.useinstructor.com/>
- guardrails-ai: <https://www.guardrailsai.com/docs/>
- Qdrant: <https://qdrant.tech/documentation/>
- Polars: <https://docs.pola.rs/>
- Qiskit: <https://docs.quantum.ibm.com/>
- PennyLane: <https://docs.pennylane.ai/>
- JAX: <https://jax.readthedocs.io/en/latest/>
- Mojo: <https://docs.modular.com/mojo/>
- MAX Engine: <https://docs.modular.com/max/>
- pytest: <https://docs.pytest.org/en/stable/>

### 👨‍🍳 CHIEF — custom/

- .rice language: <https://docs.code-rice.com/language>
- .rice OS: <https://docs.code-rice.com/os>

---

## ✅ YOU ALWAYS KNOW

- Every ROOT file is **generated by MASON** from `infra/configs/*.cue` — never edit directly
- Every `gen/` directory is **generated by buf** — never edit directly
- Every `.rice` program lives in `custom/` — CHIEF owns it, no other role touches it
- `base/private/` contains ZK proofs — never generate into it, never touch it
- No floating point for money — Haskell `Decimal` and Rust `rust_decimal` only
- No Python libraries in Mojo — pure `fn` functions only, no CPython bridge
- No database connections from SAGE — query SMITH via proto contracts only
- OpenTofu replaces Terraform everywhere — commands are `tofu validate`, `tofu plan`, `tofu apply`
- BARD hardware state = typed message structs, not proto contracts
- `rice audit` is the only path to production — no bypass

---

## ❌ YOU NEVER SUGGEST

- Editing any file in `*/gen/`
- Editing ROOT files directly — change the `.cue` in `infra/`, rerun `rice pour`
- Using CockroachDB — replaced by YugabyteDB (Apache 2.0)
- Using Terraform — replaced by OpenTofu (MPL-2.0)
- Using Helm — replaced by Timoni + CUE
- Adding business logic to BARD
- Adding UI code to SAGE
- Writing raw Go/Elixir/Rust/TypeScript/Dart/Python when `.rice` can express it
