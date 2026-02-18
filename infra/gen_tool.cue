package rice

import "tool/exec"

// gen: generuje pliki roota (config.order + king_content), potem pliki folderów z CUE (folder_file_outputs),
// na końcu kopiuje dotfoldery (folder_outputs). Uruchom z repo root: cue cmd gen ./infra
command: gen: {
	task: run: exec.Run & {
		cmd:  "bash"
		dir:  ".."
		args: ["-c", script]
	}

	script: """
		set -e
		echo "📐 Generating root config and dotfolders from CUE..."
		PKG="./infra"
		ROOT="."
		content_json=$(cue export "$PKG" -e config.king_content --out json)
		order_json=$(cue export "$PKG" -e config.order --out json)
		echo "$order_json" | jq -c '.[]' | while read -r path; do
		  content=$(echo "$content_json" | jq -r --arg p "$path" '.[$p]')
		  dir=$(dirname "$ROOT/$path")
		  mkdir -p "$dir"
		  [ -f "$ROOT/$path" ] && chmod 644 "$ROOT/$path"
		  printf '%s' "$content" > "$ROOT/$path"
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
		"""
}
