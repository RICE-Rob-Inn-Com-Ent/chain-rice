## Architektura

- `src/main/groovy/App.groovy`: Wejściowy skrypt drukujący powitanie.
- `Main.groovy`: Klasa z metodą `main` (uruchomienie przez Gradle).
- `Utils.groovy`: Pomocnicza funkcja `greet(name, prefix)`.
- `build.gradle` / `settings.gradle`: Konfiguracja projektu Gradle.
- `script.gvy` / `script.gy` / `build.gsh`: Przykładowe skrypty Groovy.

### Build/Run

- Skryptowo: `groovy src/main/groovy/App.groovy`
- Gradle: `./gradlew run`

### Rozszerzanie

- Dodaj testy (Spock/JUnit), zależności i pluginy w `build.gradle`.
- Wydziel pakiety, klasy i moduły według potrzeb.


