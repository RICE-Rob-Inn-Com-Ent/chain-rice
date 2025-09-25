# JVM bridge to JVM-based servers — 2025
#
# Usage: import this file from your flake and expose it as a devShell.
# Then run: `nix develop` for a ready-to-use shell.
#
# Focus: Essential integration/middleware only. Dependencies like gRPC, protobuf,
# OkHttp/HttpClient/Retrofit, Jackson/Gson, SLF4J/Logback/Log4j2 are resolved
# via Maven/Gradle in your project. This shell provides JDK + build tools and
# protobuf/gRPC utilities for code generation and testing.

{ pkgs ? let
    flake = builtins.getFlake "nixpkgs";
    system = builtins.currentSystem;
  in flake.legacyPackages.${system}
}: let
  # Java toolchain (prefer JDK 21+, fallback to latest available)
  jdk = pkgs.jdk21 or pkgs.jdk20 or pkgs.jdk;

  # Build tools
  maven = pkgs.maven;
  gradle = pkgs.gradle;

  # Protobuf/gRPC tooling
  protoc = pkgs.protobuf;
  buf = pkgs.buf;
  grpcurl = pkgs.grpcurl;

in pkgs.mkShell {
  name = "jvm-bridge-dev";

  packages = [
    jdk
    maven
    gradle

    protoc
    buf
    grpcurl

    # Useful CLI utilities
    pkgs.git
    pkgs.curl
    pkgs.jq
    pkgs.openssl
    pkgs.pkg-config
  ];

  shellHook = ''
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Java environment
    export JAVA_HOME=${jdk}
    export PATH=${jdk}/bin:$PATH

    # Maven/Gradle tuning
    export MAVEN_OPTS="-Dfile.encoding=UTF-8 -Xms512m -Xmx2g"
    export GRADLE_OPTS="-Dfile.encoding=UTF-8 -Dorg.gradle.jvmargs='-Xms512m -Xmx2g'"

    echo "[jvm-bridge-dev] Java $(${jdk}/bin/java -version 2>&1 | head -n1) ready."
    echo "Use Maven/Gradle to add:"
    echo "- gRPC: io.grpc:grpc-netty, grpc-protobuf, grpc-stub"
    echo "- Protobuf: com.google.protobuf:protobuf-java"
    echo "- HTTP: com.squareup.okhttp3:okhttp, org.apache.httpcomponents.client5:httpclient5, com.squareup.retrofit2:retrofit"
    echo "- JSON: com.fasterxml.jackson.core:jackson-databind, com.google.code.gson:gson"
    echo "- Logging: org.slf4j:slf4j-api + ch.qos.logback:logback-classic or org.apache.logging.log4j:log4j-core"
    echo "Protobuf tools: protoc=${protoc}/bin/protoc, buf=${buf}/bin/buf, grpcurl available."
  '';
}
