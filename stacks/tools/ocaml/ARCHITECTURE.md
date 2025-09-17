## Architektura

- `utils.mli` / `utils.ml`: moduł z funkcją `greet` (sygnatura + implementacja).
- `main.ml`: punkt wejścia wykorzystujący `Utils.greet` i `Sys.argv`.
- `dune`: konfiguracja biblioteki `utils` i wykonywalnego `main`.

### Build flow

- `dune build` i `dune exec ./main.exe`

### Rozszerzanie

- Dodaj moduły i testy (alcotest/ounit), rozbij na biblioteki.
- Użyj opam do zarządzania zależnościami.


