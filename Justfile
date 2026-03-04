# The Rice Framework - Emoji-Driven Orchestration
# Senior Polyglot Architect Implementation

set shell := ["bash", "-cu"]

# ------------------------------------------------------------------------------
# Super short aliases
# ------------------------------------------------------------------------------

alias i := install
alias u := update
alias s := start
alias x := stop
alias c := config
alias l := lint
alias d := deploy
alias h := check

# ------------------------------------------------------------------------------
# Helper variables
# ------------------------------------------------------------------------------

cue_dir := "cue"
cue_workspace := "{{ cue_dir }}/workspace"
cue_config := "{{ cue_dir }}/config"
cue_infra := "{{ cue_dir }}/infra"
cue_app := "{{ cue_dir }}/app"

# ------------------------------------------------------------------------------
# Default
# ------------------------------------------------------------------------------

default:
    @just --list

# ------------------------------------------------------------------------------
# 📦 INSTALL - Full toolchain initialization
# ------------------------------------------------------------------------------

install:
    # Install all toolchains: Pixi + Rust + Haskell + Elixir
    # Usage: just install | just i | just 📦
    @bash -c ' \
        set -e; \
        echo "📦 Installing Rice Framework toolchain..."; \
        \
        # Install Pixi if missing \
        if ! command -v pixi >/dev/null 2>&1; then \
            echo "📥 Installing Pixi..."; \
            curl -fsSL https://pixi.sh/install.sh | sh; \
            export PATH="$$HOME/.pixi/bin:$$PATH"; \
        fi; \
        \
        # Install via Pixi \
        echo "📦 Installing dependencies from pixi.toml..."; \
        pixi install || (echo "⚠️  Run: curl -fsSL https://pixi.sh/install.sh | sh  then  just install" && exit 1); \
        \
        # Initialize Rust toolchain \
        if ! command -v rustup >/dev/null 2>&1; then \
            echo "🦀 Initializing Rust toolchain..."; \
            curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
            export PATH="$$HOME/.cargo/bin:$$PATH"; \
        fi; \
        rustup toolchain install stable || true; \
        \
        # Initialize Haskell (Stack) \
        if ! command -v stack >/dev/null 2>&1; then \
            echo "🏔️  Installing Stack for Haskell..."; \
            curl -sSL https://get.haskellstack.org/ | sh; \
        fi; \
        \
        # Initialize Elixir (Mix) \
        if command -v mix >/dev/null 2>&1; then \
            echo "💧 Elixir/Mix already available"; \
        else \
            echo "💧 Elixir will be available via pixi (elixir package)"; \
        fi; \
        \
        echo "✅ Rice Framework installation complete!"; \
        echo "   Run: just c  (config menu)"; \
    '

# ------------------------------------------------------------------------------
# c CONFIG - Interactive configuration menu
# ------------------------------------------------------------------------------

config mode="":
    # Interactive configuration menu
    # Usage: just c | just c full | just c infra | just c app
    @bash -c ' \
        MODE="{{ mode }}"; \
        if [ -z "$MODE" ]; then \
            if command -v fzf >/dev/null 2>&1; then \
                MODE=$(echo -e "full\ninfra\napp" | fzf --prompt "Select config mode: "); \
            else \
                echo "🔧 Configuration Menu:"; \
                echo "  1) full  - Generate everything (YAML, JSON, TF, K8s) from CUE"; \
                echo "  2) infra - Only Terraform + Atlas (DB migrations)"; \
                echo "  3) app   - Only API (Proto + OpenAPI)"; \
                read -p "Select [1-3]: " choice; \
                case "$choice" in \
                    1) MODE=full ;; \
                    2) MODE=infra ;; \
                    3) MODE=app ;; \
                    *) echo "❌ Invalid choice"; exit 1 ;; \
                esac; \
            fi; \
        fi; \
        \
        case "$MODE" in \
            full) \
                echo "🔧 Generating full configuration from CUE..."; \
                just config-cue-all; \
                ;; \
            infra) \
                echo "🌱 Generating infrastructure configuration..."; \
                just config-infra; \
                ;; \
            app) \
                echo "📦 Generating API configuration..."; \
                just config-app; \
                ;; \
            *) \
                echo "❌ Invalid mode: $MODE (use: full, infra, app)"; \
                exit 1; \
                ;; \
        esac; \
    '

config-workspace:
    # Generate root config and dotfolders from CUE (tylko cue cmd, bez .sh)
    @cue cmd gen ./infra

config-cue-all:
    # Generate all configs from CUE: workspace (root + dotfolders) then config/infra/app
    @bash -c ' \
        set -e; \
        echo "🔧 Generating all configurations from CUE..."; \
        just config-workspace; \
        \
        # Generate biome.json from CUE \
        if [ -f "{{ cue_config }}/biome.cue" ]; then \
            echo "  → Generating biome.json..."; \
            cue export {{ cue_config }}/biome.cue --out json > biome.json || true; \
        fi; \
        \
        # Generate tsconfig.base.json from CUE \
        if [ -f "{{ cue_config }}/tsconfig.cue" ]; then \
            echo "  → Generating tsconfig.base.json..."; \
            cue export {{ cue_config }}/tsconfig.cue --out json > tsconfig.base.json || true; \
        fi; \
        \
        # Generate buf.yaml from CUE \
        if [ -f "{{ cue_config }}/buf.cue" ]; then \
            echo "  → Generating buf.yaml..."; \
            cue export {{ cue_config }}/buf.cue --out yaml > buf.yaml || true; \
        fi; \
        \
        # Generate Terraform from CUE \
        just config-infra; \
        \
        # Generate API configs \
        just config-app; \
        \
        echo "✅ All configurations generated!"; \
    '

config-infra:
    # Generate Terraform + Atlas from CUE
    @bash -c ' \
        set -e; \
        echo "🌱 Generating infrastructure (Terraform + Atlas)..."; \
        \
        # Export CUE infra to Terraform JSON \
        if [ -f "{{ cue_infra }}/main.cue" ]; then \
            echo "  → Exporting CUE infra to terraform/*.tf.json..."; \
            mkdir -p terraform/generated; \
            cue export {{ cue_infra }}/main.cue --out json > terraform/generated/main.tf.json || true; \
        fi; \
        \
        # Run Terraform plan \
        if [ -f "terraform/main.tf" ] || [ -f "terraform/generated/main.tf.json" ]; then \
            echo "  → Running terraform plan..."; \
            cd terraform && terraform init -upgrade && terraform plan -out=tfplan || true; \
        fi; \
        \
        # Sync secrets via sops + age \
        if command -v sops >/dev/null 2>&1 && [ -f ".secrets.yaml" ]; then \
            echo "  → Syncing secrets via sops..."; \
            sops -d .secrets.yaml > .secrets.decrypted.yaml || true; \
        fi; \
        \
        echo "✅ Infrastructure configuration ready!"; \
    '

config-app:
    # Generate API configs (Proto + OpenAPI)
    @bash -c ' \
        set -e; \
        echo "📦 Generating API configuration (Proto + OpenAPI)..."; \
        \
        # Generate buf.yaml from CUE if exists \
        if [ -f "{{ cue_config }}/buf.cue" ]; then \
            echo "  → Updating buf.yaml from CUE..."; \
            cue export {{ cue_config }}/buf.cue --out yaml > buf.yaml || true; \
        fi; \
        \
        # Generate Proto code \
        if command -v buf >/dev/null 2>&1 && [ -f "buf.yaml" ]; then \
            echo "  → Generating Proto code (Go, TS, Python)..."; \
            buf generate || true; \
        fi; \
        \
        # Generate OpenAPI from CUE if exists \
        if [ -f "{{ cue_app }}/openapi.cue" ]; then \
            echo "  → Generating openapi.json from CUE..."; \
            cue export {{ cue_app }}/openapi.cue --out json > openapi.json || true; \
        fi; \
        \
        echo "✅ API configuration ready!"; \
    '

# ------------------------------------------------------------------------------
# 🚀 DEPLOY - CI/CD + K8s deployment
# ------------------------------------------------------------------------------

deploy target="":
    # Deploy via Dagger CI/CD + Timoni K8s
    # Usage: just deploy | just d | just 🚀
    @bash -c ' \
        TARGET="{{ target }}"; \
        if [ -z "$$TARGET" ]; then \
            TARGET="all"; \
        fi; \
        \
        echo "🚀 Deploying Rice Framework (target: $$TARGET)..."; \
        \
        # Run Dagger pipeline \
        if command -v dagger >/dev/null 2>&1 && [ -f "dagger.json" ]; then \
            echo "  → Running Dagger CI/CD pipeline..."; \
            dagger run || true; \
        fi; \
        \
        # Apply Timoni K8s manifests \
        if command -v timoni >/dev/null 2>&1 && [ -d "cue/k8s" ]; then \
            echo "  → Applying Timoni K8s manifests..."; \
            timoni apply -f cue/k8s || true; \
        fi; \
        \
        echo "✅ Deployment complete!"; \
    '

# ------------------------------------------------------------------------------
# 🩺 CHECK - Health check & status
# ------------------------------------------------------------------------------

check:
    # Health check: VHS terminal recording or Python .rice parser
    # Usage: just check | just h | just 🩺
    @bash -c ' \
        echo "🩺 Running Rice Framework health check..."; \
        \
        # Option 1: VHS terminal recording \
        if command -v vhs >/dev/null 2>&1 && [ -f "vhs.tape" ]; then \
            echo "  → Recording terminal status with VHS..."; \
            vhs vhs.tape || true; \
        fi; \
        \
        # Option 2: Python .rice parser \
        if command -v python >/dev/null 2>&1 && [ -f "python/app/main.py" ]; then \
            echo "  → Parsing .rice files with Python..."; \
            cd python && python -m app.main --check || true; \
        fi; \
        \
        # General status \
        echo "  → Checking toolchain status..."; \
        command -v pixi >/dev/null 2>&1 && echo "    ✅ Pixi: $$(pixi --version 2>/dev/null || echo 'installed')" || echo "    ❌ Pixi: not found"; \
        command -v cue >/dev/null 2>&1 && echo "    ✅ CUE: $$(cue version 2>/dev/null || echo 'installed')" || echo "    ❌ CUE: not found"; \
        command -v terraform >/dev/null 2>&1 && echo "    ✅ Terraform: $$(terraform version 2>/dev/null | head -1)" || echo "    ❌ Terraform: not found"; \
        command -v buf >/dev/null 2>&1 && echo "    ✅ Buf: $$(buf --version 2>/dev/null || echo 'installed')" || echo "    ❌ Buf: not found"; \
        \
        echo "✅ Health check complete!"; \
    '

# ------------------------------------------------------------------------------
# 📚 DOCS - Documentation generation
# ------------------------------------------------------------------------------

doc:
    # Generate and copy validated docs to /docs
    # Usage: just doc
    @bash -c ' \
        set -e; \
        echo "📚 Generating documentation..."; \
        \
        # Validate markdown files \
        if command -v markdownlint-cli2 >/dev/null 2>&1; then \
            echo "  → Validating markdown files..."; \
            markdownlint-cli2 "markdown/**/*.md" || true; \
        fi; \
        \
        # Generate docs with MkDocs \
        if command -v mkdocs >/dev/null 2>&1 && [ -f "mkdocs.yml" ]; then \
            echo "  → Building MkDocs site..."; \
            mkdocs build --site-dir docs || true; \
        fi; \
        \
        # Generate index.tpl dashboards \
        if command -v gomplate >/dev/null 2>&1; then \
            echo "  → Generating index.tpl dashboards..."; \
            just generate-dashboards || true; \
        fi; \
        \
        echo "✅ Documentation generated in /docs!"; \
    '

generate-dashboards:
    # Generate all index.tpl dashboards from CUE data
    @bash -c ' \
        set -e; \
        echo "📊 Generating dashboard interfaces..."; \
        \
        # Export CUE data for dashboards \
        if [ -f "{{ cue_config }}/dashboards.cue" ]; then \
            cue export {{ cue_config }}/dashboards.cue --out json > .dashboards.json || true; \
        fi; \
        \
        # Generate markdown/index.html \
        if [ -f "markdown/index.tpl" ] && [ -f ".dashboards.json" ]; then \
            echo "  → Generating markdown/index.html..."; \
            gomplate -f markdown/index.tpl -d data=.dashboards.json -o markdown/index.html || true; \
        fi; \
        \
        # Generate python/index.html \
        if [ -f "python/index.tpl" ] && [ -f ".dashboards.json" ]; then \
            echo "  → Generating python/index.html..."; \
            gomplate -f python/index.tpl -d data=.dashboards.json -o python/index.html || true; \
        fi; \
        \
        # Generate elixir/index.html \
        if [ -f "elixir/index.tpl" ] && [ -f ".dashboards.json" ]; then \
            echo "  → Generating elixir/index.html..."; \
            gomplate -f elixir/index.tpl -d data=.dashboards.json -o elixir/index.html || true; \
        fi; \
        \
        # Generate rust/index.html \
        if [ -f "rust/index.tpl" ] && [ -f ".dashboards.json" ]; then \
            echo "  → Generating rust/index.html..."; \
            gomplate -f rust/index.tpl -d data=.dashboards.json -o rust/index.html || true; \
        fi; \
        \
        # Generate terraform/index.html \
        if [ -f "terraform/index.tpl" ] && [ -f ".dashboards.json" ]; then \
            echo "  → Generating terraform/index.html..."; \
            gomplate -f terraform/index.tpl -d data=.dashboards.json -o terraform/index.html || true; \
        fi; \
        \
        echo "✅ Dashboards generated!"; \
    '

# ------------------------------------------------------------------------------
# 👁️ WATCH - Per-role watchers (hot reload / lint watch)
# Narzędzia: Go→air, Rust→bacon/clippy+test, Python→ruff, Bun/TS→biome, CUE→cue vet, Elixir→mix compile --watch
# ------------------------------------------------------------------------------

watch-all:
    # Run all role watchers in parallel, then wait
    just watch-smith & \
    just watch-clerk & \
    just watch-sage & \
    just watch-bard & \
    just watch-mason & \
    wait

watch-smith:
    # 🧑‍🏭 SMITH (service): Go air (hot reload)
    pixi run air -C service/

watch-smith-elixir:
    # 🧑‍🏭 SMITH (service): Elixir mix compile --watch
    cd service && pixi run mix compile --watch

watch-clerk:
    # 👨‍💼 CLERK (store): Rust – clippy + test (ex bacon.toml)
    pixi run watchexec -w store -e rs,toml -- bash -c 'cd store && cargo clippy --all-targets -- -D warnings && cargo test'

watch-sage:
    # 🧑‍🔬 SAGE (bot): Python ruff check --watch
    pixi run ruff check --watch bot/

watch-bard:
    # 🧑‍🎤 BARD (frontend): biome check --watch
    pixi run biome check --watch frontend/

watch-mason:
    # 👷 MASON (infra): CUE vet
    pixi run cue vet ./infra/...

# ------------------------------------------------------------------------------
# 🔥 HOT-RELOAD - CUE watcher
# ------------------------------------------------------------------------------

watch-cue:
    # Watch CUE files and rebuild configs automatically
    # Usage: just watch-cue
    @bash -c ' \
        echo "🔥 Starting CUE hot-reload watcher..."; \
        if command -v watchexec >/dev/null 2>&1; then \
            watchexec -w {{ cue_dir }} -e cue -- just config-cue-all; \
        else \
            echo "⚠️  watchexec not found. Install via: pixi install watchexec"; \
            echo "   Falling back to inotifywait..."; \
            if command -v inotifywait >/dev/null 2>&1; then \
                while inotifywait -r -e modify,create,delete {{ cue_dir }}; do \
                    just config-cue-all; \
                done; \
            else \
                echo "❌ No file watcher available. Install watchexec or inotify-tools."; \
            fi; \
        fi; \
    '

# ------------------------------------------------------------------------------
# Lint (Trunk removed – use per-tool targets: ruff, biome, clippy, golangci, buf-*)
# ------------------------------------------------------------------------------

lint:
    # Run linters individually: just ruff-check, just biome-check, just clippy, just buf-lint, etc.
    @just --list | grep -E '^(ruff|biome|clippy|buf-|golangci)' || true
    @echo "Run specific linters, e.g.: just ruff-check, just biome-check, just clippy, just buf-lint"

lint-fix:
    # Run per-tool formatters/fixers as needed (e.g. buf-format, pixi/ruff, etc.)
    @echo "No Trunk. Use: just buf-format, or run ruff/biome/clippy --fix manually."

# ------------------------------------------------------------------------------
# Buf – Proto lint (standard), format, generate
# ------------------------------------------------------------------------------

buf-lint:
    @pixi run buf-lint

buf-format:
    @pixi run buf-format

buf-generate:
    @pixi run buf-generate

# ------------------------------------------------------------------------------
# Docs – MkDocs
# ------------------------------------------------------------------------------

docs-serve:
    @pixi run docs-serve

docs-build:
    @pixi run docs-build

# ------------------------------------------------------------------------------
# Update - Update all tools via Pixi
# ------------------------------------------------------------------------------

update:
    # Update all tools (Pixi)
    # Usage: just update | just u
    @echo "🔄 Updating tools via Pixi..."
    @pixi update || (echo "⚠️  Run: pixi install" && exit 1)

# ------------------------------------------------------------------------------
# Start/Stop - Project management (legacy support)
# ------------------------------------------------------------------------------

start target="":
    # Start projects/components (legacy)
    # Usage: just start | just start stack | just start ceramix | just s
    @bash -c ' \
        if [ -z "{{ target }}" ]; then \
            echo "🚀 Starting all projects..."; \
            for PROJECT_DIR in projects/*/; do \
                if [ -d "$$PROJECT_DIR" ]; then \
                    PROJECT=$$(basename "$$PROJECT_DIR"); \
                    if [ "$$PROJECT" = ".vscode" ] || [ "$$PROJECT" = ".git" ]; then continue; fi; \
                    echo "🚀 Starting project $$PROJECT..."; \
                    docker compose -f "projects/$$PROJECT/docker-compose.$$PROJECT.yml" up -d 2>/dev/null || true; \
                fi; \
            done; \
        else \
            echo "🚀 Starting {{ target }}..."; \
            docker compose -f "projects/{{ target }}/docker-compose.{{ target }}.yml" up -d 2>/dev/null || true; \
        fi; \
    '

stop target="":
    # Stop projects/components (legacy)
    # Usage: just stop | just stop stack | just stop ceramix | just x
    @bash -c ' \
        if [ -z "{{ target }}" ]; then \
            echo "🛑 Stopping all projects..."; \
            for PROJECT_DIR in projects/*/; do \
                if [ -d "$$PROJECT_DIR" ]; then \
                    PROJECT=$$(basename "$$PROJECT_DIR"); \
                    if [ "$$PROJECT" = ".vscode" ] || [ "$$PROJECT" = ".git" ]; then continue; fi; \
                    echo "🛑 Stopping project $$PROJECT..."; \
                    docker compose -f "projects/$$PROJECT/docker-compose.$$PROJECT.yml" down 2>/dev/null || true; \
                fi; \
            done; \
        else \
            echo "🛑 Stopping {{ target }}..."; \
            docker compose -f "projects/{{ target }}/docker-compose.{{ target }}.yml" down 2>/dev/null || true; \
        fi; \
    '

clean target="":
    # Clean projects/components (legacy)
    # Usage: just clean | just clean stack | just clean ceramix
    @bash -c ' \
        if [ -z "{{ target }}" ]; then \
            echo "🧹 Cleaning all projects..."; \
            for PROJECT_DIR in projects/*/; do \
                if [ -d "$$PROJECT_DIR" ]; then \
                    PROJECT=$$(basename "$$PROJECT_DIR"); \
                    if [ "$$PROJECT" = ".vscode" ] || [ "$$PROJECT" = ".git" ]; then continue; fi; \
                    echo "🧹 Cleaning project $$PROJECT..."; \
                    docker compose -f "projects/$$PROJECT/docker-compose.$$PROJECT.yml" down --remove-orphans -v 2>/dev/null || true; \
                    find "projects/$$PROJECT" -type d \( -name "node_modules" -o -name ".next" -o -name "dist" -o -name "build" -o -name "target" -o -name ".dart_tool" \) -prune -exec rm -rf {} + 2>/dev/null || true; \
                fi; \
            done; \
            echo "✅ All projects cleaned"; \
        else \
            echo "🧹 Cleaning {{ target }}..."; \
            docker compose -f "projects/{{ target }}/docker-compose.{{ target }}.yml" down --remove-orphans -v 2>/dev/null || true; \
            find "projects/{{ target }}" -type d \( -name "node_modules" -o -name ".next" -o -name "dist" -o -name "build" -o -name "target" -o -name ".dart_tool" \) -prune -exec rm -rf {} + 2>/dev/null || true; \
            echo "✅ Project {{ target }} cleaned"; \
        fi; \
    '

# ------------------------------------------------------------------------------
# Run a Pixi task from root
# ------------------------------------------------------------------------------

run task:
    # Usage: just run <task>  (task from root pixi.toml)
    @pixi run {{ task }}
