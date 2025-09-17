{ pkgs }:

{
  packages = with pkgs; [
    # BEAM toolchain
    erlang
    elixir
    rebar3

    # LSP and editor tooling
    elixir-ls

    # Phoenix/frontend helpers
    nodejs_22
    yarn
    esbuild
    tailwindcss
    inotify-tools

    # Databases and services (common adapters)
    postgresql
    redis
    sqlite

    # Build and system utilities
    git
    curl
    openssl
    gnumake
    bash
    ripgrep
    fd

    # Profiling/inspection
    async-profiler
  ];
  
  envVars = {
    # Mix and Elixir
    MIX_ENV = "dev";
    HEX_HOME = "$HOME/.hex";
    MIX_HOME = "$HOME/.mix";
    REBAR_GLOBAL_CONFIG_DIR = "$HOME/.config/rebar3";

    # Erlang runtime flags (color, larger shell history)
    ERL_AFLAGS = "-kernel shell_history enabled";

    # Locale to avoid unicode issues in iex
    LANG = "en_US.UTF-8";

    # Phoenix and assets
    PHX_SERVER = "true";
    PHX_PORT = "4000";

    # Node local bin for assets
    PATH = "$PWD/assets/node_modules/.bin:$PATH";

    # Project root hint
    CHAINRICE_ELIXIR_ROOT = "$PWD/stacks/langs/elixir";
  };
  
  shellHook = ''
    echo "🟣 Elixir $(elixir -v | head -n1 | awk '{print $2}') on Erlang $(erl -noshell -eval 'erlang:display(erlang:system_info(otp_release)), halt().' 2>/dev/null | tr -d '"' | tr -d '\n')"
    echo "   • mix/rebar3/hex bootstrapped"
    echo "   • elixir-ls for LSP, Node for assets (esbuild/tailwind)"

    # Ensure directories exist
    mkdir -p "$HEX_HOME" "$MIX_HOME" "$REBAR_GLOBAL_CONFIG_DIR"

    # Bootstrap local hex/rebar to avoid interactive prompts
    mix local.hex --force >/dev/null 2>&1 || true
    mix local.rebar --force >/dev/null 2>&1 || true

    # Install Phoenix generator globally (archive) if not present
    if ! mix help phx.new >/dev/null 2>&1; then
      echo "📦 Installing Phoenix archive (phx_new)"
      mix archive.install hex phx_new --force >/dev/null 2>&1 || true
    fi

    # Put node_modules bin on PATH (Phoenix assets)
    if [ -d "assets/node_modules/.bin" ]; then
      export PATH="assets/node_modules/.bin:$PATH"
    fi

    # If mix project, fetch deps
    if [ -f "mix.exs" ]; then
      echo "📦 mix deps.get"
      mix deps.get || true
      # Setup assets if Phoenix structure detected
      if [ -d "assets" ]; then
        if [ -f "assets/package.json" ]; then
          echo "📦 npm/yarn install in assets"
          if command -v yarn >/dev/null 2>&1; then
            (cd assets && yarn install --frozen-lockfile || yarn install) || true
          else
            (cd assets && npm install) || true
          fi
        fi
        # Ensure esbuild and tailwind are available (Phoenix >= 1.6)
        mix esbuild.install --if-missing >/dev/null 2>&1 || true
        mix tailwind.install --if-missing >/dev/null 2>&1 || true
      fi
    fi

    # Helpful aliases
    alias mx='mix'
    alias mxr='mix run'
    alias mxt='mix test'
    alias mxc='mix compile'
    alias iexmix='iex -S mix'
    alias phxnew='mix phx.new'
    alias phxserver='mix phx.server'

    # Database helpers
    alias pgstart='pg_ctl -D "$PWD/.pgdata" -l "$PWD/.pglog" start'
    alias pgstop='pg_ctl -D "$PWD/.pgdata" stop'

    # Sample project hint
    if [ -f "${CHAINRICE_ELIXIR_ROOT}/lib/hello.ex" ]; then
      echo "📘 Sample available at ${CHAINRICE_ELIXIR_ROOT}"
      echo "   elixir ${CHAINRICE_ELIXIR_ROOT}/lib/hello.ex -e Hello.main"
    fi
  '';
}
