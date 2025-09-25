# Kotlin Android frontend development — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Android frontend only (no backend/AI/analytics). Kotlin/Gradle dependencies
# such as Jetpack Compose, Ktor Client, kotlinx.serialization, Coroutines,
# Accompanist, Hilt/Dagger/Koin, Coil, Room, Navigation-Compose, and Lottie
# are managed via Gradle in your project. This shell provides SDKs and tools.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  isLinux = pkgs.stdenv.isLinux;

  # Toolchains
  jdk = pkgs.jdk17 or pkgs.jdk;
  kotlin = pkgs.kotlin;               # Kotlin compiler
  gradle = pkgs.gradle;               # Latest stable Gradle

  # Android SDK/NDK and tools
  androidSdk = pkgs.androidsdk;       # SDK with cmdline tools
  androidTools = pkgs.android-tools;  # adb, fastboot, etc.
  androidNdk = pkgs.android-ndk;      # latest NDK

in pkgs.mkShell {
  name = "kotlin-android-frontend-dev";

  packages = [
    jdk
    kotlin
    gradle

    androidSdk
    androidNdk
    androidTools

    # Helpful CLIs
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.unzip
    pkgs.which
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Java toolchain
    export JAVA_HOME=${jdk}
    export PATH=${jdk}/bin:$PATH

    # Android SDK/NDK
    export ANDROID_HOME=${androidSdk}/libexec/android-sdk
    export ANDROID_SDK_ROOT=$ANDROID_HOME
    export ANDROID_NDK_HOME=${androidNdk}
    export ANDROID_NDK_ROOT=${androidNdk}
    export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH

    # Gradle cache per-project (optional)
    export GRADLE_USER_HOME="$PWD/.gradle"

    # Accept Android licenses non-interactively (best-effort)
    if command -v sdkmanager >/dev/null 2>&1; then
      yes | sdkmanager --licenses >/dev/null 2>&1 || true
    fi

    echo "[kotlin-android-frontend-dev] Java $(${jdk}/bin/java -version 2>&1 | head -n1), Gradle $(gradle --version 2>/dev/null | head -n1)."
    echo "Android SDK: $ANDROID_HOME | NDK: $ANDROID_NDK_HOME | adb: $(adb version 2>/dev/null | head -n1)"
    echo "Use Gradle to add frontend deps: Compose, Ktor Client, serialization, coroutines, Accompanist, Hilt/Koin, Coil, Room, Navigation-Compose, Lottie."
  '';
}
