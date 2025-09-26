{
  description = "rice-dev: Unified Nix dev shells with Bazel integration (2025)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { 
          inherit system;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
              "android-sdk-cmdline-tools"
              "androidsdk"
              "terraform"
            ];
          };
        };

        # =============================================================================
        # COMMON PACKAGES (to avoid duplication)
        # =============================================================================
        
        # Base CLI tools (used everywhere)
        baseTools = with pkgs; [
          git
          curl
          jq
          openssl
          pkg-config
        ];

        # Protobuf/gRPC toolchain (used in many environments)
        protoTools = with pkgs; [
          protobuf
          buf
          grpcurl
          protoc-gen-go
          protoc-gen-go-grpc
        ];

        # Python toolchain
        python = pkgs.python311;
        py = pkgs.python311Packages;

        # Java toolchain
        jdk = pkgs.jdk21 or pkgs.jdk20 or pkgs.jdk;
        maven = pkgs.maven;
        gradle = pkgs.gradle;

        # Node.js toolchain
        nodejs = pkgs.nodejs_20 or pkgs.nodejs;
        npm = pkgs.nodePackages.npm;
        yarn = pkgs.yarn;
        pnpm = pkgs.nodePackages.pnpm;

        # Go toolchain
        go = pkgs.go_1_24 or pkgs.go_1_23 or pkgs.go_1_22 or pkgs.go;

        # Rust toolchain
        rust = pkgs.rust-bin.stable.latest or pkgs.rustc;
        cargo = pkgs.cargo;

        # .NET toolchain
        dotnet = pkgs.dotnet-sdk_8 or pkgs.dotnet-sdk;

        # BEAM toolchain
        beam = pkgs.beam.packages.erlangR26;
        erlang = beam.erlang;
        elixir = beam.elixir_1_15;
        rebar3 = beam.rebar3;

        # Android toolchain
        androidSdk = pkgs.androidsdk;
        androidTools = pkgs.android-tools;
        androidNdk = pkgs.android-ndk;

        # CUDA toolchain
        cudaPkgs = pkgs.cudaPackages;

        # Julia toolchain
        julia = pkgs.julia-bin or pkgs.julia;
        juliaPkgs = pkgs.juliaPackages or pkgs.julia;

        # Dart/Flutter toolchain
        dart = pkgs.dart;
        flutter = pkgs.flutter;

        # Swift toolchain
        swift = pkgs.swift;
        swiftformat = pkgs.swift-format or pkgs.swiftformat;
        swiftlint = pkgs.swiftlint or null;
        swiftgen = pkgs.swiftgen or null;

        # Kotlin toolchain
        kotlin = pkgs.kotlin;

        # Terraform toolchain
        terraform = pkgs.terraform;
        terraformLs = pkgs.terraform-ls;
        tflint = pkgs.tflint;
        terragrunt = pkgs.terragrunt;

        # Kubernetes toolchain
        kubectl = pkgs.kubectl;
        kustomize = pkgs.kustomize;
        helm = pkgs.helm;
        kubeseal = pkgs.kubeseal;
        kubeval = pkgs.kubeval;
        kind = pkgs.kind;

        # Ansible toolchain
        ansible = pkgs.ansible;
        ansibleLint = pkgs.ansible-lint or pkgs.python311Packages.ansible-lint;
        yamllint = pkgs.yamllint;
        molecule = pkgs.molecule;
        docker = pkgs.docker;

        # Cloud CLIs
        awscli = pkgs.awscli2;
        gcloud = pkgs.google-cloud-sdk;
        azureCli = pkgs.azure-cli;

        # Solidity toolchain
        solc = pkgs.solc;
        foundry = pkgs.foundry;

        # Bazel toolchain
        bazel = pkgs.bazel_7;
        bazelisk = pkgs.bazelisk;
        buildifier = pkgs.buildifier;
        buildozer = pkgs.buildozer;

        # Additional tools
        unzip = pkgs.unzip;
        which = pkgs.which;
        yq = pkgs.yq;
        yaml2json = pkgs.yaml2json;

      in {
        devShells = {
          # =============================================================================
          # AI & BOT DEVELOPMENT
          # =============================================================================
          
          bot-core = pkgs.mkShell {
            name = "ai-core-dev";
            packages = [
              # Мінімальне Python середовище без проблемних пакетів
              (python.withPackages (ps: with ps; [
                # Тільки базові пакети
                numpy
                pandas
                # Без scipy, matplotlib, seaborn через tkinter проблеми
                # Без transformers, diffusers через складні залежності
                # Без torch через CUDA проблеми
                # Без tensorflow через складні залежності
                # Без jax через складні залежності
              ]))
              # Native build tools
              pkgs.gcc
              pkgs.cmake
              pkgs.zlib
              pkgs.ffmpeg
              pkgs.libsndfile
              pkgs.ncurses
              pkgs.openblas
              # CUDA libs
              cudaPkgs.cudatoolkit
              cudaPkgs.cudnn
            ] ++ baseTools;
            shellHook = ''
              export PYTHONNOUSERSITE=1
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export CUDA_PATH=${cudaPkgs.cudatoolkit}
              export XLA_FLAGS=--xla_gpu_cuda_data_dir=${cudaPkgs.cudatoolkit}
              export TF_CUDA_PATHS=${cudaPkgs.cudatoolkit}:${cudaPkgs.cudnn}
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ cudaPkgs.cudatoolkit cudaPkgs.cudnn ]}:$LD_LIBRARY_PATH
              echo "[ai-core-dev] Python $(python --version) ready. CUDA: enabled (toolchain available)."
            '';
          };

          bot-integration = pkgs.mkShell {
            name = "bot-integration-dev";
            packages = [
              (python.withPackages (ps: with ps; [
                # HTTP clients
                ps.httpx
                ps.requests
                ps.aiohttp
                # Websockets / Socket.IO
                ps.websockets
                ps."python-socketio"
                # Chat platform SDKs
                ps."python-telegram-bot"
                ps.discordpy
                ps."slack-sdk"
                # API clients
                ps.openai
                ps."huggingface-hub"
                # Serialization / data
                ps.pydantic
                ps.pyyaml
                ps.orjson
                # Scheduling
                ps.apscheduler
                # Logging
                ps.loguru
                ps.structlog
              ]))
            ] ++ baseTools;
            shellHook = ''
              export PYTHONNOUSERSITE=1
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              echo "[bot-integration-dev] Python $(python --version) ready."
            '';
          };

          bot-julia-models = pkgs.mkShell {
            name = "julia-modeling-dev";
            packages = [
              # Julia with packages
              (juliaPkgs.withPackages julia (ps: with ps; [
                DataFrames
                CSV
                Distributions
                StatsBase
                StatsModels
                TimeSeries
                MarketData
                DifferentialEquations
                ModelingToolkit
                JuMP
                Plots
                Makie
                Flux
                DiffEqFlux
                CUDA
                PyCall
              ]))
              python
              # Native build tools
              pkgs.gcc
              pkgs.cmake
              pkgs.zlib
              pkgs.openblas
              pkgs.fftw
              # CUDA libs
              cudaPkgs.cudatoolkit
              cudaPkgs.cudnn
              pkgs.nvidia-settings
              pkgs.nvidia-x11
            ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export PYTHON=$(which python)
              export CUDA_PATH=${cudaPkgs.cudatoolkit}
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ cudaPkgs.cudatoolkit cudaPkgs.cudnn ]}:$LD_LIBRARY_PATH
              echo "[julia-modeling-dev] Julia $(${julia}/bin/julia -e 'print(VERSION)') with PyCall (Python $(python --version | cut -d' ' -f2)) ready."
            '';
          };

          bot-finance-reporting = pkgs.mkShell {
            name = "analytics-reporting-dev";
            packages = [
              (python.withPackages (ps: with ps; [
                # Core analytics stack
                ps.pandas
                ps.numpy
                ps.scipy
                # Visualization
                ps.matplotlib
                ps.seaborn
                ps.plotly
                ps.bokeh
                ps.altair
                # Excel report generation
                ps.openpyxl
                ps.xlsxwriter
                # Notebooks and interactivity
                ps.jupyterlab
                ps.ipywidgets
                # Dashboards
                ps.dash
                ps.streamlit
                # Geospatial / maps
                ps.pygmt
                ps.cartopy
                # API data fetching
                ps.requests
                ps.httpx
                ps.aiohttp
                # Databases
                ps.sqlalchemy
                ps.psycopg2
                # Validation & utilities
                ps.pydantic
                ps.faker
                # Notebook export and formatting
                ps.nbconvert
                ps.jupyter
              ]))
              # System tools and libs
              pkgs.gdal
              pkgs.proj
              pkgs.geos
              pkgs.gmt
              pkgs.ghostscript
              pkgs.graphviz
              pkgs.pandoc
              (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small latexmk xetex; })
              pkgs.wkhtmltopdf
              pkgs.postgresql
            ] ++ baseTools;
            shellHook = ''
              export PYTHONNOUSERSITE=1
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export PG_CONFIG=$(which pg_config)
              echo "[analytics-reporting-dev] Python $(python --version) ready for analysis, dashboards, and reporting."
            '';
          };

          # =============================================================================
          # BACKEND DEVELOPMENT
          # =============================================================================
          
          go-backend = pkgs.mkShell {
            name = "go-cosmos-backend-dev";
            packages = [
              # Go toolchain and helpers
              go
              pkgs.gopls
              pkgs.delve
              pkgs.golangci-lint
              pkgs.gotestsum
              # Proto/gRPC
              pkgs.protobuf
              pkgs.buf
              pkgs.protoc-gen-go
              pkgs.protoc-gen-go-grpc
              pkgs.grpcurl
              # Cosmos/Tendermint
              (pkgs.ignite or pkgs.go-ethereum)
              (pkgs.cometbft or pkgs.tendermint)
              # DB clients/servers
              pkgs.postgresql
              pkgs.redis
              pkgs.sqlite
            ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export GOPATH=${"$PWD"}/.gopath
              export GOBIN=${"$GOPATH"}/bin
              export PATH=$GOBIN:$PATH
              export PATH=${pkgs.protoc-gen-go}/bin:${pkgs.protoc-gen-go-grpc}/bin:$PATH
              if [ -f go.mod ]; then
                echo "[go-cosmos-backend-dev] Detected go.mod; running 'go mod download'..."
                go mod download || true
              fi
              echo "[go-cosmos-backend-dev] Go $(${go}/bin/go version) ready. Protobuf: ${pkgs.protobuf}/bin/protoc, gRPC plugins installed."
            '';
          };

          # =============================================================================
          # CONNECTION BRIDGES
          # =============================================================================
          
          dotnet-bridge = pkgs.mkShell {
            name = ".net-bridge-dev";
            packages = [
              dotnet
            ] ++ protoTools ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export DOTNET_CLI_TELEMETRY_OPTOUT=1
              echo "[.net-bridge-dev] .NET $(${dotnet}/bin/dotnet --version) ready."
            '';
          };

          beam-bridge = pkgs.mkShell {
            name = "beam-bridge-dev";
            packages = [
              erlang
              elixir
              rebar3
            ] ++ protoTools ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export MIX_HOME="$PWD/.mix"
              export HEX_HOME="$PWD/.hex"
              export REBAR_CACHE_DIR="$PWD/.cache/rebar3"
              export PATH="$MIX_HOME/bin:$PATH"
              echo "[beam-bridge-dev] Erlang/Elixir ready."
            '';
          };

          python-fastapi-bridge = pkgs.mkShell {
            name = "python-bridge-fastapi-dev";
            packages = [
              (python.withPackages (ps: with ps; [
                ps.fastapi
                ps.starlette
                ps.aiohttp
                ps.httpx
                ps.requests
                ps.pydantic
                ps.uvicorn
                ps.hypercorn
                ps.websockets
                ps.loguru
              ]))
            ] ++ baseTools;
            shellHook = ''
              export PYTHONNOUSERSITE=1
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              echo "[python-bridge-fastapi-dev] Python $(python --version) ready for API/middleware bridging."
            '';
          };

          jvm-bridge = pkgs.mkShell {
            name = "jvm-bridge-dev";
            packages = [
              jdk
              maven
              gradle
            ] ++ protoTools ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export JAVA_HOME=${jdk}
              export PATH=${jdk}/bin:$PATH
              export MAVEN_OPTS="-Dfile.encoding=UTF-8 -Xms512m -Xmx2g"
              export GRADLE_OPTS="-Dfile.encoding=UTF-8 -Dorg.gradle.jvmargs='-Xms512m -Xmx2g'"
              echo "[jvm-bridge-dev] Java $(${jdk}/bin/java -version 2>&1 | head -n1) ready."
            '';
          };

          php-bridge = pkgs.mkShell {
            name = "php-bridge-dev";
            packages = [
              (pkgs.php82 or pkgs.php).withExtensions (exts: with exts; [ curl json openssl ])
              pkgs.phpPackages.composer
            ] ++ protoTools ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export COMPOSER_HOME="$PWD/.composer"
              echo "[php-bridge-dev] PHP ready."
            '';
          };

          # =============================================================================
          # BLOCKCHAIN & SMART CONTRACTS
          # =============================================================================
          
          rust-cosmos = pkgs.mkShell {
            name = "rust-blockchain-dev";
            packages = [
              (rust.override { extensions = [ "rust-src" "rustfmt" "clippy" ]; })
              cargo
            ] ++ protoTools ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export CARGO_HOME="$PWD/.cargo"
              export RUSTUP_HOME="$PWD/.rustup"
              export PATH="$CARGO_HOME/bin:$PATH"
              echo "[rust-blockchain-dev] Rust $(${rust}/bin/rustc --version) with Cargo $(cargo --version | awk '{print $2}') ready."
            '';
          };

          solidity-evm = pkgs.mkShell {
            name = "solidity-evm-dev";
            packages = [
              nodejs
              npm
              yarn
              solc
              foundry
            ] ++ protoTools ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
              export FOUNDRY_ROOT="$PWD/.foundry"
              echo "[solidity-evm-dev] Node.js $(node --version) with npm $(npm --version) and yarn $(yarn --version) ready."
            '';
          };

          # =============================================================================
          # FRONTEND DEVELOPMENT
          # =============================================================================
          
          flutter-dart = pkgs.mkShell {
            name = "dart-flutter-frontend-dev";
            packages = [
              dart
              flutter
              androidSdk
              (pkgs.jdk17 or pkgs.jdk)
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export PATH=${flutter}/bin:${dart}/bin:$PATH
              export PUB_CACHE="$PWD/.pub-cache"
              mkdir -p "$PUB_CACHE/bin"
              export PATH="$PUB_CACHE/bin:$PATH"
              export ANDROID_HOME=${androidSdk}/libexec/android-sdk
              export ANDROID_SDK_ROOT=$ANDROID_HOME
              export JAVA_HOME=${pkgs.jdk17 or pkgs.jdk}
              export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH
              echo "[dart-flutter-frontend-dev] Dart $(dart --version 2>&1 | head -n1), Flutter $(flutter --version 2>/dev/null | head -n1)."
            '';
          };

          kotlin-android = pkgs.mkShell {
            name = "kotlin-android-frontend-dev";
            packages = [
              (pkgs.jdk17 or pkgs.jdk)
              kotlin
              gradle
              androidSdk
              androidNdk
              androidTools
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export JAVA_HOME=${pkgs.jdk17 or pkgs.jdk}
              export PATH=${pkgs.jdk17 or pkgs.jdk}/bin:$PATH
              export ANDROID_HOME=${androidSdk}/libexec/android-sdk
              export ANDROID_SDK_ROOT=$ANDROID_HOME
              export ANDROID_NDK_HOME=${androidNdk}
              export ANDROID_NDK_ROOT=${androidNdk}
              export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH
              export GRADLE_USER_HOME="$PWD/.gradle"
              echo "[kotlin-android-frontend-dev] Java $(${pkgs.jdk17 or pkgs.jdk}/bin/java -version 2>&1 | head -n1), Gradle $(gradle --version 2>/dev/null | head -n1)."
            '';
          };

          swift-ios = pkgs.mkShell {
            name = "swift-frontend-dev";
            packages = [
              swift
            ] ++ pkgs.lib.optional (swiftformat != null) swiftformat
              ++ pkgs.lib.optional (swiftlint != null) swiftlint
              ++ pkgs.lib.optional (swiftgen != null) swiftgen
              ++ pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.cocoapods
              ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export PATH=${swift}/bin:$PATH
              echo "[swift-frontend-dev] Swift $(${swift}/bin/swift --version | head -n1)."
            '';
          };

          angular-frontend = pkgs.mkShell {
            name = "angular-ts-frontend-dev";
            packages = [
              nodejs
              npm
              yarn
              pnpm
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              corepack enable >/dev/null 2>&1 || true
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              mkdir -p "$NPM_CONFIG_PREFIX/bin"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
              echo "[angular-ts-frontend-dev] Node $(node --version), npm $(npm --version), yarn $(yarn --version), pnpm $(pnpm --version)."
            '';
          };

          next-frontend = pkgs.mkShell {
            name = "next-react-ts-frontend-dev";
            packages = [
              nodejs
              npm
              yarn
              pnpm
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              corepack enable >/dev/null 2>&1 || true
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              mkdir -p "$NPM_CONFIG_PREFIX/bin"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
              echo "[next-react-ts-frontend-dev] Node $(node --version), npm $(npm --version), yarn $(yarn --version), pnpm $(pnpm --version)."
            '';
          };

          nuxt-frontend = pkgs.mkShell {
            name = "nuxt-vue-ts-frontend-dev";
            packages = [
              nodejs
              npm
              yarn
              pnpm
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              corepack enable >/dev/null 2>&1 || true
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              mkdir -p "$NPM_CONFIG_PREFIX/bin"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
              echo "[nuxt-vue-ts-frontend-dev] Node $(node --version), npm $(npm --version), yarn $(yarn --version), pnpm $(pnpm --version)."
            '';
          };

          ts-shared = pkgs.mkShell {
            name = "ts-shared-tooling-dev";
            packages = [
              nodejs
              npm
              yarn
              pnpm
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              corepack enable >/dev/null 2>&1 || true
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              mkdir -p "$NPM_CONFIG_PREFIX/bin"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
              echo "[ts-shared-tooling-dev] Node $(node --version), npm $(npm --version), yarn $(yarn --version), pnpm $(pnpm --version)."
            '';
          };

          # =============================================================================
          # DEVELOPMENT TOOLS
          # =============================================================================
          
          proto-tools = pkgs.mkShell {
            name = "protobuf-compilation-dev";
            packages = [
              pkgs.protobuf
              pkgs.protoc-gen-go
              pkgs.protoc-gen-go-grpc
              pkgs.buf
              pkgs.grpcurl
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export PATH=${pkgs.protoc-gen-go}/bin:${pkgs.protoc-gen-go-grpc}/bin:$PATH
              echo "[protobuf-compilation-dev] protoc $(protoc --version | head -n1)"
            '';
          };

          bazel-dev = pkgs.mkShell {
            name = "bazel-dev";
            packages = [
              bazel
              bazelisk
              buildifier
              buildozer
              pkgs.openjdk17
              python
              go
            ] ++ [ yq ] ++ baseTools;
            shellHook = ''
              echo "🔨 Bazel Development Environment"
              echo "Available tools: bazel, bazelisk, buildifier, buildozer"
            '';
          };

          # =============================================================================
          # DEVOPS & INFRASTRUCTURE
          # =============================================================================
          
          ansible = pkgs.mkShell {
            name = "ansible-dev";
            packages = [
              ansible
              ansibleLint
              yamllint
              molecule
              docker
            ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              echo "[ansible-dev] ansible $(ansible --version | head -n1), ansible-lint $(ansible-lint --version | head -n1), molecule $(molecule --version | head -n1)."
            '';
          };

          k8s = pkgs.mkShell {
            name = "k8s-dev";
            packages = [
              kubectl
              kustomize
              helm
              kubeseal
              kubeval
              kind
            ] ++ [ yaml2json ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              echo "[k8s-dev] kubectl $(kubectl version --client --short 2>/dev/null | head -n1), helm $(helm version --short), kustomize $(kustomize version --short), kind $(kind version | head -n1)."
            '';
          };

          terraform = pkgs.mkShell {
            name = "terraform-dev";
            packages = [
              terraform
              terraformLs
              tflint
              terragrunt
              awscli
              gcloud
              azureCli
            ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              echo "[terraform-dev] terraform $(terraform version | head -n1), tflint $(tflint --version | head -n1), terragrunt $(terragrunt --version | head -n1)."
            '';
          };

          # =============================================================================
          # DEFAULT SHELL
          # =============================================================================
          default = pkgs.mkShell { packages = [ pkgs.git ]; };
        };
      }
    );
}