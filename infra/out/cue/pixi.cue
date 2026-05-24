package workspace

// cue cmd embed — pixi.toml
emitFiles_pixi: [
		{
			path:    "pixi.toml"
			content: #"""
[project]
name = "rice SDK"
version = "0.1.0"
description = ".rice SDK — sovereign programming language and enterprise operating system"
# channels / platforms — BARD body (odin body_main) syncs from atlas.sys hardware.
channels = ["conda-forge"]
platforms = ["linux-64"]

# ============================================================
# 🫅 KING — ROOT
# ============================================================
[dependencies]
just = "1.42.*"          # task runner — all rice commands
direnv = "2.37.*"      # auto-loads .envrc on cd (match conda-forge; was 3.1 — unsatisfiable)
go-sops = "3.9.*"      # encrypted secrets (conda-forge: go-sops; binary is `sops`)
age = "1.2.*"            # encryption backend for sops
git-cliff = "2.4.*"      # changelog generation
lefthook = "1.10.*"      # git hooks
convco = "0.6.*"         # conventional commits
reuse = "6.*"          # license compliance
# trufflehog — conda build pins py<3.11; conflicts with python 3.13; use binary release in CI
vhs = "0.7.*"            # terminal recordings for docs
ttyd = "1.7.*"           # terminal sharing
jq = "1.7.*"             # JSON processor
go-yq = "4.44.*"       # YAML processor
watchexec = "2.1.*"      # file watcher
lychee = "0.15.*"        # broken link checker
cosign = "3.*"         # container signing
trivy = "0.58.*"         # CVE scanner — containers + code
curl = "8.0.*"           # HTTP client

# ============================================================
# 🫅 KING — additional root tooling
#
# TODO:
# [ ] add syft — SBOM generation for 🚚 bundle before registry push
#     syft = "*"
# [ ] add grype — CVE scan of SBOM (complement to trivy)
#     grype = "*"
# [ ] add osquery — host integrity queries (rice audit → _audit-security)
#     osquery = "*"
# [ ] add nuclei — HTTP vulnerability scanner (rice audit → _audit-penetration)
#     nuclei = "*"
# [ ] add suricata — IDS rules engine (rice audit → _audit-penetration)
#     suricata = "*" (linux-64 only)
# [ ] add nmap — port scanner (rice audit → _audit-penetration)
#     nmap = "*"
# [ ] add dagger — already in dagger.json but expose as pixi task too
#     dagger = "0.13.*"
# ============================================================

[target.linux-64.dependencies]
inotify-tools = "3.20.*" # Linux file events (conda-forge; no 4.x)
docker-cli = "*"           # container CLI (package `docker` not on conda-forge)

# ============================================================
# 👷 MASON — infra/
# ============================================================
cue = "0.16.*"         # CUE CLI (conda 0.9.x package is cuepls/LSP, not `cue cmd`)
buf = "1.*"            # Protobuf linting and code generation
# timoni / dagger — not on conda-forge; `pixi run install-timoni`, host Dagger for CI
opentofu = "*"         # infrastructure as code
kubernetes-client = "1.24.*" # kubectl + k8s client libs (not `kubectl` package)
k9s = "*"           # Kubernetes TUI
awscli = "2.22.*"        # AWS cloud provider
google-cloud-sdk = "*" # GCP cloud provider
# azure-cli — conda solve conflict (azure-batch); use pip/host install for Azure work
mkdocs = "1.6.*"         # documentation site generator
mkdocs-material = "9.5.*" # MkDocs theme
vale = "3.4.*"           # prose linter for Markdown
markdownlint-cli2 = "0.13.*" # Markdown linter
openjdk = "21.*"            # JRE for openapi-generator-cli (PyPI) # OpenAPI client/server generation
checkov = "3.2.*"        # infrastructure security scanner

# ============================================================
# 🧑‍🏭 SMITH — service/
# ============================================================
go = "1.23.*"            # Go runtime
# golangci-lint — pixi run install-golangci-lint (go install)
gofumpt = "0.7.*"        # Go formatter (stricter gofmt)
# govulncheck / sqlc / atlas — `pixi run install-govulncheck` etc. (go install)
# air — not satisfiable on conda-forge linux-64
# TODO:
# [ ] add sqlc — Go type-safe SQL codegen via install-sqlc task
# [ ] add migrate — lightweight DB migration runner (complements Atlas)
#     golang-migrate = "*"
# [ ] add suricata rules via pixi task (linux-64 target only)
elixir = "1.18.*"        # Elixir runtime
erlang = "27.*"          # OTP runtime
# lexical — not on conda-forge; install via mix/hex when needed

# ============================================================
# 👨‍💼 CLERK — base/
# ============================================================
rust = "1.84.*"          # Rust toolchain (cargo/clippy/rustfmt via rustup components in env)
rust-analyzer = "*" # Rust LSP
# bacon / cargo-* — install via `cargo install` when needed (conda names/versions flaky)
ghc = "*"           # Haskell compiler — PATH via pixi; IDE: rice.code-workspace
stack = "*"         # Haskell build tool
# haskell-language-server / fourmolu / hlint / stan — use ghcup/stack outside pixi on linux-64
zig = "0.15.2"         # Zig compiler (align with build.zig / ZLS)
# zls — not on conda-forge at 0.15.2; install from zigtools or build.zig

# ============================================================
# 🧑‍🔬 SAGE — function/
# ============================================================
python = "3.13.*"        # Python runtime
# mojo / max — body-odin adds when atlas.sys modular_stack=true (NVML/GPU)
uv = "0.5.*"             # Python package manager
ruff = "0.8.*"           # Python linter + formatter
bandit = "1.8.*"         # Python SAST
pytest = "8.*"           # Python test runner
# TODO:
# [ ] add pip-audit — Python dependency CVE scan (rice audit → _audit-security)
#     pip-audit = "*"
# [ ] verify MAX Engine (max, mojo) listed here — NOT in pyproject.toml
#     max and mojo belong in pixi.toml under [dependencies] with modular-channels
#     they must NOT appear in function/pyproject.toml

# ============================================================
# 🧑‍🎤 BARD — frontend/
# ============================================================
# bun / fvm / ols / biome / tailwindcss / lightningcss / axe-core-cli — host/npm installs
ffmpeg = "*"         # video/audio processing (conda-forge)

# PyPI-only (no conda-forge on linux-64)
[pypi-dependencies]
# semgrep — PyPI/conda urllib3 pin conflict in unified env; run via `pipx run semgrep` or CI image
openapi-generator-cli = ">=7.8"

[tasks]
install-timoni = "go install github.com/stefanprodan/timoni/cmd/timoni@latest"
install-sqlc = "go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest"
install-atlas = "go install ariga.io/atlas/cmd/atlas@latest"
install-govulncheck = "go install golang.org/x/vuln/cmd/govulncheck@latest"
install-golangci-lint = "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
install-air = "go install github.com/air-verse/air@latest"
body = "cd frontend/inventory && odin run body_main.odin -file"
install-buck2 = "curl --proto '=https' --tlsv1.2 -sSf https://github.com/facebook/buck2/releases/latest/download/buck2-x86_64-unknown-linux-musl.zst | zstd -d > ~/.local/bin/buck2 && chmod +x ~/.local/bin/buck2"
install-odin = "git clone https://github.com/odin-lang/Odin && cd Odin && make"
test-mojo = "mojo package function/job/src/mojo -o function/job/src/mojo/__mojocache__/sage.mojopkg"
mason-render = "cue cmd emit ./infra/out/_tool.cue"
mason-env-list = "git ls-files | grep -E '\\.env($|\\.)' || true"
mason-gen-workspace-cue = "buck2 build //infra/out:gen_workspace_cue"
# TODO:
# [ ] add task: install-cosign — cosign for signing 🚚 bundle
# [ ] add task: install-syft — SBOM generator
# [ ] add task: setup-age — generate age keypair to ~/.config/sops/age/keys.txt
#     prompts for dev vs ci key, writes public key placeholder back to .sops.yaml
# [ ] add task: rice-geo-audit — GEO audit across SMITH + BARD
#     runs content freshness check, structured-data validation, crawlability report
#     reads RICE_GEO_TARGETS from env — list of URLs to audit
#     outputs: infra/docs/geo-report.md


"""#
		}
]
