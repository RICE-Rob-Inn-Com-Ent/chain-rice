# Rice Dev Flutter Frontend

Flutter додаток для rice-dev екосистеми з сучасними UI компонентами та анімаціями.

## Особливості

### 🎨 UI та компоненти
- **Responsive Framework** - адаптивний дизайн для всіх пристроїв
- **Material Design 3** - сучасний дизайн від Google
- **Google Fonts** - красиві шрифти Inter
- **Flutter SVG** - підтримка векторної графіки
- **GetWidget** - готові UI компоненти

### 🎭 Анімації та ефекти
- **Animations** - анімації Flutter
- **Rive** - інтерактивні анімації
- **Lottie** - анімації After Effects
- **Velocity X** - швидкі анімації

### 📊 Візуалізація даних
- **FL Chart** - графіки та діаграми
- **Flutter Staggered Grid View** - сітка з різними розмірами

### 🎯 State Management
- **Flutter Bloc** - управління станом
- **Riverpod** - сучасний state management
- **Flutter Hooks** - хуки для функціональних компонентів

### 🧭 Навігація
- **Go Router** - декларативна навігація

### 🎨 Теми
- **Flex Color Scheme** - гнучкі кольорові схеми
- **Flutter Native Splash** - splash screen
- **Flutter Launcher Icons** - іконки додатка

## Встановлення

1. Встановіть Flutter SDK
2. Встановіть залежності:
```bash
flutter pub get
```

## Запуск

### Linux Desktop
```bash
flutter run -d linux
```

### Web
```bash
flutter run -d chrome
```

### Android (потрібен Android SDK)
```bash
flutter run -d android
```

## Структура проекту

```
lib/
├── main.dart              # Основний файл додатка
├── screens/               # Екрани додатка
├── widgets/               # Переиспользуемые виджеты
├── models/                # Моделі даних
├── services/              # Сервіси та API
├── utils/                 # Утиліти
└── constants/             # Константи

assets/
├── images/                # Зображення
├── icons/                 # Іконки
└── animations/            # Анімації (Rive, Lottie)
```

## Доступні залежності

### State Management
- `flutter_bloc: ^8.1.2` - BLoC pattern
- `hooks_riverpod: ^2.4.0` - Riverpod state management
- `flutter_hooks: ^0.20.5` - Hooks для функціональних компонентів

### Навігація
- `go_router: ^14.0.0` - Декларативна навігація

### UI та компоненти
- `responsive_framework: ^1.2.0` - Адаптивний дизайн
- `animations: ^2.0.8` - Анімації Flutter
- `rive: ^0.12.3` - Інтерактивні анімації
- `lottie: ^3.1.2` - Анімації After Effects
- `flutter_staggered_grid_view: ^0.7.0` - Сітка з різними розмірами
- `fl_chart: ^0.65.0` - Графіки та діаграми
- `getwidget: ^4.0.0` - Готові UI компоненти
- `velocity_x: ^3.6.0` - Швидкі анімації

### Теми та графіка
- `flex_color_scheme: ^7.3.1` - Гнучкі кольорові схеми
- `google_fonts: ^6.2.1` - Google шрифти
- `flutter_svg: ^2.0.10+1` - Підтримка SVG

### Локалізація та зручності
- `intl: ^0.17.0` - Інтернаціоналізація
- `flutter_native_splash: ^2.4.0` - Splash screen
- `flutter_launcher_icons: ^0.13.1` - Іконки додатка

## Розробка

1. Створюйте нові екрани в `lib/screens/`
2. Додавайте переиспользуемые виджеты в `lib/widgets/`
3. Створюйте моделі даних в `lib/models/`
4. Додавайте сервіси в `lib/services/`
5. Використовуйте `flutter analyze` для перевірки коду
6. Запускайте `flutter test` для тестування

## Приклад використання

```dart
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveRowColumn(
        layout: ResponsiveBreakpoints.of(context).smallerThan(DESKTOP)
            ? ResponsiveRowColumnType.COLUMN
            : ResponsiveRowColumnType.ROW,
        children: [
          ResponsiveRowColumnItem(
            child: Text('Responsive Content'),
          ),
        ],
      ),
    );
  }
}
```

## Підтримка платформ

- ✅ Linux Desktop
- ✅ Web
- ⚠️ Android (потребує Android SDK)
- ⚠️ iOS (потребує macOS та Xcode)

## Ліцензія

Цей проект є частиною rice-dev екосистеми.
