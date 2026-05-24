package build

import (
	"list"
	"strings"
)

// CLERK / base — per-package Buck2 manifests (`base/<module>/BUCK`).
// Each check genrule watches only that tree (rebuild target: buck2 build //base/<module>:check).

_genruleOpen:  "genrule(\n    name = \"check\",\n"
_genruleMid:   "    out = \"check.stamp\",\n    cmd = \"\"\"\n"
_genruleClose: "\"\"\",\n    visibility = [\"PUBLIC\"],\n)\n"

#RustCheck: {
	crate!: string
	_script: strings.Join([
		"set -euo pipefail\n",
		"REPO=$(git rev-parse --show-toplevel)\n",
		"export PATH=\"$REPO/.pixi/envs/default/bin:$HOME/.cargo/bin:/usr/bin:$PATH\"\n",
		"cd \"$REPO/base\"\n",
		"if [ -f Cargo.lock ]; then\n",
		"  cargo build -p ",
		crate,
		" --locked\n",
		"else\n",
		"  cargo build -p ",
		crate,
		"\n",
		"fi\n",
		"touch \"$OUT\"\n",
	], "")
	out: _genruleOpen +
		"    srcs = glob([\"src/**/*.rs\", \"Cargo.toml\", \"../Cargo.toml\"]),\n" +
		_genruleMid +
		_script +
		_genruleClose
}

_cabalCheck: _genruleOpen +
	"    srcs = glob([\"lib/**/*.hs\", \"test/**/*.hs\", \"calc.cabal\"]),\n" +
	_genruleMid +
	strings.Join([
		"set -euo pipefail\n",
		"REPO=$(git rev-parse --show-toplevel)\n",
		"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/bin:$PATH\"\n",
		"cd \"$REPO/base/calc\"\n",
		"cabal build all\n",
		"touch \"$OUT\"\n",
	], "") +
	_genruleClose

_zigCheck: _genruleOpen +
	"    srcs = glob([\"src/**/*.zig\", \"build.zig.zon\", \"../build.zig\", \"../build.zig.zon\"]),\n" +
	_genruleMid +
	strings.Join([
		"set -euo pipefail\n",
		"REPO=$(git rev-parse --show-toplevel)\n",
		"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/bin:$PATH\"\n",
		"cd \"$REPO/base\"\n",
		"zig build verify\n",
		"touch \"$OUT\"\n",
	], "") +
	_genruleClose

_clerkModules: [
	{name: "calc", kind: "cabal"},
	{name: "contract", kind: "rust", crate: "contract"},
	{name: "mint", kind: "rust", crate: "mint"},
	{name: "policies", kind: "rust", crate: "policies"},
	{name: "private", kind: "rust", crate: "private"},
	{name: "security", kind: "zig"},
]

_clerkBody: {
	calc:      _cabalCheck
	contract:  (#RustCheck & {crate: "contract"}).out
	mint:      (#RustCheck & {crate: "mint"}).out
	policies:  (#RustCheck & {crate: "policies"}).out
	private:   (#RustCheck & {crate: "private"}).out
	security:  _zigCheck
}

baseBuck: {
	modules: list.Concat([
		["bench"],
		[for m in _clerkModules {m.name}],
	])

	clerkEmitFiles: [
		for m in _clerkModules {
			path: "base/\(m.name)/BUCK"
			content: strings.Join([
				"# MASON-generated Buck2 manifest — do not edit by hand.\n",
				"# Source: infra/build/cue/base.cue — watches base/\(m.name)\n",
				"# Rebuild: buck2 build '//base/\(m.name):check'\n\n",
				_clerkBody[m.name],
			], "")
		},
	]
}
