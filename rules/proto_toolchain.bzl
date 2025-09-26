"""Protobuf toolchain integration with Nix."""

load("@bazel_skylib//lib:shell.bzl", "shell")

def _nix_proto_toolchain_impl(ctx):
    """Implementation for nix_proto_toolchain rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    
    # Create a script that provides Protobuf toolchain from Nix
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Export Protobuf environment variables from Nix shell
export PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command which protoc | xargs dirname):$PATH
export PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command which protoc-gen-go | xargs dirname):$PATH
export PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command which protoc-gen-go-grpc | xargs dirname):$PATH
export PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command which buf | xargs dirname):$PATH
export PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command which grpcurl | xargs dirname):$PATH

# Execute the command in the Nix shell with Protobuf environment
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_proto_toolchain.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_proto_toolchain = rule(
    implementation = _nix_proto_toolchain_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
    },
    executable = True,
)
