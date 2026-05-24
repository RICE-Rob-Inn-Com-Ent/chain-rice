# Contributing to .rice SDK

Welcome to the pit stop. If you want to push code to .rice, you need to follow
the High-Performance Protocol. No bloat, no legacy, just pure logic.

## The Toolbox (Zero-Config)

We don't do manual installs. We use Pixi.

After clone (or when CUE / MASON inputs change):

- `pixi install`
- `direnv allow` (loads generated `.envrc` that walks **git-tracked** `*.env*` paths — never commit secrets)
- `pixi run mason-env-list` — preview which env-like paths `git ls-files` would match
- `pixi run mason-render` — materialize package + workspace `emitTextFiles` via `cue cmd emit ./infra/out/_tool.cue` ([`infra/package/polyglot.cue`](infra/package/polyglot.cue) + [`infra/out/cue/pack.cue`](infra/out/cue/pack.cue) and other slices under [`infra/out/cue/`](infra/out/cue/))
- `pixi run mason-gen-workspace-cue` — re-embed tracked root files into `infra/out/cue/*.cue` and [`infra/docs/cue/docs.cue`](infra/docs/cue/docs.cue) via `buck2 build //infra/out:gen_workspace_cue` (script is `_EMBED_B64` in [`infra/out/BUCK`](infra/out/BUCK))

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






