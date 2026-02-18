package rice

// Import: config (pliki king, dotfoldery). Komenda gen jest w gen_tool.cue.
import config "github.com/rice-rob-inn-com-ent/rice-mono/infra/config"

// Pliki roota: cue cmd gen eksportuje config.order i config.king_content (skrypt w gen_tool.cue).
// Dotfoldery roota: (1) pliki z CUE (king_folder_file_outputs → .github/) z kings_root_github.cue; (2) kopiowanie (folder_outputs).
folder_file_outputs: config.king_folder_file_outputs
folder_outputs: [
	{source: "infra/kubernetes", target: ".kubernetes"},
	{source: "infra/terraform", target: ".terraform"},
	{source: "infra/reuse", target: ".reuse"},
	{source: "infra/markdown/devcontainer/vscode", target: ".vscode"},
]
