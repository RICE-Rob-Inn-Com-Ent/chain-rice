# 🛠️ Development Tools Setup

Quick reference for setting up development environment for Rice-Mono project.

## 🚀 Quick Install (All Tools)

Install everything at once:

```bash
cd /home/mrDinkelman/rice-mono
./.dev/scripts/setup-all.sh
```

**Installs:**

- ☕ Java JDK 17
- 📦 Node.js 20.x LTS
- 🐳 kind (Kubernetes in Docker)
- ☸️ kubectl
- ⎈ helm

---

## 📦 Individual Component Installation

### Java JDK 17 (for Android/Kotlin/Gradle)

**Why needed?**

- Android library development
- Kotlin Language Server
- Gradle Language Server

**Install:**

```bash
./.dev/scripts/setup-java.sh
```

**Manual install (Arch Linux):**

```bash
sudo pacman -S jdk17-openjdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
```

**Verify:**

```bash
java -version
echo $JAVA_HOME
```

---

### Node.js 20.x LTS (for Frontend/SonarQube)

**Why needed?**

- Frontend web development (React, Next.js)
- SonarQube code analysis (requires >= 20.12.0)
- TypeScript/JavaScript Language Servers
- npm/pnpm/yarn package managers

**Install:**

```bash
./.dev/scripts/setup-nodejs.sh
```

**Manual install (Arch Linux):**

```bash
sudo pacman -S nodejs npm
```

**Verify:**

```bash
node --version   # Should be >= v20.12.0
npm --version
```

---

### Bazel / Bazelisk (Build System)

**Why needed?**

- Monorepo build system
- Multi-language build support (Python, Go, Rust, TypeScript, Java, Kotlin)
- Bazel Language Server / Starlark support
- Incremental builds and caching

**Install:**

```bash
./.dev/scripts/setup-bazel.sh
```

**Manual install (Arch Linux):**

```bash
# Install Bazelisk (Bazel version manager) from AUR
yay -S bazelisk

# Or install manually
curl -Lo /tmp/bazelisk https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64
chmod +x /tmp/bazelisk
sudo mv /tmp/bazelisk /usr/local/bin/bazelisk
sudo ln -sf /usr/local/bin/bazelisk /usr/local/bin/bazel
```

**Verify:**

```bash
bazel --version
bazel info
```

**Build project:**

```bash
# Build everything
bazel build //...

# Build specific target
bazel build //.bot:main

# Run tests
bazel test //...

# Clean
bazel clean
```

---

### kind (Kubernetes in Docker)

**Why needed?**

- Local Kubernetes cluster for development
- Testing Kubernetes deployments
- ArgoCD, Helm chart testing

**Install:**

```bash
# Included in setup-all.sh, or manual:
sudo pacman -S kind
```

**Create cluster:**

```bash
kind create cluster --name rice-mono
```

**Verify:**

```bash
kind --version
kind get clusters
```

---

### Flutter SDK (Optional - for Mobile Development)

**Why needed?**

- Flutter mobile app development
- Dart Language Server
- Android/iOS cross-platform development

**Install:**

```bash
./.dev/scripts/setup-flutter.sh
```

**Manual install (Arch Linux):**

```bash
# Clone Flutter repository
sudo git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
sudo chown -R $USER:$USER /opt/flutter

# Add to PATH
export PATH="/opt/flutter/bin:$PATH"

# Complete setup
flutter precache
flutter doctor
```

**Verify:**

```bash
flutter --version
flutter doctor
```

**Note:** Flutter requires additional setup for Android/iOS development:

- **Android:** Install Android Studio
- **iOS:** Install Xcode (macOS only)

---

## 🔧 Troubleshooting

### "JAVA_HOME is not set"

**Language Servers failing:**

- ❌ Gradle Language Server
- ❌ Kotlin Language Server
- ❌ Java Language Server

**Solution:**

```bash
./.dev/scripts/setup-java.sh
source ~/.bashrc
```

Then restart VS Code/Cursor.

---

### "Node.js runtime version 20.12.0 or later is required"

**SonarQube fails to analyze code**

**Solution:**

```bash
./.dev/scripts/setup-nodejs.sh
source ~/.bashrc
```

Then restart VS Code/Cursor.

---

### Language Servers keep initializing forever

**Causes:**

1. Missing Java/Node.js
2. Incorrect paths in VS Code settings
3. Missing build files (build.gradle.kts, package.json)

**Solution:**

```bash
# Install missing dependencies
./.dev/scripts/setup-all.sh

# Restart VS Code/Cursor completely
# Check Output panel for specific errors
```

---

### "Could not find a Flutter SDK"

**Dart/Flutter extension fails**

**Solution:**

```bash
# Install Flutter SDK
./.dev/scripts/setup-flutter.sh

# Restart terminal
source ~/.bashrc

# Restart VS Code/Cursor
```

Then in VS Code, click "Locate SDK" and point to `/opt/flutter`

---

### "Failed to find a Bazel workspace"

**Bazel extension can't find workspace**

**Solution:**

```bash
# Install Bazel
./.dev/scripts/setup-bazel.sh

# Restart terminal
source ~/.bashrc

# Restart VS Code/Cursor
```

The issue should resolve after:

1. Bazel is installed
2. WORKSPACE file exists in project root (created by setup script)
3. VS Code/Cursor is restarted

---

## 📁 Project-Specific Setup

### Android Components Library

Located in: `.frontend/android/`

**Requirements:**

- Java JDK 17 ✅ (installed by setup-java.sh)
- Android SDK (optional for building)
- Gradle 8.0+ (wrapper included)

**Build:**

```bash
cd .frontend/android
./gradlew :components:build
```

**Test:**

```bash
./gradlew :components:test
```

---

### Frontend Web Apps

Located in: `.frontend/web/next/`

**Requirements:**

- Node.js 20.x ✅ (installed by setup-nodejs.sh)
- npm/pnpm

**Install dependencies:**

```bash
cd .frontend/web/next
npm install
```

**Run dev server:**

```bash
npm run dev
```

---

## 🔄 After Installation

### 1. Restart Terminal

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

### 2. Restart VS Code/Cursor

Close and reopen completely (not just reload window).

### 3. Verify Installations

```bash
java -version        # Should show 17.x
node --version       # Should show v20.x
npm --version
kind --version
kubectl version --client
helm version
```

### 4. Check Environment Variables

```bash
echo $JAVA_HOME     # Should be /usr/lib/jvm/java-17-openjdk
echo $PATH          # Should include Java and Node bins
```

---

## 📚 See Also

- [Quick Start Guide](QUICKSTART.md) - Complete DevOps setup
- [README](README.md) - Full documentation
- [Kubernetes Guide](docs/KUBERNETES.md) - K8s configuration
- [Android Components](../.frontend/android/README.md) - Android library docs

---

## ℹ️ Version Requirements

| Tool    | Minimum | Recommended | Purpose                 |
| ------- | ------- | ----------- | ----------------------- |
| Java    | 17.0    | 17.0.16+    | Android, Kotlin, Gradle |
| Node.js | 20.12.0 | 20.x LTS    | Frontend, SonarQube     |
| npm     | 10.0    | 10.x        | Package management      |
| Bazel   | 7.0.0   | 7.x         | Monorepo build system   |
| Flutter | 3.0     | 3.x stable  | Mobile development      |
| kind    | 0.20.0  | 0.23.0+     | Local Kubernetes        |
| kubectl | 1.28    | 1.30+       | Kubernetes CLI          |
| helm    | 3.12    | 3.14+       | Kubernetes packages     |
| Docker  | 24.0    | 25.0+       | Container runtime       |

---

**Built with ❤️ by the Rice-Mono Team**
