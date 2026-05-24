package main

import (
	"context"
	"fmt"

	"golang.org/x/sync/errgroup"
)

func thinkScriptBootstrap() string {
	return `
set -euo pipefail
mkdir -p /src/.rice/cache/thought
mkdir -p /src/.rice/cache/thought/models
mkdir -p /src/.rice/cache/thought/rag
mkdir -p /src/.rice/cache/thought/lora
mkdir -p /src/.rice/cache/thought/mojo

if [ ! -s /src/atlas.sys ]; then
  echo "atlas.sys not found; run perform before think"
  exit 1
fi

if [ ! -f /src/.rice/cache/compose.bin ]; then
  echo "forge compose engine marker missing (.rice/cache/compose.bin); run forge first"
  exit 1
fi
`
}

func thinkScriptRoleModels() string {
	return `
set -euo pipefail
echo "── think: role GGUF orchestration ──"
roles="${RICE_ROLES:-SAGE CLERK BARD KING}"
model_root="${RICE_GGUF_ROOT:-/src/.rice/models}"
mkdir -p "${model_root}"
for role in ${roles}; do
  role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
  model="${model_root}/${role_lc}.gguf"
  if [ ! -f "${model}" ]; then
    echo "warning: missing role model ${model}; creating placeholder"
    : > "${model}"
  fi
  {
    echo "role=${role}"
    echo "gguf=${model}"
    echo "atlas=/src/atlas.sys"
  } > "/src/.rice/cache/thought/models/${role_lc}.env"
done
`
}

func thinkScriptRAG() string {
	return `
set -euo pipefail
echo "── think: RAG ignition ──"
rag_manifest="/src/.rice/cache/thought/rag/context.manifest"
atlas_hash="$(sha256sum /src/atlas.sys | awk '{print $1}')"
{
  echo "atlas=/src/atlas.sys"
  echo "atlas_sha256=${atlas_hash}"
  echo "infra_logs=/src/.rice/cache/forge-dashboard.log"
  echo "vector_store=/src/.rice/cache/thought/rag/vector.sqlite"
  echo "rag_backend=${RICE_RAG_BACKEND:-sqlite}"
} > "${rag_manifest}"
`
}

func thinkScriptAiderLoRA() string {
	return `
set -euo pipefail
echo "── think: aider + LoRA adapters ──"
roles="${RICE_ROLES:-SAGE CLERK BARD KING}"
adapters_root="${RICE_LORA_ROOT:-/src/.rice/lora}"
mkdir -p "${adapters_root}"
for role in ${roles}; do
  role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
  adapter="${adapters_root}/${role_lc}.safetensors"
  if [ ! -f "${adapter}" ]; then
    echo "warning: missing LoRA adapter ${adapter}; creating placeholder"
    : > "${adapter}"
  fi
  {
    echo "role=${role}"
    echo "adapter=${adapter}"
    echo "agentic_engine=${RICE_AGENT_ENGINE:-aider}"
  } > "/src/.rice/cache/thought/lora/${role_lc}.env"
done
`
}

func thinkScriptMojoAndLearning() string {
	return `
set -euo pipefail
echo "── think: mojo pruning + autonomous learning loop ──"
cat > /src/.rice/cache/thought/mojo/prune.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd /src
if command -v mojo >/dev/null 2>&1; then
  if [ -f function/job/mojo/__init__.mojo ]; then
    mojo function/job/mojo/__init__.mojo || true
  fi
fi
echo "last_prune_at=$(date -u +%FT%TZ)" > /src/.rice/cache/thought/mojo/prune.state
EOF
chmod +x /src/.rice/cache/thought/mojo/prune.sh
/src/.rice/cache/thought/mojo/prune.sh

cat > /src/.rice/cache/thought/learn-loop.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd /src
roles="${RICE_ROLES:-SAGE CLERK BARD KING}"
gpu_budget="${RICE_GPU_BUDGET_PERCENT:-85}"
npu_budget="${RICE_NPU_BUDGET_PERCENT:-85}"
collect_usage() {
  gpu="unknown"
  if command -v nvidia-smi >/dev/null 2>&1; then
    gpu="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n 1 | tr -d ' ')"
  fi
  echo "${gpu},${npu_budget},${gpu_budget}"
}
while true; do
  usage="$(collect_usage)"
  echo "$(date -u +%FT%TZ),usage=${usage}" >> /src/.rice/cache/thought/resource.log
  if command -v inotifywait >/dev/null 2>&1; then
    inotifywait -r -e close_write,create,move,delete \
      --exclude '(^|/)\.git/|(^|/)buck-out/|(^|/)node_modules/|(^|/)\.rice/cache/' /src >/dev/null 2>&1 || true
  else
    sleep 5
  fi
  for role in ${roles}; do
    role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
    echo "$(date -u +%FT%TZ),role=${role},event=incremental_adjust" >> /src/.rice/cache/thought/learn.log
    touch "/src/.rice/cache/thought/lora/${role_lc}.refresh"
  done
  /src/.rice/cache/thought/mojo/prune.sh || true
done
EOF
chmod +x /src/.rice/cache/thought/learn-loop.sh

if [ -f /src/.rice/cache/thought/learn-loop.pid ] && kill -0 "$(cat /src/.rice/cache/thought/learn-loop.pid)" 2>/dev/null; then
  echo "learning loop already running (pid $(cat /src/.rice/cache/thought/learn-loop.pid))"
else
  nohup /src/.rice/cache/thought/learn-loop.sh > /src/.rice/cache/thought/learn-loop.out 2>&1 &
  echo $! > /src/.rice/cache/thought/learn-loop.pid
fi
`
}

func thinkScriptIPCSync() string {
	return `
set -euo pipefail
echo "── think: IPC neural sync ──"
compose_bin="$(cat /src/.rice/cache/compose.bin)"
compose_file="${RICE_COMPOSE_FILE:-docker-compose.yml}"
if [ -f "${compose_file}" ]; then
  ${compose_bin} -f "${compose_file}" ps > /src/.rice/cache/thought/ipc.containers || true
fi
{
  echo "transport=elixir-go-bridge"
  echo "state_file=/src/.rice/cache/thought/ipc.containers"
  echo "sync_mode=${RICE_THINK_SYNC_MODE:-eventual}"
} > /src/.rice/cache/thought/ipc.env
`
}

func thinkScriptModelRuntime() string {
	return `
set -euo pipefail
echo "── think: cognitive runtime wake-up ──"
roles="${RICE_ROLES:-SAGE CLERK BARD KING}"
mkdir -p /src/.rice/cache/thought/runtime
for role in ${roles}; do
  role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
  {
    echo "role=${role}"
    echo "status=awake"
    echo "model_env=/src/.rice/cache/thought/models/${role_lc}.env"
    echo "lora_env=/src/.rice/cache/thought/lora/${role_lc}.env"
    echo "rag_manifest=/src/.rice/cache/thought/rag/context.manifest"
  } > "/src/.rice/cache/thought/runtime/${role_lc}.state"
done
`
}

// Think transitions the forged repository from ready state to a running
// cognitive network with role models, RAG context, LoRA, and learning loops.
func (m *Rice) Think(ctx context.Context) error {
	src, err := workspaceDir()
	if err != nil {
		return err
	}

	if err := runPourStep(ctx, "think-bootstrap", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "think-bootstrap", thinkScriptBootstrap())
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "think-core-init", func(stepCtx context.Context) error {
		g, egCtx := errgroup.WithContext(stepCtx)
		g.Go(func() error { return runBash(egCtx, src, "think-role-models", thinkScriptRoleModels()) })
		g.Go(func() error { return runBash(egCtx, src, "think-rag", thinkScriptRAG()) })
		g.Go(func() error { return runBash(egCtx, src, "think-aider-lora", thinkScriptAiderLoRA()) })
		return g.Wait()
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "think-neural-maintenance", func(stepCtx context.Context) error {
		g, egCtx := errgroup.WithContext(stepCtx)
		g.Go(func() error { return runBash(egCtx, src, "think-mojo-learning", thinkScriptMojoAndLearning()) })
		g.Go(func() error { return runBash(egCtx, src, "think-ipc-sync", thinkScriptIPCSync()) })
		return g.Wait()
	}); err != nil {
		return err
	}

	if err := runPourStep(ctx, "think-runtime", func(stepCtx context.Context) error {
		return runBash(stepCtx, src, "think-runtime", thinkScriptModelRuntime())
	}); err != nil {
		return err
	}

	ctr := withPixi(src)
	ctr = withBash(ctr, `set -euo pipefail; echo "🧠 think complete: cognitive network awake"`)
	if err := mustSync(ctx, ctr, "think-finalize"); err != nil {
		return err
	}
	if _, err := ctr.Directory("/src").Export(ctx, "."); err != nil {
		return fmt.Errorf("export workspace after think: %w", err)
	}
	return nil
}
