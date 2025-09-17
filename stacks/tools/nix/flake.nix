{
  description = "ChainRice Development Environment - Complete stack for blockchain tax system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Import logic from stacks
    go-stack = {
      url = "path:../../../../stacks/go";
      flake = false;
    };
    
    react-stack = {
      url = "path:../../../../stacks/react";
      flake = false;
    };
    
    julia-stack = {
      url = "path:../../../../stacks/julia";
      flake = false;
    };
    
    python-stack = {
      url = "path:../../../../stacks/python";
      flake = false;
    };
    
    docker-stack = {
      url = "path:../../../../stacks/docker";
      flake = false;
    };
    
    terraform-stack = {
      url = "path:../../../../stacks/terraform";
      flake = false;
    };
    
    ansible-stack = {
      url = "path:../../../../stacks/ansible";
      flake = false;
    };
    
    rust-stack = {
      url = "path:../../../../stacks/rust";
      flake = false;
    };
    
    nextjs-stack = {
      url = "path:../../../../stacks/react";  # Next.js shares React stack base
      flake = false;
    };
    
    proto-stack = {
      url = "path:../../../../stacks/proto";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Import configurations from stacks
        goConfig = import ./stacks/go.nix { inherit pkgs; };
        reactConfig = import ./stacks/react.nix { inherit pkgs; };
        juliaConfig = import ./stacks/julia.nix { inherit pkgs; };
        pythonConfig = import ./stacks/python.nix { inherit pkgs; };
        dockerConfig = import ./stacks/docker.nix { inherit pkgs; };
        terraformConfig = import ./stacks/terraform.nix { inherit pkgs; };
        ansibleConfig = import ./stacks/ansible.nix { inherit pkgs; };
        rustConfig = import ./stacks/rust.nix { inherit pkgs; };
        csharpConfig = import ./stacks/c#.nix { inherit pkgs; };
        cppConfig = import ./stacks/c++.nix { inherit pkgs; };
        clojureConfig = import ./stacks/clojure.nix { inherit pkgs; };
        dartConfig = import ./stacks/dart.nix { inherit pkgs; };
        elixirConfig = import ./stacks/elixir.nix { inherit pkgs; };
        erlangConfig = import ./stacks/erlang.nix { inherit pkgs; };
        fsharpConfig = import ./stacks/f#.nix { inherit pkgs; };
        groovyConfig = import ./stacks/groovy.nix { inherit pkgs; };
        haskellConfig = import ./stacks/haskell.nix { inherit pkgs; };
        javaConfig = import ./stacks/java.nix { inherit pkgs; };
        kotlinConfig = import ./stacks/kotlin.nix { inherit pkgs; };
        octaveConfig = import ./stacks/octave.nix { inherit pkgs; };
        ocamlConfig = import ./stacks/ocaml.nix { inherit pkgs; };
        phpConfig = import ./stacks/php.nix { inherit pkgs; };
        scalaConfig = import ./stacks/scala.nix { inherit pkgs; };
        solidityConfig = import ./stacks/solidity.nix { inherit pkgs; };
        sqlConfig = import ./stacks/sql.nix { inherit pkgs; };
        swiftConfig = import ./stacks/swift.nix { inherit pkgs; };
        toolsConfig = import ./stacks/tools.nix { inherit pkgs; };
        nodeConfig = import ./stacks/node.nix { inherit pkgs; };
        nextjsConfig = import ./stacks/nextjs.nix { inherit pkgs; };
        protoConfig = import ./stacks/proto.nix { inherit pkgs; };
        
        # ChainRice specific packages
        chainRicePackages = with pkgs; [
          # Database
          sqlite
          sqlite-interactive
          
          # Development tools
          git
          gnumake
          curl
          jq
          
          # Monitoring & debugging
          htop
          netcat
          lsof
          
          # SSL/TLS
          openssl
          
          # Protocol buffers
          protobuf
          protoc-gen-go
          protoc-gen-go-grpc
          
          # Additional tools for blockchain development
          grpcurl
          
          # File utilities
          tree
          fd
          ripgrep
        ];
        
        # Combine all package lists
        allPackages = chainRicePackages 
          ++ goConfig.packages 
          ++ reactConfig.packages 
          ++ juliaConfig.packages 
          ++ pythonConfig.packages 
          ++ dockerConfig.packages 
          ++ terraformConfig.packages 
          ++ ansibleConfig.packages
          ++ rustConfig.packages
          ++ csharpConfig.packages
          ++ cppConfig.packages
          ++ clojureConfig.packages
          ++ dartConfig.packages
          ++ elixirConfig.packages
          ++ erlangConfig.packages
          ++ fsharpConfig.packages
          ++ groovyConfig.packages
          ++ haskellConfig.packages
          ++ javaConfig.packages
          ++ kotlinConfig.packages
          ++ octaveConfig.packages
          ++ ocamlConfig.packages
          ++ phpConfig.packages
          ++ scalaConfig.packages
          ++ solidityConfig.packages
          ++ sqlConfig.packages
          ++ swiftConfig.packages
          ++ toolsConfig.packages
          ++ nodeConfig.packages
          ++ nextjsConfig.packages
          ++ protoConfig.packages;
          
        # Environment variables from all stacks
        allEnvVars = goConfig.envVars 
          // reactConfig.envVars 
          // juliaConfig.envVars 
          // pythonConfig.envVars 
          // dockerConfig.envVars 
          // terraformConfig.envVars 
          // ansibleConfig.envVars
          // rustConfig.envVars
          // csharpConfig.envVars
          // cppConfig.envVars
          // clojureConfig.envVars
          // dartConfig.envVars
          // elixirConfig.envVars
          // erlangConfig.envVars
          // fsharpConfig.envVars
          // groovyConfig.envVars
          // haskellConfig.envVars
          // javaConfig.envVars
          // kotlinConfig.envVars
          // octaveConfig.envVars
          // ocamlConfig.envVars
          // phpConfig.envVars
          // scalaConfig.envVars
          // solidityConfig.envVars
          // sqlConfig.envVars
          // swiftConfig.envVars
          // toolsConfig.envVars
          // nodeConfig.envVars
          // nextjsConfig.envVars
          // protoConfig.envVars
          // {
            # ChainRice specific environment variables
            CHAIN_RICE_ROOT = "$PWD";
            CHAIN_RICE_DATA_DIR = "$PWD/data";
            CHAIN_RICE_BUILD_DIR = "$PWD/backend/go/build";
            
            # Database
            DB_PATH = "$PWD/backend/go/accounting.db";
            
            # API Configuration
            TAX_API_PORT = "8003";
            BLOCKCHAIN_API_PORT = "1317";
            FRONTEND_PORT = "5173";
            
            # CORS origins
            CORS_ORIGINS = "http://localhost:5173,http://localhost:3000";
            
            # Development mode
            NODE_ENV = "development";
            GO_ENV = "development";
          };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = allPackages;
          
          shellHook = ''
            echo "🌾 ChainRice Development Environment"
            echo "======================================"
            echo ""
            echo "📋 Available stacks:"
            echo "  • Go ${pkgs.go.version} (Cosmos SDK blockchain + Tax API)"
            echo "  • Node.js ${pkgs.nodejs.version} (React frontend)"
            echo "  • Next.js ${pkgs.nodejs.version} (Full-stack React framework)"
            echo "  • Rust ${pkgs.rustc.version} (CosmWasm smart contracts)"
            echo "  • .NET SDK ${pkgs.dotnet-sdk_8.version} (C# development)"
            echo "  • C/C++ ${pkgs.clang.version}/${pkgs.gcc.version} (Systems & performance)"
            echo "  • Clojure ${pkgs.clojure.version} (JVM/REPL)"
            echo "  • Dart ${pkgs.dart.version} / Flutter (multi-platform UI)"
            echo "  • Elixir ${pkgs.elixir.version} on Erlang ${pkgs.erlang.version} (BEAM)"
            echo "  • Erlang/OTP ${pkgs.erlang.version} (Distributed systems)"
            echo "  • F# on .NET SDK ${pkgs.dotnet-sdk_8.version} (FP on .NET)"
            echo "  • Groovy ${pkgs.groovy.version} (Scripting/Gradle)"
            echo "  • Haskell GHC ${pkgs.ghc.version} (FP/compilers)"
            echo "  • Java ${pkgs.jdk21.version} (JVM/Gradle/Maven)"
            echo "  • Kotlin ${pkgs.kotlin.version} (KTS/Gradle)"
            echo "  • Octave $(octave --quiet --eval \"printf('%s', version());\") (Numerics)"
            echo "  • OCaml ${pkgs.ocaml.version} (dune/opam)"
            echo "  • PHP ${pkgs.php.version} (Composer/QA tools)"
            echo "  • Scala $(scala -version 2>&1 | sed -n 's/.*version //p' | head -n1) (sbt/Metals)"
            echo "  • Solidity $(solc --version 2>/dev/null | sed -n '1p') (Foundry/Hardhat/Truffle)"
            echo "  • SQL: Postgres ${pkgs.postgresql.version} / MySQL ${pkgs.mysql80.version} / SQLite ${pkgs.sqlite.version} + Redis/Mongo/ClickHouse/Cassandra/Neo4j"
            echo "  • Swift $(swift --version 2>/dev/null | head -n1) (SwiftPM, swift-format, swiftlint)"
            echo "  • Infra Tools: Ansible/Docker/Terraform + AWS/Azure/GCP + K8s"
            echo "  • Node Frontend: React/TS/Next/Angular/Vue + ESLint/Prettier/Jest/Vitest"
            echo "  • Protocol Buffers ${pkgs.protobuf.version} + Buf ${pkgs.buf.version} (Schema management)"
            echo "  • Julia ${pkgs.julia-bin.version} (Functions)"
            echo "  • Python ${pkgs.python3.version} (Backend services)"
            echo "  • Docker ${pkgs.docker.version} (Containerization)"
            echo "  • Terraform ${pkgs.terraform.version} (Infrastructure)"
            echo "  • Ansible (Configuration management)"
            echo ""
            echo "🗄️ Database: SQLite ${pkgs.sqlite.version}"
            echo "🔧 Build tools: Make, Git, Protocol Buffers"
            echo ""
            echo "🚀 Quick start:"
            echo "  cd backend/go && make build    # Build Go services"
            echo "  cd frontend/react && npm install && npm run dev  # Start React frontend"
            echo "  cd frontend/next && npm install && npm run dev   # Start Next.js frontend"
            echo "  cd contracts/rust && cargo build --target wasm32-unknown-unknown  # Build smart contracts"
            echo "  cd contracts/proto && buf generate  # Generate code from proto files"
            echo "  make tax-status-simple         # Check service status"
            echo ""
            echo "📊 Ports:"
            echo "  • React Frontend:  http://localhost:5173"
            echo "  • Next.js Frontend: http://localhost:3000"
            echo "  • Tax API:         http://localhost:8003"
            echo "  • Blockchain:      http://localhost:1317"
            echo ""
            
            # Set all environment variables
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") allEnvVars)}
            
            # Initialize stack configurations
            ${goConfig.shellHook or ""}
            ${reactConfig.shellHook or ""}
            ${juliaConfig.shellHook or ""}
            ${pythonConfig.shellHook or ""}
            ${dockerConfig.shellHook or ""}
            ${terraformConfig.shellHook or ""}
            ${ansibleConfig.shellHook or ""}
            ${rustConfig.shellHook or ""}
            ${csharpConfig.shellHook or ""}
            ${cppConfig.shellHook or ""}
            ${clojureConfig.shellHook or ""}
            ${dartConfig.shellHook or ""}
            ${elixirConfig.shellHook or ""}
            ${erlangConfig.shellHook or ""}
            ${fsharpConfig.shellHook or ""}
            ${groovyConfig.shellHook or ""}
            ${haskellConfig.shellHook or ""}
            ${javaConfig.shellHook or ""}
            ${kotlinConfig.shellHook or ""}
            ${octaveConfig.shellHook or ""}
            ${ocamlConfig.shellHook or ""}
            ${phpConfig.shellHook or ""}
            ${scalaConfig.shellHook or ""}
            ${solidityConfig.shellHook or ""}
            ${sqlConfig.shellHook or ""}
            ${swiftConfig.shellHook or ""}
            ${toolsConfig.shellHook or ""}
            ${nodeConfig.shellHook or ""}
            ${nextjsConfig.shellHook or ""}
            ${protoConfig.shellHook or ""}
            
            # ChainRice specific setup
            echo "🔧 Setting up ChainRice environment..."
            
            # Create necessary directories
            mkdir -p $CHAIN_RICE_DATA_DIR
            mkdir -p $CHAIN_RICE_BUILD_DIR
            
            # Set up Go workspace
            if [ -f "backend/go/go.mod" ]; then
              echo "📦 Go workspace detected"
              export GOPATH="$HOME/go"
              export PATH="$GOPATH/bin:$PATH"
            fi
            
            # Set up Node.js for frontends
            if [ -d "frontend/react/node_modules" ]; then
              echo "⚛️  React frontend detected"
              export PATH="frontend/react/node_modules/.bin:$PATH"
            fi
            
            if [ -d "frontend/next/node_modules" ]; then
              echo "⚡ Next.js frontend detected"
              export PATH="frontend/next/node_modules/.bin:$PATH"
            fi
            
            # Set up Rust for smart contracts
            if [ -f "contracts/rust/Cargo.toml" ]; then
              echo "🦀 Rust smart contracts detected"
              export CARGO_MANIFEST_DIR="$PWD/contracts/rust"
            fi
            
            # Set up Protocol Buffers
            if [ -d "contracts/proto" ]; then
              echo "📋 Protocol Buffers workspace detected"
              export PROTO_ROOT="$PWD/contracts/proto"
            fi
            
            # Julia setup
            if [ -f "functions/julia/Project.toml" ]; then
              echo "🔬 Julia functions detected"
              export JULIA_PROJECT="functions/julia"
            fi
            
            echo ""
            echo "✅ Environment ready! Happy coding! 🎉"
          '';
        };
        
        # Individual development shells for specific stacks
        devShells.go = pkgs.mkShell {
          buildInputs = chainRicePackages ++ goConfig.packages;
          shellHook = ''
            echo "🐹 Go Development Environment (ChainRice)"
            ${goConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "go"; }))}
          '';
        };
        
        devShells.react = pkgs.mkShell {
          buildInputs = chainRicePackages ++ reactConfig.packages;
          shellHook = ''
            echo "⚛️  React Development Environment (ChainRice)"
            ${reactConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "react"; }))}
          '';
        };
        
        devShells.julia = pkgs.mkShell {
          buildInputs = chainRicePackages ++ juliaConfig.packages;
          shellHook = ''
            echo "🔬 Julia Development Environment (ChainRice)"
            ${juliaConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "julia"; }))}
          '';
        };
        
        devShells.python = pkgs.mkShell {
          buildInputs = chainRicePackages ++ pythonConfig.packages;
          shellHook = ''
            echo "🐍 Python Development Environment (ChainRice)"
            ${pythonConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "python"; }))}
          '';
        };
        
        devShells.rust = pkgs.mkShell {
          buildInputs = chainRicePackages ++ rustConfig.packages;
          shellHook = ''
            echo "🦀 Rust Development Environment (ChainRice CosmWasm)"
            ${rustConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "rust"; }))}
          '';
        };

        devShells.csharp = pkgs.mkShell {
          buildInputs = chainRicePackages ++ csharpConfig.packages;
          shellHook = ''
            echo "🔷 C#/.NET Development Environment (ChainRice)"
            ${csharpConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "csharp"; }))}
          '';
        };

        devShells.cpp = pkgs.mkShell {
          buildInputs = chainRicePackages ++ cppConfig.packages;
          shellHook = ''
            echo "🔶 C/C++ Development Environment (ChainRice)"
            ${cppConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "cpp"; }))}
          '';
        };

        devShells.clojure = pkgs.mkShell {
          buildInputs = chainRicePackages ++ clojureConfig.packages;
          shellHook = ''
            echo "🟢 Clojure Development Environment (ChainRice)"
            ${clojureConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "clojure"; }))}
          '';
        };

        devShells.dart = pkgs.mkShell {
          buildInputs = chainRicePackages ++ dartConfig.packages;
          shellHook = ''
            echo "💠 Dart/Flutter Development Environment (ChainRice)"
            ${dartConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "dart"; }))}
          '';
        };

        devShells.elixir = pkgs.mkShell {
          buildInputs = chainRicePackages ++ elixirConfig.packages;
          shellHook = ''
            echo "🟣 Elixir Development Environment (ChainRice)"
            ${elixirConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "elixir"; }))}
          '';
        };

        devShells.erlang = pkgs.mkShell {
          buildInputs = chainRicePackages ++ erlangConfig.packages;
          shellHook = ''
            echo "🟠 Erlang Development Environment (ChainRice)"
            ${erlangConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "erlang"; }))}
          '';
        };

        devShells.fsharp = pkgs.mkShell {
          buildInputs = chainRicePackages ++ fsharpConfig.packages;
          shellHook = ''
            echo "🟦 F#/.NET Development Environment (ChainRice)"
            ${fsharpConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "fsharp"; }))}
          '';
        };

        devShells.groovy = pkgs.mkShell {
          buildInputs = chainRicePackages ++ groovyConfig.packages;
          shellHook = ''
            echo "🟫 Groovy/Gradle Development Environment (ChainRice)"
            ${groovyConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "groovy"; }))}
          '';
        };

        devShells.haskell = pkgs.mkShell {
          buildInputs = chainRicePackages ++ haskellConfig.packages;
          shellHook = ''
            echo "🔷 Haskell Development Environment (ChainRice)"
            ${haskellConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "haskell"; }))}
          '';
        };

        devShells.java = pkgs.mkShell {
          buildInputs = chainRicePackages ++ javaConfig.packages;
          shellHook = ''
            echo "☕ Java Development Environment (ChainRice)"
            ${javaConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "java"; }))}
          '';
        };

        devShells.kotlin = pkgs.mkShell {
          buildInputs = chainRicePackages ++ kotlinConfig.packages;
          shellHook = ''
            echo "🟪 Kotlin Development Environment (ChainRice)"
            ${kotlinConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "kotlin"; }))}
          '';
        };

        devShells.octave = pkgs.mkShell {
          buildInputs = chainRicePackages ++ octaveConfig.packages;
          shellHook = ''
            echo "🟨 Octave Development Environment (ChainRice)"
            ${octaveConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "octave"; }))}
          '';
        };

        devShells.ocaml = pkgs.mkShell {
          buildInputs = chainRicePackages ++ ocamlConfig.packages;
          shellHook = ''
            echo "🟧 OCaml Development Environment (ChainRice)"
            ${ocamlConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "ocaml"; }))}
          '';
        };

        devShells.php = pkgs.mkShell {
          buildInputs = chainRicePackages ++ phpConfig.packages;
          shellHook = ''
            echo "🐘 PHP Development Environment (ChainRice)"
            ${phpConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "php"; }))}
          '';
        };

        devShells.scala = pkgs.mkShell {
          buildInputs = chainRicePackages ++ scalaConfig.packages;
          shellHook = ''
            echo "🟦 Scala Development Environment (ChainRice)"
            ${scalaConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "scala"; }))}
          '';
        };

        devShells.solidity = pkgs.mkShell {
          buildInputs = chainRicePackages ++ solidityConfig.packages;
          shellHook = ''
            echo "🟩 Solidity Development Environment (ChainRice)"
            ${solidityConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "solidity"; }))}
          '';
        };

        devShells.sql = pkgs.mkShell {
          buildInputs = chainRicePackages ++ sqlConfig.packages;
          shellHook = ''
            echo "🟦 SQL Development Environment (ChainRice)"
            ${sqlConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "sql"; }))}
          '';
        };

        devShells.swift = pkgs.mkShell {
          buildInputs = chainRicePackages ++ swiftConfig.packages;
          shellHook = ''
            echo "🟪 Swift Development Environment (ChainRice)"
            ${swiftConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "swift"; }))}
          '';
        };

        devShells.tools = pkgs.mkShell {
          buildInputs = chainRicePackages ++ toolsConfig.packages;
          shellHook = ''
            echo "🛠️ Infra Tools Development Environment (ChainRice)"
            ${toolsConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "tools"; }))}
          '';
        };

        devShells.node = pkgs.mkShell {
          buildInputs = chainRicePackages ++ nodeConfig.packages;
          shellHook = ''
            echo "🟩 Node Frontend Development Environment (ChainRice)"
            ${nodeConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "node"; }))}
          '';
        };
        
        devShells.nextjs = pkgs.mkShell {
          buildInputs = chainRicePackages ++ nextjsConfig.packages;
          shellHook = ''
            echo "⚡ Next.js Development Environment (ChainRice)"
            ${nextjsConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "nextjs"; }))}
          '';
        };
        
        devShells.proto = pkgs.mkShell {
          buildInputs = chainRicePackages ++ protoConfig.packages;
          shellHook = ''
            echo "📋 Protocol Buffers Development Environment (ChainRice)"
            ${protoConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "proto"; }))}
          '';
        };
        
        devShells.infra = pkgs.mkShell {
          buildInputs = chainRicePackages ++ dockerConfig.packages ++ terraformConfig.packages ++ ansibleConfig.packages;
          shellHook = ''
            echo "🏗️  Infrastructure Development Environment (ChainRice)"
            ${dockerConfig.shellHook or ""}
            ${terraformConfig.shellHook or ""}
            ${ansibleConfig.shellHook or ""}
            ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "export ${name}=\"${toString value}\"") (allEnvVars // { FOCUS = "infrastructure"; }))}
          '';
        };
      });
}
