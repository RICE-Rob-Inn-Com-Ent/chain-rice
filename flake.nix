{
  description = "rice-dev: Unified Nix dev shells with Bazel integration (2025) - Complete Monorepo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix.url = "github:nix-community/poetry2nix";
    rust-overlay.url = "github:oxalica/rust-overlay";
    node2nix.url = "github:nix-community/node2nix";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, rust-overlay, node2nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Overlays to tweak packages
        overlays = [
          poetry2nix.overlays.default
          rust-overlay.overlays.default
          (final: prev: {
            python311Packages = prev.python311Packages // {
              # Avoid test failure in pytest-doctestplus (numpy ufunc __code__)
              pytest-doctestplus = prev.python311Packages.pytest-doctestplus.overrideAttrs (old: {
                doCheck = false;
              });
            };
          })
        ];

        pkgs = import nixpkgs { 
          inherit system overlays;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
              "android-sdk-cmdline-tools"
              "androidsdk"
              "terraform"
              "cuda-toolkit"
              "cudnn"
            ];
            android_sdk.accept_license = true;
          };
        };

        # Feature toggles from environment
        androidEnabled = (builtins.getEnv "INCLUDE_ANDROID") == "1";

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
        rust = pkgs.rustc;
        cargo = pkgs.cargo;

        # .NET toolchain
        dotnet = pkgs.dotnet-sdk_8 or pkgs.dotnet-sdk;

        # BEAM toolchain
        beam = pkgs.beam.packages.erlang_26;
        erlang = beam.erlang;
        elixir = beam.elixir_1_15;
        rebar3 = beam.rebar3;

        # Android toolchain
        androidSdk = pkgs.androidsdk;
        androidTools = pkgs.android-tools;

        # CUDA toolchain
        cudaPkgs = pkgs.cudaPackages;

        # Julia toolchain
        julia = pkgs.julia-bin or pkgs.julia;

        # Dart/Flutter toolchain
        dart = pkgs.dart;
        flutter = pkgs.flutter;

        # Swift toolchain (only on macOS)
        swift = pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.swift;
        swiftformat = pkgs.lib.optional pkgs.stdenv.isDarwin (pkgs.swift-format or pkgs.swiftformat);
        swiftlint = pkgs.lib.optional pkgs.stdenv.isDarwin (pkgs.swiftlint or null);
        swiftgen = pkgs.lib.optional pkgs.stdenv.isDarwin (pkgs.swiftgen or null);

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

        # Kafka toolchain
        kafka = pkgs.apacheKafka;
        zookeeper = pkgs.zookeeper;

        # Additional tools
        unzip = pkgs.unzip;
        which = pkgs.which;
        yq = pkgs.yq;
        yaml2json = pkgs.yaml2json;

        # PHP toolchain
        php = pkgs.php;
        composer = pkgs.phpPackages.composer;

        # Development tools
        concurrently = pkgs.nodePackages.concurrently;
        nodemon = pkgs.nodePackages.nodemon;
        pm2 = pkgs.nodePackages.pm2;

      in {
        devShells = {
          # =============================================================================
          # AI & BOT DEVELOPMENT
          # =============================================================================
          
          bot-core = pkgs.mkShell {
            name = "ai-core-dev";
            packages = [
              (python.withPackages (ps: with ps; [
                numpy
                pandas
                scipy
                scikit-learn
                matplotlib
                seaborn
                plotly
                torch
                torchvision
                torchaudio
                transformers
                diffusers
                accelerate
                openai
                huggingface-hub
                sentence-transformers
                langchain
                llama-index
                faiss-cpu
                chromadb
                pillow
                opencv-python
                soundfile
                pydub
                tiktoken
                fastapi
                uvicorn
                requests
                httpx
                aiohttp
                websockets
                pydantic
                pyyaml
                orjson
                loguru
                structlog
                apscheduler
                python-multipart
                python-jose
                passlib
                bcrypt
                python-dotenv
                tqdm
                jinja2
                black
                ruff
                pytest
                ipykernel
                notebook
                jupyterlab
              ]))
              pkgs.gcc
              pkgs.cmake
              pkgs.zlib
              pkgs.ffmpeg
              pkgs.libsndfile
              pkgs.ncurses
              pkgs.openblas
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
              # Julia
              julia
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
              # Kafka toolchain (includes Sarama via Go modules)
              kafka
              zookeeper
            ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export GOPATH=${"$PWD"}/.gopath
              export GOBIN=${"$GOPATH"}/bin
              export PATH=$GOBIN:$PATH
              export PATH=${pkgs.protoc-gen-go}/bin:${pkgs.protoc-gen-go-grpc}/bin:$PATH
              # Kafka environment
              export KAFKA_HOME=${kafka}
              export PATH=${kafka}/bin:$PATH
              if [ -f go.mod ]; then
                echo "[go-cosmos-backend-dev] Detected go.mod; running 'go mod download'..."
                go mod download || true
              fi
              echo "[go-cosmos-backend-dev] Go $(${go}/bin/go version) ready. Protobuf: ${pkgs.protobuf}/bin/protoc, gRPC plugins installed."
              echo "[go-cosmos-backend-dev] Kafka tools available: kafka-topics, kafka-console-producer, kafka-console-consumer"
              echo "[go-cosmos-backend-dev] Note: Use 'go get github.com/IBM/sarama' to install Sarama Kafka client for Go"
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
                # FastAPI and web server
                fastapi
                uvicorn
                # HTTP clients  
                requests
                httpx
                # AI integrations
                openai
                huggingface-hub
                # Data validation
                pydantic
                # Async support
                aiohttp
                websockets
                # Logging
                loguru
                structlog
                # Basic utilities
                pyyaml
                orjson
                # Additional useful packages
                python-multipart
                python-jose
                passlib
                bcrypt
                # Development tools
                pip
                setuptools
                wheel
              ]))
            ] ++ baseTools;
            shellHook = ''
              export PYTHONNOUSERSITE=1
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              echo "[python-bridge-fastapi-dev] Python $(python --version) with all dependencies ready."
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
              pkgs.php
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
              rust
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
              androidTools
            ] ++ [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export JAVA_HOME=${pkgs.jdk17 or pkgs.jdk}
              export PATH=${pkgs.jdk17 or pkgs.jdk}/bin:$PATH
              export ANDROID_HOME=${androidSdk}/libexec/android-sdk
              export ANDROID_SDK_ROOT=$ANDROID_HOME
              export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH
              export GRADLE_USER_HOME="$PWD/.gradle"
              echo "[kotlin-android-frontend-dev] Java $(${pkgs.jdk17 or pkgs.jdk}/bin/java -version 2>&1 | head -n1), Gradle $(gradle --version 2>/dev/null | head -n1)."
            '';
          };

          swift-ios = pkgs.mkShell {
            name = "swift-frontend-dev";
            packages = if pkgs.stdenv.isDarwin then [
              pkgs.swift
            ] ++ pkgs.lib.optional (pkgs.swift-format != null) pkgs.swift-format
              ++ pkgs.lib.optional (pkgs.swiftlint != null) pkgs.swiftlint
              ++ pkgs.lib.optional (pkgs.swiftgen != null) pkgs.swiftgen
              ++ pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.cocoapods
              ++ [ unzip which ] ++ baseTools else [ unzip which ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              if [ "$(uname)" = "Darwin" ]; then
                export PATH=${pkgs.swift}/bin:$PATH
                echo "[swift-frontend-dev] Swift $(${pkgs.swift}/bin/swift --version | head -n1)."
              else
                echo "[swift-frontend-dev] Swift is only available on macOS."
              fi
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
          # MESSAGING & STREAMING
          # =============================================================================
          
          kafka-dev = pkgs.mkShell {
            name = "kafka-messaging-dev";
            packages = [
              # Kafka toolchain
              kafka
              zookeeper
              # Go for Sarama client development
              go
              pkgs.gopls
              # Python for kafka-python client development
              python
              # Node.js for kafkajs client development
              nodejs
              npm
            ] ++ baseTools;
            shellHook = ''
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8
              export KAFKA_HOME=${kafka}
              export PATH=${kafka}/bin:$PATH
              export GOPATH=${"$PWD"}/.gopath
              export GOBIN=${"$GOPATH"}/bin
              export PATH=$GOBIN:$PATH
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
              echo "[kafka-messaging-dev] Kafka development environment ready."
              echo "[kafka-messaging-dev] Available clients:"
              echo "  - Go: go get github.com/IBM/sarama"
              echo "  - Python: pip install kafka-python"
              echo "  - Node.js: npm install kafkajs"
              echo "  - CLI tools: kafka-topics, kafka-console-producer, kafka-console-consumer"
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
              # Ensure Terraform data dir is always at the repo root
              REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
              export TF_DATA_DIR="$REPO_ROOT/.terraform"
              echo "[terraform-dev] terraform $(terraform version | head -n1), tflint $(tflint --version | head -n1), terragrunt $(terragrunt --version | head -n1)."
            '';
          };

          # =============================================================================
          # MONOREPO DEVELOPMENT
          # =============================================================================
          
          monorepo = pkgs.mkShell {
            name = "rice-dev-monorepo";
            packages = [
              # Core development tools
              pkgs.git
              pkgs.curl
              pkgs.jq
              pkgs.openssl
              pkgs.pkg-config
              
              # Python ecosystem (AI/Bots + FastAPI)
              (python.withPackages (ps: with ps; [
                # Core runtime (lean, reliable)
                numpy
                pandas
                scipy
                scikit-learn
                matplotlib
                seaborn
                plotly
                # Web / FastAPI
                fastapi
                uvicorn
                requests
                httpx
                aiohttp
                websockets
                # AI Integrations
                openai
                huggingface-hub
                transformers
                diffusers
                accelerate
                torch
                torchvision
                torchaudio
                sentence-transformers
                langchain
                llama-index
                faiss-cpu
                chromadb
                python-telegram-bot
                discordpy
                slack-sdk
                # Audio/Image processing
                pillow
                opencv-python
                soundfile
                pydub
                tiktoken
                # Finance & Analytics
                statsmodels
                # Data & Validation
                pydantic
                pyyaml
                orjson
                # Dev essentials
                pip
                setuptools
                wheel
                # Logging & schedulers
                loguru
                structlog
                apscheduler
                # Auth & multipart
                python-multipart
                python-jose
                passlib
                bcrypt
                # Development tools
                black
                ruff
                pytest
                ipykernel
                notebook
                jupyterlab
                # Additional utilities
                python-dotenv
                tqdm
                jinja2
              ]))
              
              # Go ecosystem (Backend + Blockchain)
              go
              pkgs.gopls
              pkgs.delve
              pkgs.golangci-lint
              pkgs.gotestsum
              
              # Java ecosystem (JVM Bridge)
              jdk
              maven
              gradle
              
              # Node.js ecosystem (Frontend)
              nodejs
              npm
              yarn
              pnpm
              concurrently
              nodemon
              pm2
              
              # Rust ecosystem (Blockchain contracts)
              rust
              cargo
              
              # BEAM ecosystem (Elixir/Erlang)
              erlang
              elixir
              rebar3
              
              # .NET ecosystem
              dotnet
              
              # PHP ecosystem
              php
              composer
              
              # Frontend frameworks
              dart
              flutter
              kotlin
            ] ++ (pkgs.lib.optionals androidEnabled [ androidSdk androidTools ])
            ++ [
              
              # Blockchain tools
              solc
              foundry
              
              # DevOps & Infrastructure
              terraform
              terraformLs
              tflint
              terragrunt
              kubectl
              kustomize
              helm
              kubeseal
              kubeval
              kind
              ansible
              ansibleLint
              yamllint
              molecule
              docker
              
              # Cloud CLIs
              awscli
              gcloud
              azureCli
              
              # Protobuf/gRPC
              pkgs.protobuf
              pkgs.buf
              pkgs.grpcurl
              pkgs.protoc-gen-go
              pkgs.protoc-gen-go-grpc
              
              # Bazel ecosystem
              bazel
              bazelisk
              buildifier
              buildozer
              
              # Messaging
              kafka
              zookeeper
              
              # Additional tools
              pkgs.gcc
              pkgs.cmake
              pkgs.zlib
              pkgs.ffmpeg
              pkgs.libsndfile
              pkgs.ncurses
              pkgs.openblas
              pkgs.unzip
              pkgs.which
              pkgs.yq
              pkgs.yaml2json
              pkgs.parallel
              pkgs.htop
              pkgs.vim
              pkgs.nano
              
              # CUDA support
              cudaPkgs.cudatoolkit
              cudaPkgs.cudnn
            ];
            shellHook = ''
              # Environment setup
              export PYTHONNOUSERSITE=1
              export LC_ALL=C.UTF-8
              export LANG=C.UTF-8

              # Git repo root and Terraform data dir
              REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
              export TF_DATA_DIR="$REPO_ROOT/.terraform"
              
              # Go environment
              export GOPATH="$PWD/.gopath"
              export GOBIN="$GOPATH/bin"
              export PATH="$GOBIN:$PATH"
              export PATH="${pkgs.protoc-gen-go}/bin:${pkgs.protoc-gen-go-grpc}/bin:$PATH"
              
              # Java environment
              export JAVA_HOME=${jdk}
              export PATH=${jdk}/bin:$PATH
              export MAVEN_OPTS="-Dfile.encoding=UTF-8 -Xms512m -Xmx2g"
              export GRADLE_OPTS="-Dfile.encoding=UTF-8 -Dorg.gradle.jvmargs='-Xms512m -Xmx2g'"
              
              # Node.js environment
              corepack enable >/dev/null 2>&1 || true
              export NPM_CONFIG_PREFIX="$PWD/.npm-global"
              mkdir -p "$NPM_CONFIG_PREFIX/bin"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
              
              # Rust environment
              export CARGO_HOME="$PWD/.cargo"
              export RUSTUP_HOME="$PWD/.rustup"
              export PATH="$CARGO_HOME/bin:$PATH"
              
              # BEAM environment
              export MIX_HOME="$PWD/.mix"
              export HEX_HOME="$PWD/.hex"
              export REBAR_CACHE_DIR="$PWD/.cache/rebar3"
              export PATH="$MIX_HOME/bin:$PATH"
              
              # .NET environment
              export DOTNET_CLI_TELEMETRY_OPTOUT=1
              
              # PHP environment
              export COMPOSER_HOME="$PWD/.composer"
              
              # Flutter/Dart environment
              export PATH=${flutter}/bin:${dart}/bin:$PATH
              export PUB_CACHE="$PWD/.pub-cache"
              mkdir -p "$PUB_CACHE/bin"
              export PATH="$PUB_CACHE/bin:$PATH"
              export ANDROID_HOME=${androidSdk}/libexec/android-sdk
              export ANDROID_SDK_ROOT=$ANDROID_HOME
              export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH
              
              # CUDA environment
              export CUDA_PATH=${cudaPkgs.cudatoolkit}
              export XLA_FLAGS=--xla_gpu_cuda_data_dir=${cudaPkgs.cudatoolkit}
              export TF_CUDA_PATHS=${cudaPkgs.cudatoolkit}:${cudaPkgs.cudnn}
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ cudaPkgs.cudatoolkit cudaPkgs.cudnn ]}:$LD_LIBRARY_PATH
              
              # Kafka environment
              export KAFKA_HOME=${kafka}
              export PATH=${kafka}/bin:$PATH
              
              # Terraform environment
              export TF_CLI_CONFIG_FILE="$PWD/.terraformrc"
              
              # Docker environment
              export DOCKER_CONFIG="$PWD/.docker"
              
              # Bazel environment
              export BAZEL_USE_CPP_ONLY_TOOLCHAIN=1
              
              # Create necessary directories
              mkdir -p .gopath .npm-global .cargo .rustup .mix .hex .cache/rebar3 .composer .pub-cache .docker
              
              # Initialize Go modules if needed
              if [ -f libs/backend/go.mod ]; then
                echo "📦 Initializing Go modules..."
                cd libs/backend && go mod download || true && cd ../..
              fi
              
              # Initialize Python packages if needed
              if [ -f bots/pyproject.toml ]; then
                echo "🐍 Installing Python requirements..."
                cd bots && poetry install || pip install -r requirements.txt || true && cd ..
              fi
              
              # Initialize Node.js packages if needed
              if [ -f libs/frontend/ts/package.json ]; then
                echo "📦 Installing Node.js dependencies..."
                cd libs/frontend/ts && npm install || yarn install || pnpm install || true && cd ../../..
              fi
              
              # Initialize Julia packages if needed
              if [ -f bots/Project.toml ]; then
                echo "🔬 Initializing Julia packages..."
                cd bots && julia --project=. -e "using Pkg; Pkg.instantiate()" || true && cd ..
              fi
              
              # Initialize Rust packages if needed
              if [ -f libs/contract/rust/Cargo.toml ]; then
                echo "🦀 Initializing Rust packages..."
                cd libs/contract/rust && cargo fetch || true && cd ../../..
              fi
              
              # Initialize .NET packages if needed
              if [ -f libs/connection/.NET/ConnectionDotNet.csproj ]; then
                echo "🔷 Initializing .NET packages..."
                cd libs/connection/.NET && dotnet restore || true && cd ../../..
              fi
              
              # Initialize PHP packages if needed
              if [ -f libs/connection/PHP/composer.json ]; then
                echo "🐘 Initializing PHP packages..."
                cd libs/connection/PHP && composer install || true && cd ../../..
              fi
              
              # Initialize Maven packages if needed
              if [ -f libs/connection/JVM/pom.xml ]; then
                echo "☕ Initializing Maven packages..."
                cd libs/connection/JVM && mvn dependency:resolve || true && cd ../../..
              fi
              
              # Initialize Flutter packages if needed
              if [ -f libs/frontend/dart/pubspec.yaml ]; then
                echo "📱 Initializing Flutter packages..."
                cd libs/frontend/dart && flutter pub get || true && cd ../../..
              fi
              
              # Display environment info
              echo ""
              echo "🚀 RICE-DEV MONOREPO ENVIRONMENT READY!"
              echo "======================================"
              echo "🐍 Python: $(python --version)"
              echo "🐹 Go: $(${go}/bin/go version)"
              echo "☕ Java: $(${jdk}/bin/java -version 2>&1 | head -n1)"
              echo "📦 Node.js: $(node --version)"
              echo "🦀 Rust: $(${rust}/bin/rustc --version)"
              echo "🔧 Bazel: $(bazel --version | head -n1)"
              echo "🐳 Docker: $(docker --version)"
              echo "☸️  Kubernetes: $(kubectl version --client --short 2>/dev/null | head -n1)"
              echo "🏗️  Terraform: $(terraform version | head -n1)"
              echo "🔷 .NET: $(dotnet --version)"
              echo "🐘 PHP: $(php --version | head -n1)"
              echo "📱 Flutter: $(flutter --version 2>/dev/null | head -n1)"
              echo "🔬 Julia: $(julia --version | head -n1)"
              echo ""
              echo "Available commands:"
              echo "  bazel run //:dev          - Enter development mode"
              echo "  bazel run //:build        - Build all targets"
              echo "  bazel run //:test         - Test all targets"
              echo "  ./scripts/start-all.sh    - Start all services"
              echo "  ./scripts/dev-watch.sh   - Start development with hot reload"
              echo "  ./scripts/dev-services.sh - Start all services concurrently"
              echo ""
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