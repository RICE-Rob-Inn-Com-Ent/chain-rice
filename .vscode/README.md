# 🎯 VS Code Workspace Configuration - Expert Guide

> **Your IDE configuration mastery starts here. This is the control center of your development experience.**

## 📋 Overview

This directory contains **VS Code workspace configuration files** that define how your IDE behaves, what tools are
available, and how you debug and build your projects. These files are the DNA of your development environment.

### The Four Pillars of IDE Configuration

```text
.vscode/
├── settings.json      # 🎛️ IDE BEHAVIOR - How VS Code acts and reacts
├── extensions.json    # 🔌 TOOLING ECOSYSTEM - What powers your IDE
├── launch.json        # 🐛 DEBUG CONFIGURATIONS - How you debug code
└── tasks.json         # 🔨 BUILD AUTOMATION - How you run common commands
```

---

## 🎛️ `settings.json` - The Behavior Controller

**What it does**: Defines **every aspect** of how VS Code behaves in this workspace.

- **Editor behavior**: Formatting, tabs, line endings, rulers
- **Language-specific settings**: Python, JavaScript, Go, Rust configs
- **File associations**: What syntax highlighting to use
- **Auto-save, auto-format**: When and how code is saved/formatted
- **Search/exclude patterns**: What files to ignore
- **IntelliSense settings**: Code completion behavior

**When to edit**:

- Adding a new language to the project
- Changing code formatting standards
- Adjusting IntelliSense behavior
- Excluding more files from search

**📚 Learn more**: [`../.doc/helpers/vscode/SETTINGS.md`](../.doc/helpers/vscode/SETTINGS.md)

---

## 🔌 `extensions.json` - The Power-Up Manager

**What it does**: Declares **recommended extensions** that team members should install.

- **Recommendations**: Extensions VS Code will prompt users to install
- **Unwanted recommendations**: Extensions to avoid (conflicts/deprecated)
- **Workspace consistency**: Ensures everyone has the same tools

**Key sections**:

- ✅ `recommendations`: List of extension IDs to install
- ❌ `unwantedRecommendations`: Extensions to avoid

**When to edit**:

- Adding support for a new language/framework
- Removing deprecated extensions
- Standardizing team tooling

**📚 Learn more**: [`../.doc/helpers/vscode/EXTENSIONS.md`](../.doc/helpers/vscode/EXTENSIONS.md)

---

## 🐛 `launch.json` - The Debug Master

**What it does**: Defines **debug configurations** for running and debugging code.

- **Language-specific debuggers**: Python, Go, Rust, Node.js, etc.
- **Launch vs Attach**: Start a program vs attach to running process
- **Environment variables**: Set env vars during debugging
- **Compound configurations**: Debug multiple services simultaneously

**Core concepts**:

- `"type"`: Debugger type (debugpy, go, node, lldb, chrome)
- `"request"`: "launch" (start new) or "attach" (connect to existing)
- `"program"`: What file/executable to run
- `"preLaunchTask"`: Task to run before debugging (e.g., build)

**When to edit**:

- Adding new debug configurations for new services
- Changing environment variables for debugging
- Setting up multi-service debugging (compounds)

**📚 Learn more**: [`../.doc/helpers/vscode/LAUNCH.md`](../.doc/helpers/vscode/LAUNCH.md)

---

## 🔨 `tasks.json` - The Automation Engine

**What it does**: Defines **automated tasks** you can run from VS Code.

- **Build tasks**: Compile, build, bundle code
- **Test tasks**: Run test suites
- **Lint tasks**: Check code quality
- **Custom scripts**: Any shell command you run frequently

**Task types**:

- `"shell"`: Run shell commands
- `"process"`: Run executables directly
- `"npm"`, `"gulp"`, etc.: Run task runners

**Key concepts**:

- `"label"`: Task name shown in UI
- `"command"`: What to execute
- `"group"`: "build" or "test" (affects shortcuts)
- `"problemMatcher"`: Parse output for errors/warnings
- `"isBackground"`: Keep task running (for dev servers)

**When to edit**:

- Adding new build/test commands
- Creating shortcuts for frequent operations
- Setting up watch tasks for live reload

**📚 Learn more**: [`../.doc/helpers/vscode/TASKS.md`](../.doc/helpers/vscode/TASKS.md)

---

## 🚀 Quick Start

### For New Team Members

1. **Install VS Code**: Download from [code.visualstudio.com](https://code.visualstudio.com)

2. **Open this workspace**:

   ```bash
   code /home/mrDinkelman/rice-mono
   ```

3. **Install recommended extensions**:

   - VS Code will show a notification
   - Click "Install All" or press `Cmd/Ctrl+Shift+P` → "Extensions: Show Recommended Extensions"

4. **Verify setup**:
   - Open any file → formatting should work automatically
   - Press `F5` → debug configurations should appear
   - Press `Cmd/Ctrl+Shift+B` → build tasks should be available

### Common Workflows

#### 🐛 Debugging

```text
1. Set breakpoints (click left of line numbers)
2. Press F5 or click Run → Start Debugging
3. Select configuration (e.g., "🤖 Python: Bot Core")
4. Debug controls appear in top toolbar
```

#### 🔨 Running Tasks

```text
1. Press Cmd/Ctrl+Shift+B → Quick access to build tasks
2. Or: Cmd/Ctrl+Shift+P → "Tasks: Run Task" → Select task
3. Or: Terminal menu → Run Task
```

#### ⚙️ Changing Settings

```text
1. Cmd/Ctrl+Shift+P → "Preferences: Open Workspace Settings (JSON)"
2. Edit settings.json
3. Save → Changes apply immediately
```

---

## 📐 File Structure Deep Dive

### Why JSON?

VS Code uses **JSON with comments** (JSONC) for configuration:

- **Machine-readable**: Easy for tools to parse
- **Human-readable**: You can read and edit it
- **Validation**: VS Code provides IntelliSense and error checking
- **Version control friendly**: Git diffs show changes clearly

### Schema Validation

All these files use **JSON Schemas** for validation:

- Hover over any property → see documentation
- Start typing → get autocomplete suggestions
- Invalid values → get red squiggles with error messages

### Comment Styles

```json
// Single-line comment - Use for brief notes

/*
   Multi-line comment
   Use for longer explanations
*/

// ============================================================================
// Section headers - Use for organization
// ============================================================================
```

---

## 🎓 Expert Tips for IDE Configuration

### 1. **Workspace vs User Settings**

```text
User Settings (.vscode/settings.json in your home):
  ✓ Personal preferences (theme, font size, keybindings)
  ✓ Machine-specific (paths to tools)
  ✗ Team standards (formatting, linting)

Workspace Settings (.vscode/settings.json in project):
  ✓ Team standards (code style, formatting)
  ✓ Project-specific (file associations)
  ✓ Version controlled (everyone gets same settings)
  ✗ Personal preferences (your theme choices)
```

### 2. **Layer Your Configurations**

VS Code settings follow a **hierarchy** (most specific wins):

```text
1. User Settings           (global, lowest priority)
2. Workspace Settings      (this project, medium priority)
3. Folder Settings         (multi-root, high priority)
4. Language-specific       (highest priority within scope)
```

### 3. **Use Language-Specific Overrides**

Instead of:

```json
{
  "editor.tabSize": 2
  // Python needs 4 spaces though...
}
```

Do this:

```json
{
  "editor.tabSize": 2,
  "[python]": {
    "editor.tabSize": 4 // Only for Python files
  }
}
```

### 4. **Leverage Extension Settings**

Extensions add their own settings:

```json
{
  // ESLint settings
  "eslint.validate": ["javascript", "typescript"],
  "eslint.workingDirectories": ["frontend"],

  // Python settings
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": false,
  "python.linting.ruffEnabled": true
}
```

### 5. **Master Problem Matchers**

Problem matchers parse command output to show errors in the Problems panel:

```json
{
  "problemMatcher": {
    "owner": "typescript",
    "fileLocation": "relative",
    "pattern": {
      "regexp": "^(.*)\\((\\d+),(\\d+)\\):\\s+(error|warning)\\s+(\\w+):\\s+(.*)$",
      "file": 1,
      "line": 2,
      "column": 3,
      "severity": 4,
      "code": 5,
      "message": 6
    }
  }
}
```

Common built-in matchers:

- `$tsc` - TypeScript compiler
- `$eslint-compact` - ESLint
- `$go` - Go compiler
- `$gcc` - C/C++ compiler

### 6. **Compound Debug Configurations**

Debug multiple services at once:

```json
{
  "compounds": [
    {
      "name": "Full Stack",
      "configurations": ["Backend API", "Frontend React", "Database Migrations"],
      "stopAll": true // Stop all when one stops
    }
  ]
}
```

### 7. **Task Dependencies**

Chain tasks together:

```json
{
  "label": "Build and Test",
  "dependsOn": ["Build", "Test"],
  "dependsOrder": "sequence" // or "parallel"
}
```

### 8. **Variable Substitution**

Use VS Code variables in configs:

```json
{
  "${workspaceFolder}": "/path/to/workspace",
  "${file}": "current/file/path.js",
  "${fileBasename}": "path.js",
  "${fileBasenameNoExtension}": "path",
  "${fileDirname}": "current/file",
  "${env:HOME}": "environment variable",
  "${command:git.branch}": "Run VS Code command"
}
```

### 9. **Settings Sync**

Enable Settings Sync to share:

- ✅ User settings
- ✅ Keybindings
- ✅ Extensions
- ❌ Workspace settings (use git instead)

### 10. **Performance Optimization**

```json
{
  // Exclude from file watcher (saves CPU)
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/target/**": true,
    "**/.git/**": true
  },

  // Limit search scope
  "search.exclude": {
    "**/dist/**": true,
    "**/build/**": true
  },

  // Disable unnecessary features
  "editor.minimap.enabled": false, // If you don't use it
  "breadcrumbs.enabled": false // If you don't use it
}
```

---

## 🔍 Troubleshooting

### Settings Not Working?

1. **Check setting scope**: User vs Workspace vs Language-specific
2. **Check for typos**: VS Code will show warnings
3. **Restart VS Code**: Some settings require restart
4. **Check extension**: Setting might require extension to be installed

### Extension Not Activating?

1. **Check extension ID**: Must match exactly (case-sensitive)
2. **Check version**: Some extensions require specific VS Code version
3. **Check conflicts**: Some extensions conflict with each other
4. **Check logs**: Help → Toggle Developer Tools → Console

### Debug Config Not Working?

1. **Check paths**: All paths must be correct (use variables!)
2. **Check debugger type**: Must match installed extension
3. **Check program path**: File must exist
4. **Check preLaunchTask**: Task must be defined in tasks.json

### Task Not Running?

1. **Check command**: Must be valid shell command
2. **Check cwd**: Current working directory must exist
3. **Check problem matcher**: If output isn't parsed correctly
4. **Check shell**: Sometimes need explicit shell: `/bin/bash`

---

## 📚 Deep Dive Guides

### For Complete Mastery, Read These

| File              | Guide                                                                          | What You'll Learn                                                          |
| ----------------- | ------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| `settings.json`   | [`../.doc/helpers/vscode/SETTINGS.md`](../.doc/helpers/vscode/SETTINGS.md)     | Every setting explained, advanced patterns, performance tuning             |
| `extensions.json` | [`../.doc/helpers/vscode/EXTENSIONS.md`](../.doc/helpers/vscode/EXTENSIONS.md) | Extension ecosystem, conflict resolution, custom extension recommendations |
| `launch.json`     | [`../.doc/helpers/vscode/LAUNCH.md`](../.doc/helpers/vscode/LAUNCH.md)         | Debugger internals, multi-target debugging, remote debugging               |
| `tasks.json`      | [`../.doc/helpers/vscode/TASKS.md`](../.doc/helpers/vscode/TASKS.md)           | Task automation mastery, custom problem matchers, complex workflows        |

---

## 🎯 Best Practices

### ✅ Do

- **Version control these files**: Everyone gets same setup
- **Use comments**: Explain non-obvious settings
- **Test changes**: Verify settings work for everyone
- **Keep organized**: Use section headers
- **Use relative paths**: `${workspaceFolder}/...`
- **Document custom settings**: Add comments explaining why

### ❌ Don't

- **Hardcode absolute paths**: Won't work on other machines
- **Mix personal preferences**: Use user settings for those
- **Commit secrets**: Use environment variables instead
- **Over-configure**: Only set what differs from defaults
- **Ignore schemas**: They prevent errors

---

## 🌟 Summary

These four files are your **IDE control panel**:

1. **`settings.json`** → How VS Code behaves
2. **`extensions.json`** → What tools are available
3. **`launch.json`** → How you debug
4. **`tasks.json`** → How you build/test/automate

Master these files, and you master your development environment.

**Next steps**:

1. Read the detailed guides in [`../.doc/helpers/vscode/`](../.doc/helpers/vscode/)
2. Experiment with settings
3. Create your own debug configurations
4. Automate your workflows with tasks

---

## 💡 Pro Tip

Press `Cmd/Ctrl+Shift+P` and type "settings" or "debug" or "task" to quickly access these files.

---

Happy configuring! 🚀
