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
build --action_env=NIX_DEVELOP_SHELL
build --action_env=NIX_SHELL

# Python configuration for Nix
build --python_path=/nix/store/*-python3-*/bin/python3
build --python_version=PY3
build --action_env=PYTHONPATH
build --action_env=PYTHONNOUSERSITE
build --action_env=LC_ALL
build --action_env=LANG

# Java configuration for Nix
build --java_runtime_version=17
build --java_language_version=17
build --action_env=JAVA_HOME
build --action_env=MAVEN_OPTS
build --action_env=GRADLE_OPTS

# Go configuration for Nix
build --@io_bazel_rules_go//go/config:static
build --action_env=GOROOT
build --action_env=GOPATH
build --action_env=GOBIN

# Rust configuration for Nix
build --action_env=CARGO_HOME
build --action_env=RUSTUP_HOME
build --action_env=RUST_SRC_PATH

# C++ configuration for Nix
build --cxxopt=-std=c++17
build --linkopt=-Wl,--as-needed
build --action_env=CC
build --action_env=CXX
build --action_env=LD_LIBRARY_PATH

# Nix-specific toolchain paths
build --action_env=BAZEL_USE_CPP_ONLY_TOOLCHAIN=1

# Repository cache for Nix
build --repository_cache=/tmp/bazel-repo-cache

# Nix development shell integration
run --action_env=NIX_DEVELOP_SHELL
run --action_env=NIX_SHELL
run --action_env=NIX_PATH
run --action_env=NIX_STORE
run --action_env=NIX_PROFILES

# Test configuration for Nix
test --test_output=errors
test --test_summary=short
test --test_timeout=300
test --action_env=NIX_DEVELOP_SHELL
test --action_env=NIX_SHELL

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

# Protobuf configuration for Nix
build --action_env=PROTOC
build --action_env=PROTOC_GEN_GO
build --action_env=PROTOC_GEN_GO_GRPC

# Node.js configuration for Nix
build --action_env=NODE_PATH
build --action_env=NPM_CONFIG_PREFIX
build --action_env=YARN_CACHE_FOLDER

# Terraform configuration for Nix
build --action_env=TF_VAR_*
build --action_env=TF_CLI_CONFIG_FILE

# Kubernetes configuration for Nix
build --action_env=KUBECONFIG
build --action_env=KUBE_CONFIG_PATH

# Docker configuration for Nix
build --action_env=DOCKER_HOST
build --action_env=DOCKER_CONFIG

