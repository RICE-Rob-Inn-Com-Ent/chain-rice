package docker

import "strings"

// messaging.cue — `.docker/messaging/` (platform hardcoded).

_messagingNatsConf: """
# NATS — JetStream limits from CHIEF (params.compose.nats)
port: 4222
http_port: 8222
server_name: nats
max_payload: \(params.compose.nats.maxPayload)
jetstream {
  store_dir: "/data"
  max_mem_store: \(params.compose.nats.jetstreamMaxMem)
  max_file_store: \(params.compose.nats.jetstreamMaxFile)
}
"""

_messagingTemporalDynamic: """
	frontend.enableClientVersionCheck:
	  - value: true
	    constraints: {}
	system.forceSearchAttributesCacheRefreshOnRead:
	  - value: true
	    constraints: {}
	"""

_messagingDockerfileNats: strings.Join([
	"# syntax=docker/dockerfile:1",
	"ARG NATS_VERSION=2.10",
	"FROM nats:${NATS_VERSION}-alpine",
	"COPY .docker/messaging/nats.conf /etc/nats/nats.conf",
	"EXPOSE 4222 8222 6222",
	"HEALTHCHECK --interval=5s --timeout=3s --retries=5 \\",
	"  CMD wget -q -O- http://127.0.0.1:8222/healthz",
	"CMD [\"--config\", \"/etc/nats/nats.conf\"]",
], "\n")

_messagingDockerfileTemporal: strings.Join([
	"# syntax=docker/dockerfile:1",
	"ARG TEMPORAL_VERSION=1.25.2",
	"FROM temporalio/auto-setup:${TEMPORAL_VERSION}",
	"EXPOSE 7233 8088",
	"HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=10 \\",
	"  CMD temporal operator cluster health",
], "\n")

_messagingTemporalConf: """
	# Temporal — env wired in compose (platform).
	"""
