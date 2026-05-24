package docs

import (
	"strings"
	"tool/file"
)

_generatedHeader: """
	# Generated — cue cmd genDocs ./infra/docs
	# Params: infra/gen/chief/docs_project.cue (Mint from custom/*/infra/docs.rice)

	"""

command: genDocs: {
	for path, body in allFiles {
		let safe = strings.Replace(path, "/", "-", -1)
		"write-\(safe)": file.Create & {
			filename:    path
			contents:    _generatedHeader + body
			permissions: 0o644
		}
	}
}
