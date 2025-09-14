## C# / .NET Hello World

**Build & Run**

- `dotnet build`
- `dotnet run --project src/Hello/Hello.csproj`

## Do czego najlepiej pasuje C#/.NET?

- Aplikacje biznesowe i web: ASP.NET Core (REST, gRPC, MVC, minimal APIs).
- Aplikacje desktopowe: WPF, WinForms, MAUI.
- Gry: Unity (C# jako główny język skryptowy).
- Chmura i mikrousługi: świetne wsparcie narzędzi i wydajny runtime.
- Skrypty i automatyzacja w ekosystemie Windows/Azure.

## Kiedy rozważyć inne języki?

- Niskopoziomowe systemy/RTOS: C/C++/Rust.
- Szybkie prototypowanie data/ML: Python.
- Narzędzia CLI o prostym deployment: Go.

## Oceny (1–5 gwiazdek)

- Skala: 1 = niskie/małe, 5 = wysokie/duże.

- Poziom trudności nauki: ★★★☆☆
- Bogactwo bibliotek/ekosystemu: ★★★★☆
- Bogactwo zastosowań w praktyce: ★★★★☆
- Wydajność runtime: ★★★★☆
- Dojrzałość narzędzi/buildów: ★★★★★

## Co zawiera projekt?

- Minimalna aplikacja konsolowa z klasą `Greeter`.
- Struktura gotowa do rozbudowy (testy, warstwy, DI).

Zobacz `ARCHITECTURE.md`, aby poznać układ i jak go rozwijać.


## Przykładowe biblioteki i narzędzia

- Web/HTTP: ASP.NET Core (Minimal APIs, MVC), gRPC for .NET.
- Dostęp do danych: Entity Framework Core, Dapper.
- Konfiguracja/DI: `Microsoft.Extensions.Configuration`, `Microsoft.Extensions.DependencyInjection`.
- Logowanie: Serilog, NLog, Microsoft.Extensions.Logging.
- Testy: xUnit, NUnit, MSTest, FluentAssertions.
- UI: WPF, WinForms, .NET MAUI (desktop/mobile).
- Narzędzia: `dotnet` CLI, NuGet, Rider/VS/VS Code.

## Jak zacząć z tym przykładem?

- Zbuduj: `dotnet build`
- Uruchom: `dotnet run --project src/Hello/Hello.csproj`
- Rozwiń dalej wg wskazówek w `ARCHITECTURE.md` (dodaj testy, warstwy, DI).


