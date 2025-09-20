{
  description = "ChainRice Development Environment - Comprehensive Nix packages for all technologies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Language-specific inputs
    rust-overlay.url = "github:oxalica/rust-overlay";
    node2nix.url = "github:svanderburg/node2nix";
    poetry2nix.url = "github:nix-community/poetry2nix";
    
    # Development tools
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, node2nix, poetry2nix, pre-commit-hooks, devenv, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        
        # Import our package libraries
        backendPackages = import ./libs/backend.nix { inherit pkgs; };
        frontendPackages = import ./libs/frontend.nix { inherit pkgs; };
        toolsPackages = import ./libs/tools.nix { inherit pkgs; };
        
      in
      {
        # Main packages
        packages = {
          # Backend packages
          inherit (backendPackages)
            chainrice-go
            chainrice-dotnet-bridge
            chainrice-beam-bridge
            chainrice-python-bridge
            chainrice-jvm-bridge
            chainrice-php-bridge;
          
          # Frontend packages
          inherit (frontendPackages)
            chainrice-flutter-app
            chainrice-android-app
            chainrice-ios-app
            chainrice-nextjs-app
            chainrice-nuxtjs-app
            chainrice-angular-app;
          
          # Tools packages
          inherit (toolsPackages)
            chainrice-auto
            chainrice-contracts
            chainrice-data
            chainrice-dev
            chainrice-misc;
          
          # Meta packages
          backend-all = backendPackages.all;
          frontend-all = frontendPackages.all;
          tools-all = toolsPackages.all;
          
          # Complete development environment
          chainrice-dev-env = pkgs.buildEnv {
            name = "chainrice-dev-env";
            paths = [
              backendPackages.all
              frontendPackages.all
              toolsPackages.all
            ];
          };
        };

        # Development shells
        devShells = {
          # Backend development
          backend = pkgs.mkShell {
            buildInputs = backendPackages.all;
            shellHook = ''
              echo "ChainRice Backend Development Environment"
              echo "Available services:"
              echo "  - Go services (blockchain, accounting, tax)"
              echo "  - .NET bridge"
              echo "  - BEAM bridge (Erlang/Elixir)"
              echo "  - Python bridge"
              echo "  - JVM bridge (Java/Kotlin/Scala)"
              echo "  - PHP bridge"
            '';
          };
          
          # Frontend development
          frontend = pkgs.mkShell {
            buildInputs = frontendPackages.all;
            shellHook = ''
              echo "ChainRice Frontend Development Environment"
              echo "Available frameworks:"
              echo "  - Flutter/Dart (mobile)"
              echo "  - Kotlin/Android (mobile)"
              echo "  - Swift/iOS (mobile)"
              echo "  - Next.js (web)"
              echo "  - Nuxt.js (web)"
              echo "  - Angular (web)"
            '';
          };
          
          # Tools development
          tools = pkgs.mkShell {
            buildInputs = toolsPackages.all;
            shellHook = ''
              echo "ChainRice Tools Development Environment"
              echo "Available tools:"
              echo "  - AUTO (build automation)"
              echo "  - CONTRACTS (blockchain smart contracts)"
              echo "  - DATA (AI, SQL, data science)"
              echo "  - DEV (DevOps, infrastructure)"
              echo "  - MISC (experimental languages)"
            '';
          };
          
          # Complete development environment
          default = pkgs.mkShell {
            buildInputs = [
              backendPackages.all
              frontendPackages.all
              toolsPackages.all
            ];
            shellHook = ''
              echo "ChainRice Complete Development Environment"
              echo ""
              echo "Backend Services:"
              echo "  - Go services (blockchain, accounting, tax)"
              echo "  - Bridge libraries (.NET, BEAM, Python, JVM, PHP)"
              echo ""
              echo "Frontend Applications:"
              echo "  - Mobile: Flutter, Kotlin/Android, Swift/iOS"
              echo "  - Web: Next.js, Nuxt.js, Angular"
              echo ""
              echo "Development Tools:"
              echo "  - AUTO: Build automation and proto generation"
              echo "  - CONTRACTS: Smart contracts (CosmWasm, Solidity)"
              echo "  - DATA: AI, SQL, data science tools"
              echo "  - DEV: DevOps and infrastructure tools"
              echo "  - MISC: Experimental languages and tools"
              echo ""
              echo "Quick start:"
              echo "  make up    # Install everything"
              echo "  make open  # Start all services with hot reload"
              echo "  make help  # Show available commands"
            '';
          };
        };

        # Docker images
        dockerImages = {
          # Backend images
          chainrice-go = pkgs.dockerTools.buildImage {
            name = "chainrice/go";
            tag = "latest";
            contents = [ backendPackages.chainrice-go ];
            config = {
              Cmd = [ "chainrice-go" ];
              ExposedPorts = {
                "8080/tcp" = {};
                "8081/tcp" = {};
                "26657/tcp" = {};
              };
            };
          };
          
          chainrice-dotnet-bridge = pkgs.dockerTools.buildImage {
            name = "chainrice/dotnet-bridge";
            tag = "latest";
            contents = [ backendPackages.chainrice-dotnet-bridge ];
            config = {
              Cmd = [ "chainrice-dotnet-bridge" ];
            };
          };
          
          # Frontend images
          chainrice-flutter-app = pkgs.dockerTools.buildImage {
            name = "chainrice/flutter-app";
            tag = "latest";
            contents = [ frontendPackages.chainrice-flutter-app ];
            config = {
              Cmd = [ "chainrice-flutter-app" ];
            };
          };
          
          # Tools images
          chainrice-auto = pkgs.dockerTools.buildImage {
            name = "chainrice/auto";
            tag = "latest";
            contents = [ toolsPackages.chainrice-auto ];
            config = {
              Cmd = [ "chainrice-auto" ];
            };
          };
        };

        # NixOS modules
        nixosModules = {
          chainrice = { config, lib, pkgs, ... }: {
            options.services.chainrice = {
              enable = lib.mkEnableOption "ChainRice services";
              
              goServices = {
                enable = lib.mkEnableOption "ChainRice Go services";
                port = lib.mkOption {
                  type = lib.types.port;
                  default = 8080;
                  description = "Port for Go services";
                };
              };
              
              bridges = {
                dotnet = lib.mkEnableOption ".NET bridge";
                beam = lib.mkEnableOption "BEAM bridge";
                python = lib.mkEnableOption "Python bridge";
                jvm = lib.mkEnableOption "JVM bridge";
                php = lib.mkEnableOption "PHP bridge";
              };
            };
            
            config = lib.mkIf config.services.chainrice.enable {
              systemd.services.chainrice-go = lib.mkIf config.services.chainrice.goServices.enable {
                description = "ChainRice Go services";
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  ExecStart = "${backendPackages.chainrice-go}/bin/chainrice-go";
                  Restart = "always";
                };
              };
            };
          };
        };

        # Home Manager modules
        homeManagerModules = {
          chainrice = { config, lib, pkgs, ... }: {
            options.programs.chainrice = {
              enable = lib.mkEnableOption "ChainRice development tools";
              
              backend = lib.mkEnableOption "Backend development tools";
              frontend = lib.mkEnableOption "Frontend development tools";
              tools = lib.mkEnableOption "Development tools";
            };
            
            config = lib.mkIf config.programs.chainrice.enable {
              home.packages = with pkgs; [
                (lib.mkIf config.programs.chainrice.backend backendPackages.all)
                (lib.mkIf config.programs.chainrice.frontend frontendPackages.all)
                (lib.mkIf config.programs.chainrice.tools toolsPackages.all)
              ];
            };
          };
        };

        # Checks
        checks = {
          pre-commit = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              nix-linter.enable = true;
              shellcheck.enable = true;
            };
          };
        };

        # Formatter
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}