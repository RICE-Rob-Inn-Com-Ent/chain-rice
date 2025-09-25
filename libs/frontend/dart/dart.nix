# Dart/Flutter frontend development — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Frontend only (no backend/AI/analytics). Flutter/Dart packages such as
# flutter_bloc, provider, get_it, dio, freezed, json_serializable, intl,
# flutter_hooks, animations, go_router, flutter_svg, lottie are managed via
# pubspec.yaml in your project. This shell provides Dart/Flutter SDKs and tooling.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  dart = pkgs.dart;        # latest stable
  flutter = pkgs.flutter;  # latest stable

  # Android tooling for Linux (for building/running Android targets)
  androidPkgs = pkgs.androidsdk;
  jdk = pkgs.jdk17 or pkgs.jdk;

in pkgs.mkShell {
  name = "dart-flutter-frontend-dev";

  packages = [
    dart
    flutter

    # Helpful CLI tools
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.which
    pkgs.unzip
  ] ++ (if isLinux then [
    androidPkgs
    jdk
  ] else []) ++ (if isDarwin then [
    pkgs.cocoapods
  ] else []);

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Make Flutter/Dart available
    export PATH=${flutter}/bin:${dart}/bin:$PATH

    # Project-local pub cache so global activations persist per project
    export PUB_CACHE="$PWD/.pub-cache"
    mkdir -p "$PUB_CACHE/bin"
    export PATH="$PUB_CACHE/bin:$PATH"

    # Android setup on Linux
    ${pkgs.lib.optionalString isLinux ''
      export ANDROID_HOME=${androidPkgs}/libexec/android-sdk
      export ANDROID_SDK_ROOT=$ANDROID_HOME
      export JAVA_HOME=${jdk}
      export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH

      # Accept Android licenses non-interactively if needed
      yes | sdkmanager --licenses >/dev/null 2>&1 || true
    ''}

    # Activate Flutter build tools locally (idempotent and fast if already installed)
    dart --disable-analytics >/dev/null 2>&1 || true
    flutter --disable-analytics >/dev/null 2>&1 || true

    dart pub global activate flutter_launcher_icons >/dev/null 2>&1 || true
    dart pub global activate flutter_native_splash >/dev/null 2>&1 || true

    echo "[dart-flutter-frontend-dev] Dart $(dart --version 2>&1 | head -n1), Flutter $(flutter --version 2>/dev/null | head -n1)."
    echo "Ready for: flutter run / build (web, Android; iOS on macOS with Xcode)."
    echo "Add frontend deps in pubspec.yaml: flutter_bloc, provider, get_it, dio, freezed, json_serializable, intl, flutter_hooks, animations, go_router, flutter_svg, lottie."
  '';
}
