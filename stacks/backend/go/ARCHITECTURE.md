## Architektura

- `go.mod`: Metadane modułu.
- `main.go`: Punkt wejścia — pobiera imię z argv i wypisuje powitanie.
- `internal/greeter`: Pakiet z funkcją `Greet(name string) string` + test.

### Flow

- Uruchom: `go run ./ [Name]`
- Testy: `go test ./...`

### Rozszerzanie

- Dodaj więcej pakietów w `internal/` lub publiczne w `pkg/`.
- Dodaj `cmd/<app>` dla wielu binarek.


