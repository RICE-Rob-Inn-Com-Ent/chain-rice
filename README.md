# 🍚 .rice SDK | The Sovereign Architecture

*Total Privacy. Absolute Performance. One Language. The World is Our Grain.*

---

## 👑 Quick Start

**Step 1 — Install pixi (one time, clean machine):**

```bash
# Linux / macOS
curl -fsSL https://pixi.sh/install.sh | sh && source ~/.bashrc

# Windows — WSL2 required
wsl --install
# then inside WSL2:
curl -fsSL https://pixi.sh/install.sh | sh && source ~/.bashrc
```

**Step 2 — Bootstrap the kingdom:**

```bash
git clone https://github.com/RICE-Rob-Inn-Com-Ent/rice.git
cd rice
pixi install
direnv allow
rice pour       # foundation — configs, contracts, dependencies
rice perform    # scan hardware — GPU, audio, displays, drivers
rice forge      # start Docker services — aware of your hardware
rice think      # load AI models — matched to your hardware
rice audit      # verify everything — security, CVEs, full check
```

**Local pixi:** Root [`pixi.toml`](pixi.toml) is the **default monorepo toolchain** (KING/MASON/SMITH/CLERK/SAGE/BARD via conda-forge). **TS/JS-only conda packages** (`biome`, `lightningcss`) are omitted — use project-local `bun`/`npm`. **SBOM:** `syft` and `grype` are conda deps; tools without conda pins use **`pixi run install-*`** (see `[tasks]`). Locks **`linux-64` only**; run `pixi lock` after edits.

**`rice cook <project>`:** Needs [**Dagger**](https://docs.dagger.io/) — `dagger -m . -c 'rice | cook --project …'` → [`service/ci/src/cook.go`](service/ci/src/cook.go).

### MASON

- **Polyglot package** (`infra/package/`): [`polyglot.cue`](infra/package/polyglot.cue) + language-only [`infra/package/cue/*.cue`](infra/package/cue/). `languageBuck` is in `polyglot.cue` (`buildPlan` from [`infra/build/_tool.cue`](infra/build/_tool.cue)). `cue export` copies `infra/{build,docker}/_tool.cue` to `merge_build.cue` / `merge_docker.cue` plus [`infra/docker/cue/*.cue`](infra/docker/cue/). Then `packageLanguages`, `packageIndex`, `renderPlan`, and **`emitTextFiles`** cover `.buckconfig`, `docker-compose.yml`, `.dockerignore`, cell `BUCK`, and cell manifests. Workspace roll-up lives in [`infra/out/cue/pack.cue`](infra/out/cue/pack.cue) (`emitTextFiles` + `pathPack`). Workflow entrypoints use `cue cmd` with an explicit tool path, for example [`infra/out/_tool.cue`](infra/out/_tool.cue) (next to [`infra/out/BUCK`](infra/out/BUCK)), plus [`infra/k8s/_tool.cue`](infra/k8s/_tool.cue), [`infra/terraform/_tool.cue`](infra/terraform/_tool.cue), [`infra/_tool.cue`](infra/_tool.cue).
- **Workspace root** (`infra/out/cue/`): category slices (`vcs.cue`, `env.cue`, `docs.cue` → [`infra/docs/cue/docs.cue`](infra/docs/cue/docs.cue), `ws.cue`, …) — repo-root files at emit time. See [`infra/out/README.md`](infra/out/README.md).
- **MASON emit / workspace CUE / mint overlay:** run **`dagger -m . -c 'rice | pour'`** — steps live in [`service/ci/src/pour.go`](service/ci/src/pour.go) (`mason-cue-emit`, `mason-gen-workspace-cue`, `mason-overlay-schema`, `mason-overlay-check`).
- **Render CUE only (local):** `cue cmd emit ./infra/out/_tool.cue` (same as former `pixi run mason-render`).
- **Refresh embedded workspace CUE:** `buck2 build //infra/out:gen_workspace_cue` (needs `buck2` on `PATH`).
- **Validate**: `buck2 build //infra/package:validate_package_cue`, `buck2 build //infra/out:validate_workspace_cue`.

---

## 🏰 The Seven Roles

### 🫅 KING

Read-only map of the entire kingdom. KING never writes — he orients, routes,
and guards. Root-facing configs are materialized by MASON from `infra/out/cue/`. Every question belongs to a role.

### 👷 MASON

Owns `infra/` — CUE templates that generate every config, Protobuf schemas that
define every inter-role contract, Markdown docs published to the world.
If it was generated — it came from MASON.

### 🧑‍🏭 SMITH

Owns `service/` — Go microservices and Elixir immune system.
If it runs — it runs here. If it crashes — Elixir catches it here.
Guard never goes down. Silence is not permitted.

### 👨‍💼 CLERK

Owns `base/` — Rust smart contracts, Haskell formal proofs, Zig near-metal defense,
and the `.rice` compiler. If it moves money — it is verified here.
If it threatens the system — it is neutralized here.

### 🧑‍🎤 BARD

Owns `frontend/` — TypeScript browser interfaces, Dart device shells,
Odin GPU/audio/video at bare-metal speed.
59 FPS is not 60 FPS. A bad UI is a broken promise.

**Pixi (BARD installs):** `pixi run install-flutter`, `pixi run install-odin` (need **`git`** on the host). SBOM: **`syft` / `grype`** are conda deps; **`dagger` CLI**: `pixi run install-dagger`. TS/JS conda tools stay out of root `pixi.toml` — use per-project `bun`/`npm` where needed.

### 🧑‍🔬 SAGE

Owns `function/` — Python AI pipelines, Mojo near-metal kernels,
quantum simulations, vector retrieval, multi-agent orchestration.
Every output is validated before it leaves.

### 👨‍🍳 CHIEF

Owns `custom/` — the `.rice` programming language itself.
You do not orchestrate roles manually — you express intent, the compiler delegates.
One `.rice` file. The kingdom assembles itself.

---

## Daily Workflow

```bash
rice prepare myapp  # create new project in custom/myapp/
rice cook myapp     # dev mode — hot reload
rice serve myapp    # production — audit + deploy
```






