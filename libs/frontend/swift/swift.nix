# Swift iOS/macOS frontend development — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Frontend only (no backend/AI/analytics). App dependencies like
# SwiftUI, Combine, Alamofire, SwiftyJSON, Kingfisher, Lottie, Realm/CoreData
# are managed by SPM (or Xcode) in your project on macOS. This shell provides
# the Swift toolchain, Swift Package Manager, and supporting tools. On macOS,
# it can interoperate with an installed Xcode + Command Line Tools.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  isDarwin = pkgs.stdenv.isDarwin;

  swift = pkgs.swift;               # Swift 5.10+ toolchain
  swiftformat = pkgs.swift-format or pkgs.swiftformat;
  swiftlint = pkgs.swiftlint or null;
  swiftgen = pkgs.swiftgen or null; # asset & localization management

  # macOS-only helpers
  cocoapods = if isDarwin then pkgs.cocoapods else null;

in pkgs.mkShell {
  name = "swift-frontend-dev";

  packages = [
    swift
  ] ++ pkgs.lib.optional (swiftformat != null) swiftformat
    ++ pkgs.lib.optional (swiftlint != null) swiftlint
    ++ pkgs.lib.optional (swiftgen != null) swiftgen
    ++ pkgs.lib.optional (cocoapods != null) cocoapods
    ++ [
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

    # Swift toolchain in PATH
    export PATH=${swift}/bin:$PATH

    # macOS + Xcode integration notes
    ${pkgs.lib.optionalString isDarwin ''
      # If Xcode is installed, ensure xcrun/xcodebuild are available
      if ! command -v xcodebuild >/dev/null 2>&1; then
        echo "Note: Xcode not found. Install Xcode and Command Line Tools for iOS/macOS SDKs." >&2
      fi
    ''}

    echo "[swift-frontend-dev] Swift $(${swift}/bin/swift --version | head -n1)."
    echo "SPM ready. Add frontend deps in Package.swift/Xcode: Alamofire, SwiftyJSON, Kingfisher, Lottie, etc."
    echo "UI frameworks (SwiftUI, Combine) are provided by Apple SDKs on macOS."
  '';
}
