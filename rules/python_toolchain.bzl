"""Python toolchain integration with Nix."""

load("@bazel_skylib//lib:shell.bzl", "shell")

def _nix_python_toolchain_impl(ctx):
    """Implementation for nix_python_toolchain rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    
    # Create a script that provides Python toolchain from Nix
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Export Python environment variables from Nix shell
export PYTHONPATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command python -c "import sys; print(':'.join(sys.path))")
export PYTHONNOUSERSITE=1
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Execute the command in the Nix shell with Python environment
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_python_toolchain.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_python_toolchain = rule(
    implementation = _nix_python_toolchain_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
    },
    executable = True,
)
