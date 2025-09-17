{ pkgs }:

{
  packages = with pkgs; [
    # JVM & Scala toolchain
    jdk21
    scala
    sbt
    scala-cli
    coursier
    ammonite
    mill

    # Language server & build server
    metals
    bloop

    # Formatting & linting
    scalafmt
    scalafix

    # Profiling/monitoring
    jdk-mission-control
    visualvm

    # Utilities
    git
    curl
    ripgrep
    fd
    unzip
    zip
  ];
  
  envVars = {
    # Java/Scala configuration
    JAVA_HOME = "${pkgs.jdk21.home}";
    LANG = "en_US.UTF-8";

    # sbt configuration
    SBT_OPTS = "-Xms512m -Xmx4g -XX:+UseG1GC -XX:+UseStringDeduplication -Dsbt.log.noformat=true";
    JAVA_OPTS = "-Xms512m -Xmx4g -XX:+UseG1GC";
    COURSIER_CACHE = "$HOME/.cache/coursier";

    # Project root hint
    CHAINRICE_SCALA_ROOT = "$PWD/stacks/langs/scala";
  };
  
  shellHook = ''
    echo "🟦 Scala $(scala -version 2>&1 | head -n1 | sed 's/.*version //') / sbt $(sbt --version 2>&1 | head -n1 | sed 's/sbt //')"
    echo "   • Metals/Bloop, Scalafmt/Scalafix, Ammonite, Mill, Scala-CLI"

    export JAVA_HOME="${JAVA_HOME}"

    # Ensure coursier cache exists
    mkdir -p "$COURSIER_CACHE"

    # Prefer project sbt wrapper if present
    if [ -f "sbt" ]; then
      chmod +x sbt
      alias sbt='./sbt'
    fi

    # Warm sbt (non-blocking) if a build is detected
    if [ -f "build.sbt" ] || [ -d "project" ]; then
      (sbt -Dsbt.log.noformat=true --error about >/dev/null 2>&1 || true) &
    fi

    # Bloop warm-up (non-blocking)
    if command -v bloop >/dev/null 2>&1; then
      (bloop about >/dev/null 2>&1 || true) &
    fi

    # Metals hint
    if command -v metals >/dev/null 2>&1; then
      echo "💡 Metals available. Open the project in your editor to start the LSP."
    fi

    # Helpful aliases
    alias sbr='sbt run'
    alias sbc='sbt compile'
    alias sbtst='sbt test'
    alias sbfmt='sbt scalafmtAll'
    alias sbfix='sbt scalafixAll'

    alias amm='amm'
    alias millb='mill __.compile'
    alias millt='mill __.test'

    alias scfmt='scalafmt -c .scalafmt.conf -i $(git ls-files "**/*.{scala,sbt}")'
    alias scfix='scalafix'

    # Sample project hint
    if [ -f "${CHAINRICE_SCALA_ROOT}/build.sbt" ]; then
      echo "📘 Sample available at ${CHAINRICE_SCALA_ROOT}"
      echo "   (cd ${CHAINRICE_SCALA_ROOT} && sbt run)"
    fi
  '';
}
