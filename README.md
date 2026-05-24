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

### MASON

- **Polyglot package** (`infra/package/`): [`polyglot.cue`](infra/package/polyglot.cue) + language-only [`infra/package/cue/*.cue`](infra/package/cue/). `cue export` uses `merge_build.cue` (copy of [`infra/build/_tool.cue`](infra/build/_tool.cue)); **`emitTextFiles`** covers `.buckconfig`, cell `BUCK`, and cell manifests. Workspace roll-up lives in [`infra/out/cue/pack.cue`](infra/out/cue/pack.cue) (`emitTextFiles` + `pathPack`). Workflow entrypoints: [`infra/out/_tool.cue`](infra/out/_tool.cue), [`infra/k8s/_tool.cue`](infra/k8s/_tool.cue), [`infra/terraform/_tool.cue`](infra/terraform/_tool.cue), [`infra/_tool.cue`](infra/_tool.cue).
- **Workspace root** (`infra/out/cue/`): category slices (`vcs.cue`, `env.cue`, `docs.cue` → [`infra/docs/cue/docs.cue`](infra/docs/cue/docs.cue), `ws.cue`, …) — repo-root files at emit time. See [`infra/out/README.md`](infra/out/README.md).
- **Render everything**: `pixi run mason-render` (runs `cue cmd emit ./infra/out/_tool.cue`; same as `buck2 build //infra/package:render_all` or `//infra/out:render_workspace`). Regenerate embedded workspace CUE: `pixi run mason-gen-workspace-cue` (same as `buck2 build //infra/out:gen_workspace_cue`).
- **Refresh CUE snapshots after editing root files**: `pixi run mason-gen-workspace-cue`.
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






