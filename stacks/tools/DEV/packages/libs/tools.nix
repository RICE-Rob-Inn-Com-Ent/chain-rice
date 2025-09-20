{ pkgs, lib, ... }:

let
  # AUTO tools (build automation, proto generation)
  autoTools = with pkgs; [
    # Build tools
    make
    cmake
    ninja
    meson
    bazel
    
    # Protocol Buffers
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    protoc-gen-grpc-web
    buf
    grpcurl
    
    # Shell tools
    bash
    zsh
    fish
    dash
    tcsh
    ksh
    
    # Scripting languages
    python311
    nodejs_20
    ruby
    perl
    lua
  ];

  # CONTRACTS tools (blockchain smart contracts)
  contractTools = with pkgs; [
    # Rust for CosmWasm
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
    
    # Solidity for Ethereum
    solc
    foundry
    hardhat
    truffle
    
    # Blockchain tools
    geth
    parity
    cosmos-sdk
    tendermint
    cosmwasm-workspace
    
    # Testing
    forge
    anvil
    cast
    chisel
  ];

  # DATA tools (AI, SQL, data science)
  dataTools = with pkgs; [
    # Python data science
    python311
    python311Packages.numpy
    python311Packages.pandas
    python311Packages.scipy
    python311Packages.matplotlib
    python311Packages.seaborn
    python311Packages.plotly
    python311Packages.jupyter
    python311Packages.notebook
    
    # Machine Learning
    python311Packages.tensorflow
    python311Packages.pytorch
    python311Packages.scikit-learn
    python311Packages.keras
    python311Packages.opencv4
    
    # Julia
    julia_18
    julia-stdlib
    
    # Octave/Matlab
    octave
    octavePackages.control
    octavePackages.signal
    octavePackages.statistics
    
    # Databases
    postgresql_16
    mysql
    sqlite
    redis
    mongodb
    influxdb
    clickhouse
    
    # SQL tools
    postgresql_16
    mysql
    sqlite
    redis
    mongodb
    
    # Data visualization
    gnuplot
    graphviz
    plantuml
    mermaid-cli
  ];

  # DEV tools (development infrastructure)
  devTools = with pkgs; [
    # Version control
    git
    git-lfs
    gh
    gitlab-runner
    
    # CI/CD
    github-runner
    gitlab-runner
    jenkins
    drone-cli
    tekton-cli
    
    # Containerization
    docker
    docker-compose
    podman
    buildah
    skopeo
    
    # Kubernetes
    kubectl
    helm
    kustomize
    k9s
    k3s
    minikube
    kind
    
    # Infrastructure as Code
    terraform
    terragrunt
    pulumi
    ansible
    vagrant
    
    # Monitoring
    prometheus
    grafana
    jaeger
    zipkin
    elasticsearch
    kibana
    logstash
    fluentd
    
    # Security
    vault
    consul
    nomad
    trivy
    snyk
    bandit
    semgrep
  ];

  # MISC tools (experimental languages)
  miscTools = with pkgs; [
    # Functional languages
    haskell
    ghc
    stack
    cabal-install
    
    # OCaml
    ocaml
    opam
    dune
    merlin
    
    # C++
    gcc
    clang
    gdb
    valgrind
    cppcheck
    clang-tools
    
    # System languages
    rustc
    cargo
    go
    zig
    nim
    crystal
    
    # Scripting
    python311
    ruby
    perl
    lua
    tcl
    guile
  ];

in
{
  # AUTO package
  chainrice-auto = pkgs.stdenv.mkDerivation rec {
    pname = "chainrice-auto";
    version = "1.0.0";
    src = ./.;
    
    buildInputs = autoTools;
    
    buildPhase = ''
      make build
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      cp -r . $out/
    '';
    
    meta = with lib; {
      description = "ChainRice automation tools and build scripts";
      homepage = "https://github.com/chainrice/auto";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # CONTRACTS package
  chainrice-contracts = pkgs.stdenv.mkDerivation rec {
    pname = "chainrice-contracts";
    version = "1.0.0";
    src = ./.;
    
    buildInputs = contractTools;
    
    buildPhase = ''
      # Build CosmWasm contracts
      cd stacks/tools/CONTRACTS/rust
      cargo build --release
      
      # Build Solidity contracts
      cd ../solidity
      forge build
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      cp -r . $out/
    '';
    
    meta = with lib; {
      description = "ChainRice smart contracts for various blockchains";
      homepage = "https://github.com/chainrice/contracts";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # DATA package
  chainrice-data = pkgs.stdenv.mkDerivation rec {
    pname = "chainrice-data";
    version = "1.0.0";
    src = ./.;
    
    buildInputs = dataTools;
    
    buildPhase = ''
      # Build Python packages
      cd stacks/tools/DATA/python
      pip install -e .
      
      # Build Julia packages
      cd ../julia
      julia --project=. -e "using Pkg; Pkg.instantiate()"
      
      # Build Octave packages
      cd ../octave
      octave --eval "pkg install -local -auto ."
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      cp -r . $out/
    '';
    
    meta = with lib; {
      description = "ChainRice data science and AI tools";
      homepage = "https://github.com/chainrice/data";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # DEV package
  chainrice-dev = pkgs.stdenv.mkDerivation rec {
    pname = "chainrice-dev";
    version = "1.0.0";
    src = ./.;
    
    buildInputs = devTools;
    
    buildPhase = ''
      # Build Docker images
      cd stacks/tools/DEV/docker
      docker build -t chainrice-dev .
      
      # Build Terraform modules
      cd ../terraform
      terraform init
      terraform plan
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      cp -r . $out/
    '';
    
    meta = with lib; {
      description = "ChainRice development infrastructure and DevOps tools";
      homepage = "https://github.com/chainrice/dev";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # MISC package
  chainrice-misc = pkgs.stdenv.mkDerivation rec {
    pname = "chainrice-misc";
    version = "1.0.0";
    src = ./.;
    
    buildInputs = miscTools;
    
    buildPhase = ''
      # Build Haskell packages
      cd stacks/tools/MISC/haskell
      stack build
      
      # Build OCaml packages
      cd ../ocaml
      dune build
      
      # Build C++ packages
      cd ../cplusplus
      make build
    '';
    
    installPhase = ''
      mkdir -p $out/bin
      cp -r . $out/
    '';
    
    meta = with lib; {
      description = "ChainRice experimental and miscellaneous tools";
      homepage = "https://github.com/chainrice/misc";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # All tools packages
  all = with pkgs; [
    chainrice-auto
    chainrice-contracts
    chainrice-data
    chainrice-dev
    chainrice-misc
    
    # Individual tool sets
    autoTools
    contractTools
    dataTools
    devTools
    miscTools
  ];
}
