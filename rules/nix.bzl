"""Bazel rules for Nix integration with rice-dev flake."""

load("@bazel_skylib//lib:shell.bzl", "shell")

def _nix_shell_impl(ctx):
    """Implementation for nix_shell rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    
    # Create a script that enters the Nix shell
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Enter the Nix development shell
exec nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_shell.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_shell = rule(
    implementation = _nix_shell_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
    },
    executable = True,
)

def _nix_build_impl(ctx):
    """Implementation for nix_build rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    targets = ctx.attr.targets
    
    # Create a script that builds targets in the Nix shell
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Build targets in the Nix shell
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command bazel build """ + " ".join([shell.quote(t) for t in targets]) + """
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_build.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_build = rule(
    implementation = _nix_build_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
        "targets": attr.string_list(mandatory = True),
    },
    executable = True,
)

def _nix_test_impl(ctx):
    """Implementation for nix_test rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    targets = ctx.attr.targets
    
    # Create a script that tests targets in the Nix shell
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Test targets in the Nix shell
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command bazel test """ + " ".join([shell.quote(t) for t in targets]) + """
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_test.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_test = rule(
    implementation = _nix_test_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
        "targets": attr.string_list(mandatory = True),
    },
    executable = True,
)

def _nix_toolchain_impl(ctx):
    """Implementation for nix_toolchain rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    tool_name = ctx.attr.tool_name
    tool_path = ctx.attr.tool_path
    
    # Create a script that provides the tool from Nix shell
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Execute the tool in the Nix shell
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command """ + shell.quote(tool_path) + """ "$@"
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_tool.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_toolchain = rule(
    implementation = _nix_toolchain_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
        "tool_name": attr.string(mandatory = True),
        "tool_path": attr.string(mandatory = True),
    },
    executable = True,
)
