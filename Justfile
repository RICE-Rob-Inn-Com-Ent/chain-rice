# .rice OS — thin entrypoint → Dagger module (service/ci, `dagger call`).
# Install: https://docs.dagger.io/install — or `./bin/dagger` from the install script.
# Regenerate bindings after editing functions: `dagger develop` (from repo root).

export PATH := justfile_directory() + "/bin:" + env_var_or_default("PATH", "")

help:
    @just --list

# `base/bench` — quick JSON smoke (from monorepo root).
base-bench-smoke:
    cd "{{ justfile_directory() }}/base" && cargo run -p bench -- --json-smoke

# Compile Criterion harness without running full benchmarks.
base-bench-compile:
    cd "{{ justfile_directory() }}/base" && cargo bench -p bench --no-run

# Zig under `base/`: fmt-check, ast-check, and `security` tests (requires Zig ≥ 0.15 on PATH).
base-zig-verify:
    cd "{{ justfile_directory() }}/base" && zig build verify

# Buck2 CLERK shims: per-module checks (requires `buck2` on PATH).
base-buck-clerk:
    cd "{{ justfile_directory() }}" && buck2 build '//base/contract:check' '//base/mint:check' '//base/policies:check' '//base/private:check' '//base/util:check' '//base/bench:check' '//base/calc:check' '//base/security:check'

pour:
    @dagger call pour

forge:
    @dagger call forge

audit:
    @dagger call audit

think:
    @dagger call think

perform:
    @dagger call perform

prepare project:
    @dagger call prepare --project "{{project}}"

cook project:
    @dagger call cook --project "{{project}}"

serve project:
    @dagger call serve --project "{{project}}"
