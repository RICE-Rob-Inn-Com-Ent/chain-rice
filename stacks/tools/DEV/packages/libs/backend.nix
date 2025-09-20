{ pkgs, lib, ... }:

let
  # Go packages for ChainRice main services
  goPackages = with pkgs; [
    go_1_24
    gopls
    golangci-lint
    go-tools
    staticcheck
    gosec
    gomock
    mockgen
    protoc-gen-go
    protoc-gen-go-grpc
  ];

  # .NET packages for bridge
  dotnetPackages = with pkgs; [
    dotnet-sdk_8
    dotnet-aspnetcore_8
    dotnet-runtime_8
    nuget-to-nix
  ];

  # BEAM (Erlang/Elixir) packages
  beamPackages = with pkgs; [
    erlang_26
    elixir_1_16
    rebar3
    hex
    mix2nix
  ];

  # Python packages for bridge
  pythonPackages = with pkgs; [
    python311
    python311Packages.pip
    python311Packages.setuptools
    python311Packages.wheel
    python311Packages.httpx
    python311Packages.grpc
    python311Packages.protobuf
    python311Packages.pytest
    python311Packages.black
    python311Packages.isort
    python311Packages.mypy
    python311Packages.flake8
  ];

  # JVM packages
  jvmPackages = with pkgs; [
    jdk17
    gradle_8
    maven
    sbt
    scala_2_13
    kotlin
    groovy
    clojure
  ];

  # PHP packages
  phpPackages = with pkgs; [
    php83
    php83Packages.composer
    php83Packages.phpunit
    php83Packages.phpstan
    php83Packages.phpcs
  ];

  # Database packages
  databasePackages = with pkgs; [
    postgresql_16
    mysql
    sqlite
    redis
    mongodb
  ];

  # Protocol Buffers and gRPC
  protoPackages = with pkgs; [
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    protoc-gen-grpc-web
    buf
    grpcurl
  ];

  # Development tools
  devTools = with pkgs; [
    git
    curl
    wget
    jq
    yq
    tree
    htop
    tmux
    vim
    nano
  ];

in
{
  # Main ChainRice Go services
  chainrice-go = pkgs.buildGoModule rec {
    pname = "chainrice-go";
    version = "1.0.0";
    src = ./.;
    
    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    
    subPackages = [
      "modules/blockchain/cmd"
      "modules/accounting-api/cmd"
      "modules/tax-api/cmd"
    ];
    
    meta = with lib; {
      description = "ChainRice Go services - blockchain, accounting, and tax APIs";
      homepage = "https://github.com/chainrice/chainrice-go";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # .NET Bridge
  chainrice-dotnet-bridge = pkgs.buildDotnetModule rec {
    pname = "chainrice-dotnet-bridge";
    version = "1.0.0";
    src = ./.;
    
    projectFile = "stacks/backend/.NET/ChainRice.Bridge.csproj";
    nugetDeps = ./stacks/backend/.NET/packages.nix;
    
    meta = with lib; {
      description = "ChainRice .NET bridge for connecting to Go services";
      homepage = "https://github.com/chainrice/bridge-dotnet";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # BEAM Bridge
  chainrice-beam-bridge = pkgs.beamPackages.mixRelease rec {
    pname = "chainrice-beam-bridge";
    version = "1.0.0";
    src = ./.;
    
    mixNixDeps = import ./stacks/backend/BEAM/mix.nix { inherit pkgs; };
    
    meta = with lib; {
      description = "ChainRice BEAM bridge for connecting to Go services";
      homepage = "https://github.com/chainrice/bridge-beam";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # Python Bridge
  chainrice-python-bridge = pkgs.python311Packages.buildPythonPackage rec {
    pname = "chainrice-python-bridge";
    version = "1.0.0";
    src = ./.;
    
    propagatedBuildInputs = with pkgs.python311Packages; [
      httpx
      grpcio
      protobuf
      pydantic
      loguru
    ];
    
    meta = with lib; {
      description = "ChainRice Python bridge for connecting to Go services";
      homepage = "https://github.com/chainrice/bridge-python";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # JVM Bridge
  chainrice-jvm-bridge = pkgs.gradle.buildGradlePackage rec {
    pname = "chainrice-jvm-bridge";
    version = "1.0.0";
    src = ./.;
    
    gradleFlags = [ "build" ];
    
    meta = with lib; {
      description = "ChainRice JVM bridge for connecting to Go services";
      homepage = "https://github.com/chainrice/bridge-jvm";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # PHP Bridge
  chainrice-php-bridge = pkgs.php.buildComposerProject rec {
    pname = "chainrice-php-bridge";
    version = "1.0.0";
    src = ./.;
    
    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    
    meta = with lib; {
      description = "ChainRice PHP bridge for connecting to Go services";
      homepage = "https://github.com/chainrice/bridge-php";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  # All backend packages
  all = with pkgs; [
    # Core Go services
    chainrice-go
    
    # Bridge libraries
    chainrice-dotnet-bridge
    chainrice-beam-bridge
    chainrice-python-bridge
    chainrice-jvm-bridge
    chainrice-php-bridge
    
    # Language runtimes
    goPackages
    dotnetPackages
    beamPackages
    pythonPackages
    jvmPackages
    phpPackages
    
    # Databases
    databasePackages
    
    # Protocol tools
    protoPackages
    
    # Development tools
    devTools
  ];
}
