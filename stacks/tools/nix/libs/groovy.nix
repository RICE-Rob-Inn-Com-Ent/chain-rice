{ pkgs }:

{
  packages = with pkgs; [
    # JVM and Groovy toolchain
    jdk21
    groovy
    gradle
    maven

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

    # Gradle/Maven configuration
    GRADLE_USER_HOME = "$HOME/.gradle";
    MAVEN_CONFIG = "$HOME/.m2";
    GRADLE_OPTS = "-Dorg.gradle.daemon=true -Dorg.gradle.jvmargs='-Xmx2g -XX:+UseG1GC'";
    MAVEN_OPTS = "-Xmx2g";

    # Project root hint
    CHAINRICE_GROOVY_ROOT = "$PWD/stacks/langs/groovy";
  };
  
  shellHook = ''
    echo "🟫 Groovy $(groovy -version 2>&1 | awk '{print $3}') with Gradle $(gradle --version | awk '/Gradle/{print $2}' | head -n1) / Maven $(mvn -v | awk 'NR==1{print $3}')"

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

    # Resolve dependencies to warm cache (non-blocking)
    if [ -f "build.gradle" ]; then
      (gw --quiet tasks >/dev/null 2>&1 || true) &
    fi

    # Helpful aliases
    alias grun='gw run'
    alias gtest='gw test'
    alias gclean='gw clean'
    alias gbuild='gw build'
    alias mci='mvn clean install -DskipTests'
    alias mct='mvn -q -DskipITs test'

    # REPL
    alias groovysh='rlwrap groovysh'

    # Sample project hint
    if [ -f "${CHAINRICE_GROOVY_ROOT}/build.gradle" ]; then
      echo "📘 Sample available at ${CHAINRICE_GROOVY_ROOT}"
      echo "   groovy ${CHAINRICE_GROOVY_ROOT}/src/main/groovy/App.groovy"
      echo "   (cd ${CHAINRICE_GROOVY_ROOT} && gw run)"
    fi
  '';
}
