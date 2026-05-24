package build

import "strings"

// SAGE / function — per-package Buck2 manifests (`function/<module>/BUCK`).
// Each `check` genrule watches only that package (rebuild: buck2 build //function/<module>:check).

_pythonScriptSuffix: "touch \"$OUT\"\n"

#PythonCheck: {
	module!: string
	srcs!:   string
	out: _genruleOpen + srcs + _genruleMid + strings.Join([
		"set -euo pipefail\n",
		"REPO=$(git rev-parse --show-toplevel)\n",
		"export PATH=\"$REPO/.pixi/envs/default/bin:$HOME/.local/bin:/usr/bin:$PATH\"\n",
		"cd \"$REPO/function\"\n",
		"uv sync\n",
		"uv run ruff check ",
		module,
		"/src\n",
		_pythonScriptSuffix,
	], "") + _genruleClose
}

#PythonCheckMojo: {
	module!: string
	srcs!:   string
	out: _genruleOpen + srcs + _genruleMid + strings.Join([
		"set -euo pipefail\n",
		"REPO=$(git rev-parse --show-toplevel)\n",
		"export PATH=\"$REPO/.pixi/envs/default/bin:$HOME/.local/bin:/usr/bin:$PATH\"\n",
		"cd \"$REPO/function\"\n",
		"uv sync\n",
		"uv run ruff check ",
		module,
		"/src\n",
		"if command -v mojo >/dev/null 2>&1; then\n",
		"  mkdir -p \"$REPO/function/",
		module,
		"/mojo/__mojocache__\"\n",
		"  mojo package \"$REPO/function/",
		module,
		"/mojo\" -o \"$REPO/function/",
		module,
		"/mojo/__mojocache__/sage.mojopkg\"\n",
		"else\n",
		"  echo \"mojo not on PATH — add mojo to root pixi.toml\" >&2\n",
		"  exit 1\n",
		"fi\n",
		_pythonScriptSuffix,
	], "") + _genruleClose
}

_sageModules: [
	{name: "agent"},
	{name: "job"},
	{name: "simulation"},
	{name: "vector"},
]

_sageBody: {
	agent: (#PythonCheck & {
		module: "agent"
		srcs:   "    srcs = glob([\"pyproject.toml\", \"../pyproject.toml\", \"src/**/*.py\"]),\n"
	}).out
	simulation: (#PythonCheck & {
		module: "simulation"
		srcs:   "    srcs = glob([\"pyproject.toml\", \"../pyproject.toml\", \"src/**/*.py\"]),\n"
	}).out
	vector: (#PythonCheck & {
		module: "vector"
		srcs:   "    srcs = glob([\"pyproject.toml\", \"../pyproject.toml\", \"src/**/*.py\"]),\n"
	}).out
	job: (#PythonCheckMojo & {
		module: "job"
		srcs:   "    srcs = glob([\"pyproject.toml\", \"../pyproject.toml\", \"src/**/*.py\", \"mojo/**/*.mojo\"]),\n"
	}).out
}

functionBuck: {
	modules: [for m in _sageModules {m.name}]

	sageEmitFiles: [
		for m in _sageModules {
			path: "function/\(m.name)/BUCK"
			content: strings.Join([
				"# MASON-generated Buck2 manifest — do not edit by hand.\n",
				"# Source: infra/build/cue/function.cue — watches function/\(m.name)\n",
				"# Rebuild: buck2 build '//function/\(m.name):check'\n\n",
				_sageBody[m.name],
			], "")
		},
	]
}
