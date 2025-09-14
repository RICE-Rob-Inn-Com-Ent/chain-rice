## Architektura

- `deps.edn`: Konfiguracja zależności/ścieżek.
- `src/hello/core.clj`: Przestrzeń nazw wejściowa z funkcją `-main`.
- `test/`: Miejsce na testy (opcjonalnie).

### Flow uruchomienia

1. `clojure -M -m hello.core` — startuje `-main` i wypisuje komunikat.
2. Alternatywnie: `clojure -M -e "(println \"Hello, World!\")"` bez kompilacji.

### Rozszerzanie

- Dodaj kolejne przestrzenie nazw w `src/` i testy w `test/`.
- Wprowadź routing (Reitit/Compojure) i warstwy (handler/service/repo) wg potrzeb.
- Rozważ Leiningen lub narzędzia REPL do pracy interaktywnej.

