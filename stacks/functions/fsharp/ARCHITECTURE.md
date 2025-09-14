## Architecture

- `MyApp.fsproj`: Definicja projektu .NET.
- `Utils.fsi` / `Utils.fs`: API i implementacja funkcji `greet`.
- `Program.fs`: Punkt wejścia używający `greet`.
- `script.fsx`: Skrypt pokazujący użycie z innym prefiksem.
- `Program.fsx`: Prosty skrypt „Hello, World!” (pozostaje opcjonalny).

### Build flow

- Build: `dotnet build`
- Run: `dotnet run --project MyApp.fsproj`
- Script: `dotnet fsi script.fsx`

### Rozszerzanie

- Dodaj testy (xUnit + FsUnit) oraz moduły domenowe.
- Wydziel biblioteki klas i referencje.


