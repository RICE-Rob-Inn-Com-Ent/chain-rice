## Architecture

- `src/hello.erl`: Moduł z funkcją start/0 wypisującą tekst.
- (opcjonalnie) `hello.escript`: jednoplikowy skrypt uruchamialny.

### Build flow

- `erlc src/hello.erl && erl -noshell -s hello start -s init stop`
- lub `escript hello.escript`

### Rozszerzanie

- OTP behaviours (gen_server, supervisor), aplikacje (`.app`), rebar3/mix.
- Testy: eunit/common_test.


