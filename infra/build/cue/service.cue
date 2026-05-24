package build

import "strings"

// SMITH / service — per-package Buck2 manifests (`service/<module>/BUCK`).
// Each `check` genrule watches only that package (rebuild: buck2 build //service/<module>:check).

_scriptSuffix: "touch \"$OUT\"\n"

#GoCheck: {
	module!: string
	out: _genruleOpen +
		"    srcs = glob([\"go.mod\", \"go.sum\", \"src/**/*.go\"]),\n" +
		_genruleMid +
		strings.Join([
			"set -euo pipefail\n",
			"REPO=$(git rev-parse --show-toplevel)\n",
			"export PATH=\"$REPO/.pixi/envs/default/bin:$HOME/go/bin:/usr/bin:$PATH\"\n",
			"cd \"$REPO/service/",
			module,
			"\"\n",
			"if [ -f go.sum ]; then\n",
			"  go build -mod=readonly ./...\n",
			"else\n",
			"  go build ./...\n",
			"fi\n",
			_scriptSuffix,
		], "") +
		_genruleClose
}

#ElixirCheck: {
	module!: string
	out: _genruleOpen +
		"    srcs = glob([\"mix.exs\", \"lib/**/*.ex\", \"../mix.exs\", \"../mix.lock\", \"../config/config.exs\"]),\n" +
		_genruleMid +
		strings.Join([
			"set -euo pipefail\n",
			"REPO=$(git rev-parse --show-toplevel)\n",
			"export PATH=\"$REPO/.pixi/envs/default/bin:$HOME/.mix/escripts:$HOME/.local/bin:/usr/bin:$PATH\"\n",
			"cd \"$REPO/service\"\n",
			"mix local.hex --force\n",
			"mix local.rebar --force\n",
			"mix deps.get\n",
			"mix compile --warnings-as-errors\n",
			_scriptSuffix,
		], "") +
		_genruleClose
}

_smithModules: [
	{name: "auth", kind: "go"},
	{name: "connection", kind: "elixir"},
	{name: "core", kind: "elixir"},
	{name: "database", kind: "go"},
	{name: "guard", kind: "elixir"},
	{name: "messages", kind: "elixir"},
	{name: "pipeline", kind: "elixir"},
	{name: "queue", kind: "go"},
	{name: "token", kind: "go"},
	{name: "web", kind: "go"},
]

_smithBody: {
	auth: (#GoCheck & {module: "auth"}).out
	connection: (#ElixirCheck & {module: "connection"}).out
	core: (#ElixirCheck & {module: "core"}).out
	database: (#GoCheck & {module: "database"}).out
	guard: (#ElixirCheck & {module: "guard"}).out
	messages: (#ElixirCheck & {module: "messages"}).out
	pipeline: (#ElixirCheck & {module: "pipeline"}).out
	queue: (#GoCheck & {module: "queue"}).out
	token: (#GoCheck & {module: "token"}).out
	web: (#GoCheck & {module: "web"}).out
}

serviceBuck: {
	modules: [for m in _smithModules {m.name}]

	smithEmitFiles: [
		for m in _smithModules {
			path: "service/\(m.name)/BUCK"
			content: strings.Join([
				"# MASON-generated Buck2 manifest — do not edit by hand.\n",
				"# Source: infra/build/cue/service.cue — watches service/\(m.name)\n",
				"# Rebuild: buck2 build '//service/\(m.name):check'\n\n",
				_smithBody[m.name],
			], "")
		},
	]
}
