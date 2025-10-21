# 🌌 InfiniR

**Multi-Platform AI-Powered Infinite Reality**

## 🏗️ Multi-Platform Architecture

InfiniR is a **multi-platform project** using components from rice-mono libraries:

```
.project/infinir/
├── web/              → Vite + React (imports from .frontend/next/)
├── desktop/          → Flutter Desktop (imports from .frontend/flutter/)
└── mobile/
    ├── android/      → Kotlin + Compose (imports from .frontend/android/)
    └── ios/          → Swift + SwiftUI (imports from .frontend/ios/)
```

**Philosophy:** Minimal code in `.project/`, maximum reuse from `.frontend/`

## 🚀 Quick Start

### Web Platform

```bash
cd web
npm install
npm run dev
# → http://localhost:3000
```

### Desktop Platform

```bash
cd desktop
flutter pub get
flutter run -d linux
```

### Mobile Android

```bash
cd mobile/android
./gradlew installDebug
```

### Mobile iOS

```bash
cd mobile/ios
swift run
```

## 📦 Backend Services (from rice-mono)

- **Token Service** (Go) - Port 8080
- **CQRS Service** (Go) - Port 8081
- **GraphQL API** - Port 4000

## 🎯 Development Workflow

### Option 1: VS Code Debugger (Recommended)

```
Press F5 → Select:
- ⭐ Dev: Web Only              (Just web)
- ⭐ Dev: Web + Backend          (Web + Go + GraphQL)
- ⭐ Dev: All Platforms          (Web + Desktop + Mobile)
- ⭐ Full Stack: Backend + All   (Everything!)
```

### Option 2: npm scripts

```bash
# Web
npm run dev:web

# Desktop
npm run dev:desktop

# Android
npm run dev:android

# iOS
npm run dev:ios
```

## 🧪 Testing

### Test All Platforms

```bash
npm run test:all
```

### Test Individual Platforms

```bash
npm run test:web        # Vitest
npm run test:desktop    # Flutter test
npm run test:android    # Gradle test
npm run test:ios        # Swift test
```

## 📁 Project Slot Pattern

This project lives in the `.project/` **DYNAMIC SLOT**:

1. **Current Project**: InfiniR (this repo)
2. **When Finished**: `git push` → delete `.project/*` → clone next project
3. **Next Project**: Different repo with different stack

`.project/` = **One project at a time**, but rice-mono libraries stay permanent!

## 🎨 What Shows on Screen

All platforms show the same content (with platform-specific rendering):

```
┌────────────────────────────────────┐
│                                    │
│           I n f i n i R           │
│      (gradient animation)          │
│                                    │
│     Infinite Reality Awaits        │
│         [Platform Name]            │
│                                    │
└────────────────────────────────────┘
```

## 📊 Dependency Philosophy

| Platform | Frontend Source      | Custom Code |
| -------- | -------------------- | ----------- |
| Web      | `.frontend/next/`    | ~5 files    |
| Desktop  | `.frontend/flutter/` | ~2 files    |
| Android  | `.frontend/android/` | ~3 files    |
| iOS      | `.frontend/ios/`     | ~2 files    |

**Goal**: Keep `.project/` thin, libraries thick!
