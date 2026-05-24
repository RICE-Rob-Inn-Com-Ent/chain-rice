# `service/ci` — Dagger module (SMITH)

Go package for the Dagger module in [`dagger.json`](../../dagger.json) (`"source": "service/ci"`).

## Commands (monorepo root)

```bash
./rice pipeline              # pour → perform → forge → think → prepare → cook → audit → serve
./rice pour
./rice perform
./rice forge
./rice think
./rice audit
./rice prepare code-rice.com
./rice cook code-rice.com
./rice serve code-rice.com
```

Equivalent: `dagger call <function> [--project …]`.

Host `pixi install` before the first run speeds container bootstrap (Dagger layer cache).

### Dagger engine DNS

If module load fails with `lookup proxy.golang.org on 10.87.0.1:53: i/o timeout`, the
auto-provisioned engine cannot resolve external hosts. Fix:

```bash
mkdir -p ~/.config/dagger
cat > ~/.config/dagger/engine.toml <<'EOF'
[dns]
nameservers = ["<host-resolver>", "8.8.8.8", "1.1.1.1"]
EOF
docker rm -f "$(docker ps -q --filter 'name=dagger-engine-')"
dagger functions   # recreates engine with new DNS
```

Use your host resolver (see `/etc/resolv.conf`) as the first nameserver.

**Bootstrap order (no chicken-and-egg):**

1. `rice perform` — **Odin only** (`withOdin`): `atlas.sys` + sync `pixi.toml` (no `pour.ok`, no pixi).
2. `rice pour` — Odin body → `pixi install` → `cue emit` → body again (CUE must not leave wrong `platforms`).
3. `direnv` — loads `pixi shell-hook` only when `.pixi/envs/default` already exists (after pour).

**BARD body:** `frontend/inventory/body_main.odin` — hardware scan in Odin, not shell.

## Environment

| Variable | Effect |
| --- | --- |
| `RICE_CHIEF_PROJECTS` | Space-separated slugs for `pipeline` (default: `code-rice.com egos.app`) |
| `RICE_AUDIT_GATE` | `commit` (default), `release`, `deploy`, `all`, `skip` |
| `RICE_SERVE_MODE` | `local` or `cloud` override for serve |
