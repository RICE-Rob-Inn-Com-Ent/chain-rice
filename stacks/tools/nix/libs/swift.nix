{ pkgs }:

{
  packages = with pkgs; [
    # Swift toolchain and build tools
    swift
    clang
    llvm
    lldb
    cmake
    ninja
    pkg-config
    curl
    git

    # Swift Package Manager and helpers
    swiftpm

    # Linters / Formatters
    swift-format
    swiftlint

    # iOS/Apple platform helpers (cross-compile limited on Linux)
    # Provision for protobuf/grpc if needed by Swift
    protobuf
    grpc

    # UI/testing helpers
    xcbeautify
  ];

  envVars = {
    SWIFTENV_ROOT = "$HOME/.swiftenv";
    SWIFT_BUILD_FLAGS = "-Xswiftc -Ounchecked";
    SWIFTPM_RESOLVER = "https";

    # Set clang as default C/C++ for C targets encountered by SwiftPM
    CC = "clang";
    CXX = "clang++";

    # Useful for SPM binary targets
    PKG_CONFIG_PATH = "${pkgs.pkg-config}/lib/pkgconfig";
  };

  shellHook = ''
    echo "🟪 Swift toolchain: $(swift --version 2>/dev/null | head -n1)"

    # If a Package.swift exists, ensure .build directory exists
    if [ -f "Package.swift" ]; then
      mkdir -p .build
    fi

    # Aliases
    alias sb='swift build'
    alias sr='swift run'
    alias st='swift test'
    alias spm='swift package'
    alias sresolve='swift package resolve'
    alias supdate='swift package update'
    alias sformat='swift-format format --in-place --recursive .'
    alias slint='swiftlint || true'

    # Pretty build (if logs piped)
    alias sbx='swift build 2>&1 | xcbeautify || swift build'
    alias stx='swift test 2>&1 | xcbeautify || swift test'

    # Quick start tips
    echo "💡 Init SPM: swift package init --type executable"
    echo "💡 Build: sb | Run: sr | Test: st"
    echo "💡 Format: sformat | Lint: slint"
  '';
}
