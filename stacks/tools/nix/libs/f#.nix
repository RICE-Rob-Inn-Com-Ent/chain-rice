{ pkgs }:

{
  packages = with pkgs; [
    # .NET SDK and runtime
    dotnet-sdk_8
    dotnet-runtime_8

    # F# language tooling
    fsautocomplete  # LSP
    fantomas        # formatter

    # Helpful dev tools
    editorconfig-checker
    git
    curl
    jq
    gnumake
  ];
  
  envVars = {
    # .NET configuration
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1";
    DOTNET_NOLOGO = "1";

    # NuGet cache
    NUGET_PACKAGES = "$HOME/.nuget/packages";

    # Add dotnet tools path
    PATH = "$HOME/.dotnet/tools:$PATH";

    # Project root hint
    CHAINRICE_FSHARP_ROOT = "$PWD/stacks/langs/f#";
  };
  
  shellHook = ''
    echo "🟦 .NET SDK ${pkgs.dotnet-sdk_8.version} for F# development"
    echo "   • FsAutoComplete (LSP)"
    echo "   • Fantomas (formatter)"

    # Ensure dotnet tools are on PATH
    export PATH="$HOME/.dotnet/tools:$PATH"

    # Optionally install useful dotnet global tools (idempotent)
    if command -v dotnet >/dev/null 2>&1; then
      dotnet tool update -g paket >/dev/null 2>&1 || dotnet tool install -g paket >/dev/null 2>&1 || true
      dotnet tool update -g fake-cli >/dev/null 2>&1 || dotnet tool install -g fake-cli >/dev/null 2>&1 || true
      dotnet tool update -g fantomas-tool >/dev/null 2>&1 || dotnet tool install -g fantomas-tool >/dev/null 2>&1 || true
      dotnet tool update -g dotnet-fsharplint >/dev/null 2>&1 || dotnet tool install -g dotnet-fsharplint >/dev/null 2>&1 || true
    fi

    # Restore example project if present
    if [ -f "${CHAINRICE_FSHARP_ROOT}/MyApp.fsproj" ]; then
      echo "📦 Restoring F# sample project"
      dotnet restore "${CHAINRICE_FSHARP_ROOT}/MyApp.fsproj" || true
    fi

    # Formatting (non-blocking)
    if command -v fantomas >/dev/null 2>&1; then
      (fantomas . >/dev/null 2>&1 || true) &
    fi

    # Helpful aliases
    alias dn='dotnet'
    alias dnb='dotnet build'
    alias dnr='dotnet run'
    alias dnt='dotnet test'
    alias dnrw='dotnet watch run'
    alias dntw='dotnet watch test'
    alias ffmt='fantomas .'
    alias flint='dotnet fsharplint lint'

    # Print quick info
    dotnet --info | sed -n '1,20p' | cat
  '';
}
