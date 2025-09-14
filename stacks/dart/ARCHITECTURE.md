## Architektura

- `pubspec.yaml`: Metadane pakietu i zależności.
- `lib/greeter.dart`: Prosta klasa `Greeter` generująca komunikat.
- `bin/main.dart`: Punkt wejścia — używa `Greeter` i wypisuje wynik.
- `test/greeter_test.dart`: Podstawowe testy jednostkowe.

### Build/Run

- Uruchom: `dart run bin/main.dart`
- Testy: `dart test`

### Rozszerzanie

- Dodaj kolejne moduły w `lib/` i testy w `test/`.
- W CLI używaj `argParser` lub pakietów do parsowania argumentów.
- W aplikacjach Flutter trzymaj logikę w `lib/` i UI w widgetach.
