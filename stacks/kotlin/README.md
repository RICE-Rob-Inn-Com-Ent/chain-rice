## Kotlin Hello World (CLI)

**Build & Run (Gradle)**

- `./gradlew run --args "Ala"`

**Ręcznie (pojedynczy plik)**

- Kompilacja: `kotlinc src/main/kotlin/App.kt -include-runtime -d app.jar`
- Uruchomienie: `java -jar app.jar`

## Do czego najlepiej pasuje Kotlin?

- Backend JVM (Ktor, Spring), Android, skrypty JVM (Kotlin Script).
- Nowoczesna składnia, null-safety, coroutines.

## Kiedy rozważyć inne języki?

- Bardzo proste CLI i single-binary: Go.
- Niskopoziomowe komponenty: Rust/C++.

## Oceny (1–5 gwiazdek)

- Skala: 1 = niskie/małe, 5 = wysokie/duże.
- Poziom trudności nauki: ★★★☆☆
- Ekosystem/biblioteki: ★★★★☆ (JVM/Android)
- Zastosowania w praktyce: ★★★★☆
- Wydajność runtime (JVM): ★★★★☆
- Narzędzia/build: ★★★★★ (Gradle KTS)

Zobacz `ARCHITECTURE.md`, aby poznać strukturę i kierunki rozbudowy.


