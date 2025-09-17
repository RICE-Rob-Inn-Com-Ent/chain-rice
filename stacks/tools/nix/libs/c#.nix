{ pkgs }:

{
  packages = with pkgs; [
    # .NET SDK and runtimes
    dotnet-sdk_8
    dotnet-runtime_8

    # Language server and editor tooling
    omnisharp-roslyn
    csharpier
    editorconfig-checker

    # Testing and coverage
    # dotnet includes test runner; add coverlet for coverage reports if available
    coverlet

    # Build tools
    gnumake
    gcc

    # Utilities
    git
    curl
    jq
  ];
  
  envVars = {
    # .NET configuration
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1";
    DOTNET_NOLOGO = "1";
    
    # NuGet cache and sources
    NUGET_PACKAGES = "$HOME/.nuget/packages";

    # Project defaults
    DOTNET_GENERATE_ASPNET_CERTIFICATE = "false";
    ASPNETCORE_ENVIRONMENT = "Development";

    # C# workspace hints
    CHAINRICE_DOTNET_ROOT = "$PWD/stacks/cs";
  };
  
  shellHook = ''
    echo "🔷 .NET SDK ${pkgs.dotnet-sdk_8.version} with C# development tools"
    echo "   • OmniSharp LSP for IDE support"
    echo "   • CSharpier for formatting"
    echo "   • Coverlet for coverage"

    # Ensure dotnet tools path is present
    export PATH="$HOME/.dotnet/tools:$PATH"

    # Restore and build sample if present
    if [ -f "${CHAINRICE_DOTNET_ROOT}/src/Hello/Hello.csproj" ]; then
      echo "📦 Restoring sample project (Hello)"
      dotnet restore "${CHAINRICE_DOTNET_ROOT}/src/Hello/Hello.csproj" || true
    fi

    # Format on entry if repository has C# and formatter exists
    if command -v dotnet &> /dev/null && command -v csharpier &> /dev/null; then
      if ls **/*.cs >/dev/null 2>&1; then
        echo "✨ Running csharpier (format)"
        csharpier . >/dev/null 2>&1 || true
      fi
    fi

    # Helpful aliases
    alias dn='dotnet'
    alias dnb='dotnet build'
    alias dnr='dotnet run'
    alias dnt='dotnet test'
    alias dnrw='dotnet watch run'
    alias dntw='dotnet watch test'

    # Print versions
    dotnet --info | sed -n '1,20p' | cat
  '';
}
