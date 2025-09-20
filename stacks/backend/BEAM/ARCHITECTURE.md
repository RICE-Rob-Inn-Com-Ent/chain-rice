## Architecture

- `src/Hello/Program.cs`: Punkt wejścia aplikacji (top-level statements).
- `src/Hello/Greeter.cs`: Prosta klasa domenowa generująca komunikat.
- `src/Hello/Hello.csproj`: Definicja projektu .NET.

### Build flow

1. Przygotuj SDK: `dotnet --info`
2. Build: `dotnet build`
3. Run: `dotnet run --project src/Hello/Hello.csproj`

### Rozszerzanie

- Dodaj testy: `tests/Hello.Tests/` z xUnit/NUnit/MSTest.
- Dodaj DI/logowanie/konfigurację (Microsoft.Extensions.*).
- Wydziel biblioteki klas (`classlib`) i referencje między projektami.


