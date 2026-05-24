# Generated — cue cmd gen ./infra
# Params: infra/proto/cue/infra.cue + infra/gen/chief/ (Mint from custom/*/infra/docker.rice)
#!/usr/bin/env bash
set -euo pipefail
REGISTRY="${MODEL_REGISTRY:-/etc/ollama/model.json}"
READY="/tmp/models-ready"
AUTO="${MODEL_AUTO_PULL:-true}"
BACKEND="${MODEL_BACKEND:-ollama}"
RETRIES="${MODEL_PULL_RETRIES:-3}"
	if [[ "${AUTO}" != "true" ]]; then
	  echo "model-pull: MODEL_AUTO_PULL=false — skip"
	  exit 0
	fi
	if [[ "${BACKEND}" == "vllm" ]]; then
	  echo "model-pull: backend=vllm — HuggingFace handles weights"
	  touch "${READY}"
	  exit 0
	fi
	if [[ ! -f "${REGISTRY}" ]]; then
	  echo "model-pull: missing registry ${REGISTRY}" >&2
	  exit 1
	fi

	pull_one() {
	  local spec="$1"
	  local id q
	  id="$(echo "${spec}" | sed -n 's/.*"model_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
	  q="$(echo "${spec}" | sed -n 's/.*"quantization"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
	  [[ -n "${id}" ]] || return 0
	  local tag="${id}"
	  [[ -n "${q}" && "${q}" != "null" ]] && tag="${id}:${q}"
	  local n=0
	  while [[ $n -lt "${RETRIES}" ]]; do
	    if ollama pull "${tag}"; then
	      echo "model-pull: ok ${tag}"
	      return 0
	    fi
	    n=$((n + 1))
	    sleep 2
	  done
	  echo "model-pull: failed ${tag}" >&2
	  return 1
	}

	if command -v python3 >/dev/null 2>&1; then
	  mapfile -t specs < <(python3 - "${REGISTRY}" <<'PY'
	import json, sys
	with open(sys.argv[1]) as f:
	    data = json.load(f)
	roles = data.get("roles") or {}
	default = data.get("pull_on_start_default", True)
	for name, cfg in roles.items():
	    if not isinstance(cfg, dict):
	        continue
	    if cfg.get("pull_on_start", default) and cfg.get("backend", "ollama") == "ollama":
	        print(json.dumps(cfg))
	PY
	)
	  for s in "${specs[@]}"; do pull_one "${s}"; done
	else
	  echo "model-pull: python3 required to parse model.json" >&2
	  exit 1
	fi

	ollama list > "${READY}" 2>/dev/null || true
	echo "model-pull: ready → ${READY}"