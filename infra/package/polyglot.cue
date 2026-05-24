package package

import "list"

// MASON polyglot package — `polyglot.cue` + `cue/*.cue` (languages only). Семантично це «tool entry» для `cue export` поруч з `infra/out/_tool.cue` (`cue cmd`), але basename **не** `_tool.cue` — CUE ігнорує `*_tool.cue` поза `cue cmd` (див. `DIAGRAM.puml`, `cue help inputs`). Buck slice: `infra/build/build.cue` + `infra/build/cue/*.cue` (`buildPlan` in `cue/pack.cue`; `//infra/build:render_build`).
// Workspace (repo root) files: `infra/out/cue/*.cue` + `//infra/out:render_workspace` — not imported here.
//
// Buck: `buck2 build //infra/build:render_build` then `cue export polyglot.cue … ../build/build.cue ../build/cue/*.cue …`.
//
// Genrules (//infra/package:BUCK):
//   validate_package_cue — cue export packageIndex, …, emitTextFiles
//   render_all — cue cmd emit ./infra/out/_tool.cue (package + workspace emitTextFiles)
//
// emitTextFiles — package cells only {path, content}; workspace roll-up lives in infra/out/cue/pack.cue.

// Buck2 slice — same package as other `language*`; data from `infra/build/cue/pack.cue` (`buildPlan`).
languageBuck: {
	manager:      "buck2"
	manifestFile: "BUCK"
	ecosystem:    "buck2"
	manifests: buildPlan.buckPaths

	render: {
		buckFiles: [for p in manifests {
			path: p
			kind: "buck-manifest"
			data: {note: "Rendered by //infra/build:render_build (infra/build/cue/pack.cue)"}
		}]
	}
}

// packageLanguages — source of truth by language / ecosystem.
packageLanguages: {
	rust:    languageRust
	python:  languagePython
	dart:    languageDart
	go:      languageGo
	elixir:  languageElixir
	haskell: languageHaskell
	zig:     languageZig
	buck2:   languageBuck
}

// packageIndex — stable projection for tooling.
packageIndex: {
	rustCargo:          packageLanguages.rust.manifests
	pythonPyproject:    packageLanguages.python.manifests
	dartPubspec:        packageLanguages.dart.manifests
	goMod:              packageLanguages.go.manifests
	elixirMix:          packageLanguages.elixir.manifests
	haskellPackageYaml: packageLanguages.haskell.manifests
	zigBuild:           packageLanguages.zig.manifests
	buck:               packageLanguages.buck2.manifests
}

// packageLanguagesFull — full payloads (manifests, constraints, render hints).
packageLanguagesFull: packageLanguages

// renderPlan — paths to generated manifests (execution-facing).
renderPlan: {
	manifestsByLanguage: {
		rust:    list.Concat([[packageLanguages.rust.render.workspaceToml.path], [for m in packageLanguages.rust.render.moduleTomls {m.path}]])
		python:  [for p in packageLanguages.python.render.pyprojectTomls {p.path}]
		dart:    [for p in packageLanguages.dart.render.pubspecYamls {p.path}]
		go:      [for m in packageLanguages.go.render.goMods {m.path}]
		elixir:  [for m in packageLanguages.elixir.render.mixProjects {m.path}]
		haskell: [packageLanguages.haskell.render.packageYaml.path]
		zig:     [packageLanguages.zig.render.buildZig.path, packageLanguages.zig.render.buildZon.path, "base/security/build.zig.zon"]
		buck2:   [for b in packageLanguages.buck2.render.buckFiles {b.path}]
	}

	renderArtifacts: {
		rust: {
			workspace: packageLanguages.rust.render.workspaceToml
			modules:   packageLanguages.rust.render.moduleTomls
		}
		python:  packageLanguages.python.render.pyprojectTomls
		dart:    packageLanguages.dart.render.pubspecYamls
		go:      packageLanguages.go.render.goMods
		elixir:  packageLanguages.elixir.render.mixProjects
		haskell: packageLanguages.haskell.render.packageYaml
		zig: {
			buildZig: packageLanguages.zig.render.buildZig
			buildZon: packageLanguages.zig.render.buildZon
		}
		buck2: packageLanguages.buck2.render.buckFiles
	}

	// Paths touched by ROLE emitTextFiles (repo-root paths live in infra/out/cue/).
	toolingPaths: [
		".buckconfig",
		"base/.clippy.toml",
		"base/rustfmt.toml",
		"base/fourmolu.yaml",
		"base/.hlint.yaml",
		"base/calc/calc.cabal",
		"base/package.yaml",
		"base/build.zig",
		"base/build.zig.zon",
		"base/security/build.zig.zon",
		"frontend/lang/slang.yaml",
	]
}

// Merged text-file emission for ROLE cells (disk write: cue cmd emit ./infra/out/_tool.cue).
emitTextFiles: list.Concat([
	languageRust.emitFiles,
	languageHaskell.emitFiles,
	languageZig.emitFiles,
	languageDart.emitFiles,
	languagePython.emitFiles,
	buildPlan.emitFiles,
])
