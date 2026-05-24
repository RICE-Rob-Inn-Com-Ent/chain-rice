package build

import "strings"

// MASON / infra — Buck cells at `infra/{docker,docs,k8s,out,package,proto,terraform}/BUCK`.
// Each target watches only its module tree (rebuild: buck2 build '//infra/<module>:…').

_masonPath: "set -euo pipefail\nREPO=$(git rev-parse --show-toplevel)\nexport PATH=\"$REPO/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"\n"

#DockerGen: {
	out: strings.Join([
		"genrule(\n",
		"    name = \"gen_docker\",\n",
		"    srcs = glob([\"docker.cue\", \"cue/**/*.cue\"]),\n",
		"    out = \"gen_docker.stamp\",\n",
		"    cmd = \"\"\"\n",
		_masonPath,
		"cd \"$REPO\"\n",
		"cue cmd gen ./infra/_tool.cue\n",
		"touch \"$OUT\"\n",
		"\"\"\",\n",
		"    visibility = [\"PUBLIC\"],\n",
		")\n\n",
		"genrule(\n",
		"    name = \"check\",\n",
		"    srcs = glob([\"docker.cue\", \"cue/**/*.cue\"]),\n",
		"    out = \"check.stamp\",\n",
		"    cmd = \"\"\"\n",
		_masonPath,
		"cd \"$REPO\"\n",
		"shopt -s globstar nullglob\n",
		"files=(./infra/docker/_tool.cue ./infra/docker/cue/**/*.cue ./infra/gen/chief/docker_project.cue)\n",
		"cue vet \"${files[@]}\"\n",
		"touch \"$OUT\"\n",
		"\"\"\",\n",
		"    visibility = [\"PUBLIC\"],\n",
		")\n",
	], "")
}

#DocsCheck: {
	out: _genruleOpen +
		"    srcs = glob([\"docs.cue\", \"DIAGRAM.puml\", \"*.md\"]),\n" +
		_genruleMid +
		_masonPath +
		"cd \"$REPO\"\ncue vet ./infra/docs/docs.cue\n" +
		_scriptSuffix +
		_genruleClose
}

#K8sGen: {
	out: strings.Join([
		"genrule(\n",
		"    name = \"gen_kubernetes_cue\",\n",
		"    srcs = glob([\"_tool.cue\", \"cue/**/*.cue\"]),\n",
		"    out = \"gen_kubernetes_cue.stamp\",\n",
		"    cmd = \"\"\"\n",
		_masonPath,
		"cd \"$REPO\"\n",
		"shopt -s globstar nullglob\n",
		"files=(./infra/k8s/_tool.cue ./infra/k8s/cue/**/*.cue ./infra/gen/chief/k8s_project.cue)\n",
		"cue vet \"${files[@]}\"\n",
		"cue cmd genK8s \"${files[@]}\"\n",
		"touch \"$OUT\"\n",
		"\"\"\",\n",
		"    visibility = [\"PUBLIC\"],\n",
		")\n\n",
		"genrule(\n",
		"    name = \"check\",\n",
		"    srcs = glob([\"_tool.cue\", \"cue/**/*.cue\"]),\n",
		"    out = \"check.stamp\",\n",
		"    cmd = \"\"\"\n",
		_masonPath,
		"cd \"$REPO\"\n",
		"shopt -s globstar nullglob\n",
		"files=(./infra/k8s/_tool.cue ./infra/k8s/cue/**/*.cue ./infra/gen/chief/k8s_project.cue)\n",
		"cue vet \"${files[@]}\"\n",
		"touch \"$OUT\"\n",
		"\"\"\",\n",
		"    visibility = [\"PUBLIC\"],\n",
		")\n",
	], "")
}

#ProtoCheck: {
	out: _genruleOpen +
		"    srcs = glob([\"cue/*.cue\", \"buf.yaml\", \"buf.gen.yaml\", \"DIAGRAM.puml\"]),\n" +
		_genruleMid +
		_masonPath +
		"cd \"$REPO\"\n" +
		"cue vet ./infra/proto/cue/...\n" +
		"if command -v buf >/dev/null 2>&1 && [ -d node/proto ]; then buf lint -f infra/proto/buf.yaml; fi\n" +
		_scriptSuffix +
		_genruleClose
}

#TerraformGen: {
	out: strings.Join([
		"genrule(\n",
		"    name = \"gen_opentofu_variables\",\n",
		"    srcs = glob([\"cue/*.cue\", \"_tool.cue\"]),\n",
		"    out = \"gen_opentofu_variables.stamp\",\n",
		"    cmd = \"\"\"\n",
		_masonPath,
		"cd \"$REPO\"\n",
		"shopt -s nullglob\n",
		"tf=(./infra/terraform/_tool.cue ./infra/terraform/cue/*.cue)\n",
		"cue vet \"${tf[@]}\"\n",
		"cue cmd gen \"${tf[@]}\"\n",
		"touch \"$OUT\"\n",
		"\"\"\",\n",
		"    visibility = [\"PUBLIC\"],\n",
		")\n\n",
		"genrule(\n",
		"    name = \"check\",\n",
		"    srcs = glob([\"cue/*.cue\", \"_tool.cue\"]),\n",
		"    out = \"check.stamp\",\n",
		"    cmd = \"\"\"\n",
		_masonPath,
		"cd \"$REPO\"\n",
		"shopt -s nullglob\n",
		"tf=(./infra/terraform/_tool.cue ./infra/terraform/cue/*.cue)\n",
		"cue vet \"${tf[@]}\"\n",
		"touch \"$OUT\"\n",
		"\"\"\",\n",
		"    visibility = [\"PUBLIC\"],\n",
		")\n",
	], "")
}

_packageBuck: strings.Join([
	"# MASON — polyglot package CUE (`polyglot.cue` + `cue/*.cue` + `infra/build/build.cue` + `infra/build/cue/*.cue`).\n",
	"# Rebuild: buck2 build '//infra/package:validate_package_cue' '//infra/package:render_all'\n\n",
	"genrule(\n",
	"    name = \"validate_package_cue\",\n",
	"    srcs = glob([\"polyglot.cue\", \"cue/*.cue\", \"../build/build.cue\", \"../build/cue/*.cue\"]),\n",
	"    out = \"validate.stamp\",\n",
	"    cmd = \"\"\"set -euo pipefail\n",
	"cd \"$SRCDIR\"\n",
	"REPO=`git rev-parse --show-toplevel`\n",
	"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"\n",
	"cd \"$REPO/infra/package\"\n",
	"shopt -s nullglob\n",
	"build_inputs=(\"$REPO/infra/build/build.cue\")\n",
	"readarray -t build_cue < <(find \"$REPO/infra/build/cue\" -name '*.cue' | LC_ALL=C sort -u)\n",
	"build_inputs+=(\"${build_cue[@]}\")\n",
	"pkg=(cue/*.cue)\n",
	"readarray -t pksort < <(printf '%s\\n' \"${pkg[@]}\" | LC_ALL=C sort -u)\n",
	"for e in packageIndex packageLanguages packageLanguagesFull renderPlan emitTextFiles; do\n",
	"  cue export polyglot.cue \"${pksort[@]}\" \"${build_inputs[@]}\" -e \"$e\" --out json > /dev/null\n",
	"done\n",
	"touch \"$OUT\"\n",
	"\"\"\",\n",
	"    visibility = [\"PUBLIC\"],\n",
	")\n\n",
	"genrule(\n",
	"    name = \"render_all\",\n",
	"    srcs = glob([\"polyglot.cue\", \"cue/*.cue\"])\n",
	"    + glob([\"../build/build.cue\", \"../build/cue/*.cue\", \"../out/_tool.cue\", \"../out/cue/*.cue\", \"../out/cue/docs.cue\", \"../docs/docs.cue\"]),\n",
	"    out = \"render_all.stamp\",\n",
	"    cmd = \"\"\"set -euo pipefail\n",
	"REPO=`git rev-parse --show-toplevel`\n",
	"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"\n",
	"cd \"$REPO\"\n",
	"if command -v buck2 >/dev/null 2>&1; then\n",
	"  buck2 build //infra/build:render_build\n",
	"fi\n",
	"cue cmd emit ./infra/out/_tool.cue\n",
	"touch \"$OUT\"\n",
	"\"\"\",\n",
	"    visibility = [\"PUBLIC\"],\n",
	")\n",
], "")

_outBuck: strings.Join([
	"# MASON — workspace: `cue/*.cue` + `_tool.cue`. Embed script: `infra/scripts/gen_workspace_cue.sh`.\n",
	"# Rebuild: buck2 build '//infra/out:validate_workspace_cue' '//infra/out:render_workspace' '//infra/out:gen_workspace_cue'\n\n",
	"genrule(\n",
	"    name = \"validate_workspace_cue\",\n",
	"    srcs = [\"_tool.cue\"] + glob([\"cue/*.cue\", \"cue/docs.cue\"]),\n",
	"    out = \"validate_workspace.stamp\",\n",
	"    cmd = \"\"\"set -euo pipefail\n",
	"REPO=`git rev-parse --show-toplevel`\n",
	"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"\n",
	"cd \"$REPO\"\n",
	"cue vet ./infra/out/...\n",
	"touch \"$OUT\"\n",
	"\"\"\",\n",
	"    visibility = [\"PUBLIC\"],\n",
	")\n\n",
	"genrule(\n",
	"    name = \"render_workspace\",\n",
	"    srcs = [\"_tool.cue\"] + glob([\"cue/*.cue\", \"cue/docs.cue\"]),\n",
	"    out = \"render_workspace.stamp\",\n",
	"    cmd = \"\"\"set -euo pipefail\n",
	"REPO=`git rev-parse --show-toplevel`\n",
	"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"\n",
	"cd \"$REPO\"\n",
	"cue cmd emit ./infra/out/_tool.cue\n",
	"touch \"$OUT\"\n",
	"\"\"\",\n",
	"    visibility = [\"PUBLIC\"],\n",
	")\n\n",
	"genrule(\n",
	"    name = \"gen_workspace_cue\",\n",
	"    srcs = [\"_tool.cue\", \"cue/pack.cue\"] + glob([\"cue/*.cue\"]) + [\"../scripts/gen_workspace_cue.sh\"],\n",
	"    out = \"gen_workspace_cue.stamp\",\n",
	"    cmd = \"\"\"set -euo pipefail\n",
	"REPO=`git rev-parse --show-toplevel`\n",
	"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"\n",
	"bash \"$REPO/infra/scripts/gen_workspace_cue.sh\"\n",
	"touch \"$OUT\"\n",
	"\"\"\",\n",
	"    visibility = [\"PUBLIC\"],\n",
	")\n\n",
	"genrule(\n",
	"    name = \"check\",\n",
	"    srcs = [\"_tool.cue\"] + glob([\"cue/*.cue\"]),\n",
	"    out = \"check.stamp\",\n",
	"    cmd = \"\"\"set -euo pipefail\n",
	"REPO=`git rev-parse --show-toplevel`\n",
	"export PATH=\"$REPO/.pixi/envs/default/bin:/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"\n",
	"cd \"$REPO\"\n",
	"cue vet ./infra/out/...\n",
	"touch \"$OUT\"\n",
	"\"\"\",\n",
	"    visibility = [\"PUBLIC\"],\n",
	")\n",
], "")

_masonBody: {
	docker:    (#DockerGen).out
	docs:      (#DocsCheck).out
	k8s:       (#K8sGen).out
	out:       _outBuck
	package:   _packageBuck
	proto:     (#ProtoCheck).out
	terraform: (#TerraformGen).out
}

_masonModules: [
	{name: "docker"},
	{name: "docs"},
	{name: "k8s"},
	{name: "out"},
	{name: "package"},
	{name: "proto"},
	{name: "terraform"},
]

infraBuck: {
	modules: [for m in _masonModules {m.name}]

	masonEmitFiles: [
		for m in _masonModules {
			path: "infra/\(m.name)/BUCK"
			content: strings.Join([
				"# MASON-generated Buck2 manifest — do not edit by hand.\n",
				"# Source: infra/build/cue/infra.cue — watches infra/\(m.name)\n",
				if m.name == "k8s" {
					"# Rebuild: buck2 build '//infra/k8s:gen_kubernetes_cue'\n\n"
				}
				if m.name == "terraform" {
					"# Rebuild: buck2 build '//infra/terraform:gen_opentofu_variables'\n\n"
				}
				if m.name == "docker" {
					"# Rebuild: buck2 build '//infra/docker:gen_docker'\n\n"
				}
				if m.name == "package" || m.name == "out" {
					""
				}
				if m.name != "k8s" && m.name != "terraform" && m.name != "docker" && m.name != "package" && m.name != "out" {
					"# Rebuild: buck2 build '//infra/\(m.name):check'\n\n"
				}
				_masonBody[m.name],
			], "")
		},
	]
}
