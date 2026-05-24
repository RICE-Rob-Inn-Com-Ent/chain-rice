package rice

import (
	"github.com/rice-rob-inn-com-ent/rice/infra/configs"
	"tool/exec"
	"tool/file"
)

_source: configs

#ConfigSchema: {
	metadata: name: string
	spec: {
		version: string
		enabled: bool | *true
	}
	content: [string]: string
}

_file_map: _source.outputs

folder_sync: [
	{source: "infra/kubernetes", target: ".kubernetes"},
	{source: "infra/terraform",  target: ".terraform"},
	{source: "infra/reuse",      target: ".reuse"},
	{source: "infra/vscode",     target: ".vscode"},
]

command: gen: {

	validate: exec.Run & {
		display: "🔍 Vetting: Validating all configurations in infra/configs..."
		cmd:     "cue vet ./infra/configs/... -d #ConfigSchema"
	}

	write_files: {
		for path, data in _file_map {
			"write-\(path)": file.Create & {
				$after:   validate
				filename: path
				contents: data
				permissions: 0o444
			}
		}
	}

	sync_folders: {
		for item in folder_sync {
			"sync-\(item.target)": exec.Run & {
				$after: write_files
				cmd:    "rm -rf \(item.target) && cp -r \(item.source) \(item.target)"
				display: "  → Syncing \(item.source) to \(item.target)"
			}
		}
	}

	final_msg: exec.Run & {
		$after: sync_folders
		cmd:    "echo ✅ Manifest processed: All files generated and validated."
	}
}
