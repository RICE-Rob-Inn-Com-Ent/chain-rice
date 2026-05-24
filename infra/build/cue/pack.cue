package build

import "list"

// MASON build — Buck2 `.buckconfig`, cell `BUCK` paths, and stub emits.
// Role module lists: `base.cue`, `function.cue`, `frontend.cue`, `service.cue`, `infra.cue` (mason/infra cells).
// Validate / render: `buck2 build //infra/build:validate_build_cue` / `:render_build`.

_buckHeader: #"""
# MASON-generated Buck2 manifest — do not edit by hand.
# Source: infra/build/cue/pack.cue + //infra/build:render_build
"""#

_buckConfig: #"""
# MASON-generated — do not edit by hand.
# Source: infra/build/cue/pack.cue + //infra/build:render_build
# Buck2 + bundled prelude (cells, aliases, ignores).

[cells]
    root = .
    prelude = prelude
    toolchains = toolchains
    none = none

[cell_aliases]
    config = prelude
    ovr_config = prelude
    fbcode = none
    fbsource = none
    fbcode_macros = none
    buck = none

[external_cells]
    prelude = bundled

[parser]
    target_platform_detector_spec = \
        target:root//...->prelude//platforms:default \
        target:prelude//...->prelude//platforms:default \
        target:toolchains//...->prelude//platforms:default

[build]
    threads = 0
    engine = buck2
    execution_platforms = prelude//platforms:default
    default_target_platform = prelude//platforms:default

[alias]
    all     = //...
    king    = //base/mint/...
    mason   = //infra/...
    smith   = //service/...
    sage    = //function/...
    bard    = //frontend/...
    clerk   = //base/contract:check //base/mint:check //base/policies:check //base/private:check //base/util:check //base/bench:check //base/calc:check //base/security:check
    chief   = //base/mint/... //custom/...

[cache]
    mode = dir
    dir = .buck-cache
    dir_max_size_gb = 20

[remoteexecution]
    enabled = false

[download]
    max_number_of_http_connections = 16

[project]
    ignore = \
        .git, \
        .envrc, \
        .rice-model, \
        .rice-model-base, \
        .rice-hardware.json, \
        .rice-compute.json, \
        secrets.enc.env, \
        node_modules, \
        __pycache__, \
        .dart_tool, \
        .pub-cache, \
        _build, \
        deps, \
        .pixi, \
        buck-out, \
        .buck-cache, \
        base/target, \
        base/.zig-cache, \
        base/zig-out

[go]
    root = service/
    vendor = service/vendor/
    cover_tool = cover
    go_flags = -mod=vendor

[rust]
    edition = 2021
    rustc_flags = -D warnings

[python]
    interpreter = .pixi/envs/default/bin/python
    version = 3.12
    package_style = inplace

[cxx]
    default_platform = linux-x86_64
    combined_preproc = true

[test]
    timeout_ms = 60000
    parallel = true
    always_show_test_output = true

[log]
    max_traces = 50
    chrome_trace_format = true

[ui]
    show_progress = true
    thread_line_limit = 16
    show_full_failed_command = true

"""#

_clerkBuckPaths: [for f in baseBuck.clerkEmitFiles {f.path}]
_bardBuckPaths:  [for f in frontendBuck.bardEmitFiles {f.path}]
_sageBuckPaths:  [for f in functionBuck.sageEmitFiles {f.path}]
_smithBuckPaths: [for f in serviceBuck.smithEmitFiles {f.path}]
_masonBuckPaths:  [for f in infraBuck.masonEmitFiles {f.path}]
_generatedBuckPaths: list.Concat([_clerkBuckPaths, _bardBuckPaths, _sageBuckPaths, _smithBuckPaths, _masonBuckPaths])

// Derived from role slices — clerk/base, bard/frontend, sage/function, smith/service, mason/infra.
buildPlan: {
	buckPaths: list.SortStrings(list.Concat([
		[for m in baseBuck.modules {"base/\(m)/BUCK"}],
		[for m in functionBuck.modules {"function/\(m)/BUCK"}],
		[for m in frontendBuck.modules {"frontend/\(m)/BUCK"}],
		[for m in infraBuck.modules {"infra/\(m)/BUCK"}],
		[for m in serviceBuck.modules {"service/\(m)/BUCK"}],
	]))

	_stubBuckPaths: [
		for p in buckPaths if !list.Contains(_generatedBuckPaths, p) {
			p
		}
	]

	emitFiles: list.Concat([
		[{
			path:    ".buckconfig"
			content: _buckConfig
		}],
		baseBuck.clerkEmitFiles,
		frontendBuck.bardEmitFiles,
		functionBuck.sageEmitFiles,
		serviceBuck.smithEmitFiles,
		infraBuck.masonEmitFiles,
		[for p in _stubBuckPaths {
			path:    p
			content: _buckHeader
		}],
	])
}
