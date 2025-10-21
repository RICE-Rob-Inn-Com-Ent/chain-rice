# Swift Frontend - Rice Mono

## 🚀 Quick Start

### Prerequisites

✅ Swift 6.0.3 - Installed and configured!

### Setup

```bash
# Reload environment
source ~/.bashrc

# Verify Swift is working
swift --version
```

### Build & Run

```bash
cd .frontend/ios

# Resolve dependencies
swift package resolve

# Build the project
swift build

# Run tests (when available)
swift test
```

## 📦 Project Structure

```
.frontend/ios/
├── Package.swift          # Swift Package Manager manifest
├── Sources/
│   └── SwiftFrontend/    # Main source code
├── BUILD.bazel           # Bazel build configuration
└── README_SWIFT.md       # This file
```

## 📚 Dependencies

This project uses cutting-edge Swift libraries:

### Architecture

- **The Composable Architecture** - Unidirectional data flow

### UI Components

- **SVGKit** - SVG rendering
- **Lottie** - Beautiful animations
- **SwiftUIX** - Extended SwiftUI components
- **SPAlert** - Native alerts and toasts

### Utilities

- **Kingfisher** - Image downloading and caching
- **Alamofire** - Networking
- **CryptoSwift** - Cryptography
- **BonMot** - Typography
- **Localize-Swift** - Localization

## 🛠️ VS Code Integration

### Required Extension

Install: **Swift Language** (`sswg.swift-lang`)

### Features Available

- ✅ Syntax highlighting
- ✅ IntelliSense (code completion)
- ✅ Error checking
- ✅ Inlay hints
- ✅ Debugging support
- ✅ Swift Package Manager integration

### Restart VS Code

After installation, **restart VS Code** to activate the Swift extension.

## 🎯 Development Workflow

### 1. Add New Feature

```bash
# Create new Swift file
touch Sources/SwiftFrontend/MyFeature.swift

# Edit in VS Code with full IntelliSense
code Sources/SwiftFrontend/MyFeature.swift
```

### 2. Add Dependency

Edit `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/author/Package.git", from: "1.0.0")
],
targets: [
    .target(
        name: "SwiftFrontend",
        dependencies: ["Package"]
    )
]
```

### 3. Build & Test

```bash
swift build
swift test
```

## 🐧 Building on Linux for iOS

While you can develop and test Swift code on Linux, building for iOS requires:

1. **Cross-compilation toolchain** (complex)
2. **Use CI/CD** - GitHub Actions with macOS runners
3. **Remote macOS build server**

### Recommended: GitHub Actions

Create `.github/workflows/ios-build.yml`:

```yaml
name: iOS Build
on: [push]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          cd .frontend/ios
          swift build
          swift test
```

## 🔄 Multi-Platform Strategy

Rice-Mono uses a hybrid approach:

| Platform       | Technology  | Development OS               |
| -------------- | ----------- | ---------------------------- |
| iOS/macOS      | **Swift**   | Linux (code) + macOS (build) |
| Android        | **Kotlin**  | Linux                        |
| Cross-platform | **Flutter** | Linux                        |
| Web            | **Next.js** | Linux                        |

## 📖 Learning Resources

- [Swift Documentation](https://docs.swift.org)
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [Swift on Linux](https://swift.org/getting-started/#using-the-package-manager)
- [Point-Free Videos](https://www.pointfree.co) - Advanced Swift & TCA

## 🆘 Troubleshooting

### "Package resolution failed"

```bash
rm -rf .build/
swift package resolve
```

### "libxml2 warnings"

These are harmless. Swift works fine despite the warnings.

### "VS Code not recognizing Swift"

1. Restart VS Code
2. Check extension is installed: `sswg.swift-lang`
3. Verify settings in `.vscode/settings.json`

## 🎉 You're Ready!

Your Swift development environment on Arch Linux is fully configured and ready for multi-platform development!

Happy coding! 🚀
