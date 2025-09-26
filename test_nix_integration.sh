#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Testing Nix-Bazel Integration for rice-dev"
echo "=============================================="

# Test 1: Check if Nix is available
echo "1. Testing Nix availability..."
if command -v nix >/dev/null 2>&1; then
    echo "✅ Nix is available: $(nix --version)"
else
    echo "❌ Nix is not available"
    exit 1
fi

# Test 2: Check if flake.nix is valid
echo "2. Testing flake.nix validity..."
if nix --extra-experimental-features "nix-command flakes" flake check . >/dev/null 2>&1; then
    echo "✅ flake.nix is valid"
else
    echo "❌ flake.nix has issues"
    nix --extra-experimental-features "nix-command flakes" flake check .
    exit 1
fi

# Test 3: Test Nix development shells
echo "3. Testing Nix development shells..."
shells=("default" "go-backend" "python-fastapi-bridge" "rust-cosmos" "proto-tools")

for shell in "${shells[@]}"; do
    echo "  Testing shell: $shell"
    if nix --extra-experimental-features "nix-command flakes" develop .#$shell --command echo "Shell $shell works" >/dev/null 2>&1; then
        echo "  ✅ $shell shell works"
    else
        echo "  ❌ $shell shell failed"
    fi
done

# Test 4: Test Bazel with Nix integration
echo "4. Testing Bazel with Nix integration..."
if bazel query //... >/dev/null 2>&1; then
    echo "✅ Bazel can query targets"
else
    echo "❌ Bazel query failed"
    exit 1
fi

# Test 5: Test Nix shell targets
echo "5. Testing Nix shell targets..."
if bazel query //:nix_default >/dev/null 2>&1; then
    echo "✅ Nix shell targets are available"
else
    echo "❌ Nix shell targets not found"
    exit 1
fi

# Test 6: Test toolchain targets
echo "6. Testing toolchain targets..."
toolchains=("nix_go_toolchain" "nix_python_toolchain" "nix_rust_toolchain" "nix_proto_toolchain")

for toolchain in "${toolchains[@]}"; do
    if bazel query //:$toolchain >/dev/null 2>&1; then
        echo "  ✅ $toolchain is available"
    else
        echo "  ❌ $toolchain not found"
    fi
done

# Test 7: Test build targets
echo "7. Testing build targets..."
if bazel query //:nix_build_all >/dev/null 2>&1; then
    echo "✅ Nix build targets are available"
else
    echo "❌ Nix build targets not found"
fi

# Test 8: Test .bazelrc.nix integration
echo "8. Testing .bazelrc.nix integration..."
if [ -f .bazelrc.nix ]; then
    echo "✅ .bazelrc.nix exists"
    if grep -q "NIX_PATH" .bazelrc.nix; then
        echo "✅ Nix environment variables configured"
    else
        echo "❌ Nix environment variables not configured"
    fi
else
    echo "❌ .bazelrc.nix not found"
fi

echo ""
echo "🎉 Nix-Bazel Integration Test Complete!"
echo "======================================"
echo ""
echo "Available commands:"
echo "  bazel run //:dev          - Enter default Nix shell"
echo "  bazel run //:build        - Build all targets with Nix"
echo "  bazel run //:test         - Test all targets with Nix"
echo "  bazel run //:go_toolchain - Use Go toolchain from Nix"
echo "  bazel run //:python_toolchain - Use Python toolchain from Nix"
echo "  bazel run //:rust_toolchain - Use Rust toolchain from Nix"
echo "  bazel run //:proto_toolchain - Use Protobuf toolchain from Nix"
echo ""
echo "Available Nix shells:"
for shell in "${shells[@]}"; do
    echo "  nix develop .#$shell"
done
