## Architektura

- `index.jl`: Prosty skrypt wypisujący powitanie.
- `main.jl`: Punkt wejścia korzystający z modułu z `src/` i parametrów argv.
- `src/`: Kod źródłowy pakietu (np. `MyApp.jl`).
- `test/`: Testy jednostkowe (pakiet `Test`).
- `Project.toml` / `Manifest.toml`: pliki projektu Julia (zależności i blokada).

### Flow

- Szybko: `julia index.jl`
- Projekt: `julia --project=. main.jl Ala`
- Testy: `julia --project=. -e 'using Pkg; Pkg.test()'`

### Rozszerzanie

- Dodaj moduły w `src/`, testy w `test/`, i zależności przez `using Pkg; Pkg.add("...")`.
- Rozważ `Pkg.generate("MyApp")` dla pełnego szkieletu pakietu.


