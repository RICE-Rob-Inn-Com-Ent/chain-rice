## Erlang Hello World

**Build & Run (escript)**

- `erlc src/hello.erl && erl -noshell -s hello start -s init stop`
- lub `escript hello.escript`

## Do czego najlepiej pasuje Erlang?

- Systemy rozproszone, wysokodostępne, o niskich opóźnieniach (telekom, messaging).
- Model aktorów, hot code reload, odporność na błędy (OTP).

## Kiedy rozważyć inne języki?

- Proste web/mikrousługi: Elixir (na BEAM), Go.
- Intensywne obliczenia niskiego poziomu: Rust/C++.

## Oceny (1–5 gwiazdek)

- Skala: 1 = niskie/małe, 5 = wysokie/duże.
- Poziom trudności nauki: ★★★★☆
- Ekosystem/biblioteki: ★★★☆☆
- Zastosowania w praktyce: ★★★★☆
- Niezawodność/HAA: ★★★★★
- Narzędzia/build: ★★★☆☆

## Jak zacząć?

- Uruchom wg powyższych komend.
- Zobacz `ARCHITECTURE.md` jak tworzyć moduły i aplikacje OTP.


