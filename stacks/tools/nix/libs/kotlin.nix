{ pkgs }:

{
  packages = with pkgs; [
    # JVM + Kotlin toolchain
    jdk21
    kotlin
    gradle

    # Language server and quality tools
    kotlin-language-server
    ktlint
    detekt
    google-java-format

    # Android (optional CLI tools; full SDK managed externally)
    android-tools

    # HTTP and build helpers
    maven
    curl
    git
    unzip
    zip
    ripgrep
    fd
    rlwrap
  ];
  
  envVars = {
    # Java/Kotlin configuration
    JAVA_HOME = "${pkgs.jdk21.home}";
    LANG = "en_US.UTF-8";

    # Gradle/Maven configuration
    GRADLE_USER_HOME = "$HOME/.gradle";
    MAVEN_CONFIG = "$HOME/.m2";
    GRADLE_OPTS = "-Dorg.gradle.daemon=true -Dorg.gradle.jvmargs='-Xmx4g -XX:+UseG1GC'";
    MAVEN_OPTS = "-Xms512m -Xmx2g";

    # Project root hint
    CHAINRICE_KOTLIN_ROOT = "$PWD/stacks/langs/kotlin";
  };
  
  shellHook = ''
    echo "🟪 Kotlin: $(kotlinc -version 2>&1 | head -n1)"
    echo "   • Gradle $(gradle --version 2>/dev/null | awk '/Gradle/{print $2}' | head -n1) / Maven $(mvn -v | sed -n '1p')"

    export JAVA_HOME="${JAVA_HOME}"

    # Prefer local Gradle wrapper if present
    if [ -f "gradlew" ]; then
      chmod +x gradlew
      alias gw='./gradlew'
    else
      alias gw='gradle'
    fi

    # Bootstrap Gradle wrapper if build.gradle(.kts) exists
    if { [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; } && [ ! -f "gradlew" ]; then
      echo "🔧 Initializing Gradle wrapper"
      gradle wrapper || true
      chmod +x gradlew 2>/dev/null || true
    fi

    # Warm caches (non-blocking)
    if [ -f "build.gradle.kts" ] || [ -f "build.gradle" ]; then
      (gw --quiet tasks >/dev/null 2>&1 || true) &
    fi

    # LSP warm-up
    if command -v kotlin-language-server >/dev/null 2>&1; then
      (kotlin-language-server --help >/dev/null 2>&1 || true) &
    fi

    # Helpful aliases
    alias kfmt='ktlint -F || true && google-java-format -i $(git ls-files "**/*.java")'
    alias klin='ktlint || true && detekt --build-upon-default-config --all-rules || true'
    alias gkb='gw build'
    alias gkr='gw run'
    alias gkt='gw test'

    # Kotlin REPL
    alias krepl='rlwrap kotlinc'

    # Sample project hint
    if [ -f "${CHAINRICE_KOTLIN_ROOT}/build.gradle.kts" ]; then
      echo "📘 Sample available at ${CHAINRICE_KOTLIN_ROOT}"
      echo "   (cd ${CHAINRICE_KOTLIN_ROOT} && ./gradlew run --args \"World\" 2>/dev/null || gradle run --args \"World\")"
    fi
  '';
}
