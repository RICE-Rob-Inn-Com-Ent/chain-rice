package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

)

const thinkPipelineScript = `
set -euo pipefail
REPO="${RICE_MONO_ROOT:-/src}"
cd "$REPO"
export PATH="$REPO/.pixi/envs/default/bin:/root/.pixi/bin:/usr/local/bin:/usr/bin:$PATH"
roles="${RICE_ROLES:-SAGE CLERK BARD KING}"

if [[ ! -s /src/atlas.sys ]]; then
  echo "error: run rice perform first" >&2
  exit 1
fi
if [[ ! -f /src/.rice/cache/forge.ok ]]; then
  echo "error: run rice forge first" >&2
  exit 1
fi

mkdir -p .rice/cache/thought/{models,rag,lora,runtime,mojo}

atlas_hash="$(sha256sum /src/atlas.sys | awk '{print $1}')"
{
  echo "atlas=/src/atlas.sys"
  echo "atlas_sha256=${atlas_hash}"
  echo "rag_backend=${RICE_RAG_BACKEND:-sqlite}"
  echo "vector_store=/src/.rice/cache/thought/rag/vector.sqlite"
} > .rice/cache/thought/rag/context.manifest

model_root="${RICE_GGUF_ROOT:-/src/.rice/models}"
mkdir -p "${model_root}"
for role in ${roles}; do
  role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
  model="${model_root}/${role_lc}.gguf"
  if [[ ! -f "${model}" ]]; then
    printf 'GGUF placeholder for %s (pull weights separately)\n' "${role}" > "${model}"
  fi
  {
    echo "role=${role}"
    echo "gguf=${model}"
    echo "atlas=/src/atlas.sys"
    echo "status=ready"
  } > ".rice/cache/thought/models/${role_lc}.env"
done

adapters_root="${RICE_LORA_ROOT:-/src/.rice/lora}"
mkdir -p "${adapters_root}"
for role in ${roles}; do
  role_lc="$(echo "$role" | tr '[:upper:]' '[:lower:]')"
  adapter="${adapters_root}/${role_lc}.safetensors"
  if [[ ! -f "${adapter}" ]]; then
    : > "${adapter}"
  fi
  {
    echo "role=${role}"
    echo "adapter=${adapter}"
    echo "agentic_engine=${RICE_AGENT_ENGINE:-aider}"
    echo "status=ready"
  } > ".rice/cache/thought/lora/${role_lc}.env"
  {
    echo "role=${role}"
    echo "status=awake"
    echo "model_env=/src/.rice/cache/thought/models/${role_lc}.env"
    echo "lora_env=/src/.rice/cache/thought/lora/${role_lc}.env"
  } > ".rice/cache/thought/runtime/${role_lc}.state"
done

echo "last_prune_at=$(date -u +%FT%TZ)" > .rice/cache/thought/mojo/prune.state
echo ok > .rice/cache/think.ok
echo "✅ think: cognitive network manifests ready"
`

// Think materializes role model/RAG/LoRA manifests after forge (weights optional on disk).
func (m *Rice) Think(ctx context.Context) error {
	root := moduleRoot()
	src, err := workspaceDir(ctx)
	if err != nil {
		return err
	}

	if err := runPourStep(ctx, "think", func(stepCtx context.Context) error {
		ctr := withBash(withPixi(src), thinkPipelineScript)
		if err := mustSync(stepCtx, ctr, "think"); err != nil {
			return err
		}
		return exportWorkspace(stepCtx, ctr)
	}); err != nil {
		return err
	}

	if _, err := os.Stat(filepath.Join(root, ".rice", "cache", "think.ok")); err != nil {
		return fmt.Errorf("think: think.ok missing: %w", err)
	}
	fmt.Println("✅ think complete")
	return nil
}
