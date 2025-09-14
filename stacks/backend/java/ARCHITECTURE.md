## Architektura

- `src/com/example/App.java`: Punkt wejścia — odczyt argumentu i powitanie.
- `src/com/example/Greeter.java`: Prosta klasa domenowa generująca komunikat.
- `build.gradle`: Konfiguracja Gradle (application + testy).

### Build/Run

- `./gradlew run --args "Ala"`
- Ręcznie: `javac -d out src/com/example/*.java && java -cp out com.example.App Ala`

### Rozszerzanie

- Dodaj testy (JUnit), zależności (np. Spring), wielomodułowość.


