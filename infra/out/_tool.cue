package workspace

// MASON `infra/out` — repo-root workspace emits: `cue/*.cue` + `_tool.cue` workflow (same layout idea as `infra/k8s`).
//
// CUE accepts custom `command` blocks only from filenames ending in `_tool.cue`.
// ROLE entry next to `BUCK`: this file + data under `cue/`.
//
// | Area | Files |
// |------|--------|
// | Path pack + `emitTextFiles` roll-up | `cue/pack.cue` |
// | Slices (generated + maintained) | `cue/vcs.cue`, `cue/env.cue`, … |
// | Docs slice (canonical file) | `cue/docs.cue` (next to `pack.cue`) |
// | Tooling (`.github/`, `.cursor/`, `.reuse/`, aider) | `cue/tooling.cue` |
// | Embed from disk | `buck2 build //infra/out:gen_workspace_cue` (`_EMBED_B64` in `BUCK`) |
//
// **Validate (repo root):**
//
//	cue vet ./infra/out/...
//
// **Emit / embed:**
//
//	cue cmd emit ./infra/out/_tool.cue
//	buck2 build //infra/out:gen_workspace_cue
//
import "tool/exec"

command: emit: {
	rolePackage: exec.Run & {
		display: "MASON emit — //infra/package (polyglot.cue + merge_build.cue + cue/*.cue)"
		cmd: ["bash", "-c", #"""
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
			cd "$REPO/infra/package"
			shopt -s nullglob
			cue_files=()
			for f in cue/*.cue; do
				[[ "$(basename "$f")" == _tool.cue ]] && continue
				cue_files+=("$f")
			done
			readarray -t sorted < <(printf '%s\n' "${cue_files[@]}" | LC_ALL=C sort -u)
			cue export polyglot.cue merge_build.cue "${sorted[@]}" -e emitTextFiles --out json | jq -c '.[]' | while IFS= read -r line; do
				rel="$(jq -r .path <<<"$line")"
				mkdir -p "$(dirname "$REPO/$rel")"
				jq -r .content <<<"$line" >"$REPO/$rel"
			done
			"""#]
	}

	workspaceSlices: exec.Run & {
		$after: rolePackage
		display: "MASON emit — workspace (infra/out/cue)"
		cmd: ["bash", "-c", #"""
			set -euo pipefail
			REPO="${RICE_MONO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
			cd "$REPO/infra/out/cue"
			cue export pack.cue vcs.cue env.cue ws.cue pixi.cue hooks.cue supply.cue ci.cue vhs.cue tooling.cue docs.cue mkdocs_site.cue -e emitTextFiles --out json | jq -c '.[]' | while IFS= read -r line; do
				rel="$(jq -r .path <<<"$line")"
				mkdir -p "$(dirname "$REPO/$rel")"
				jq -r .content <<<"$line" >"$REPO/$rel"
			done
			"""#]
	}
}
