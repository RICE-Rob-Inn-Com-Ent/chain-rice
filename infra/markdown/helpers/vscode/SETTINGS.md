# 🎛️ `settings.json` - The Ultimate Guide

> **Expert guide to VS Code settings configuration**

## 🧠 The Philosophy of Settings

With extensive experience, The fundamental principle: **`settings.json` is the DNA of your development environment**. It's not
just configuration—it's a declaration of how code should be written, formatted, analyzed, and presented. Master this
file, and you master your craft.

---

## 📖 Table of Contents

1. [JSON Structure & Syntax](#1-json-structure--syntax)
2. [The Setting Hierarchy](#2-the-setting-hierarchy)
3. [Core Editor Settings](#3-core-editor-settings)
4. [Language-Specific Configurations](#4-language-specific-configurations)
5. [File System & Search](#5-file-system--search)
6. [Extensions Integration](#6-extensions-integration)
7. [Performance Optimization](#7-performance-optimization)
8. [Advanced Patterns](#8-advanced-patterns)
9. [Common Pitfalls](#9-common-pitfalls)

---

## 1. JSON Structure & Syntax

### The Foundation

```json
{
  // This is JSONC (JSON with Comments)
  // VS Code's configuration language

  "setting.name": "value", // Simple string value
  "another.setting": 123, // Number value
  "boolean.setting": true, // Boolean value

  // Array values
  "array.setting": ["item1", "item2"],

  // Object values
  "object.setting": {
    "nested": "property"
  },

  // Language-specific overrides (most powerful feature)
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

### Key Rules I've Learned

1. **Trailing commas are allowed** (but inconsistent—I recommend avoiding them)
2. **Comments are essential** (your future self will thank you)
3. **Order doesn't matter** (but organization does—group related settings)
4. **Quotes are required** for strings (single quotes are invalid JSON)

---

## 2. The Setting Hierarchy

This is **CRITICAL** to understand. After extensive debugging "why isn't this working?", Here's the hierarchy:

```text
┌─────────────────────────────────────┐
│  DEFAULT SETTINGS (VS Code)        │  ← Lowest priority
├─────────────────────────────────────┤
│  USER SETTINGS (~/.config/...)     │  ← Your personal preferences
├─────────────────────────────────────┤
│  WORKSPACE SETTINGS (.vscode/)     │  ← Project-wide (THIS FILE)
├─────────────────────────────────────┤
│  FOLDER SETTINGS (multi-root)      │  ← Per-folder in multi-root
├─────────────────────────────────────┤
│  LANGUAGE OVERRIDES ([python])     │  ← Highest priority for that language
└─────────────────────────────────────┘
```

### The Golden Rule

**Most specific always wins.** A `[python]` override in workspace settings beats a general `editor.tabSize` in user
settings.

### How to Check What's Actually Active

```text
Cmd/Ctrl+Shift+P → "Preferences: Open Settings (UI)"
→ Hover over any setting → See where it's defined
```

---

## 3. Core Editor Settings

### The Big Three (Format, Save, Actions)

```json
{
  // Auto-format on save (99% of projects need this)
  "editor.formatOnSave": true,

  // Format on paste (be careful—can be annoying)
  "editor.formatOnPaste": false,

  // Actions to run when saving
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit", // Fix all auto-fixable issues
    "source.fixAll.eslint": "explicit", // ESLint auto-fix
    "source.organizeImports": "explicit", // Sort/remove imports
    "source.sortImports": "explicit" // Sort imports
  }
}
```

#### Why `"explicit"` instead of `true`?

Having seen countless configurations, `"explicit"` is the modern way:

- `true`: Deprecated (still works)
- `"explicit"`: Opt-in (you control it)
- `"never"`: Opt-out
- `false`: Disabled

### Tab Size & Spaces (The Eternal Debate)

```json
{
  "editor.tabSize": 2, // Default: 2 spaces
  "editor.insertSpaces": true, // Spaces, not tabs
  "editor.detectIndentation": true, // Auto-detect from file

  // Override per language
  "[python]": {
    "editor.tabSize": 4 // PEP 8 requires 4 spaces
  },
  "[go]": {
    "editor.insertSpaces": false // Go uses tabs
  },
  "[java]": {
    "editor.tabSize": 4 // Java convention
  }
}
```

**Pro tip**: `detectIndentation` is smart—it reads existing files and matches their style. But in new files, `tabSize`
is used.

### Visual Guides

```json
{
  // Rulers (vertical lines showing line length limits)
  "editor.rulers": [80, 100, 120], // Multiple rulers

  // Bracket colorization (built-in since VS Code 1.60)
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active", // or "true" for always

  // Indentation guides
  "editor.guides.highlightActiveIndentation": true,

  // Whitespace rendering
  "editor.renderWhitespace": "boundary", // "none"|"boundary"|"selection"|"all"

  // Line numbers
  "editor.lineNumbers": "on", // "on"|"off"|"relative"

  // Minimap
  "editor.minimap.enabled": true,
  "editor.minimap.showSlider": "always"
}
```

### IntelliSense (Code Completion)

```json
{
  "editor.suggestSelection": "first", // Select first suggestion
  "editor.inlineSuggest.enabled": true, // Inline suggestions (Copilot)

  "editor.quickSuggestions": {
    "other": true, // Variables, functions
    "comments": false, // Inside comments
    "strings": true // Inside strings
  },

  "editor.snippetSuggestions": "top", // Snippets at top of list

  // Accept suggestions on Enter
  "editor.acceptSuggestionOnEnter": "on", // "on"|"off"|"smart"

  // Trigger suggest on any character (not just Ctrl+Space)
  "editor.quickSuggestionsDelay": 10 // Delay in ms
}
```

### Word Wrap

```json
{
  "editor.wordWrap": "off", // "off"|"on"|"wordWrapColumn"|"bounded"

  // If using "wordWrapColumn"
  "editor.wordWrapColumn": 120,

  // Override for specific languages
  "[markdown]": {
    "editor.wordWrap": "on" // Markdown should wrap
  }
}
```

---

## 4. Language-Specific Configurations

This is where the **real power** lies. After configuring countless projects, The key lesson is: **always use language
overrides**.

### The Pattern

```json
{
  "[languageId]": {
    "editor.settingName": "value",
    "another.setting": "value"
  }
}
```

### Language IDs Reference

| Language   | ID                                   | Common Override      |
| ---------- | ------------------------------------ | -------------------- |
| Python     | `python`                             | Tab size: 4          |
| JavaScript | `javascript`                         | Formatter: Prettier  |
| TypeScript | `typescript`                         | Formatter: Prettier  |
| JSX/TSX    | `javascriptreact`, `typescriptreact` | Formatter: Prettier  |
| Go         | `go`                                 | Insert spaces: false |
| Rust       | `rust`                               | Tab size: 4          |
| Java       | `java`                               | Tab size: 4          |
| Kotlin     | `kotlin`                             | Tab size: 4          |
| C/C++      | `c`, `cpp`                           | Tab size: 4          |
| HTML       | `html`                               | Tab size: 2          |
| CSS/SCSS   | `css`, `scss`                        | Tab size: 2          |
| JSON       | `json`, `jsonc`                      | Tab size: 2          |
| YAML       | `yaml`                               | Tab size: 2          |
| Markdown   | `markdown`                           | Word wrap: on        |
| Dockerfile | `dockerfile`                         | Tab size: 2          |
| Shell      | `shellscript`                        | Tab size: 2          |

### Python Example (The Complete Setup)

```json
{
  "[python]": {
    // Formatter
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.tabSize": 4, // PEP 8

    // Code actions on save
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit" // isort integration
    }
  },

  // Python extension settings
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.analysis.typeCheckingMode": "basic", // or "strict"
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true, // Fast linter
  "python.testing.pytestEnabled": true
}
```

### JavaScript/TypeScript (The Modern Stack)

```json
{
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[javascriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // TypeScript specific
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.inlayHints.parameterNames.enabled": "all",
  "typescript.tsdk": "node_modules/typescript/lib",

  // ESLint
  "eslint.enable": true,
  "eslint.validate": ["javascript", "typescript", "javascriptreact", "typescriptreact"]
}
```

### Rust (The Systems Language)

```json
{
  "[rust]": {
    "editor.defaultFormatter": "rust-lang.rust-analyzer",
    "editor.formatOnSave": true,
    "editor.tabSize": 4
  },

  // Rust analyzer settings
  "rust-analyzer.checkOnSave.command": "clippy",
  "rust-analyzer.cargo.features": "all",
  "rust-analyzer.inlayHints.enable": true
}
```

---

## 5. File System & Search

### Files Configuration

```json
{
  // Encoding
  "files.encoding": "utf8",

  // Line endings
  "files.eol": "\n", // LF (Unix) - always use this

  // End of file
  "files.insertFinalNewline": true, // Add newline at end
  "files.trimFinalNewlines": true, // Remove extra newlines
  "files.trimTrailingWhitespace": true, // Remove trailing spaces

  // Auto save
  "files.autoSave": "onFocusChange", // "off"|"afterDelay"|"onFocusChange"|"onWindowChange"
  "files.autoSaveDelay": 1000, // ms (if afterDelay)

  // File associations
  "files.associations": {
    "*.proto": "proto3",
    "*.bzl": "starlark",
    "*.bazel": "starlark",
    "BUILD": "starlark",
    "WORKSPACE": "starlark",
    "Dockerfile.*": "dockerfile",
    ".env.*": "dotenv"
  },

  // Files to exclude from file explorer
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true,
    "**/__pycache__": true,
    "bazel-*": true // Bazel symlinks
  },

  // Files to exclude from file watcher (performance!)
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/node_modules/**": true,
    "**/dist/**": true,
    "**/.venv/**": true,
    "**/target/**": true // Rust build dir
  }
}
```

### Search Configuration

```json
{
  // Search exclusions
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true,
    "**/target": true,
    "**/.git": true,
    "**/*.min.js": true,
    "bazel-*": true,
    "**/__pycache__": true,
    "**/coverage": true
  },

  // Search behavior
  "search.useIgnoreFiles": true, // Respect .gitignore
  "search.followSymlinks": false, // Don't follow symlinks
  "search.smartCase": true, // Case-sensitive if uppercase present

  // Search in results
  "search.searchEditor.defaultNumberOfContextLines": 1
}
```

#### Why exclude build directories?

Performance. Experience shows: **never search generated files**. It's slow, and results are useless.

---

## 6. Extensions Integration

### Prettier (The Formatter King)

```json
{
  "prettier.requireConfig": true, // Only format if .prettierrc exists
  "prettier.useEditorConfig": true, // Respect .editorconfig
  "prettier.enable": true,

  // Specific settings (or use .prettierrc)
  "prettier.semi": true,
  "prettier.singleQuote": true,
  "prettier.trailingComma": "es5",
  "prettier.printWidth": 100,
  "prettier.tabWidth": 2
}
```

### ESLint (JavaScript Linter)

```json
{
  "eslint.enable": true,
  "eslint.validate": ["javascript", "javascriptreact", "typescript", "typescriptreact", "vue"],
  "eslint.workingDirectories": [{ "pattern": "frontend/*" }, { "pattern": "backend/node" }],
  "eslint.codeActionsOnSave.mode": "all"
}
```

### Python Extensions

```json
{
  // Pylance (Language server)
  "python.analysis.autoImportCompletions": true,
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.inlayHints.functionReturnTypes": true,

  // Black formatter
  "black-formatter.args": ["--line-length", "100"],

  // Ruff linter
  "ruff.args": ["--line-length=100"]
}
```

### GitLens (Git Supercharged)

```json
{
  "gitlens.currentLine.enabled": false, // Inline blame (can be noisy)
  "gitlens.codeLens.enabled": true, // Code lens above functions
  "gitlens.blame.compact": false,
  "gitlens.blame.format": "${author|10} ${date}"
}
```

---

## 7. Performance Optimization

With extensive experience, The key lesson is: **performance matters**. Here's how to make VS Code blazing fast:

### Disable Unused Features

```json
{
  // If you don't use minimap
  "editor.minimap.enabled": false,

  // If you don't use breadcrumbs
  "breadcrumbs.enabled": false,

  // Reduce file watcher overhead
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/node_modules/**": true,
    "**/.venv/**": true,
    "**/target/**": true,
    "**/dist/**": true,
    "**/__pycache__": true
  }
}
```

### Limit Extension Overhead

```json
{
  // Limit editor history
  "workbench.editor.limit.enabled": true,
  "workbench.editor.limit.value": 10,

  // Disable auto-updates if on slow connection
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": true
}
```

### Optimize Search

```json
{
  // Exclude everything you don't need to search
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true,
    "**/.git": true
  },

  // Don't follow symlinks (can cause infinite loops)
  "search.followSymlinks": false
}
```

---

## 8. Advanced Patterns

### Multi-Language Projects

```json
{
  // Default for most files
  "editor.tabSize": 2,
  "editor.insertSpaces": true,

  // Python exceptions
  "[python]": {
    "editor.tabSize": 4,
    "editor.defaultFormatter": "ms-python.black-formatter"
  },

  // Go exceptions
  "[go]": {
    "editor.insertSpaces": false, // Go uses tabs
    "editor.defaultFormatter": "golang.go"
  },

  // Java/Kotlin exceptions
  "[java]": {
    "editor.tabSize": 4
  },
  "[kotlin]": {
    "editor.tabSize": 4
  }
}
```

### Workspace-Specific Python Environments

```json
{
  // Use project's virtual environment
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",

  // Poetry projects
  "python.poetryPath": "poetry",

  // Conda environments
  "python.condaPath": "/opt/anaconda3/bin/conda"
}
```

### Monorepo Configuration

```json
{
  // ESLint working directories
  "eslint.workingDirectories": [{ "pattern": "frontend/*" }, { "pattern": "backend/*" }],

  // Python paths
  "python.analysis.extraPaths": ["${workspaceFolder}/backend", "${workspaceFolder}/shared"],

  // TypeScript SDK per project
  "typescript.tsdk": "frontend/node_modules/typescript/lib"
}
```

---

## 9. Common Pitfalls

### ❌ Hardcoding Absolute Paths

**Bad**:

```json
{
  "python.defaultInterpreterPath": "/home/john/projects/myproject/.venv/bin/python"
}
```

**Good**:

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
```

### ❌ Forgetting Language Overrides

**Bad**:

```json
{
  "editor.defaultFormatter": "esbenp.prettier-vscode"
  // This affects ALL languages, including Python!
}
```

**Good**:

```json
{
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}
```

### ❌ Mixing User and Workspace Settings

**User settings** (personal):

- Theme, font size, keybindings
- Machine-specific paths

**Workspace settings** (team):

- Code style, formatting rules
- Linting configuration
- Project-specific paths

### ❌ Over-excluding Files

Don't exclude too much—you might need to search those files!

**Bad**:

```json
{
  "files.exclude": {
    "**/*.test.js": true // Now you can't see tests!
  }
}
```

---

## 🎓 Expert Insights

### The 80/20 Rule

80% of your productivity comes from these 20% of settings:

1. `editor.formatOnSave: true`
2. `editor.codeActionsOnSave`
3. Language-specific `defaultFormatter`
4. `files.autoSave`
5. `search.exclude` for performance

### The "Why" Behind Common Settings

```json
{
  // Why? Consistent formatting across team
  "editor.formatOnSave": true,

  // Why? Git diffs are cleaner with LF
  "files.eol": "\n",

  // Why? Git best practice
  "files.insertFinalNewline": true,

  // Why? Python PEP 8 standard
  "[python]": {
    "editor.tabSize": 4
  },

  // Why? Performance—don't search generated code
  "search.exclude": {
    "**/dist": true
  }
}
```

### Variable Substitution

Use VS Code variables for flexibility:

```json
{
  "${workspaceFolder}": "/path/to/workspace",
  "${workspaceFolderBasename}": "workspace-name",
  "${file}": "current-file-full-path",
  "${fileBasename}": "current-file-name.ext",
  "${fileBasenameNoExtension}": "current-file-name",
  "${fileDirname}": "current-file-directory",
  "${env:HOME}": "environment-variable",
  "${command:extension.commandId}": "result-of-vs-code-command"
}
```

---

## 🚀 The Ultimate Template

Here's my expert-refined template:

```json
{
  // ============================================================================
  // EDITOR CORE
  // ============================================================================
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit",
    "source.organizeImports": "explicit"
  },
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.rulers": [80, 120],
  "editor.bracketPairColorization.enabled": true,

  // ============================================================================
  // FILES
  // ============================================================================
  "files.encoding": "utf8",
  "files.eol": "\n",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "files.autoSave": "onFocusChange",

  // ============================================================================
  // PERFORMANCE
  // ============================================================================
  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/__pycache__": true
  },
  "search.exclude": {
    "**/dist": true,
    "**/build": true
  },

  // ============================================================================
  // LANGUAGE OVERRIDES
  // ============================================================================
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.tabSize": 4
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

---

**This is proven expert knowledge. May your configurations be optimal.** 🚀
