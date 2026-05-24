package docker

import "strings"

// Optional compose service fragments (included only when stack.*.enabled).

_optionalVolumeLines: strings.Join([
	if stack.postal.enabled {"  postal-data:"},
	if stack.ollama.enabled {"  ollama-data:"},
	if stack.vllm.enabled {"  vllm-data:"},
], "\n")

_ollamaService: """
  ollama:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/bot/Dockerfile.ollama
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    environment:
      OLLAMA_KEEP_ALIVE: "\(params.compose.ollama.keepAlive)"
      OLLAMA_NUM_PARALLEL: "\(params.compose.ollama.numParallel)"
      OLLAMA_MAX_LOADED_MODELS: "\(params.compose.ollama.maxLoadedModels)"
      OLLAMA_HOST: "0.0.0.0:11434"
      MODEL_AUTO_PULL: \(params.compose.ollama.autoPull)
      MODEL_BACKEND: \(params.compose.ollama.backend)
      MODEL_PULL_RETRIES: "\(params.bot.registry.pull_retries)"
    deploy:
      resources:
        limits:
          memory: \(params.compose.ollama.memoryLimit)
        reservations:
          devices:
            - driver: nvidia
              count: \(params.compose.ollama.gpuCount)
              capabilities: [gpu]
    networks: [inference, edge]
    profiles: [\(params.compose.ollama.profile)]
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://127.0.0.1:11434/api/version"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 60s
"""

_vllmService: """
  vllm:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/bot/Dockerfile.vllm
    container_name: vllm
    ports:
      - "8000:8000"
    volumes:
      - vllm-data:/root/.cache/huggingface
      - \(params.compose.vllm.loraMount)
      - \(params.compose.vllm.weightsMount)
    environment:
      VLLM_MODEL: \(params.compose.vllm.model)
      VLLM_ENABLE_LORA: \(params.compose.vllm.enableLora)
      VLLM_MAX_LORA_RANK: "\(params.compose.vllm.maxLoraRank)"
      VLLM_GPU_MEMORY_UTILIZATION: "\(params.compose.vllm.gpuMemoryUtilization)"
      VLLM_MAX_NUM_SEQS: "\(params.compose.vllm.maxNumSeqs)"
      HF_TOKEN: "${HF_TOKEN:-}"
    deploy:
      resources:
        limits:
          memory: \(params.compose.vllm.memoryLimit)
        reservations:
          devices:
            - driver: nvidia
              count: \(params.compose.vllm.gpuCount)
              capabilities: [gpu]
    networks: [inference, edge]
    profiles: [\(params.compose.vllm.profile)]
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://127.0.0.1:8000/health"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 120s
"""

_postalService: """
  postal:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/mail/Dockerfile.postal
      args:
        EXPOSE_PORT: "5000"
    container_name: postal
    profiles: [\(params.compose.postal.profile)]
    ports:
      - "25:25"
      - "5000:5000"
    volumes:
      - postal-data:/opt/postal/data
    environment:
      PORT: "5000"
      POSTAL_SMTP_HOST: postal
      POSTAL_DB_HOST: yugabyte
      POSTAL_DB_PORT: "5433"
      POSTAL_DB_USER: \(params.compose.db.user)
      POSTAL_DB_PASSWORD: "${YUGABYTE_PASSWORD:?set YUGABYTE_PASSWORD}"
    networks: [mail, edge]
    depends_on:
      yugabyte:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O- http://127.0.0.1:5000/ >/dev/null 2>&1 || exit 0"]
      interval: 15s
      timeout: 5s
      retries: 3
"""

_otpService: """
  otp:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/server/Dockerfile.otp
    container_name: otp
    ports:
      - "\(server.otp.port):4000"
    environment:
      PHX_SERVER: "true"
      PHX_HOST: "0.0.0.0"
      PORT: "4000"
      RICE_WEB_GRPC_HOST: "rpc"
      RICE_WEB_GRPC_PORT: "\(server.rpc.port)"
      DATABASE_URL: "ecto://\(params.compose.db.user):${YUGABYTE_PASSWORD:?set YUGABYTE_PASSWORD}@yugabyte:5433/\(params.compose.db.name)"
    networks: [edge, data]
    depends_on:
      yugabyte:
        condition: service_healthy
      redis:
        condition: service_started
      nats:
        condition: service_started
    deploy:
      resources:
        limits:
          memory: \(server.otp.memoryLimit)
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O- http://127.0.0.1:4000/ >/dev/null 2>&1 || exit 0"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 40s
"""

_docsService: """
  docs:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/server/Dockerfile.docs
    container_name: docs
    ports:
      - "\(server.docs.port):8080"
    networks: [edge]
    deploy:
      resources:
        limits:
          memory: \(server.docs.memoryLimit)
"""

_rpcService: """
  rpc:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/server/Dockerfile.rpc
    container_name: rpc
    ports:
      - "\(server.rpc.port):50051"
    networks: [edge, data]
"""

_agentService: """
  agent:
    <<: *stack-defaults
    build:
      context: ..
      dockerfile: .docker/server/Dockerfile.agent
    container_name: agent
    ports:
      - "\(server.agent.port):8001"
    networks: [edge, inference]
"""

_optionalServices: strings.Join([
	if stack.ollama.enabled {_ollamaService},
	if stack.vllm.enabled {_vllmService},
	if stack.postal.enabled {_postalService},
	if stack.otp.enabled {_otpService},
	if stack.docs.enabled {_docsService},
	if stack.rpc.enabled {_rpcService},
	if stack.agent.enabled {_agentService},
], "\n")
