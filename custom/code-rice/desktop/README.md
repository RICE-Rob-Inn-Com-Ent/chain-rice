# Flutter Desktop App - GiPT-1 AGI

Flutter application replacing the web frontend, designed for better IDE integration and native performance.

## 🚀 Quick Start

### Prerequisites

1. **Install Flutter SDK** (if not already installed):
   ```bash
   cd /home/mrDinkelman/rice-mono
   ./.dev/scripts/setup-flutter.sh
   ```

2. **Verify installation**:
   ```bash
   flutter doctor
   ```

### Development

#### Install Dependencies

```bash
cd .frontend/desktop
flutter pub get
```

#### Run in Debug Mode

```bash
# Desktop (Linux/macOS/Windows)
flutter run -d linux
flutter run -d macos
flutter run -d windows

# Chrome (Web)
flutter run -d chrome

# Mobile (if needed)
flutter run -d android
flutter run -d ios
```

#### Build Release

```bash
# Desktop
flutter build linux --release
flutter build macos --release
flutter build windows --release

# Web
flutter build web --release
```

## 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── screens/                     # UI screens
│   ├── dashboard/              # Dashboard screen
│   ├── training/               # Training/Geny screen
│   ├── benchmark/              # Benchmark screen
│   └── interfaces/             # Business interfaces
│       ├── data_manager_screen.dart
│       ├── knowledge_base_screen.dart
│       └── cloud_manager_screen.dart
└── widgets/                     # Reusable widgets
    └── side_nav.dart           # Side navigation bar
```

## 🎯 Features

- **Dashboard**: System overview and monitoring
- **Training (Geny)**: AI model training and management
- **Benchmark**: Model performance comparison
- **Business Interfaces**: 
  - Data Manager
  - Knowledge Base
  - Cloud Manager

## 🔗 Integration

### Backend API

The app connects to the Rice-Mono backend services:
- **GraphQL Router**: `http://localhost:4000`
- **Backend API**: `http://localhost:8080`

Configure API endpoints in `lib/config/api_config.dart` (to be created).

### Running with Backend

1. Start infrastructure and backend:
   ```bash
   make launch-infra
   make launch-backend
   ```

2. Run Flutter app:
   ```bash
   cd .frontend/desktop
   flutter run -d linux
   ```

## 🛠️ Development Tools

### VS Code Extensions

Recommended extensions:
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

## 📝 Notes

- This Flutter app replaces the previous web frontend (`.frontend/web`)
- Better IDE integration with hot reload and debugging
- Native performance on desktop platforms
- Cross-platform support (Linux, macOS, Windows, Web, Mobile)
