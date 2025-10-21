# Rice Android Components Library

Biblioteka reużywalnych komponentów Android dla projektu Rice-Mono.

## Struktura

```
android/
├── components/                 # Moduł biblioteki komponentów
│   └── src/
│       └── main/
│           ├── kotlin/        # Komponenty Kotlin/Compose
│           └── AndroidManifest.xml
├── build.gradle.kts           # Główna konfiguracja Gradle
├── settings.gradle.kts        # Ustawienia projektu Gradle
└── gradle.properties          # Właściwości Gradle

```

## Komponenty

### RiceButton

Przycisk Compose z domyślnym stylingiem Rice-Mono.

```kotlin
RiceButton(
    text = "Click Me",
    onClick = { /* action */ }
)
```

## Rozwój

### Dodawanie nowych komponentów

1. Stwórz nowy plik w `components/src/main/kotlin/com/ricemono/components/`
2. Zdefiniuj komponent jako `@Composable` funkcję
3. Dodaj `@Preview` dla podglądu w Android Studio
4. Eksportuj publiczny interfejs

### Build

```bash
# Build biblioteki
./gradlew :components:build

# Testy
./gradlew :components:test

# Clean
./gradlew clean
```

## Integracja

Biblioteka może być używana w:

- Aplikacjach Android (natywnych)
- Flutter przez platform channels
- React Native przez native modules

## Wymagania

- Android SDK: 24+ (Android 7.0+)
- Target SDK: 34 (Android 14)
- Kotlin: 1.9.20+
- Gradle: 8.0+
- Java: 17+
