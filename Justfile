# .rice OS — task runner
# rice <command> → .bin/rice <command> → just <command>
# Usage: rice <command> [args]

KING_MODEL  := "rice-king"     # Qwen3-8B              r=64  α=128
MASON_MODEL := "rice-mason"    # Qwen2.5-Coder-7B      r=64  α=128
SMITH_MODEL := "rice-smith"    # Qwen2.5-Coder-7B      r=32  α=64
CLERK_MODEL := "rice-clerk"    # Qwen2.5-Coder-7B      r=128 α=256
SAGE_MODEL  := "rice-sage"     # Qwen2.5-Coder-7B      r=64  α=128
CHIEF_MODEL := "rice-chief"    # Qwen2.5-Coder-7B      r=128 α=256
BARD_MODEL  := "rice-bard"     # Qwen2.5-VL-7B         r=64  α=128

BACKEND  := env_var_or_default("RICE_BACKEND", "ollama")
VLLM_URL := env_var_or_default("RICE_VLLM_URL", "http://localhost:8000")
RICE_AI := env_var_or_default("RICE_AI", "cursor")

RULES_DIR := if RICE_AI == "cursor"      { ".cursor/rules" }
        else if RICE_AI == "windsurf"    { ".windsurf/rules" }
        else if RICE_AI == "claude"      { ".claude/rules" }
        else if RICE_AI == "copilot"     { ".github/instructions" }
        else                             { ".cursor/rules" }

KING_READS := "--read " + RULES_DIR + "/KING.mdc"   + \
             " --read " + RULES_DIR + "/MASON.mdc"  + \
             " --read " + RULES_DIR + "/SMITH.mdc"  + \
             " --read " + RULES_DIR + "/CLERK.mdc"  + \
             " --read " + RULES_DIR + "/BARD.mdc"   + \
             " --read " + RULES_DIR + "/SAGE.mdc"   + \
             " --read " + RULES_DIR + "/CHIEF.mdc"

# ============================================================
# 🫅 KING — rice bin (the 🚚 bundle)
# Buck2 collects the entire kingdom into a single deployable artifact.
# The 🚚 file IS the OS — one binary, every role, every runtime.
#
# TODO:
# [ ] write infra/platforms/BUILD — execution platform definition for Buck2
# [ ] write infra/toolchains/BUILD — toolchain declarations for all 7 roles
#     Go toolchain (go_toolchain), Rust toolchain (rust_toolchain),
#     Python toolchain (python_bootstrap_binary), Elixir (system_toolchain),
#     Haskell (haskell_toolchain), Zig (system_toolchain), Odin (system_toolchain)
# [ ] write base/mint/BUCK — rust_binary target for the .rice compiler
#     srcs = glob(["src/**/*.rs"]),
#     deps = [logos, chumsky, rowan, salsa, miette, minijinja, tower-lsp, petgraph]
#     visibility = ["PUBLIC"]
# [ ] write service/BUCK — go_binary targets: web, auth, token, database, queue, bench
#     go_binary per service, srcs + deps declared, no compilation inside Docker
# [ ] write service/BUCK — mix_binary targets: core, pipeline, cluster, guard, connection
#     elixir_library + elixir_release rules — releases bundled with OTP
# [ ] write frontend/BUCK — bun_bundle target for browser/
#     bun_run rule → produces dist/ artifact
# [ ] write frontend/BUCK — flutter_build target for screen/
#     flutter_binary → produces APK + web bundle + desktop binary
# [ ] write frontend/BUCK — odin_binary targets for vendor/ hardware daemon
#     odin_binary, srcs = vendor/**/*.odin, flags = ["-vet", "-strict-style"]
# [ ] write function/BUCK — python_binary target for SAGE FastAPI service
#     python_binary, main = function/main.py, deps = pyproject deps via pixi
# [ ] write function/BUCK — mojo_binary targets for kernel/ compute files
#     mojo_binary per kernel, max-engine linked
# [ ] write ROOT BUCK or BUILD_RICE — 🚚 bundle target
#     filegroup collecting all role binaries + config exports + model registry
#     output: buck-out/gen/rice/🚚 — the sovereign binary
#     cosign signs the bundle on `rice audit → deploy`
#     buck2 build //:rice produces the complete artifact
# ============================================================

rule role task="":
    @just _rule-{{role}} "{{task}}"

_model-load model:
    #!/usr/bin/env bash
    set -euo pipefail
    BACKEND="${RICE_BACKEND:-ollama}"
    MODEL="{{model}}"
    CURRENT=$(cat .rice-model 2>/dev/null || echo "none")

    if [ "$BACKEND" = "ollama" ]; then
        echo "🔄 swapping model: $CURRENT → $MODEL"
        [ "$CURRENT" != "none" ] && ollama stop "$CURRENT" 2>/dev/null || true
        ollama run "$MODEL" --keepalive 0 &
        # Czekaj na gotowość
        until ollama list | grep -q "$MODEL"; do sleep 1; done
        echo "$MODEL" > .rice-model
        echo "✅ $MODEL ready (Ollama)"

    elif [ "$BACKEND" = "vllm" ]; then
        echo "🔄 loading LoRA adapter: $MODEL"
        curl -sf -X POST "${RICE_VLLM_URL:-http://localhost:8000}/v1/load_lora_adapter" \
          -H "Content-Type: application/json" \
          -d "{\"lora_name\": \"$MODEL\", \"lora_path\": \"function/model/lora/$MODEL\"}" \
          || (echo "❌ vLLM not running — run rice think first" && exit 1)
        echo "$MODEL" > .rice-model
        echo "✅ $MODEL adapter loaded (vLLM)"
    fi

_king-model:
    #!/usr/bin/env bash
    BACKEND="${RICE_BACKEND:-ollama}"
    if [ "$BACKEND" = "ollama" ]; then
        echo "ollama/{{KING_MODEL}}"
    else
        echo "openai/{{KING_MODEL}}"
    fi

_editor-model model:
    #!/usr/bin/env bash
    BACKEND="${RICE_BACKEND:-ollama}"
    if [ "$BACKEND" = "ollama" ]; then
        echo "ollama/{{model}}"
    else
        echo "openai/{{model}}"
    fi

_rule-mason task="":
    @just _model-load "{{MASON_MODEL}}"
    aider \
      --architect \
      --model $(just _king-model) \
      --editor-model $(just _editor-model "{{MASON_MODEL}}") \
      {{KING_READS}} \
      infra/configs/ infra/schemas/ \
      --message "{{task}}"

_rule-smith task="":
    @just _model-load "{{SMITH_MODEL}}"
    aider \
      --architect \
      --model $(just _king-model) \
      --editor-model $(just _editor-model "{{SMITH_MODEL}}") \
      {{KING_READS}} \
      service/ \
      --message "{{task}}"

_rule-clerk task="":
    @just _model-load "{{CLERK_MODEL}}"
    aider \
      --architect \
      --model $(just _king-model) \
      --editor-model $(just _editor-model "{{CLERK_MODEL}}") \
      {{KING_READS}} \
      base/ \
      --message "{{task}}"

_rule-sage task="":
    @just _model-load "{{SAGE_MODEL}}"
    aider \
      --architect \
      --model $(just _king-model) \
      --editor-model $(just _editor-model "{{SAGE_MODEL}}") \
      {{KING_READS}} \
      function/ \
      --message "{{task}}"

_rule-chief task="":
    @just _model-load "{{CHIEF_MODEL}}"
    aider \
      --architect \
      --model $(just _king-model) \
      --editor-model $(just _editor-model "{{CHIEF_MODEL}}") \
      {{KING_READS}} \
      base/mint/ custom/ \
      --message "{{task}}"

_rule-bard task="":
    @just _model-load "{{BARD_MODEL}}"
    aider \
      --architect \
      --model $(just _king-model) \
      --editor-model $(just _editor-model "{{BARD_MODEL}}") \
      {{KING_READS}} \
      frontend/ \
      --message "{{task}}"

default:
    @just --list

# ============================================================
# 👷 MASON — rice pour
# Pours the kingdom foundation.
#
# TODO:
# [ ] write infra/configs/cursor.cue
# [ ] write infra/configs/windsurf.cue
# [ ] write infra/configs/vscode.cue
# [ ] write infra/configs/claude.cue
# [ ] write infra/configs/copilot.cue
# [ ] write infra/configs/cursor-ai.cue
# [ ] write infra/configs/windsurf-ai.cue
# [ ] write infra/configs/aws.cue
# [ ] write infra/configs/gcp.cue
# [ ] write infra/configs/azure.cue
# [ ] write infra/schemas/*.proto for all roles
# [ ] write infra/docs/ mkdocs content
# [ ] write infra/configs/envoy.cue — Envoy Gateway config (replaced Traefik)
#     listeners, routes, virtual hosts, rate limits, CORS, JWT filter — all templated
#     RICE_ENVOY_PORT, RICE_ENVOY_ADMIN_PORT read from env
# [ ] write infra/configs/victoriametrics.cue — VictoriaMetrics scrape config
#     scrape_interval, retention_period, storage_data_path all soft-coded
# [ ] write infra/configs/tempo.cue — Grafana Tempo config (replaced Jaeger)
#     ingestion: otlp_http + otlp_grpc, storage: s3 OR local depending on RICE_TRACE_BACKEND
# [ ] write infra/configs/grafana.cue — Grafana datasources + dashboard provisioning
#     datasources: VictoriaMetrics, Tempo, Qdrant — auto-provisioned
# [ ] add observability services to docker-compose.yml via CUE:
#     victoriametrics (port soft-coded), tempo (port soft-coded), grafana (port soft-coded)
#     all on `kingdom` network, all with healthchecks
# [ ] write infra/configs/envrc.cue — generate .envrc from CUE template
#     RICE_BACKEND, RICE_AI, RICE_RENDER, RICE_AUDIO, RICE_TRACE_BACKEND,
#     RICE_REGISTRY, RICE_K8S_CONTEXT — all with safe defaults
# ============================================================

pour:
    @echo "👷 pouring foundation..."
    pixi install
    @just _setup-ide
    @just _setup-ai
    @just _setup-cloud
    cue vet infra/configs/*.cue
    cue export infra/configs/*.cue
    buf generate
    cd service && go mod tidy
    cd service && mix deps.get
    cd base && cargo fetch
    cd base && hpack
    cd frontend/browser && bun install
    cd frontend/screen && flutter pub get
    cd function && uv sync
    mkdocs build
    @echo "✅ foundation ready"

_setup-ide:
    #!/usr/bin/env bash
    echo "Which IDE? (cursor/windsurf/vscode/all/skip)"
    read -r ide
    case $ide in
        cursor)   cue export infra/configs/cursor.cue ;;
        windsurf) cue export infra/configs/windsurf.cue ;;
        vscode)   cue export infra/configs/vscode.cue ;;
        all)      cue export infra/configs/cursor.cue
                  cue export infra/configs/windsurf.cue
                  cue export infra/configs/vscode.cue ;;
        skip)     echo "skipping IDE setup" ;;
    esac

_setup-ai:
    #!/usr/bin/env bash
    echo "Which AI agent? (claude/copilot/cursor-ai/windsurf-ai/all/skip)"
    read -r ai
    case $ai in
        claude)      cue export infra/configs/claude.cue ;;
        copilot)     cue export infra/configs/copilot.cue ;;
        cursor-ai)   cue export infra/configs/cursor-ai.cue ;;
        windsurf-ai) cue export infra/configs/windsurf-ai.cue ;;
        all)         cue export infra/configs/claude.cue
                     cue export infra/configs/copilot.cue
                     cue export infra/configs/cursor-ai.cue
                     cue export infra/configs/windsurf-ai.cue ;;
        skip)        echo "skipping AI setup" ;;
    esac

_setup-cloud:
    #!/usr/bin/env bash
    echo "Cloud provider? (aws/gcp/azure/all/skip)"
    read -r cloud
    case $cloud in
        aws)   cue export infra/configs/aws.cue ;;
        gcp)   cue export infra/configs/gcp.cue ;;
        azure) cue export infra/configs/azure.cue ;;
        all)   cue export infra/configs/aws.cue
               cue export infra/configs/gcp.cue
               cue export infra/configs/azure.cue ;;
        skip)  echo "skipping cloud setup" ;;
    esac

# ============================================================
# 🧑‍🎤 BARD — rice perform
# Performs the machine — scans hardware, installs drivers,
# selects rendering and audio profile, starts watcher daemon.
#
# TODO:
# [ ] implement _scan-hardware in Odin — frontend/vendor/
#     detect CPU model, cores, threads, clock, instruction sets
#     detect all GPUs + VRAM + Vulkan/CUDA/ROCm capability
#     detect all audio devices + sample rates + audio API
#     detect all displays + resolution + refresh + HDR + gamut
#     detect all cameras + resolution + frame rate + IR/depth
#     detect all network interfaces + speeds
#     detect all storage drives + speeds + available space
#     detect all USB/Bluetooth + game controllers + MIDI
#     write hardware profile to .rice-hardware.json
# [ ] implement _install-drivers in Odin — frontend/vendor/
#     GPU: check installed vs latest, install silently
#     GPU: install Vulkan runtime if missing
#     GPU: install CUDA runtime if NVIDIA detected
#     GPU: install ROCm runtime if AMD detected
#     audio: install PipeWire/PulseAudio if Linux + missing
#     camera: check installed vs latest, install silently
#     network: check installed vs latest, install silently
#     codecs: check ffmpeg availability, install missing
#     codecs: install media foundation codecs on Windows
#     on fail: continue with current, log warning to SMITH bench/
#     on reboot required: notify developer, continue without reboot
# [ ] implement _start-daemon in Odin — frontend/vendor/
#     watch GPU state — AI using GPU? switch wgpu to WebGL
#     watch audio devices — new device? activate automatically
#     watch cameras — new camera? activate automatically
#     watch displays — new monitor? configure automatically
#     watch USB/Bluetooth — new device? detect + activate
#     expose live state as typed message structs — no proto
#     supervised restart only — Guard catches crashes
#     daemon must run as long as machine is on
# ============================================================

perform:
    @echo "🧑‍🎤 performing machine..."
    @just _scan-hardware
    @just _install-drivers
    @just _setup-rendering
    @just _setup-audio
    @just _start-daemon
    @echo "✅ machine ready"

_scan-hardware:
    #!/usr/bin/env bash
    echo "reading the machine — CPU, GPU, audio, displays, cameras, network, storage, peripherals..."
    # TODO: implement in Odin — frontend/vendor/
    # output: .rice-hardware.json
    # [ ] expose hardware profile via NATS subject hardware.state.> — typed structs
    #     CHIEF reads hardware.state.gpu, hardware.state.audio on every rice cook
    #     schema: typed Odin struct → serialized to msgpack, no proto contract
    # [ ] write .rice-hardware.json schema — versioned, validated by CUE on read
    #     fields: cpu{model,cores,threads,avx512}, gpu[]{vendor,vram_mb,cuda,rocm,vulkan},
    #             audio[]{api,sample_rate}, display[]{res,hz,hdr}, storage[]{path,free_gb}

_install-drivers:
    #!/usr/bin/env bash
    echo "installing latest drivers silently..."
    # TODO: implement in Odin — frontend/vendor/
    # GPU — Vulkan, CUDA if NVIDIA, ROCm if AMD
    # audio — PipeWire if Linux
    # camera, network, codecs

_setup-rendering:
    #!/usr/bin/env bash
    echo "Rendering mode? (vulkan/metal/dx12/webgl/auto/skip)"
    read -r mode
    case $mode in
        vulkan)   echo "RICE_RENDER=vulkan" >> .envrc ;;
        metal)    echo "RICE_RENDER=metal" >> .envrc ;;
        dx12)     echo "RICE_RENDER=dx12" >> .envrc ;;
        webgl)    echo "RICE_RENDER=webgl" >> .envrc ;;
        auto)     echo "RICE_RENDER=auto" >> .envrc ;;
        skip)     echo "skipping rendering setup" ;;
    esac

_setup-audio:
    #!/usr/bin/env bash
    echo "Audio profile? (wasapi/coreaudio/pipewire/alsa/auto/skip)"
    read -r audio
    case $audio in
        wasapi)    echo "RICE_AUDIO=wasapi" >> .envrc ;;
        coreaudio) echo "RICE_AUDIO=coreaudio" >> .envrc ;;
        pipewire)  echo "RICE_AUDIO=pipewire" >> .envrc ;;
        alsa)      echo "RICE_AUDIO=alsa" >> .envrc ;;
        auto)      echo "RICE_AUDIO=auto" >> .envrc ;;
        skip)      echo "skipping audio setup" ;;
    esac

_start-daemon:
    #!/usr/bin/env bash
    echo "starting hardware watcher daemon..."
    # TODO: implement in Odin — frontend/vendor/
    # supervised restarts via SMITH guard/

# ============================================================
# 🧑‍🏭 SMITH — rice forge
# Builds all binaries via Buck2, then loads them into Docker.
# Hot reload: Buck2 rebuilds → Docker swaps binary, no restart.
#
# TODO:
# [ ] write service/BUCK — Go + Elixir targets
# [ ] write frontend/BUCK — Bun + Dart targets
# [ ] write function/BUCK — Python targets
# [ ] write base/BUCK — Rust + Haskell + Zig targets
# [ ] write all .docker/Dockerfile.* — copy Buck2 binaries, no compilation
# [ ] write docker-compose.yml — all services with volumes + healthchecks
# [ ] write .docker/conf/yugabyte.conf
# [ ] write .docker/conf/redis.conf
# [ ] write .docker/conf/nats.conf
# [ ] write .docker/conf/temporal.conf
# [ ] write .docker/conf/qdrant.conf
# [ ] write .docker/conf/postal.conf
# [ ] write .docker/conf/mailpit.conf
# [ ] write .docker/etc/init.sql
# [ ] write .docker/etc/pull.sh — pulls GGUF model files
# [ ] write .docker/etc/model.json — model registry
# ============================================================

forge:
    @echo "🧑‍🏭 forging environment..."
    buck2 build //...
    docker compose up -d
    @echo "✅ environment ready"

# ============================================================
# 🧑‍🔬 SAGE — rice think
# Detects compute, routes models to best backend,
# starts inference, training, simulation, or agents.
#
# TODO:
# [ ] implement _detect-compute in Python — function/agent/
#     detect all GPUs + VRAM per GPU via nvidia-smi / rocm-smi
#     detect CUDA / ROCm capability
#     detect available RAM
#     detect cloud API keys presence in .envrc
#     write compute profile to .rice-compute.json
# [ ] implement _route-models in Python — function/model/
#     discrete GPU + enough VRAM → start vLLM container
#     limited VRAM → start Ollama container
#     cloud API keys → configure LiteLLM cloud router
#     CPU only → start Ollama Q4 container
#     fallback: vLLM fail → Ollama automatically
#     fallback: Ollama fail → cloud API only, warn developer
# [ ] implement inference in Python — function/model/
#     load GGUF base models from function/model/weights/
#     load LoRA adapters per role from function/model/lora/
#     start LiteLLM router pointing at loaded models
#     expose model endpoints for all 7 roles
# [ ] implement training in Python — function/model/
#     load role-specific datasets from function/model/datasets/
#     run LoRA fine-tuning for all 7 role models
#     monitor GPU temperature — pause if overheats, resume after
#     output: GGUF + LoRA adapter per role → function/model/weights/
#     output: training logs → SMITH bench/ via OTel
# [ ] implement simulation in Python — function/simulation/
#     start Qiskit + PennyLane + JAX compute
#     if training + simulation both selected → training first
#     warn developer if no GPU for JAX acceleration
# [ ] implement agents in Python — function/agent/
#     start LangGraph multi-agent workflows
#     workflows ready for CHIEF to invoke via .rice
#     all outputs validated by guardrails-ai + instructor
# ============================================================

think:
    @echo "🧑‍🔬 thinking..."
    @just _check-forge
    @just _detect-compute
    @just _route-models
    @just _setup-compute
    @echo "✅ mind ready"

_check-forge:
    #!/usr/bin/env bash
    docker compose ps | grep -q "running" || (echo "❌ rice forge not running — run rice forge first" && exit 1)

_detect-compute:
    #!/usr/bin/env bash
    echo "detecting available compute..."
    # TODO: implement in Python — function/agent/

_route-models:
    #!/usr/bin/env bash
    echo "routing models to best backend..."
    # TODO: implement in Python — function/model/
    # [ ] implement LiteLLM router config generation — function/model/litellm_config.yaml
    #     generated by SAGE on startup — NOT hardcoded in repo
    #     model_list entries: per-role endpoint, fallback chain, timeout, retry
    #     RICE_LITELLM_MASTER_KEY, RICE_LITELLM_PORT read from env
    # [ ] implement model registry — function/model/registry.json
    #     per-role: {model_id, quantization, lora_path, vram_required_mb, backend}
    #     CHIEF reads registry on every rice cook to match project domain → model
    # [ ] implement GPU temperature watcher in Python — function/agent/gpu_watch.py
    #     poll nvidia-smi / rocm-smi every RICE_GPU_POLL_INTERVAL_S (default: 30)
    #     pause training if temp > RICE_GPU_MAX_TEMP_C (default: 83)
    #     resume after temp < RICE_GPU_RESUME_TEMP_C (default: 75)
    #     emit OTel metric gpu.temperature to bench/ on every poll

_setup-compute:
    #!/usr/bin/env bash
    echo "What compute to start? (inference/training/simulation/agents/all/skip)"
    read -r compute
    case $compute in
        inference)
            echo "starting LiteLLM router + loading GGUF models..."
            # TODO: implement in Python — function/model/
            ;;
        training)
            echo "starting LoRA fine-tuning pipeline..."
            # TODO: implement in Python — function/model/
            ;;
        simulation)
            echo "starting quantum simulation..."
            # TODO: implement in Python — function/simulation/
            ;;
        agents)
            echo "starting LangGraph agent workflows..."
            # TODO: implement in Python — function/agent/
            ;;
        all)
            echo "starting all compute — sequence: training → inference → simulation → agents"
            # TODO: implement in Python — function/
            ;;
        skip)
            echo "skipping compute setup"
            ;;
    esac

# ============================================================
# 👨‍💼 CLERK — rice audit
# Final gate before anything leaves the machine.
# format → lint → test → verify → secrets → security
# → penetration → infrastructure dry-run → decision gate
#
# TODO:
# [ ] fix odin fmt command — verify correct CLI syntax
# [ ] implement eBPF probe in Zig — base/security/
# [ ] implement seccomp policy audit in Zig — base/security/
# [ ] write pytest integration tests — function/test/
# [ ] write QuickCheck property proofs — base/calc/
# [ ] write ark-groth16 ZK proof tests — base/private/
# [ ] write CosmWasm contract verification — base/contracts/
# [ ] write guardrails-ai + instructor validation tests — function/test/
# [ ] configure osquery for host integrity checks
# [ ] configure suricata rules for .rice OS threat signatures
# [ ] configure argocd app name for rice deployment
# [ ] write release artifact build pipeline
# [ ] write registry push pipeline
# ============================================================

audit:
    @echo "👨‍💼 auditing the kingdom..."
    @just _audit-format
    @just _audit-lint
    @just _audit-test
    @just _audit-verify
    @just _audit-secrets
    @just _audit-security
    @just _audit-penetration
    @just _audit-infra
    @just _audit-gate
    @echo "✅ kingdom audited"

_audit-format:
    #!/usr/bin/env bash
    echo "── format ──"
    cue vet infra/configs/*.cue
    buf lint infra/schemas/*.proto
    cd base && rustfmt --check **/*.rs
    cd base && fourmolu --mode check **/*.hs
    cd base && zig fmt --check .
    cd service && gofmt -l ./...
    cd service && mix format --check-formatted
    cd frontend/browser && biome format --write=false .
    cd frontend/screen && dart format --set-exit-if-changed .
    cd frontend/vendor && odin fmt -vet .
    cd function && ruff format --check .
    vale infra/docs/**/*.md
    taplo fmt --check **/*.toml

_audit-lint:
    #!/usr/bin/env bash
    echo "── lint ──"
    buf breaking --against '.git#branch=main' infra/schemas/*.proto
    cd base && cargo clippy -- -D warnings
    cd base && hlint .
    cd base && zig build
    cd service && golangci-lint run
    cd service && mix credo --strict
    cd frontend/browser && biome lint .
    cd frontend/screen && dart analyze
    cd function && ruff check .
    cd function && basedpyright

_audit-test:
    #!/usr/bin/env bash
    echo "── test ──"
    cd base && cargo test
    cd base && cargo test base/mint/
    cd base && cabal test
    cd base && zig build test
    cd service && go test ./...
    cd service && mix test
    cd frontend/browser && bun run vitest
    cd frontend/browser && bun run playwright test
    cd frontend/screen && flutter test
    cd frontend/screen && patrol test
    cd function && pytest function/test/
    cd function && pytest function/test/ --integration

_audit-verify:
    #!/usr/bin/env bash
    echo "── verify ──"
    cd base && cabal test calc
    cd base && cargo test private
    cd base && cargo test contracts
    cd function && pytest function/test/ -k "guardrails or instructor"

_audit-secrets:
    #!/usr/bin/env bash
    echo "── secrets ──"
    sops --decrypt --dry-run secrets.enc.env
    trufflehog git file://. --only-verified
    git log --all -p | grep -E "(api_key|secret|password|token)" && exit 1 || true

_audit-security:
    #!/usr/bin/env bash
    echo "── security ──"
    cd base && cargo audit
    cd function && pip-audit
    cd function && bandit -r function/
    osquery
    # [ ] implement osquery pack — infra/security/rice.conf
    #     queries: process_open_sockets, listening_ports, users, kernel_modules
    #     schedule: all queries every RICE_OSQUERY_INTERVAL_S (default: 60)
    # [ ] implement seccomp profile — infra/security/seccomp.json
    #     syscall allowlist per role binary — generated by Zig probe in base/security/
    #     applied to all Docker containers via security_opt in docker-compose.yml
    # [ ] implement eBPF probe — base/security/probe.zig
    #     trace execve, connect, openat syscalls
    #     emit events to NATS subject security.events.>
    #     guard/ subscribes and alerts on policy violations

_audit-penetration:
    #!/usr/bin/env bash
    echo "── penetration ──"
    docker compose ps | grep -q "running" || (echo "⚠ rice forge not running — skipping penetration" && exit 0)
    nmap -sV localhost
    nuclei -u localhost
    suricata -T
    seccomp-tools
    # TODO: eBPF probe — implement in Zig — base/security/

_audit-infra:
    #!/usr/bin/env bash
    echo "── infrastructure dry-run ──"
    tofu validate .opentofu/
    tofu plan .opentofu/
    kubectl diff -f .k8s/

_audit-gate:
    #!/usr/bin/env bash
    echo "── decision gate ──"
    # [ ] implement release artifact pipeline:
    #     buck2 build //:rice → produces 🚚 bundle
    #     cosign sign --key ${RICE_COSIGN_KEY} bundle
    #     push signed bundle to ${RICE_REGISTRY}/${RICE_REGISTRY_REPO}:${version}
    #     generate SBOM via syft → attach to release
    # [ ] implement smoke tests against production:
    #     curl ${RICE_PROD_URL}/health for every service endpoint
    #     run function/test/smoke.py against production SAGE endpoints
    #     rollback: argocd app rollback ${RICE_ARGOCD_APP} on any smoke failure
    echo "Everything is green. What next? (commit/release/deploy/all/skip)"
    read -r action
    case $action in
        commit)
            git cliff --unreleased --prepend CHANGELOG.md
            convco commit
            git push
            ;;
        release)
            # TODO: implement release artifact build + registry push
            echo "❌ commit first — then release will build artifact + push to registry"
            exit 1
            ;;
        deploy)
            tofu apply .opentofu/
            kubectl apply -f .k8s/
            argocd app sync rice
            ;;
        all)
            git cliff --unreleased --prepend CHANGELOG.md
            convco commit
            git push
            tofu apply .opentofu/
            kubectl apply -f .k8s/
            argocd app sync rice
            ;;
        skip)
            echo "nothing leaves the machine"
            ;;
    esac

# ============================================================
# 👨‍🍳 CHIEF — rice prepare / cook / serve
#
# prepare — creates new project scaffold in custom/
# cook    — compiles .rice manifest → all role languages, hot reload
# serve   — runs rice audit, then deploys to production
#
# TODO prepare:
# [ ] implement project scaffold generator in base/mint/
#     create custom/{project}/{project}.rice — empty manifest template
#     create custom/{project}/README.md — project description
#     pre-fill manifest with domain, git, infra, services sections
#     ask: which subsystems to activate (SMITH/BARD/SAGE/CLERK)?
#     generate skeleton based on selection
#
# TODO cook:
# [ ] implement .rice compiler in base/mint/ (Rust)
#     parse custom/{project}/*.rice manifest
#     read live hardware state from .rice-hardware.json (BARD daemon)
#     read compute profile from .rice-compute.json (SAGE)
#     transpile .rice → Go (SMITH microservices)
#     transpile .rice → Rust (CLERK contracts + policies)
#     transpile .rice → TypeScript (BARD browser skeletons)
#     transpile .rice → Dart (BARD screen skeletons)
#     transpile .rice → Python (SAGE pipelines + agent configs)
#     transpile .rice → CUE (MASON infra configs)
#     transpile .rice → Protobuf (MASON inter-role contracts)
#     fill BARD browser/ skeletons with project content
#     fill SAGE function/ pipelines with project intent
#     load LoRA adapter for project domain via SAGE think
#     start hot reload — watch custom/{project}/*.rice for changes
#     on change: recompile only changed sections (salsa incremental)
#     on error: miette reports beautiful compiler errors
# [ ] implement .rice → CUE transpiler step in base/mint/
#     extract infra{} block from .rice manifest
#     render to infra/configs/{project}.cue via minijinja template
#     cue export immediately — validate before any other transpilation
# [ ] implement .rice → Proto transpiler step in base/mint/
#     extract service{} block → generate service contracts in infra/schemas/{project}.proto
#     buf lint + buf generate immediately after
# [ ] implement hot reload watcher — base/mint/src/watch.rs
#     salsa database invalidation on file change
#     recompile only changed sections (dependency graph via petgraph)
#     broadcast reload event to NATS subject cook.reload.{project}
#     BARD browser dev server subscribes and hot-swaps components
# [ ] implement CHIEF model loading in cook pipeline:
#     read .rice-compute.json to find available backend
#     call SAGE LiteLLM router to load rice-chief LoRA adapter
#     adapter interprets .rice manifest intent for code generation
#     RICE_CHIEF_TIMEOUT_S controls max wait for model load
#
# TODO serve:
# [ ] implement production deploy in base/mint/ (Rust)
#     run full rice audit gate — no bypass
#     on audit pass: build production artifacts via Buck2
#     push Docker images to registry via cosign-signed tags
#     apply OpenTofu infrastructure changes
#     apply Kubernetes manifests
#     sync ArgoCD application
#     run smoke tests against production endpoints
#     on fail: rollback ArgoCD to previous version
# ============================================================

prepare project:
    @echo "👨‍🍳 preparing ingredients for {{project}}..."
    mkdir -p custom/{{project}}
    touch custom/{{project}}/{{project}}.rice
    @echo "✅ custom/{{project}} ready — write your .rice manifest"
    @echo "   TODO: scaffold generator — implement in base/mint/"

cook project:
    @echo "👨‍🍳 cooking {{project}}..."
    @echo "TODO: .rice compiler not yet implemented"
    @echo "      implement transpiler in base/mint/ (Rust)"
    @echo "      lexer: logos → parser: chumsky → CST: rowan"
    @echo "      incremental: salsa → codegen: minijinja"
    @echo "      errors: miette → LSP: tower-lsp"

serve project:
    @echo "👨‍🍳 serving {{project}} to production..."
    just audit
    @echo "TODO: production deploy not yet implemented"
    @echo "      implement in base/mint/ (Rust)"
    @echo "      Buck2 build → Docker push → tofu apply → kubectl apply → argocd sync"
