package docker

import infra "github.com/rice-rob-inn-com-ent/rice/infra/proto/cue:infra"

// pack.cue — params, output paths, file roll-up (schema: infra/proto/cue/infra.cue + infra/gen/chief/).

params: #DockerParams & projectParams

server: infra.#ServerParams & serverProjectParams
docs:   infra.#DocsParams & docsProjectParams

paths: {
	dockerRoot:   ".docker"
	composeFile:  ".docker/docker-compose.yml"
	dockerignore: ".docker/.dockerignore"
	dbDir:        ".docker/db"
	messagingDir: ".docker/messaging"
	mailDir:      ".docker/mail"
	botDir:       ".docker/bot"
	serverDir:    ".docker/server"
}

dbFiles: {
	"\(paths.dbDir)/init.sql":            _dbInitSQL
	"\(paths.dbDir)/valkey.conf":         _dbValkeyConf
	"\(paths.dbDir)/qdrant.yaml":         _dbQdrantYAML
	"\(paths.dbDir)/yugabyte.conf":       _dbYugabyteConf
	"\(paths.dbDir)/qdrant.conf":         _dbQdrantConf
	"\(paths.dbDir)/Dockerfile.yugabyte": _dbDockerfileYugabyte
	"\(paths.dbDir)/Dockerfile.valkey":   _dbDockerfileValkey
	"\(paths.dbDir)/Dockerfile.qdrant":   _dbDockerfileQdrant
}

messagingFiles: {
	"\(paths.messagingDir)/nats.conf":            _messagingNatsConf
	"\(paths.messagingDir)/temporal.conf":          _messagingTemporalConf
	"\(paths.messagingDir)/temporal-dynamic.yaml": _messagingTemporalDynamic
	"\(paths.messagingDir)/Dockerfile.nats":        _messagingDockerfileNats
	"\(paths.messagingDir)/Dockerfile.temporal":   _messagingDockerfileTemporal
}

mailFiles: {
	"\(paths.mailDir)/mailpit.conf":       _mailMailpitConf
	"\(paths.mailDir)/Dockerfile.mailpit": _mailDockerfileMailpit
	if stack.postal.enabled {
		"\(paths.mailDir)/postal.conf":        _mailPostalConf
		"\(paths.mailDir)/Dockerfile.postal":  _mailDockerfilePostal
	}
}

botFiles: {
	"\(paths.botDir)/model.json": _botModelJSON
	"\(paths.botDir)/pull.sh":    _botPullSh
	if stack.ollama.enabled {
		"\(paths.botDir)/Dockerfile.ollama": _botDockerfileOllama
	}
	if stack.vllm.enabled {
		"\(paths.botDir)/Dockerfile.vllm": _botDockerfileVllm
	}
}

serverFiles: {
	if stack.otp.enabled {
		"\(paths.serverDir)/Dockerfile.otp": _serverDockerfileOtp
	}
	if stack.rpc.enabled {
		"\(paths.serverDir)/Dockerfile.rpc": _serverDockerfileRpc
	}
	if stack.agent.enabled {
		"\(paths.serverDir)/Dockerfile.agent": _serverDockerfileAgent
	}
	if stack.docs.enabled {
		"\(paths.serverDir)/Dockerfile.docs": _serverDockerfileDocs
	}
}

mainFiles: {
	"\(paths.composeFile)":  _composeYAML
	"\(paths.dockerignore)": _dockerignore
}

allFiles: [string]: string
allFiles: dbFiles & messagingFiles & mailFiles & botFiles & serverFiles & mainFiles & docsGenFiles
