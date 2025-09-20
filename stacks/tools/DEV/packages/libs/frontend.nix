{ pkgs, lib, ... }:

let
  # Dart/Flutter packages
  dartPackages = with pkgs; [
    dart
    flutter
    flutter-tools
    dart-sass
  ];

  # Kotlin/Android packages
  kotlinPackages = with pkgs; [
    kotlin
    gradle_8
    android-studio
    android-sdk
    android-ndk
    sdkmanager
  ];

  # Swift/iOS packages
  swiftPackages = with pkgs; [
    swift
    swiftpm
    xcodebuild
    ios-deploy
    cocoapods
  ];

  # TypeScript/Web packages
  typescriptPackages = with pkgs; [
    nodejs_20
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.prettier
    nodePackages.vite
    nodePackages.next
    nodePackages.nuxt
    nodePackages.angular-cli
    nodePackages.react
    nodePackages.vue
    nodePackages.svelte
  ];

  # Web development tools
  webTools = with pkgs; [
    # CSS frameworks
    nodePackages.tailwindcss
    nodePackages.bootstrap
    nodePackages.bulma
    
    # Build tools
    nodePackages.webpack
    nodePackages.rollup
    nodePackages.parcel
    nodePackages.esbuild
    
    # Testing
    nodePackages.jest
    nodePackages.cypress
    nodePackages.playwright
    
    # Linting and formatting
    nodePackages.stylelint
    nodePackages.markdownlint
    nodePackages.husky
    nodePackages.lint-staged
  ];

  # Mobile development tools
  mobileTools = with pkgs; [
    # React Native
    nodePackages.react-native-cli
    nodePackages.expo-cli
    
    # Flutter tools
    flutter-tools
    dart-sass
    
    # Android tools
    android-studio
    android-sdk
    android-ndk
    sdkmanager
    adb
    
    # iOS tools (macOS only)
    swift
    xcodebuild
    ios-deploy
    cocoapods
  ];

  # Design and UI tools
  designTools = with pkgs; [
    # Design tools
    figma-linux
    inkscape
    gimp
    krita
    
    # Icon tools
    nodePackages.svgo
    nodePackages.svgr
    
    # Color tools
    nodePackages.colorette
    nodePackages.chalk
  ];

in
{
  # Flutter/Dart app
  chainrice-flutter-app = pkgs.buildFlutterApp rec {
    pname = "chainrice-flutter-app";
    version = "1.0.0";
    src = ./.;
    
    pubspecLock = ./stacks/frontend/dart/pubspec.lock;
    
    meta = with lib; {
      description = "ChainRice Flutter mobile application";
      homepage = "https://github.com/chainrice/app-flutter";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # Kotlin/Android app
  chainrice-android-app = pkgs.androidStudioPackages.android-studio.overrideAttrs (oldAttrs: {
    pname = "chainrice-android-app";
    version = "1.0.0";
    
    meta = with lib; {
      description = "ChainRice Android application";
      homepage = "https://github.com/chainrice/app-android";
      license = licenses.mit;
      maintainers = [ ];
    };
  });

  # Swift/iOS app
  chainrice-ios-app = pkgs.stdenv.mkDerivation rec {
    pname = "chainrice-ios-app";
    version = "1.0.0";
    src = ./.;
    
    buildInputs = with pkgs; [ swift xcodebuild ];
    
    buildPhase = ''
      swift build
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      cp .build/release/chainrice-ios-app $out/bin/
    '';
    
    meta = with lib; {
      description = "ChainRice iOS application";
      homepage = "https://github.com/chainrice/app-ios";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # Next.js app
  chainrice-nextjs-app = pkgs.buildNpmPackage rec {
    pname = "chainrice-nextjs-app";
    version = "1.0.0";
    src = ./.;
    
    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    
    buildPhase = ''
      npm run build
    '';
    
    meta = with lib; {
      description = "ChainRice Next.js web application";
      homepage = "https://github.com/chainrice/app-nextjs";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # Nuxt.js app
  chainrice-nuxtjs-app = pkgs.buildNpmPackage rec {
    pname = "chainrice-nuxtjs-app";
    version = "1.0.0";
    src = ./.;
    
    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    
    buildPhase = ''
      npm run build
    '';
    
    meta = with lib; {
      description = "ChainRice Nuxt.js web application";
      homepage = "https://github.com/chainrice/app-nuxtjs";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # Angular app
  chainrice-angular-app = pkgs.buildNpmPackage rec {
    pname = "chainrice-angular-app";
    version = "1.0.0";
    src = ./.;
    
    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    
    buildPhase = ''
      npm run build
    '';
    
    meta = with lib; {
      description = "ChainRice Angular web application";
      homepage = "https://github.com/chainrice/app-angular";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # All frontend packages
  all = with pkgs; [
    # Mobile apps
    chainrice-flutter-app
    chainrice-android-app
    chainrice-ios-app
    
    # Web apps
    chainrice-nextjs-app
    chainrice-nuxtjs-app
    chainrice-angular-app
    
    # Language runtimes
    dartPackages
    kotlinPackages
    swiftPackages
    typescriptPackages
    
    # Development tools
    webTools
    mobileTools
    designTools
  ];
}
