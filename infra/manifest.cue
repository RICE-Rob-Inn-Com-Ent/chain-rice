package rice

// Import: config (pliki king, dotfoldery).
import config "github.com/rice-rob-inn-com-ent/rice/infra/configs"

import "tool/exec"

// Pliki roota: cue cmd gen eksportuje order i king_content. Przekazane z config.
order:        config.order
king_content: config.king_content
// Dotfoldery roota: (1) pliki z CUE (king_folder_file_outputs → .github/) z kings_root_github.cue; (2) kopiowanie (folder_outputs).
folder_file_outputs: config.king_folder_file_outputs
folder_outputs: [
	{source: "infra/kubernetes", target: ".kubernetes"},
	{source: "infra/terraform", target: ".terraform"},
	{source: "infra/reuse", target: ".reuse"},
	{source: "infra/markdown/devcontainer/vscode", target: ".vscode"},
]

// gen: generuje pliki roota (config.order + king_content), potem pliki folderów z CUE (folder_file_outputs),
// na końcu kopiuje dotfoldery (folder_outputs). Uruchom z repo root: cue cmd gen ./infra
command: gen: {
	// Uruchom w repo root (.), żeby PKG="./infra" i ROOT="." wskazywały na rice-mono. dir ".." psuło to.
	task: run: exec.Run & {
		cmd: "bash"
		dir: "."
		args: ["-c", script]
	}

	script: """
		set -e
		echo "📐 Generating root config and dotfolders from CUE..."
		ROOT=$(pwd)
		while [ -n "$ROOT" ] && [ "$ROOT" != "/" ] && [ ! -f "$ROOT/infra/manifest.cue" ]; do ROOT=$(dirname "$ROOT"); done
		if [ -z "$ROOT" ] || [ ! -f "$ROOT/infra/manifest.cue" ]; then
		  echo "❌ Repo root (with infra/manifest.cue) not found. Run from rice-mono or a subfolder."
		  exit 1
		fi
		cd "$ROOT" || exit 1
		PKG="./infra"
		echo "  📂 ROOT=$ROOT (pwd=$(pwd))"
		CONTENT_JSON=$(mktemp) && trap "rm -f $CONTENT_JSON" EXIT
		echo "  ⏳ Exporting king_content (may take 1–2 min)..."
		cue export "$PKG" -e king_content --out json > "$CONTENT_JSON" || { echo "❌ cue export king_content failed"; exit 1; }
		echo "  ⏳ Exporting order..."
		order_json=$(cue export "$PKG" -e order --out json) || { echo "❌ cue export order failed"; exit 1; }
		echo "  📝 Writing root files..."
		echo "$order_json" | jq -c '.[]' | while read -r path; do
		  dir=$(dirname "$ROOT/$path")
		  mkdir -p "$dir"
		  content=$(jq -r --arg p "$path" '.[$p] // empty' "$CONTENT_JSON")
		  [ -z "$content" ] && { echo "  ⚠ skip $path (empty)"; continue; }
		  [ -f "$ROOT/$path" ] && chmod 644 "$ROOT/$path"
		  printf '%s' "$content" > "$ROOT/$path"
		  case "$path" in (*.json|*.code-workspace) jq -e . "$ROOT/$path" >/dev/null 2>&1 && jq . "$ROOT/$path" > "$ROOT/$path.tmp" && mv "$ROOT/$path.tmp" "$ROOT/$path" ;; esac
		  chmod 444 "$ROOT/$path"
		  echo "  → $path (read-only)"
		done
		cue export "$PKG" -e folder_file_outputs --out json 2>/dev/null | jq -c '.[]?' | while read -r obj; do
		  [ -z "$obj" ] && continue
		  path=$(echo "$obj" | jq -r '.path')
		  content=$(echo "$obj" | jq -r '.content')
		  [ -z "$path" ] && continue
		  [ "$content" = "null" ] && content=""
		  [ -z "$content" ] && { echo "  ⚠ skip $path (empty)"; continue; }
		  dir=$(dirname "$ROOT/$path")
		  mkdir -p "$dir"
		  [ -f "$ROOT/$path" ] && chmod 644 "$ROOT/$path"
		  printf '%s' "$content" > "$ROOT/$path"
		  chmod 444 "$ROOT/$path"
		  echo "  → $path (read-only)"
		done
		cue export "$PKG" -e folder_outputs --out json | jq -c '.[]' | while read -r obj; do
		  src=$(echo "$obj" | jq -r '.source')
		  tgt=$(echo "$obj" | jq -r '.target')
		  [ -z "$src" ] && continue
		  [ ! -d "$ROOT/$src" ] && { echo "  ⚠ skip $src → $tgt (source missing)"; continue; }
		  rm -rf "$ROOT/$tgt"
		  cp -r "$ROOT/$src" "$ROOT/$tgt"
		  echo "  → $tgt (from $src)"
		done
		echo "✅ Root config and dotfolders generated from CUE (readonly)."
		if [ ! -s "$ROOT/rice.code-workspace" ]; then
		  echo "  ⚠ rice.code-workspace empty – writing directly..."
		  cue export "$PKG" -e king_content --out json | jq -r '.["rice.code-workspace"]' > "$ROOT/rice.code-workspace" 2>/dev/null || true
		  [ -s "$ROOT/rice.code-workspace" ] && chmod 444 "$ROOT/rice.code-workspace" && echo "  → rice.code-workspace (recovered)"
		fi
		"""
}
