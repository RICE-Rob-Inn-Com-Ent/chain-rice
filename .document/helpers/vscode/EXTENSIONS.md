# 🔌 `extensions.json` - The Extension Ecosystem Master Guide

> **Expert guide to VS Code extension management**

## 🎯 The Purpose of This File

Having worked with countless VS Code extensions, The key lesson is: **`extensions.json` is your team's shared toolbox
manifest**. It's not about _forcing_ installations—it's about **recommending** the right tools for the job.

---

## 📖 Table of Contents

1. [The Extension Lifecycle](#1-the-extension-lifecycle)
2. [JSON Structure](#2-json-structure)
3. [Recommendations vs Requirements](#3-recommendations-vs-requirements)
4. [Extension IDs Deep Dive](#4-extension-ids-deep-dive)
5. [Conflict Resolution](#5-conflict-resolution)
6. [Extension Categories](#6-extension-categories)
7. [Performance Considerations](#7-performance-considerations)
8. [Advanced Strategies](#8-advanced-strategies)

---

## 1. The Extension Lifecycle

Understanding the lifecycle is key:

```text
1. Extension Published to Marketplace
   ↓
2. Added to extensions.json
   ↓
3. VS Code reads file when workspace opens
   ↓
4. Shows recommendation notification
   ↓
5. User installs (or ignores)
   ↓
6. Extension activates based on activation events
   ↓
7. Extension provides features
```

### Activation Events

Extensions don't run all the time—they activate based on events:

```javascript
// In extension's package.json
"activationEvents": [
  "onLanguage:python",        // When Python file opens
  "onCommand:myext.command",  // When command is run
  "workspaceContains:*.py",   // When workspace has Python files
  "*"                         // On startup (expensive!)
]
```

**The expert wisdom**: Extensions with `"*"` activation slow down startup. Prefer language-specific activation.

---

## 2. JSON Structure

### The Two Arrays

```json
{
  // Extensions to RECOMMEND
  "recommendations": ["publisher.extension-name", "another.extension"],

  // Extensions to AVOID
  "unwantedRecommendations": ["deprecated.extension", "conflicting.extension"]
}
```

### Extension ID Format

Every extension has a unique ID:

```text
publisher.extension-name
    │           │
    │           └─ Extension name (from package.json)
    └─ Publisher's username/organization
```

Example:

- `esbenp.prettier-vscode` → Esben Petersen's Prettier extension
- `ms-python.python` → Microsoft's Python extension

### Where to Find Extension IDs

1. **Marketplace page**: URL has it: `marketplace.visualstudio.com/items?itemName=publisher.extension-name`
2. **Installed extensions**: Right-click → "Copy Extension ID"
3. **Extension details**: Click gear icon → shows full ID

---

## 3. Recommendations vs Requirements

### This is **not** a requirements file

Experience shows: **You cannot force installations**. This file only:

✅ **Does**:

- Shows notification to install
- Lists in "Recommended" section
- Syncs across team via git

❌ **Does NOT**:

- Automatically install extensions
- Prevent workspace from opening
- Require extensions to function

### The Notification Flow

```text
User opens workspace
    ↓
VS Code checks extensions.json
    ↓
Compares with installed extensions
    ↓
Shows notification: "This workspace recommends installing 5 extensions"
    ↓
User clicks:
  • "Install All" → Installs all at once
  • "Show Recommendations" → Opens extensions panel
  • "Don't Show Again" → Workspace setting saved
```

### Making Extensions "Required" (Workaround)

While you can't force installation, you can:

1. **Document it**: In README.md, list must-have extensions
2. **Check in CI**: Write script to verify extension presence
3. **Create onboarding**: New team members get checklist
4. **Use Dev Containers**: Extensions can be installed automatically in container

---

## 4. Extension IDs Deep Dive

### Case Sensitivity

Extension IDs are **case-insensitive** in practice, but:

```json
{
  "recommendations": [
    "esbenp.prettier-vscode", // Correct (lowercase)
    "EsBeNp.PrEtTiEr-VsCoDe" // Works but ugly—don't do this
  ]
}
```

**Best practice**: Always use lowercase for consistency.

### Version Pinning (You Can't)

```json
{
  "recommendations": [
    "extension@1.2.3" // ❌ This doesn't work!
  ]
}
```

You **cannot** specify versions in `extensions.json`. Users always get the latest.

**Workaround**: Use Dev Containers with specific extension versions in `devcontainer.json`.

### Wildcard Recommendations (Doesn't Exist)

```json
{
  "recommendations": [
    "ms-python.*" // ❌ Doesn't work
  ]
}
```

You must specify each extension individually.

---

## 5. Conflict Resolution

With extensive experience, I've seen every extension conflict imaginable. Here's how to handle them:

### Identifying Conflicts

Common conflicts:

| Extension A  | Extension B | Conflict           | Solution                                |
| ------------ | ----------- | ------------------ | --------------------------------------- |
| Prettier     | Beautify    | Both format code   | Use Prettier, add Beautify to unwanted  |
| TSLint       | ESLint      | TSLint deprecated  | Use ESLint, mark TSLint unwanted        |
| Vetur        | Volar       | Both for Vue       | Use Volar (newer), mark Vetur unwanted  |
| Python (old) | Pylance     | Duplicate features | Pylance is included in Python extension |

### The Unwanted List

```json
{
  "unwantedRecommendations": [
    "hookyqr.beautify", // Prettier is better
    "eg2.tslint", // Deprecated, use ESLint
    "octref.vetur", // Use Volar for Vue 3
    "ms-vscode.typescript-javascript-grammar" // Now built-in
  ]
}
```

**When to add to unwanted**:

1. Extension is deprecated
2. Better alternative exists
3. Conflicts with recommended extension
4. Causes performance issues
5. Team had bad experience with it

### Handling Extension Packs

Some extensions are "packs" that install multiple extensions:

```json
{
  "recommendations": [
    // Bad: Extension pack might include unwanted extensions
    "vscjava.vscode-java-pack",

    // Better: Install individual extensions
    "redhat.java",
    "vscjava.vscode-java-debug",
    "vscjava.vscode-java-test"
  ]
}
```

**Expert insight**: Prefer individual extensions over packs for fine-grained control.

---

## 6. Extension Categories

### The Mental Model

I categorize extensions into 8 buckets:

```text
1. ESSENTIAL     → Must-have for any project
2. LANGUAGE      → Language-specific support
3. FRAMEWORK     → Framework-specific tools
4. LINTING       → Code quality & security
5. PRODUCTIVITY  → Developer experience
6. COLLABORATION → Team features
7. INFRASTRUCTURE → DevOps & cloud
8. OPTIONAL      → Nice-to-have, not critical
```

### Category Breakdown

#### 1. ESSENTIAL (Install These First)

```json
{
  "recommendations": [
    "editorconfig.editorconfig", // Cross-editor consistency
    "esbenp.prettier-vscode", // Code formatting
    "usernamehw.errorlens", // Inline errors
    "eamodio.gitlens", // Git superpowers
    "streetsidesoftware.code-spell-checker" // Typo prevention
  ]
}
```

#### 2. LANGUAGE (Based on Project)

```json
{
  "recommendations": [
    // Python
    "ms-python.python",
    "ms-python.vscode-pylance",
    "charliermarsh.ruff",

    // JavaScript/TypeScript
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-typescript-next",

    // Go
    "golang.go",

    // Rust
    "rust-lang.rust-analyzer",

    // Java
    "redhat.java"
  ]
}
```

#### 3. FRAMEWORK (Based on Tech Stack)

```json
{
  "recommendations": [
    // React
    "dsznajder.es7-react-js-snippets",

    // Vue
    "vue.volar",

    // Angular
    "angular.ng-template",

    // Svelte
    "svelte.svelte-vscode",

    // Flutter
    "dart-code.flutter"
  ]
}
```

#### 4. LINTING & QUALITY

```json
{
  "recommendations": [
    "sonarsource.sonarlint-vscode", // Code quality
    "snyk-security.snyk-vulnerability-scanner", // Security
    "timonwong.shellcheck", // Shell script linter
    "exiasr.hadolint" // Dockerfile linter
  ]
}
```

#### 5. PRODUCTIVITY

```json
{
  "recommendations": [
    "christian-kohler.path-intellisense", // Path autocomplete
    "gruntfuggly.todo-tree", // TODO tracker
    "alefragnani.bookmarks", // Code bookmarks
    "formulahendry.code-runner", // Quick code execution
    "wix.vscode-import-cost" // Bundle size awareness
  ]
}
```

#### 6. COLLABORATION

```json
{
  "recommendations": [
    "ms-vsliveshare.vsliveshare", // Live collaboration
    "github.vscode-pull-request-github", // GitHub PRs
    "gitlab.gitlab-workflow" // GitLab integration
  ]
}
```

#### 7. INFRASTRUCTURE

```json
{
  "recommendations": [
    "ms-azuretools.vscode-docker", // Docker
    "ms-kubernetes-tools.vscode-kubernetes-tools", // Kubernetes
    "hashicorp.terraform", // Terraform
    "redhat.ansible" // Ansible
  ]
}
```

#### 8. OPTIONAL (Nice-to-Have)

```json
{
  "recommendations": [
    "pkief.material-icon-theme", // File icons
    "github.github-vscode-theme", // Theme
    "vscodevim.vim", // Vim emulation
    "ritwickdey.liveserver" // Live web server
  ]
}
```

---

## 7. Performance Considerations

Extensions can **significantly** impact performance. With extensive experience of profiling:

### The Performance Hierarchy

```text
🟢 Lightweight (<10ms activation, <5MB memory)
   • Themes, icon packs
   • Simple syntax highlighters
   • Snippet collections

🟡 Moderate (10-100ms activation, 5-50MB memory)
   • Language servers (Pylance, TypeScript)
   • Linters (ESLint, Prettier)
   • Git extensions (GitLens)

🔴 Heavy (>100ms activation, >50MB memory)
   • Database clients
   • Remote development
   • AI assistants (Copilot)
   • Full IDE replacements
```

### Measuring Extension Impact

```bash
# Run VS Code from terminal with profiling
code --prof-startup

# Or use Command Palette
Cmd/Ctrl+Shift+P → "Developer: Startup Performance"
```

Look for:

- **Activation time**: How long extension takes to start
- **Loaded time**: How long to load extension code
- **Main thread time**: CPU usage

### Optimizing Extension Load

```json
{
  "recommendations": [
    // ✅ Good: Only activates for Python files
    "ms-python.python",

    // ⚠️ Caution: Activates on every workspace
    "ms-vscode.remote-explorer",

    // ❌ Avoid: Activates on startup (heavyweight)
    "salesforce.salesforcedx-vscode-core"
  ]
}
```

**Golden rule**: Only recommend extensions the project **actually uses**.

### The 20-Extension Rule

From extensive observation:

- **0-10 extensions**: Optimal performance
- **10-20 extensions**: Still good
- **20-30 extensions**: Noticeable slowdown
- **30+ extensions**: Consider disabling some

---

## 8. Advanced Strategies

### Strategy 1: Language-Specific Workspaces

For monorepos with multiple languages:

```json
{
  // Core recommendations (everyone needs)
  "recommendations": ["editorconfig.editorconfig", "eamodio.gitlens"]

  // Python devs: Add Python-specific
  // Go devs: Add Go-specific
  // etc.
}
```

Then create workspace-specific extension files:

- `.vscode/extensions.python.json`
- `.vscode/extensions.go.json`

**Note**: VS Code doesn't read these automatically—just for documentation.

### Strategy 2: Progressive Enhancement

Order recommendations by importance:

```json
{
  "recommendations": [
    // Phase 1: Critical (install immediately)
    "esbenp.prettier-vscode",
    "ms-python.python",

    // Phase 2: Important (install within a week)
    "eamodio.gitlens",
    "gruntfuggly.todo-tree",

    // Phase 3: Nice-to-have (optional)
    "pkief.material-icon-theme",
    "github.github-vscode-theme"
  ]
}
```

### Strategy 3: Extension Profiles (VS Code 1.75+)

VS Code now supports **profiles** for switching extension sets:

```json
// Default profile: frontend/extensions.json
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "vue.volar"
  ]
}

// Backend profile: backend/extensions.json
{
  "recommendations": [
    "ms-python.python",
    "golang.go",
    "rust-lang.rust-analyzer"
  ]
}
```

### Strategy 4: Extension Sync

For teams using **Settings Sync**:

```json
{
  // These sync across machines
  "recommendations": ["editorconfig.editorconfig", "eamodio.gitlens"]

  // But remember: workspace extensions.json
  // is in git, not Settings Sync
}
```

---

## 🎓 Expert Insights

### The Extension Selection Process

When adding an extension to recommendations:

1. **Need verification**: Does the project actually need this?
2. **Alternative check**: Is there a better extension?
3. **Conflict check**: Does it conflict with existing extensions?
4. **Performance test**: Does it slow down the IDE?
5. **Maintenance check**: Is it actively maintained?
6. **Team consensus**: Do teammates agree?

### Extension Red Flags

🚩 **Avoid extensions that**:

- Haven't been updated in 2+ years
- Have <50 ratings with <3 stars
- Are marked as "deprecated"
- Have known security issues
- Conflict with popular extensions
- Require paid subscriptions (for team recommendations)

### The Minimal Extension Philosophy

With extensive experience, The key lesson is: **Less is more**.

```text
Principle: Only recommend what's necessary

✅ Do recommend:
  • Language support for languages you use
  • Linters/formatters you've standardized on
  • Tools that enforce team conventions

❌ Don't recommend:
  • Personal preference themes
  • Productivity tools (let developers choose)
  • Experimental extensions
  • Anything with unclear purpose
```

### Documentation Template

Always document your recommendations:

```json
{
  "recommendations": [
    // ============================================================================
    // ESSENTIAL - Install these first
    // ============================================================================
    "esbenp.prettier-vscode", // Code formatter - Team standard
    "editorconfig.editorconfig", // EditorConfig support - Required

    // ============================================================================
    // LANGUAGE SUPPORT - Based on project languages
    // ============================================================================
    "ms-python.python", // Python support - Backend
    "dbaeumer.vscode-eslint", // ESLint - Frontend linting

    // ============================================================================
    // OPTIONAL - Recommended but not required
    // ============================================================================
    "eamodio.gitlens" // Enhanced Git - Productivity
  ]
}
```

---

## 🚀 The Ultimate Template

Here's my expert template for a full-stack project:

```json
{
  "recommendations": [
    // ========================================
    // CORE (Everyone needs these)
    // ========================================
    "editorconfig.editorconfig",
    "esbenp.prettier-vscode",
    "eamodio.gitlens",
    "usernamehw.errorlens",
    "streetsidesoftware.code-spell-checker",

    // ========================================
    // LANGUAGES (Project-specific)
    // ========================================
    "ms-python.python",
    "ms-python.vscode-pylance",
    "dbaeumer.vscode-eslint",
    "golang.go",
    "rust-lang.rust-analyzer",

    // ========================================
    // FRAMEWORKS (Based on tech stack)
    // ========================================
    "dsznajder.es7-react-js-snippets",
    "vue.volar",
    "angular.ng-template",

    // ========================================
    // INFRASTRUCTURE (DevOps)
    // ========================================
    "ms-azuretools.vscode-docker",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "hashicorp.terraform",

    // ========================================
    // QUALITY & SECURITY
    // ========================================
    "sonarsource.sonarlint-vscode",
    "snyk-security.snyk-vulnerability-scanner",

    // ========================================
    // PRODUCTIVITY (Optional)
    // ========================================
    "gruntfuggly.todo-tree",
    "alefragnani.bookmarks",
    "christian-kohler.path-intellisense"
  ],

  "unwantedRecommendations": [
    // Deprecated/conflicting extensions
    "hookyqr.beautify", // Use Prettier instead
    "eg2.tslint", // Deprecated - Use ESLint
    "octref.vetur" // Use Volar for Vue 3
  ]
}
```

---

## 🔍 Troubleshooting

### Extension Not Showing Up

1. **Check spelling**: Extension ID must be exact
2. **Check existence**: Search Marketplace
3. **Check workspace**: Must be in project root `.vscode/`
4. **Reload window**: `Cmd/Ctrl+Shift+P` → "Reload Window"

### Notification Not Appearing

1. **Check if already installed**: Won't notify if installed
2. **Check settings**: User may have disabled notifications
3. **Check workspace trust**: Untrusted workspaces limit features
4. **Try clearing cache**: Remove `.vscode/.ropeproject` and reload

### Extension Conflicts

1. **Check active extensions**: `Cmd/Ctrl+Shift+P` → "Extensions: Show Running Extensions"
2. **Disable one at a time**: Find the conflict
3. **Add to unwanted**: Document the conflict
4. **Update documentation**: Tell team why one is preferred

---

**Expert insight: Choose extensions wisely, document thoroughly, maintain diligently.** 🚀
