{ pkgs }:

{
  packages = with pkgs; [
    # SDKs
    dart
    flutter

    # Native build tools (useful for Flutter desktop/plugins)
    cmake
    ninja
    pkg-config
    clang
    gcc
    makeWrapper

    # Utilities
    git
    curl
    unzip
    zip
    which

    # Testing and coverage
    lcov
  ];
  
  envVars = {
    # Dart pub cache
    PUB_CACHE = "$HOME/.pub-cache";
    PATH = "$HOME/.pub-cache/bin:$PATH";

    # Flutter config
    FLUTTER_HOME = "${pkgs.flutter}";
    FLUTTER_ENV = "development";

    # Dart config
    DART_ENV = "development";

    # Project root hint
    CHAINRICE_DART_ROOT = "$PWD/stacks/langs/dart";
  };
  
  shellHook = ''
    echo "💠 Dart SDK: $(dart --version 2>&1 | head -n1)"
    if command -v flutter >/dev/null 2>&1; then
      echo "💠 Flutter: $(flutter --version 2>/dev/null | head -n1)"
    fi
    echo "   • pub cache at: $PUB_CACHE"

    # Ensure pub cache bin is in PATH
    export PATH="$PUB_CACHE/bin:$PATH"
    mkdir -p "$PUB_CACHE"

    # Global tools (idempotent activations)
    if command -v dart >/dev/null 2>&1; then
      echo "📦 Activating common Dart globals (webdev, melos, coverage, very_good_cli, dart_code_metrics)"
      dart pub global activate webdev >/dev/null 2>&1 || true
      dart pub global activate melos >/dev/null 2>&1 || true
      dart pub global activate coverage >/dev/null 2>&1 || true
      dart pub global activate very_good_cli >/dev/null 2>&1 || true
      dart pub global activate dart_code_metrics >/dev/null 2>&1 || true
    fi

    # Project dependencies
    if [ -f "pubspec.yaml" ]; then
      echo "📦 dart pub get"
      dart pub get || true
    fi

    # Melos bootstrap for workspaces
    if [ -f "melos.yaml" ] && command -v melos >/dev/null 2>&1; then
      echo "🔁 melos bootstrap"
      melos bootstrap || true
    fi

    # Helpful aliases
    alias dr='dart run'
    alias dtest='dart test'
    alias dfmt='dart format .'
    alias dfix='dart fix --apply'
    alias dan='dart analyze'

    alias fget='flutter pub get'
    alias ftest='flutter test'
    alias ffmt='dart format .'
    alias frun='flutter run'
    alias fweb='flutter run -d chrome'
    alias flinux='flutter run -d linux'

    # Example project hint
    if [ -f "${CHAINRICE_DART_ROOT}/pubspec.yaml" ]; then
      echo "📘 Sample available at ${CHAINRICE_DART_ROOT}"
      echo "   cd ${CHAINRICE_DART_ROOT} && dr bin/main.dart && dtest"
    fi
  '';
}
