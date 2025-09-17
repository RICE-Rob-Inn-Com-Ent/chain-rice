{ pkgs }:

{
  packages = with pkgs; [
    # Erlang/OTP and build tools
    erlang
    rebar3
    erlang-ls
    elixir  # optional for interop and tooling

    # Static analysis and testing tools
    dialyzer
    ctags
    ripgrep
    fd
    git
    gnumake

    # Packaging and release helpers
    zip
    unzip

    # Observability
    async-profiler
  ];
  
  envVars = {
    # Erlang shell history and colors
    ERL_AFLAGS = "-kernel shell_history enabled";

    # rebar3 cache/config
    REBAR_CACHE_DIR = "$HOME/.cache/rebar3";
    REBAR_GLOBAL_CONFIG_DIR = "$HOME/.config/rebar3";

    # Locale
    LANG = "en_US.UTF-8";

    # Project root hint
    CHAINRICE_ERLANG_ROOT = "$PWD/stacks/langs/erlang";
  };
  
  shellHook = ''
    echo "🟠 Erlang/OTP $(erl -noshell -eval 'erlang:display(erlang:system_info(otp_release)), halt().' 2>/dev/null | tr -d '"' | tr -d '\n') with rebar3"

    # Ensure rebar directories
    mkdir -p "$REBAR_CACHE_DIR" "$REBAR_GLOBAL_CONFIG_DIR"

    # Initialize dialyzer PLT if not present (non-blocking)
    if command -v dialyzer >/dev/null 2>&1; then
      (dialyzer --build_plt --apps erts kernel stdlib --output_plt "$HOME/.dialyzer_plt" >/dev/null 2>&1 || true) &
    fi

    # If rebar project, fetch deps
    if [ -f "rebar.config" ]; then
      echo "📦 rebar3 get-deps"
      rebar3 get-deps || true
    fi

    # Helpful aliases
    alias erlrepl='erl -noshell -eval "io:format(\"Erlang REPL. Use init:stop(). to exit.\\n\"), c(q)."'
    alias r3='rebar3'
    alias r3c='rebar3 compile'
    alias r3e='rebar3 eunit'
    alias r3ct='rebar3 ct'
    alias r3shell='rebar3 shell'
    alias r3rel='rebar3 release'

    # Sample project hint
    if [ -f "${CHAINRICE_ERLANG_ROOT}/src/hello.erl" ]; then
      echo "📘 Sample available at ${CHAINRICE_ERLANG_ROOT}"
      echo "   erlc ${CHAINRICE_ERLANG_ROOT}/src/hello.erl && erl -noshell -s hello start -s init stop"
    fi
  '';
}
