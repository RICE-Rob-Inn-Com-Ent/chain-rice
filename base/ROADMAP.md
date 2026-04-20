# CLERK `base/` roadmap (`.rice` substrate)

Legend: **Done** ships in tree today. **Next** closes gaps for 10/10 reuse of organs from `.rice`.

## Workspace and Buck shims

| Item | Status | Notes |
|------|--------|--------|
| [Cargo.toml](Cargo.toml) workspace (`contract`, `mint`, `policies`, `private`, `util`, `bench`) | Done | Single lockfile [Cargo.lock](Cargo.lock); `cargo check --workspace --locked` |
| Per-crate [contract/BUCK](contract/BUCK), [mint/BUCK](mint/BUCK), [policies/BUCK](policies/BUCK), [private/BUCK](private/BUCK), [util/BUCK](util/BUCK), [bench/BUCK](bench/BUCK), [calc/BUCK](calc/BUCK), [security/BUCK](security/BUCK) | Done | Each `:check` genrule — inline shell; Zig build is isolated to `security` |
| Root [.buckconfig](../.buckconfig) + [toolchains/BUCK](../toolchains/BUCK) | Done | Bundled prelude + demo toolchains |
| Native `rust_*` / `zig_library` in Buck | Next | Replace genrules when prelude Rust/Zig rules are wired for hermetic linking |

## `util` — shared types, proto, FFI bridge

| Item | Status | Notes |
|------|--------|--------|
| [util/src/bridge.rs](util/src/bridge.rs) (`calc`, `warden`, `stress`) | Done | Haskell CALC + Zig `clerk-security` behind features |
| [util/build.rs](util/build.rs) | Done | `zig-warden` link of `libclerk-security` |
| Docs for wasm vs native split | Next | Short `util/README.md` for embedders |

## `contract` — CosmWasm

| Item | Status | Notes |
|------|--------|--------|
| Sylvia contract + unit tests | Done | `cargo test -p contract` |
| Schema / `.rice` codegen from Mint | Next | Tie contract entrypoints to language AST |

## `mint` — `.rice` compiler + LSP

| Item | Status | Notes |
|------|--------|--------|
| Parser / checker / `rice-lsp` binary | Done | See [mint/Cargo.toml](mint/Cargo.toml) |
| LSP parity (refs, rename, workspace symbols) | Next | See [mint/src/lsp.rs](mint/src/lsp.rs) |
| Perf harness ↔ bench | Done | `RICE_BENCH_BIN`, `RICE_LSP_PERF` |

## `policies` — CEL, finance, audit

| Item | Status | Notes |
|------|--------|--------|
| CEL engine, finance, XML/FIX paths | Done | Optional `RICE_*` env in [`.env`](.env) |
| CALC delegation (`RICE_USE_CALC_FFI`) | Next | Wire to `util::calc` in hot paths consistently |
| Audit NATS / file backends | Partial | Env-gated in [policies/src/audit.rs](policies/src/audit.rs) |

## `private` — ZK / compliance

| Item | Status | Notes |
|------|--------|--------|
| Groth16 pipeline, env-driven setup | Done | `RICE_ZK_*` in [`.env`](.env) |
| Production trusted setup + HSM story | Next | `RICE_ZK_TRUSTED_SETUP_PATH` workflow |

## `bench` — integration harness

| Item | Status | Notes |
|------|--------|--------|
| JSON smoke, criterion wiring | Done | `just base-bench-smoke` |
| Native benches (`full-native-benches`) | Next | Zig + CALC on CI hosts |

## `security/` (Zig)

| Item | Status | Notes |
|------|--------|--------|
| `zig build verify` + `libclerk-security.a` build | Done | Via Buck `//base/security:check` |
| Operator doc for Zig warden + CI | Next | Add `base/ZIG_WARDEN.md` (or link) for `zig-warden` / `libclerk-security` |

## `calc/` (Haskell CALC)

| Item | Status | Notes |
|------|--------|--------|
| `cabal` foreign-library | Done | `//base/calc:check` genrule |
| Version pin + CI cache | Next | Align GHC with `package.yaml` / pixi |

## `.rice` language reuse (cross-cutting)

| Item | Status | Notes |
|------|--------|--------|
| Stable error surface (`util::RiceError`) | Done | |
| Spec for “organ boundaries” (who may import whom) | Next | Enforce in docs + optional lint |
| Public book chapter for `.rice` ↔ organs | Next | Link from root README |
