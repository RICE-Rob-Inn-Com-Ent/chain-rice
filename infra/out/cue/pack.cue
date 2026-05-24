package workspace

import "list"

// Path pack + workspace `emitTextFiles` roll-up (`cue cmd emit ./infra/out/_tool.cue`).
// Slice bodies: sibling `*.cue` (`emitFiles_*`); materialize via jq in `cue cmd emit` (`_tool.cue`).

pathPack: {
	// `cue cmd embed` reads these files from repo root and rewrites matching `*.cue` slices.
	embed: {
		vcs: [".gitignore", ".gitattributes"]
		docsFromRepo: [
			"README.md",
			"CONTRIBUTING.md",
			"CODE_OF_CONDUCT.md",
			"SECURITY.md",
			"LICENSE.md",
		]
		ws: ["rice.code-workspace", ".editorconfig"]
		hooks: [
			"lefthook.yml",
			".lefthook-local.yml",
			".vale.ini",
			"cliff.toml",
			".convco.toml",
		]
		supply: ["renovate.json", ".sops.yaml"]
		ci: ["dagger.json", "taplo.toml"]
		recordings: ["vhs.tape"]
		// Root tooling trees + aider — `buck2 build //infra/out:gen_workspace_cue` expands `dirPrefixes` with `git ls-files`.
		tooling: {
			files: [".aider.conf.yml", ".aiderignore"]
			dirPrefixes: [".github/", ".cursor/", ".reuse/"]
		}
		// Basenames under `cue/` that gen_workspace rewrites (same dir as this `pack.cue`).
		outCue: {
			vcs:   "vcs.cue"
			ws:    "ws.cue"
			pixi:  "pixi.cue"
			hooks: "hooks.cue"
			supply: "supply.cue"
			ci:    "ci.cue"
			vhs:     "vhs.cue"
			tooling: "tooling.cue"
		}
		// Docs slice output (package workspace, same dir as `pack.cue` — `cue export … docs.cue`).
		docsCue: "infra/out/cue/docs.cue"
	}

	// `.env` / `.envrc` targets (repo-relative). Same catalog appended to each `.env`.
	env: {
		direnv: ".envrc"
		slices: [
			"function/.env",
			"frontend/.env",
			"base/.env",
			"service/.env",
			"infra/.env",
		]
	}
}

// All root paths this package materializes (order = concat order).
emitTextFiles: list.Concat([
	emitFiles_vcs,
	emitFiles_env,
	emitFiles_docs,
	emitFiles_mkdocs,
	emitFiles_ws,
	emitFiles_pixi,
	emitFiles_hooks,
	emitFiles_supply,
	emitFiles_ci,
	emitFiles_vhs,
	emitFiles_tooling,
])
