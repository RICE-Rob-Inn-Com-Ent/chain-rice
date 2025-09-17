{ pkgs }:

{
  packages = with pkgs; [
    # JDK and build tools
    jdk21
    maven
    gradle

    # Language server and quality tools
    jdt-language-server
    checkstyle
    spotbugs
    pmd
    google-java-format
    lombok

    # Profiling/monitoring
    jdk-mission-control
    async-profiler
    visualvm

    # Utilities
    git
    curl
    unzip
    zip
    ripgrep
    fd
    rlwrap
  ];
  
  envVars = {
    # Java configuration
    JAVA_HOME = "${pkgs.jdk21.home}";
    LANG = "en_US.UTF-8";

    # Maven/Gradle configuration
    MAVEN_CONFIG = "$HOME/.m2";
    GRADLE_USER_HOME = "$HOME/.gradle";
    MAVEN_OPTS = "-Xms512m -Xmx4g";
    GRADLE_OPTS = "-Dorg.gradle.daemon=true -Dorg.gradle.jvmargs='-Xmx4g -XX:+UseG1GC'";

    # Project root hint
    CHAINRICE_JAVA_ROOT = "$PWD/stacks/langs/java";
  };
  
  shellHook = ''
    echo "☕ Java: $(java -version 2>&1 | head -n1)"
    echo "   • Maven $(mvn -v | sed -n '1p')"
    echo "   • Gradle $(gradle --version 2>/dev/null | awk '/Gradle/{print $2}' | head -n1)"

    export JAVA_HOME="${JAVA_HOME}"

    # Prefer local Gradle wrapper if present
    if [ -f "gradlew" ]; then
      chmod +x gradlew
      alias gw='./gradlew'
    else
      alias gw='gradle'
    fi

    # Bootstrap Gradle wrapper if a build.gradle exists and no wrapper yet
    if [ -f "build.gradle" ] && [ ! -f "gradlew" ]; then
      echo "🔧 Initializing Gradle wrapper"
      gradle wrapper || true
      chmod +x gradlew 2>/dev/null || true
    fi

    # Warm caches (non-blocking)
    if [ -f "build.gradle" ]; then
      (gw --quiet tasks >/dev/null 2>&1 || true) &
    fi
    if [ -f "pom.xml" ]; then
      (mvn -q -DskipTests dependency:go-offline >/dev/null 2>&1 || true) &
    fi

    # LSP warm-up
    if command -v jdt-language-server >/dev/null 2>&1; then
      (jdt-language-server -version >/dev/null 2>&1 || true) &
    fi

    # Helpful aliases
    alias jfmt='google-java-format -i $(git ls-files "**/*.java")'
    alias cstyle='mvn -q -DskipTests checkstyle:check || true'
    alias pmdc='mvn -q -DskipTests pmd:check || true'
    alias sbugs='mvn -q -DskipTests spotbugs:check || true'

    alias gwb='gw build'
    alias gwr='gw run'
    alias gwtest='gw test'
    alias mci='mvn -q -DskipTests clean install'
    alias mverify='mvn -q -DskipTests verify'

    # REPL-like
    alias jshell='${pkgs.jdk21}/bin/jshell'

    # Sample project hint
    if [ -f "${CHAINRICE_JAVA_ROOT}/src/com/example/App.java" ]; then
      echo "📘 Sample available at ${CHAINRICE_JAVA_ROOT}"
      echo "   (cd ${CHAINRICE_JAVA_ROOT} && ./gradlew run --args \"World\" 2>/dev/null || gradle run --args \"World\")"
    fi
  '';
}
