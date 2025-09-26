# Bazel configuration optimized for Nix integration
# This file extends the main .bazelrc with Nix-specific settings

# Import base configuration
import .bazelrc

# Nix-specific configurations
common --experimental_enable_bzlmod
common --experimental_allow_unresolved_symlinks

# Nix development environment integration
build --action_env=NIX_PATH
build --action_env=NIX_STORE
build --action_env=NIX_PROFILES

# Python configuration for Nix
build --python_path=/nix/store/*-python3-*/bin/python3
build --python_version=PY3

# Java configuration for Nix
build --java_runtime_version=17
build --java_language_version=17

# Go configuration for Nix
build --@io_bazel_rules_go//go/config:static

# C++ configuration for Nix
build --cxxopt=-std=c++17
build --linkopt=-Wl,--as-needed

# Nix-specific toolchain paths
build --action_env=BAZEL_USE_CPP_ONLY_TOOLCHAIN=1

# Repository cache for Nix
build --repository_cache=/tmp/bazel-repo-cache

# Nix development shell integration
run --action_env=NIX_DEVELOP_SHELL
run --action_env=NIX_SHELL

# Test configuration for Nix
test --test_output=errors
test --test_summary=short
test --test_timeout=300

# Nix-specific build optimizations
build --experimental_use_hermetic_linux_sandbox
build --sandbox_tmpfs_path=/tmp
build --sandbox_tmpfs_path=/nix

# Nix store integration
build --action_env=NIX_STORE
build --action_env=NIX_PROFILES
build --action_env=NIX_PATH

# Development mode for Nix
build --compilation_mode=fastbuild
build --strip=never
build --copt=-g
build --copt=-O0

# Nix shell environment
run --action_env=HOME
run --action_env=USER
run --action_env=PATH
run --action_env=LD_LIBRARY_PATH

