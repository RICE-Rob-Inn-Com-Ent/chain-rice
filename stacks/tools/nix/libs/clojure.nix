{ pkgs }:

{
  packages = with pkgs; [
    # JVM and Clojure toolchain
    jdk21
    clojure
    leiningen
    babashka
    rlwrap

    # LSP, linters, formatters
    clojure-lsp
    clj-kondo
    cljfmt
    joker

    # Build tools for mixed JVM projects
    maven
    gradle

    # ClojureScript tooling
    nodejs_22
    nodePackages.yarn
    nodePackages.shadow-cljs

    # Docs and utilities
    ripgrep
    fd
    git
    entr

    # Profiling and analysis
    async-profiler
    jdk-mission-control
  ];
  
  envVars = {
    # Java/Clojure configuration
    JAVA_HOME = "${pkgs.jdk21.home}";
    JVM_OPTS = "-Xms512m -Xmx4g -XX:+UseZGC -Dclojure.spec.compile-asserts=false";
    CLJ_CONFIG = "$HOME/.clojure";
    CLJ_CACHE = "$HOME/.cache/clojure";

    # Leiningen
    LEIN_JVM_OPTS = "-Xms512m -Xmx4g";

    # Clojure LSP
    CLOJURE_LSP_ENABLED = "true";

    # ClojureScript / Node
    SHADOW_CLJS_PORT = "9630";

    # Project root hints
    CHAINRICE_CLOJURE_ROOT = "$PWD/stacks/langs/clojure";
  };
  
  shellHook = ''
    echo "🟢 Clojure ${pkgs.clojure.version} on JDK ${pkgs.jdk21.version}"
    echo "   • clojure CLI / Leiningen / Babashka"
    echo "   • clojure-lsp / clj-kondo / cljfmt / joker"
    echo "   • shadow-cljs (Node ${pkgs.nodejs_22.version})"

    # Ensure JAVA_HOME and basic folders
    export JAVA_HOME="${JAVA_HOME}"
    mkdir -p "$CLJ_CONFIG" "$CLJ_CACHE"

    # Add local node_modules bin for shadow-cljs and tooling
    if [ -d "node_modules/.bin" ]; then
      export PATH="node_modules/.bin:$PATH"
    fi

    # Helpful aliases
    alias cljrepl='rlwrap clojure -M:dev:repl'
    alias leinrepl='rlwrap lein repl'
    alias bb='babashka'
    alias kondo='clj-kondo --lint .'
    alias fmt='cljfmt fix'
    alias lsp='clojure-lsp'
    alias shadow='shadow-cljs'

    # Pre-resolve deps for faster first run
    if [ -f "deps.edn" ]; then
      echo "📦 Resolving deps.edn classpath"
      clojure -P || true
    fi
    if [ -f "project.clj" ]; then
      echo "📦 Preparing Leiningen"
      lein deps || true
    fi

    # Shadow-cljs bootstrap if package.json present
    if [ -f "package.json" ]; then
      if [ ! -d "node_modules" ]; then
        echo "📦 Installing Node dependencies"
        yarn install --frozen-lockfile || yarn install || true
      fi
    fi

    # LSP warm-up (non-blocking)
    if command -v clojure-lsp >/dev/null 2>&1; then
      (clojure-lsp --version >/dev/null 2>&1 &)
    fi

    # Sample project hint
    if [ -f "${CHAINRICE_CLOJURE_ROOT}/deps.edn" ]; then
      echo "📘 Sample available at ${CHAINRICE_CLOJURE_ROOT}"
      echo "   cljrepl  # start a REPL"
      echo "   shadow watch app  # if shadow-cljs configured"
    fi
  '';
}
