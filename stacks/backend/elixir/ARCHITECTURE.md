## Architecture

- `lib/hello.ex`: Moduł z funkcją `main/0` wypisującą tekst.
- (opcjonalnie) struktura `mix` z `mix.exs` i aplikacją OTP.

### Build/Run

- `elixir lib/hello.ex -e Hello.main`
- lub w projekcie mix: `mix run -e Hello.main`

### Rozszerzanie

- Dodaj aplikację OTP, supervision tree, i użyj Phoenix/Broadway w razie potrzeby.
- Testy: ExUnit.


