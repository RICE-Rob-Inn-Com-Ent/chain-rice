# Rice Dev Kotlin Frontend

Android додаток на Kotlin з Jetpack Compose для rice-dev екосистеми.

## Особливості

### 🎨 UI та компоненти
- **Jetpack Compose** - сучасний декларативний UI toolkit
- **Material Design 3** - дизайн система від Google
- **Responsive Design** - адаптивний дизайн для різних розмірів екранів
- **Dark/Light Theme** - підтримка темної та світлої теми

### 🎭 Анімації та ефекти
- **Compose Animations** - плавні анімації
- **Lottie** - анімації After Effects
- **Material Motion** - анімації Material Design

### 🧭 Навігація
- **Navigation Compose** - типобезпечна навігація

### 🏗️ Архітектура
- **MVVM Pattern** - Model-View-ViewModel
- **ViewModel** - управління UI-станом
- **Lifecycle** - керування життєвим циклом
- **Dependency Injection** - Koin для DI

### 🎨 Теми та графіка
- **Material Icons** - розширені іконки
- **System UI Controller** - керування системним UI
- **Google Fonts** - красиві шрифти

## Встановлення

### Передумови
- Android Studio Arctic Fox або новіша версія
- Android SDK 34
- Java 17 або новіша версія
- Kotlin 1.8.10+

### Кроки встановлення

1. Клонуйте репозиторій:
```bash
git clone <repository-url>
cd rice-dev/libs/frontend/kotlin
```

2. Відкрийте проект в Android Studio

3. Синхронізуйте Gradle файли

4. Запустіть проект на емуляторі або пристрої

## Запуск

### Debug версія
```bash
./gradlew assembleDebug
```

### Release версія
```bash
./gradlew assembleRelease
```

### Тестування
```bash
./gradlew test
```

## Структура проекту

```
app/
├── src/main/
│   ├── java/com/kotlin/frontend/
│   │   ├── MainActivity.kt           # Головна активність
│   │   ├── Greeting.kt               # Compose компоненти
│   │   └── ui/theme/                 # Теми та стилі
│   │       ├── Color.kt              # Кольори
│   │       ├── Theme.kt              # Теми
│   │       └── Type.kt               # Типографіка
│   ├── res/                          # Ресурси
│   │   ├── values/
│   │   │   ├── colors.xml            # Кольори
│   │   │   ├── strings.xml           # Рядки
│   │   │   └── themes.xml            # Теми
│   │   └── layout/                   # Layout файли
│   └── AndroidManifest.xml           # Маніфест додатка
├── build.gradle.kts                  # Конфігурація модуля
└── proguard-rules.pro                # Правила ProGuard
```

## Доступні залежності

### Jetpack Compose
- `androidx.compose.ui:ui` - Основні UI компоненти
- `androidx.compose.ui:ui-tooling-preview` - Preview підтримка
- `androidx.compose.material3:material3` - Material Design 3
- `androidx.compose.animation:animation` - Анімації

### Навігація
- `androidx.navigation:navigation-compose:2.8.0` - Навігація Compose

### Анімації та UI-компоненти
- `com.airbnb.android:lottie-compose:6.5.0` - Lottie анімації
- `com.github.skydoves:landscapist-glide:2.3.6` - Завантаження зображень

### Архітектура
- `androidx.lifecycle:lifecycle-runtime-ktx:2.8.6` - Lifecycle
- `androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6` - ViewModel
- `io.insert-koin:koin-androidx-compose:3.5.3` - Dependency Injection

### UI темізація
- `androidx.compose.material:material-icons-extended` - Розширені іконки
- `com.google.accompanist:accompanist-systemuicontroller:0.34.0` - System UI

### Локалізація
- `androidx.compose.ui:ui-text-google-fonts` - Google шрифти
- `com.google.accompanist:accompanist-flowlayout:0.34.0` - Flow Layout

## Розробка

### Створення нових екранів
1. Створіть новий Composable в `ui/screens/`
2. Додайте навігацію в `Navigation.kt`
3. Додайте ViewModel якщо потрібно

### Додавання нових залежностей
1. Додайте залежність в `app/build.gradle.kts`
2. Синхронізуйте проект
3. Використовуйте в коді

### Тестування
- Unit тести в `src/test/`
- UI тести в `src/androidTest/`

## Приклад використання

```kotlin
@Composable
fun MyScreen() {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Hello Rice Dev!",
            style = MaterialTheme.typography.headlineMedium
        )
        
        Button(
            onClick = { /* action */ }
        ) {
            Text("Click me")
        }
    }
}
```

## Підтримка платформ

- ✅ Android 7.0+ (API 24+)
- ✅ Android 14 (API 34)
- ✅ Material Design 3
- ✅ Jetpack Compose

## Ліцензія

Цей проект є частиною rice-dev екосистеми.

## Допомога

Якщо у вас виникли питання:
1. Перевірте документацію Jetpack Compose
2. Перегляньте приклади в `ui/screens/`
3. Створіть issue в репозиторії
