# CLERK tooling (`base/`)

## Buck2 (per-crate only)

There is **no** `base/BUCK` and **no** `buck-scripts/`. Each module has exactly one file: `base/<module>/BUCK` with a `genrule` named **`check`** (inline shell only).

Install `buck2` (e.g. `pixi run install-buck2` at repo root). From the **monorepo root**:

```bash
buck2 build //base/contract:check
just base-buck-clerk   # all `base/*:check` targets, including security
```

The root `.buckconfig` uses the **bundled prelude** and [`toolchains/BUCK`](../toolchains/BUCK). Genrules set `CARGO_TARGET_DIR` and Zig cache/artifact dirs under `buck-out/clerk-artifacts/`.

## Zig and ZLS

- **Pixi:** `pixi install` — `zig` / `zls` for CLERK are in `pixi.toml`.
- **Arch:** `sudo pacman -S zig` (and `zls` if packaged). Match `build.zig.zon` / pixi pin.
- **Editor:** `base/.vscode/settings.json` — `zig.path` / `zig.zls.path`.

`//base/security:check` owns Zig quality gates and static library build (`libclerk-security.a`). `bench` no longer invokes Zig.

## Haskell (CALC) and HLS

- **Pixi:** `ghc`, `haskell-language-server`, `cabal` from `pixi.toml`.
- **GHCup:** [haskell.org/ghcup](https://www.haskell.org/ghcup/) then `ghcup install hls`.

`//base/calc:check` runs `cabal build foreign-library:rice_calc_ffi` when `cabal` exists; otherwise it skips.

## `base/.env`

Optional keys for runtime and tests under `base/` — see comments in [`.env`](.env). Buck `genrule` targets do not require a filled `.env`.
