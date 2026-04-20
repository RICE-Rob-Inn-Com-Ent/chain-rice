#!/usr/bin/env bash

# CUE source: infra/configs/docker/etc__pull.sh.cue (package docker; aggregator infra/configs/config.cue)
# Do not overwrite from CUE gen until shard content is wired; edit the .cue shard.

# KING TODO map
# TODO:
# [ ] read RICE_BACKEND from env — skip pull if backend = vllm (HuggingFace handles it)
# [ ] read model list from /etc/ollama/model.json — do NOT hardcode model names
# [ ] for each role model in registry where pull_on_start = true:
#     ollama pull "${model_id}:${quantization}"
#     retry up to RICE_PULL_RETRIES (default: 3) times on network failure
#     log success/failure to stdout — Docker captures to SMITH bench/ via OTel
# [ ] after all pulls: ollama list → write loaded models to /tmp/rice-models-ready
#     rice think reads this file to confirm models are available before routing
# [ ] if RICE_MODEL_AUTO_PULL=false — skip all pulls, assume models pre-loaded in volume
# [ ] if RICE_HF_TOKEN is set — configure HuggingFace auth for gated models
#     write token to ~/.cache/huggingface/token — never log the token value

set -euo pipefail

echo "Placeholder pull script for model artifacts."
