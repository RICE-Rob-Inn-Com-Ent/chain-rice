package docker

import "strings"

// mail.cue — `.docker/mail/` (platform hardcoded; mailpit profile from params).

_mailDockerfileMailpit: strings.Join([
	"# syntax=docker/dockerfile:1",
	"ARG MAILPIT_VERSION=v1.22",
	"FROM axllent/mailpit:${MAILPIT_VERSION}",
	"EXPOSE 1025 8025",
	"HEALTHCHECK --interval=5s --timeout=3s --retries=3 \\",
	"  CMD wget -q -O- http://127.0.0.1:8025/livez",
], "\n")

_mailDockerfilePostal: strings.Join([
	"# syntax=docker/dockerfile:1",
	"ARG EXPOSE_PORT=5000",
	"FROM alpine:3.20",
	"RUN apk add --no-cache ca-certificates wget",
	"EXPOSE ${EXPOSE_PORT}",
	"HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD wget -q -O- http://127.0.0.1:5000/ >/dev/null 2>&1 || exit 0",
	"CMD [\"sleep\", \"infinity\"]",
], "\n")

_mailMailpitConf: """
# Mailpit — profile \(params.compose.mailpit.profile)
"""

_mailPostalConf: """
	# Postal — compose env (platform).
	"""
