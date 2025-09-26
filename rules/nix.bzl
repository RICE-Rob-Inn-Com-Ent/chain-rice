"""
Bazel rules for integrating with Nix flakes.

This module provides rules to use Nix development environments
as Bazel toolchains and dependencies.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def _nix_shell_impl(ctx):
    """Implementation for nix_shell rule."""
    
    # Create the shell script that enters the Nix environment
    shell_script = ctx.actions.declare_file(ctx.attr.name + "_shell.sh")
    
    # Build the nix develop command
    flake_path = ctx.attr.flake_path or "."
    shell_name = ctx.attr.shell_name or "default"
    
    nix_command = "nix --extra-experimental-features 'nix-command flakes' develop {flake_path}#{shell_name}".format(
        flake_path = flake_path,
        shell_name = shell_name
    )
    
    # Create the shell script content
    script_content = """#!/bin/bash
set -euo pipefail

# Source Nix if not already available
if ! command -v nix >/dev/null 2>&1; then
    if [ -f /home/user/.nix-profile/etc/profile.d/nix.sh ]; then
        . /home/user/.nix-profile/etc/profile.d/nix.sh
    fi
fi

# Enter the Nix development shell
exec {nix_command} --command "$@"
""".format(nix_command = nix_command)
    
    ctx.actions.write(
        output = shell_script,
        content = script_content,
        is_executable = True,
    )
    
    return [
        DefaultInfo(
            executable = shell_script,
            runfiles = ctx.runfiles(files = [shell_script]),
        ),
    ]

nix_shell = rule(
    implementation = _nix_shell_impl,
    attrs = {
        "flake_path": attr.string(
            default = ".",
            doc = "Path to the Nix flake",
        ),
        "shell_name": attr.string(
            default = "default",
            doc = "Name of the Nix development shell to use",
        ),
    },
    executable = True,
    doc = "Create a shell script that enters a Nix development environment",
)

def _nix_toolchain_impl(ctx):
    """Implementation for nix_toolchain rule."""
    
    # Create a toolchain info
    toolchain_info = platform_common.ToolchainInfo(
        nix_flake_path = ctx.attr.flake_path,
        nix_shell_name = ctx.attr.shell_name,
        tools = ctx.files.tools,
    )
    
    return [toolchain_info]

nix_toolchain = rule(
    implementation = _nix_toolchain_impl,
    attrs = {
        "flake_path": attr.string(
            default = ".",
            doc = "Path to the Nix flake",
        ),
        "shell_name": attr.string(
            default = "default", 
            doc = "Name of the Nix development shell",
        ),
        "tools": attr.label_list(
            allow_files = True,
            doc = "Tools provided by this Nix environment",
        ),
    },
    doc = "Define a Nix-based toolchain for Bazel",
)

def _nix_build_impl(ctx):
    """Implementation for nix_build rule."""
    
    # Get the Nix shell command
    flake_path = ctx.attr.flake_path or "."
    shell_name = ctx.attr.shell_name or "default"
    
    nix_command = "nix --extra-experimental-features 'nix-command flakes' develop {flake_path}#{shell_name}".format(
        flake_path = flake_path,
        shell_name = shell_name
    )
    
    # Create the build script
    build_script = ctx.actions.declare_file(ctx.attr.name + "_build.sh")
    
    script_content = """#!/bin/bash
set -euo pipefail

# Source Nix if not already available
if ! command -v nix >/dev/null 2>&1; then
    if [ -f /home/user/.nix-profile/etc/profile.d/nix.sh ]; then
        . /home/user/.nix-profile/etc/profile.d/nix.sh
    fi
fi

# Run the build command in the Nix environment
{nix_command} --command bazel build {targets}
""".format(
        nix_command = nix_command,
        targets = " ".join(ctx.attr.targets)
    )
    
    ctx.actions.write(
        output = build_script,
        content = script_content,
        is_executable = True,
    )
    
    return [
        DefaultInfo(
            executable = build_script,
            runfiles = ctx.runfiles(files = [build_script]),
        ),
    ]

nix_build = rule(
    implementation = _nix_build_impl,
    attrs = {
        "flake_path": attr.string(
            default = ".",
            doc = "Path to the Nix flake",
        ),
        "shell_name": attr.string(
            default = "default",
            doc = "Name of the Nix development shell",
        ),
        "targets": attr.string_list(
            default = ["//..."],
            doc = "Bazel targets to build",
        ),
    },
    executable = True,
    doc = "Build Bazel targets within a Nix development environment",
)

def _nix_test_impl(ctx):
    """Implementation for nix_test rule."""
    
    # Get the Nix shell command
    flake_path = ctx.attr.flake_path or "."
    shell_name = ctx.attr.shell_name or "default"
    
    nix_command = "nix --extra-experimental-features 'nix-command flakes' develop {flake_path}#{shell_name}".format(
        flake_path = flake_path,
        shell_name = shell_name
    )
    
    # Create the test script
    test_script = ctx.actions.declare_file(ctx.attr.name + "_test.sh")
    
    script_content = """#!/bin/bash
set -euo pipefail

# Source Nix if not already available
if ! command -v nix >/dev/null 2>&1; then
    if [ -f /home/user/.nix-profile/etc/profile.d/nix.sh ]; then
        . /home/user/.nix-profile/etc/profile.d/nix.sh
    fi
fi

# Run the test command in the Nix environment
{nix_command} --command bazel test {targets}
""".format(
        nix_command = nix_command,
        targets = " ".join(ctx.attr.targets)
    )
    
    ctx.actions.write(
        output = test_script,
        content = script_content,
        is_executable = True,
    )
    
    return [
        DefaultInfo(
            executable = test_script,
            runfiles = ctx.runfiles(files = [test_script]),
        ),
    ]

nix_test = rule(
    implementation = _nix_test_impl,
    attrs = {
        "flake_path": attr.string(
            default = ".",
            doc = "Path to the Nix flake",
        ),
        "shell_name": attr.string(
            default = "default",
            doc = "Name of the Nix development shell",
        ),
        "targets": attr.string_list(
            default = ["//..."],
            doc = "Bazel test targets to run",
        ),
    },
    executable = True,
    doc = "Run Bazel tests within a Nix development environment",
)

