package terraform

import (
	"strings"
	"tool/file"
)

// _tool.cue — cue cmd genTerraform → repo .opentofu/

_generatedHeader: """
	# Generated — cue cmd genTerraform (MASON infra/terraform/cue)
	# CHIEF overlay: custom/*/infra/terraform.rice → infra/gen/chief/terraform_project.cue

	"""

command: genTerraform: {
	for path, body in allFiles {
		let safe = strings.Replace(path, "/", "-", -1)
		"write-\(safe)": file.Create & {
			filename:    path
			contents:    _generatedHeader + body
			permissions: 0o644
		}
	}
}
