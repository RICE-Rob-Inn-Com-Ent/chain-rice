"""Rust toolchain integration with Nix."""

load("@bazel_skylib//lib:shell.bzl", "shell")

def _nix_rust_toolchain_impl(ctx):
    """Implementation for nix_rust_toolchain rule."""
    flake_path = ctx.attr.flake_path
    shell_name = ctx.attr.shell_name
    
    # Create a script that provides Rust toolchain from Nix
    script_content = """#!/usr/bin/env bash
set -euo pipefail

# Change to the flake directory
cd """ + shell.quote(flake_path) + """

# Export Rust environment variables from Nix shell
export CARGO_HOME="$PWD/.cargo"
export RUSTUP_HOME="$PWD/.rustup"
export PATH="$CARGO_HOME/bin:$PATH"
export RUST_SRC_PATH=$(nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command rustc --print sysroot)/lib/rustlib/src/rust/library

# Execute the command in the Nix shell with Rust environment
nix --extra-experimental-features "nix-command flakes" develop .#""" + shell.quote(shell_name) + """ --command "$@"
"""
    
    script_file = ctx.actions.declare_file(ctx.label.name + "_rust_toolchain.sh")
    ctx.actions.write(script_file, script_content, is_executable = True)
    
    return [DefaultInfo(
        executable = script_file,
        runfiles = ctx.runfiles(files = [])
    )]

nix_rust_toolchain = rule(
    implementation = _nix_rust_toolchain_impl,
    attrs = {
        "flake_path": attr.string(mandatory = True),
        "shell_name": attr.string(mandatory = True),
    },
    executable = True,
)
