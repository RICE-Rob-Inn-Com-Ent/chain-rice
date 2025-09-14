## Clojure Hello World

**Uruchomienie**

- Szybko (REPL-less): `clojure -M -e "(println \"Hello, World!\")"`
- Z pliku (punkt wejścia): `clojure -M -m hello.core`

## Do czego najlepiej pasuje Clojure?

- Usługi backendowe na JVM z naciskiem na prostotę i dane niezmienne.
- Praca w REPL, szybkie iteracje, metaprogramowanie (makra).
- Integracja z ekosystemem JVM (dostęp do bibliotek Java).

## Kiedy rozważyć inne języki?

- Bardzo rozbudowane GUI lub wymagania .NET/JVM korporacyjne: C#/Java.
- Ciężkie obliczenia niskopoziomowe: Rust/C++.
- Nauka FP od zera z bogatszym materiałem edukacyjnym: Haskell/Scala.

## Oceny (1–5 gwiazdek)

- Skala: 1 = niskie/małe, 5 = wysokie/duże.
- Poziom trudności nauki: ★★★★☆
- Bogactwo bibliotek/ekosystemu: ★★★★☆ (plus cała Java)
- Bogactwo zastosowań w praktyce: ★★★★☆
- Wydajność runtime (JVM): ★★★★☆
- Narzędzia/build: ★★★★☆ (deps.edn/Lein/REPL)

## Przykładowe biblioteki i narzędzia

- Web/HTTP: Ring, Compojure, Reitit, Pedestal.
- Dostęp do danych: next.jdbc, clj-http, cheshire.
- Concurrency/FP: core.async, transducers, clojure.spec.
- Build/Narzędzia: Clojure CLI (`deps.edn`), Leiningen, REPL, nREPL.
- Testy: `clojure.test`, Midje.

## Jak zacząć z tym przykładem?

- Uruchom: `clojure -M -m hello.core`
- Zajrzyj do `ARCHITECTURE.md`, aby zobaczyć strukturę i kierunki rozbudowy.

