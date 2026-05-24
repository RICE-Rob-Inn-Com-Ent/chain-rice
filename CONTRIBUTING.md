# Contributing to .rice SDK

Welcome to the pit stop. If you want to push code to .rice, you need to follow
the High-Performance Protocol. No bloat, no legacy, just pure logic.

## The Toolbox (Zero-Config)

We don't do manual installs for core roles. We use Pixi (conda-forge); **TS/JS-only conda tools** (`biome`, `lightningcss`) stay out of root `pixi.toml` — install those per frontend project.

After clone (or when CUE / MASON inputs change):

- `pixi install`
- `direnv allow` (loads generated `.envrc` that walks **git-tracked** `*.env*` paths — never commit secrets)
- `git ls-files | grep -E '\.env($|\.)' || true` — preview env-like paths tracked by git
- **MASON pipeline:** `dagger -m . -c 'rice | pour'` (implementation: [`service/ci/src/pour.go`](service/ci/src/pour.go))
- **Ad-hoc CUE emit:** `cue cmd emit ./infra/out/_tool.cue`
- **Workspace CUE embed:** `buck2 build //infra/out:gen_workspace_cue`

## The Polyglot Manifesto (How we code)

In .rice, we use the right tool for the job. Here’s the "logic-gate" for our 8 languages:

- **Rust** – Core logic & safety. If it's critical, it's Rust. Use cargo fmt.

- **Zig** – Hardcore memory management & low-level wizardry. No hidden
  control flow.

- **Mojo** – AI infrastructure. Performance of C, flexibility of Python.

- **Go** – Networking & Cloud (Traefik/Gateway). Keep it simple, keep it fast.

- **TypeScript** – Frontend interfaces (Muse/Bard). Strict types only.

- **Python** – Glue code & ML high-level scripts. Use it sparingly.

- **CUE** – Configuration & Infrastructure. If it's a config, it must be
  validated.

## The "Near-Metal" Workflow

- **Sync** – `git pull origin main` + `pixi update`.
- **Branch** – `git checkout -b feat/your-innovation`.
- **Hack** – Use Cursor with our .cursor/ rules. Let the AI help you optimize.
- **Verify** – `just test` (triggers Dagger to test across all 8 languages).
- **Commit** – We use Conventional Commits (e.g. feat(zig): optimize memory
  allocator).

## Building & Shipping

Everything is orchestrated by Dagger. We don't care about "it works on my
machine".

## Standards (The .rice Way)

- **Zero Bloat** – If you can do it without a new dependency, do it.
- **Emotes in Code** – Use them in comments to explain the vibe of the logic.
- **Documentation** – Update docs/ARCHITECTURE.md if you change the "wiring"
  between languages.

## Final Rule: Exit 0

If the CI isn't green, the code is broken. No exceptions. We ship only
Maximum Performance.

Ready to race? Open a PR and let's build the future.






