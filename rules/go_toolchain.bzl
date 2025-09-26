"""Go toolchain integration with Nix."""

load("@bazel_skylib//lib:shell.bzl", "shell")

def _nix_go_toolchain_impl(ctx):
    """Implementation for nix_go_toolchain rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    
    # Create a script that provides Go toolchain from Nix
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Export Go environment variables from Nix shell
export GOROOT=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command go env GOROOT)
export GOPATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command go env GOPATH)
export PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command go env GOROOT)/bin:$PATH

# Execute the command in the Nix shell with Go environment
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_go_toolchain.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_go_toolchain = rule(
    implementation = _nix_go_toolchain_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
    },
    executable = True,
)
