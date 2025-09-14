## Architektura

- `Makefile`: główny plik z celami (`hello`, `build`, `clean`, `lint`, `fmt`).
- `config.mk`: nazwa/wersja aplikacji (parametryzacja builda).
- `common.mk`: pomocnicze makra logowania (`info`, `ok`, `warn`).

### Flow

- `make hello` → wypisuje przywitanie z wartości `APP_NAME` i `VERSION`.
- `make build` → tworzy katalog `dist/` i artefakt tekstowy.
- `make clean` → usuwa `dist/`.

### Rozszerzanie

- Dodaj zależności plikowe, reguły wzorcowe, i cache kompilacji.
- Wydziel moduły do osobnych `.mk` i dołączaj przez `include`.


