# CUE source: infra/configs/docker/bot__Dockerfile.sage.cue (package docker; aggregator infra/configs/config.cue)
# Do not overwrite from CUE gen until shard content is wired; edit the .cue shard.

# KING TODO map
# TODO:
# [ ] FROM python:3.13-slim — SAGE is Python-primary
# [ ] ARG SAGE_PIXI_ENV_HASH — cache busting for pixi environment
# [ ] COPY .pixi/envs/sage/ /opt/pixi/envs/sage/ — pre-built pixi env, no pip install
# [ ] COPY buck-out/gen/function/sage /usr/local/bin/rice-sage
# [ ] ENV RICE_ROLE=sage
# [ ] ENV RICE_BACKEND — read from RICE_BACKEND (ollama/vllm/litellm)
# [ ] ENV QDRANT_URL — read from RICE_QDRANT_URL
# [ ] ENV OTEL_SERVICE_NAME=rice-sage
# [ ] EXPOSE RICE_SAGE_PORT (default: 8001) — FastAPI inference endpoint
# [ ] install GPU runtime conditionally:
#     ARG CUDA_ENABLED — if true, base FROM nvidia/cuda:12.x-runtime-ubuntu22.04
#     RICE_SAGE_CUDA_VERSION controls base image tag — renovate tracks it
