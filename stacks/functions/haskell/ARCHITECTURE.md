## Architecture

- `src/Main.hs`: Punkt wejścia (`main`).
- (opcjonalnie) `package.yaml`/`stack.yaml` lub `cabal` dla builda.

### Build flow

- `ghc -o main src/Main.hs && ./main`
- lub `stack build` i `stack run`

### Rozszerzanie

- Dodaj moduły w `src/` i testy (Hspec/Tasty/QuickCheck).
- Użyj `stack` lub `cabal` dla zarządzania zależnościami.


