# Rice-Mono Flutter Project

Flutter mobile application for the Rice-Mono ecosystem.

## 🚀 Quick Start

### Prerequisites

1. **Install Flutter SDK:**

   ```bash
   cd /home/mrDinkelman/rice-mono
   ./.dev/scripts/setup-flutter.sh
   ```

2. **Verify installation:**
   ```bash
   flutter doctor
   ```

### Development

#### Install Dependencies

```bash
cd .frontend/flutter
flutter pub get
```

#### Run in Debug Mode

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Chrome (Web)
flutter run -d chrome
```

#### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release
```

## 📁 Project Structure

```
flutter/
├── lib/                    # Main application code
│   ├── main.dart          # Application entry point
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable widgets
│   └── services/          # Business logic & API calls
├── test/                  # Unit & widget tests
├── assets/                # Images, fonts, etc.
├── pubspec.yaml           # Dependencies & metadata
└── analysis_options.yaml  # Linter configuration
```

## 🛠️ Development Tools

### VS Code Extensions

Install these extensions for better development experience:

- **Dart** (dart-code.dart-code)
- **Flutter** (dart-code.flutter)
- **Flutter Widget Snippets**
- **Pubspec Assist**

### Useful Commands

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Check for updates
flutter upgrade

# Clean build artifacts
flutter clean

# Doctor (check environment)
flutter doctor -v
```

## 🔗 Integration

### Android Components

This Flutter app uses the reusable Android components library from `.frontend/android/components/`.

### Backend API

Configure API endpoints in `lib/config/api_config.dart` to connect with the Rice-Mono backend services.

## 📱 Platform Setup

### Android

1. Install Android Studio
2. Configure Android SDK
3. Set up emulator or connect physical device
4. Run `flutter doctor` to verify

### iOS (macOS only)

1. Install Xcode
2. Install CocoaPods: `sudo gem install cocoapods`
3. Set up simulator or connect physical device
4. Run `flutter doctor` to verify

### Web

No additional setup required! Just run:

```bash
flutter run -d chrome
```

## 🐛 Troubleshooting

### "Flutter SDK not found"

**Solution:**

```bash
# Install Flutter
./.dev/scripts/setup-flutter.sh

# Restart VS Code/Cursor
# In VS Code: Cmd/Ctrl+Shift+P → "Flutter: Change SDK"
# Point to: /opt/flutter
```

### "Unable to locate Android SDK"

**Solution:**

```bash
# Install Android Studio from official website
# Then set ANDROID_HOME:
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Add to ~/.bashrc to make permanent
```

### Dependency conflicts

**Solution:**

```bash
flutter clean
flutter pub get
```

### Gradle build errors

**Solution:**

```bash
cd android
./gradlew clean
cd ..
flutter run
```

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Packages](https://pub.dev/)
- [Flutter Codelabs](https://docs.flutter.dev/codelabs)

## 🤝 Contributing

See main [CONTRIBUTING.md](../../.doc/docs/CONTRIBUTING.md) for contribution guidelines.

---

**Built with ❤️ using Flutter**
