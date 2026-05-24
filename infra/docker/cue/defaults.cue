package docker

import infra "github.com/rice-rob-inn-com-ent/rice/infra/proto/cue:infra"

// MASON defaults on #DockerParams (| *) — CHIEF projectParams / Mint override via unification.

#DockerParams: infra.#DockerParams & {
	compose: {
		projectName: string | *"stack"

		db: {
			name: string | *"app"
			user: string | *"app"
		}

		redis: {
			memoryLimit: string | *"512M"
			maxmemory:   string | *"512mb"
		}

		yugabyte: {
			memoryLimit: string | *"4G"
		}

		qdrant: {
			memoryLimit:      string | *"2G"
			hnswM:            int | *16
			efConstruct:      int | *100
			maxRequestSizeMb: int | *32
			quantization:     string | *"int8"
		}

		nats: {
			memoryLimit:      string | *"1G"
			jetstreamMaxMem:  string | *"1GB"
			jetstreamMaxFile: string | *"10GB"
			maxPayload:       string | *"8MB"
		}

		temporal: {
			memoryLimit: string | *"2G"
		}

		postal: profile: string | *"_disabled"

		mailpit: {
			profile:     string | *"mailpit"
			maxMessages: string | *"1000"
			database:    string | *"/data/mailpit.db"
		}

		ollama: {
			profile:         string | *"ollama"
			memoryLimit:     string | *"6G"
			autoPull:        bool | *true
			backend:         string | *"ollama"
			maxLoadedModels: string | *"1"
			keepAlive:       string | *"-1"
			numParallel:     string | *"1"
			gpuCount:        int | *1
		}

		vllm: {
			profile:              string | *"vllm"
			memoryLimit:          string | *"6G"
			model:                string | *""
			loraMount:            string | *"../models/lora:/lora:ro"
			weightsMount:         string | *"../models/weights:/weights:ro"
			enableLora:           bool | *true
			maxLoraRank:          string | *"128"
			gpuMemoryUtilization: string | *"0.90"
			maxNumSeqs:           string | *"1"
			gpuCount:             int | *1
		}
	}

	db: init: sql: [...string]

	bot: registry: {
		version:               string | *"1"
		pull_on_start_default: bool | *true
		pull_retries:          int | *3
		roles:                 [string]: #BotRole
		fallback_chain:        [...string] | *["vllm", "ollama"]
	}
}
