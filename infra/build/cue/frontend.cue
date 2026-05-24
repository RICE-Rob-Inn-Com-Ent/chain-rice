package build

import "strings"

// BARD / frontend — per-package Buck2 manifests (`frontend/<module>/BUCK`).
// Each `check` genrule watches only that package (rebuild: buck2 build //frontend/<module>:check).

_dartScriptSuffix: "dart analyze --fatal-warnings lib\ntouch \"$OUT\"\n"

_dartCodegenStep: "dart run build_runner build --delete-conflicting-outputs\n"

#DartCheck: {
	module!:  string
	srcs!:    string
	codegen!: bool
	out: _genruleOpen + srcs + _genruleMid + strings.Join([
		"set -euo pipefail\n",
		"REPO=$(git rev-parse --show-toplevel)\n",
		"export PATH=\"$REPO/.pixi/envs/default/bin:$HOME/.pub-cache/bin:/usr/bin:$PATH\"\n",
		"cd \"$REPO/frontend\"\n",
		"dart pub get\n",
		"cd \"$REPO/frontend/",
		module,
		"\"\n",
		if codegen {
			_dartCodegenStep
		},
		_dartScriptSuffix,
	], "") + _genruleClose
}

#OdinCheck: {
	module!: string
	out: _genruleOpen +
		"    srcs = glob([\"src/**/*.odin\"]),\n" +
		_genruleMid +
		strings.Join([
			"set -euo pipefail\n",
			"REPO=$(git rev-parse --show-toplevel)\n",
			"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/bin:$PATH\"\n",
			"if ! command -v odin >/dev/null 2>&1; then\n",
			"  echo \"odin not on PATH — run: pixi run install-odin\" >&2\n",
			"  exit 1\n",
			"fi\n",
			"cd \"$REPO/frontend/",
			module,
			"\"\n",
			"odin check src/ -vet\n",
			"touch \"$OUT\"\n",
		], "") +
		_genruleClose
}

_bardModules: [
	{name: "audio"},
	{name: "browser"},
	{name: "client"},
	{name: "content"},
	{name: "lang"},
	{name: "model"},
	{name: "rule"},
	{name: "vendor"},
	{name: "video"},
]

_bardBody: {
	audio: (#OdinCheck & {module: "audio"}).out
	vendor: (#OdinCheck & {module: "vendor"}).out
	video: (#OdinCheck & {module: "video"}).out

	browser: (#DartCheck & {
		module:  "browser"
		codegen: false
		srcs:    "    srcs = glob([\"pubspec.yaml\", \"../pubspec.yaml\", \"lib/**/*.dart\"]),\n"
	}).out
	content: (#DartCheck & {
		module:  "content"
		codegen: false
		srcs:    "    srcs = glob([\"pubspec.yaml\", \"../pubspec.yaml\", \"lib/**/*.dart\"]),\n"
	}).out
	client: (#DartCheck & {
		module:  "client"
		codegen: true
		srcs:    "    srcs = glob([\"pubspec.yaml\", \"../pubspec.yaml\", \"lib/**/*.dart\"]),\n"
	}).out
	lang: (#DartCheck & {
		module:  "lang"
		codegen: true
		srcs:    "    srcs = glob([\"pubspec.yaml\", \"../pubspec.yaml\", \"slang.yaml\", \"lib/**/*.dart\", \"lib/i18n/**/*.json\"]),\n"
	}).out
	model: (#DartCheck & {
		module:  "model"
		codegen: true
		srcs:    "    srcs = glob([\"pubspec.yaml\", \"../pubspec.yaml\", \"lib/**/*.dart\"]),\n"
	}).out
	rule: (#DartCheck & {
		module:  "rule"
		codegen: true
		srcs:    "    srcs = glob([\"pubspec.yaml\", \"../pubspec.yaml\", \"lib/**/*.dart\"]),\n"
	}).out
}

frontendBuck: {
	modules: [for m in _bardModules {m.name}]

	bardEmitFiles: [
		for m in _bardModules {
			path: "frontend/\(m.name)/BUCK"
			content: strings.Join([
				"# MASON-generated Buck2 manifest — do not edit by hand.\n",
				"# Source: infra/build/cue/frontend.cue — watches frontend/\(m.name)\n",
				"# Rebuild: buck2 build '//frontend/\(m.name):check'\n\n",
				_bardBody[m.name],
			], "")
		},
	]
}
