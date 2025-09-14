## Julia — projekt przykładowy (CLI)

**Uruchomienie**

- Szybko (skrypt): `julia index.jl`
- Moduł + main: `julia --project=. main.jl Ala`
- Testy: `julia --project=. -e 'using Pkg; Pkg.test()'`

## Po co Julia istnieje (zastosowania)

- Obliczenia naukowe i inżynieryjne, numeryka, symulacje.
- Data science/ML: szybkie prototypowanie z wydajnością dzięki JIT (LLVM).
- Równoległość/współbieżność, metaprogramowanie, multiple dispatch.

## Kiedy rozważyć inne języki?

- Produkcyjne backendy o bogatym ekosystemie web: TypeScript/Java/C#.
- Bardzo niskopoziomowe komponenty: Rust/C++.

## Oceny (1–5 gwiazdek)

- Skala: 1 = niskie/małe, 5 = wysokie/duże.
- Poziom trudności nauki: ★★★☆☆
- Bogactwo bibliotek/ekosystemu: ★★★★☆ (wzrost, zwłaszcza w nauce/ML)
- Zastosowania w praktyce: ★★★★☆
- Wydajność (JIT): ★★★★☆
- Narzędzia/build: ★★★☆☆

Zobacz `ARCHITECTURE.md`, aby poznać strukturę i kierunki rozbudowy.


