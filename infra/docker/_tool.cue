package docker

import (
	"strings"
	"tool/file"
)

// _tool.cue — cue cmd genDocker (load docker/cue/**/*.cue for allFiles + params).
// Orchestrated from infra/_tool.cue — do not flatten cue/ into docker/.

_generatedHeader: """
	# Generated — cue cmd gen ./infra
	# Params: infra/proto/cue/infra.cue + infra/gen/chief/ (Mint from custom/*/infra/docker.rice)

	"""

command: genDocker: {
	for path, body in allFiles {
		let safe = strings.Replace(path, "/", "-", -1)
		"write-\(safe)": file.Create & {
			filename:    path
			contents:    _generatedHeader + body
			permissions: 0o644
		}
	}
}
