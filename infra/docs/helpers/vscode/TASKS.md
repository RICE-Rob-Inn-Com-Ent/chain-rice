# 🔨 `tasks.json` - The Task Automation Master Guide

> **Expert guide to VS Code task automation**

## 🎯 The Purpose of Tasks

With years of build automation experience, The key principle is: **`tasks.json` is your command center for repetitive
actions**. It's not just about running commands—it's about turning chaos into order, complexity into simplicity, and
manual work into automation.

---

## 📖 Table of Contents

1. [The Task Lifecycle](#1-the-task-lifecycle)
2. [JSON Structure](#2-json-structure)
3. [Task Types](#3-task-types)
4. [Problem Matchers](#4-problem-matchers)
5. [Task Dependencies](#5-task-dependencies)
6. [Input Variables](#6-input-variables)
7. [Advanced Patterns](#7-advanced-patterns)
8. [Integration with Debug](#8-integration-with-debug)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. The Task Lifecycle

Understanding how tasks execute:

```text
1. User triggers task (Cmd+Shift+B or menu)
   ↓
2. VS Code reads tasks.json
   ↓
3. Presents task selector (if multiple)
   ↓
4. Resolves dependencies (if any)
   ↓
5. Executes command in specified shell
   ↓
6. Parses output with problem matcher
   ↓
7. Shows errors/warnings in Problems panel
   ↓
8. Task completes (or runs indefinitely)
```

### Where Tasks Run

Tasks execute in:

- **Integrated Terminal**: Visible, interactive
- **Output Panel**: Hidden, non-interactive
- **Background**: Silent, for watching

---

## 2. JSON Structure

### The Core Schema

```json
{
  "version": "2.0.0", // Schema version (don't change)

  "tasks": [
    // Array of task definitions
    {
      "label": "Task Name", // Required: Human-readable name
      "type": "shell", // Required: "shell" or "process"
      "command": "echo Hello", // Required: What to run
      "problemMatcher": [], // Optional: Parse output
      "group": "build" // Optional: "build" or "test"
    }
  ]
}
```

### Essential Properties

```json
{
  "label": "Build Project", // Required: Unique identifier
  "type": "shell", // Required: How to run
  "command": "npm run build", // Required: What to run

  // Common optional properties
  "args": ["--production"], // Command arguments
  "options": {
    "cwd": "${workspaceFolder}/app", // Working directory
    "env": {
      // Environment variables
      "NODE_ENV": "production"
    },
    "shell": {
      "executable": "/bin/bash", // Specific shell
      "args": ["-c"]
    }
  },
  "problemMatcher": "$tsc", // Error parsing
  "group": {
    // Task grouping
    "kind": "build",
    "isDefault": true
  },
  "presentation": {
    // How to show output
    "reveal": "always",
    "panel": "shared",
    "focus": false
  },
  "dependsOn": ["Clean"], // Tasks to run first
  "dependsOrder": "sequence", // "sequence" or "parallel"
  "runOptions": {
    "runOn": "folderOpen" // When to auto-run
  }
}
```

---

## 3. Task Types

### Type: `shell`

Run commands in a shell (most common):

```json
{
  "label": "Build with npm",
  "type": "shell",
  "command": "npm",
  "args": ["run", "build"],
  "options": {
    "cwd": "${workspaceFolder}/frontend"
  }
}
```

**When command is a string**:

```json
{
  "type": "shell",
  "command": "npm run build && npm run test" // Shell interprets &&, |, etc.
}
```

**When command is array**:

```json
{
  "type": "shell",
  "command": "npm",
  "args": ["run", "build"] // Safer: no shell injection
}
```

### Type: `process`

Run executable directly (no shell):

```json
{
  "label": "Run Binary",
  "type": "process",
  "command": "/usr/bin/python3",
  "args": ["app.py", "--port", "8080"]
}
```

**Difference from shell**:

- ✅ Faster (no shell overhead)
- ✅ Safer (no injection attacks)
- ❌ No shell features (pipes, redirects, globbing)
- ❌ No command chaining

### Type: `npm` (Automatic)

VS Code auto-detects npm scripts:

```json
// package.json
{
  "scripts": {
    "build": "webpack",
    "test": "jest"
  }
}

// VS Code auto-creates tasks!
// No tasks.json needed for basic npm scripts
```

**Override auto-detected task**:

```json
{
  "label": "npm: build", // Must match: "npm: scriptname"
  "type": "npm",
  "script": "build",
  "problemMatcher": "$tsc-watch" // Add custom problem matcher
}
```

---

## 4. Problem Matchers

This is **the most powerful feature** you'll learn. With extensive experience, I know: **problem matchers turn output into
actionable insights**.

### What They Do

Parse command output and extract:

- **File paths**: Which file has the error
- **Line numbers**: Where in the file
- **Column numbers**: Exact position
- **Severity**: error, warning, info
- **Message**: What went wrong

Then show in **Problems panel** (Cmd+Shift+M).

### Built-in Problem Matchers

VS Code includes these:

| Matcher           | Tool             | Pattern                                   |
| ----------------- | ---------------- | ----------------------------------------- |
| `$tsc`            | TypeScript       | `file.ts(1,5): error TS1234: message`     |
| `$tsc-watch`      | TypeScript watch | Same, but with watch mode                 |
| `$eslint-compact` | ESLint           | `file.js: line 1, col 5, Error - message` |
| `$eslint-stylish` | ESLint           | Stylish format                            |
| `$jshint`         | JSHint           | JSHint output                             |
| `$go`             | Go compiler      | Go error format                           |
| `$gcc`            | GCC              | C/C++ compiler                            |
| `$msCompile`      | Visual Studio    | MSVC format                               |
| `$lessc`          | LESS compiler    | CSS errors                                |

### Using Problem Matchers

```json
{
  "label": "TypeScript Build",
  "type": "shell",
  "command": "tsc",
  "problemMatcher": "$tsc"  // Single matcher
}

{
  "label": "Multi-Tool Build",
  "type": "shell",
  "command": "build.sh",
  "problemMatcher": ["$tsc", "$eslint-compact"]  // Multiple matchers
}

{
  "label": "No Problems",
  "type": "shell",
  "command": "echo hello",
  "problemMatcher": []  // No parsing
}
```

### Custom Problem Matchers

Create your own for custom tools:

```json
{
  "label": "Custom Build",
  "type": "shell",
  "command": "mybuild",
  "problemMatcher": {
    "owner": "mybuild", // Unique identifier
    "fileLocation": "relative", // or "absolute"
    "pattern": {
      // Regex with capture groups
      "regexp": "^(.*):(\\d+):(\\d+):\\s+(error|warning):\\s+(.*)$",
      "file": 1, // Capture group 1 = file path
      "line": 2, // Group 2 = line number
      "column": 3, // Group 3 = column number
      "severity": 4, // Group 4 = "error" or "warning"
      "message": 5 // Group 5 = error message
    }
  }
}
```

**Example output**:

```text
src/app.py:42:10: error: undefined variable 'foo'
```

**Regex breakdown**:

```text
^                       Start of line
(.*)                    Group 1: File (any characters)
:                       Literal colon
(\\d+)                  Group 2: Line (digits)
:                       Literal colon
(\\d+)                  Group 3: Column (digits)
:\\s+                   Colon + whitespace
(error|warning)         Group 4: Severity
:\\s+                   Colon + whitespace
(.*)$                   Group 5: Message (rest of line)
```

### Multi-line Problem Matchers

For errors spanning multiple lines:

```json
{
  "problemMatcher": {
    "owner": "mycompiler",
    "pattern": [
      {
        "regexp": "^Error in (.*)$",
        "file": 1
      },
      {
        "regexp": "^  Line (\\d+):(\\d+)$",
        "line": 1,
        "column": 2
      },
      {
        "regexp": "^  (.*)$",
        "message": 1,
        "loop": true // Keep matching until next error
      }
    ]
  }
}
```

### Background Problem Matchers

For watch tasks that run indefinitely:

```json
{
  "label": "TypeScript Watch",
  "type": "shell",
  "command": "tsc --watch",
  "isBackground": true,  // Task runs forever
  "problemMatcher": {
    "$tsc-watch",  // Built-in watch matcher
    "background": {
      "activeOnStart": true,
      "beginsPattern": "^\\s*\\d{1,2}:\\d{2}:\\d{2} (AM|PM)? - File change detected\\.",
      "endsPattern": "^\\s*\\d{1,2}:\\d{2}:\\d{2} (AM|PM)? - Compilation complete\\."
    }
  }
}
```

---

## 5. Task Dependencies

Chain tasks together:

### Sequential Execution

```json
{
  "label": "Build All",
  "dependsOn": ["Clean", "Compile", "Test"],
  "dependsOrder": "sequence" // Run one after another
}
```

### Parallel Execution

```json
{
  "label": "Build All",
  "dependsOn": ["Build Frontend", "Build Backend"],
  "dependsOrder": "parallel" // Run simultaneously
}
```

### Complete Example

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Clean",
      "type": "shell",
      "command": "rm -rf dist"
    },
    {
      "label": "Build TypeScript",
      "type": "shell",
      "command": "tsc",
      "dependsOn": ["Clean"],
      "problemMatcher": "$tsc"
    },
    {
      "label": "Build Webpack",
      "type": "shell",
      "command": "webpack",
      "dependsOn": ["Build TypeScript"]
    },
    {
      "label": "Build All",
      "dependsOn": ["Build Webpack"],
      "problemMatcher": []
    }
  ]
}
```

**Execution order**:

```text
Clean → Build TypeScript → Build Webpack → Build All
```

---

## 6. Input Variables

Prompt user for input:

### Define Inputs

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Deploy",
      "type": "shell",
      "command": "deploy.sh ${input:environment}",
      "problemMatcher": []
    }
  ],
  "inputs": [
    {
      "id": "environment",
      "type": "pickString",
      "description": "Select environment",
      "options": ["dev", "staging", "production"],
      "default": "dev"
    }
  ]
}
```

### Input Types

#### `pickString` - Pick from list

```json
{
  "id": "buildType",
  "type": "pickString",
  "description": "Build type",
  "options": ["debug", "release"],
  "default": "debug"
}
```

#### `promptString` - Free text input

```json
{
  "id": "commitMessage",
  "type": "promptString",
  "description": "Commit message",
  "default": "Update code"
}
```

#### `command` - Run VS Code command

```json
{
  "id": "currentFile",
  "type": "command",
  "command": "extension.commandvariable.file.relativeDirDots"
}
```

---

## 7. Advanced Patterns

### Pattern 1: Multi-Stage Build

```json
{
  "tasks": [
    {
      "label": "1. Clean",
      "type": "shell",
      "command": "rm -rf dist"
    },
    {
      "label": "2. Lint",
      "type": "shell",
      "command": "eslint src/**/*.ts",
      "dependsOn": ["1. Clean"],
      "problemMatcher": "$eslint-stylish"
    },
    {
      "label": "3. Compile",
      "type": "shell",
      "command": "tsc",
      "dependsOn": ["2. Lint"],
      "problemMatcher": "$tsc"
    },
    {
      "label": "4. Test",
      "type": "shell",
      "command": "jest",
      "dependsOn": ["3. Compile"]
    },
    {
      "label": "🚀 Build All",
      "dependsOn": ["4. Test"],
      "dependsOrder": "sequence",
      "group": {
        "kind": "build",
        "isDefault": true
      }
    }
  ]
}
```

### Pattern 2: Watch Tasks

```json
{
  "label": "Watch TypeScript",
  "type": "shell",
  "command": "tsc --watch",
  "isBackground": true,
  "problemMatcher": "$tsc-watch",
  "presentation": {
    "reveal": "never", // Don't show terminal
    "panel": "dedicated" // Use dedicated panel
  }
}
```

### Pattern 3: Cross-Platform Commands

```json
{
  "label": "Build (Cross-platform)",
  "type": "shell",
  "windows": {
    "command": "build.bat"
  },
  "linux": {
    "command": "./build.sh"
  },
  "osx": {
    "command": "./build.sh"
  }
}
```

### Pattern 4: Environment-Specific Tasks

```json
{
  "label": "Deploy to ${input:environment}",
  "type": "shell",
  "command": "deploy",
  "args": ["--env", "${input:environment}"],
  "options": {
    "env": {
      "ENV": "${input:environment}"
    }
  }
}
```

### Pattern 5: Docker Integration

```json
{
  "label": "Docker: Build",
  "type": "shell",
  "command": "docker",
  "args": ["build", "-t", "myapp:latest", "."]
},
{
  "label": "Docker: Run",
  "type": "shell",
  "command": "docker",
  "args": ["run", "-p", "8080:8080", "myapp:latest"],
  "isBackground": true,
  "dependsOn": ["Docker: Build"]
}
```

---

## 8. Integration with Debug

Tasks integrate with `launch.json`:

### Pre-Launch Task

```json
// tasks.json
{
  "label": "build",
  "type": "shell",
  "command": "tsc",
  "problemMatcher": "$tsc"
}

// launch.json
{
  "name": "Debug",
  "type": "node",
  "request": "launch",
  "preLaunchTask": "build",  // Run before debugging
  "program": "${workspaceFolder}/dist/app.js"
}
```

### Post-Debug Task

```json
// launch.json
{
  "name": "Debug",
  "type": "node",
  "request": "launch",
  "program": "${workspaceFolder}/app.js",
  "postDebugTask": "cleanup"  // Run after debugging
}

// tasks.json
{
  "label": "cleanup",
  "type": "shell",
  "command": "rm -rf temp"
}
```

---

## 9. Troubleshooting

### Task Not Running

**Check**:

1. Label is unique
2. Command exists in PATH
3. Working directory is correct
4. Shell is specified correctly

```json
{
  "label": "Debug Task",
  "type": "shell",
  "command": "echo ${workspaceFolder}", // Print variables
  "presentation": {
    "reveal": "always" // Always show output
  }
}
```

### Problem Matcher Not Working

**Test your regex**:

```json
{
  "problemMatcher": {
    "pattern": {
      "regexp": "YOUR_REGEX_HERE"
      // Test against actual output!
    }
  }
}
```

**Debug steps**:

1. Copy actual error output
2. Test regex at regex101.com
3. Verify capture groups match schema
4. Check `fileLocation` setting

### Variables Not Expanding

```json
{
  // ✅ Correct
  "command": "${workspaceFolder}/build.sh",

  // ❌ Wrong - needs quotes in shell commands
  "command": "cd ${workspaceFolder} && ./build.sh"
}
```

---

## 🎓 Expert Insights

### Task Naming Conventions

```json
{
  // Good: Descriptive, grouped
  "label": "Build: TypeScript",
  "label": "Build: Webpack",
  "label": "Test: Unit",
  "label": "Test: Integration",
  "label": "Deploy: Staging",
  "label": "Deploy: Production",

  // Use emojis for quick recognition
  "label": "🔨 Build All",
  "label": "🧪 Run Tests",
  "label": "🚀 Deploy",
  "label": "🧹 Clean"
}
```

### The Build Task Hierarchy

```text
Level 1: Atomic tasks (single command)
  ├─ Clean
  ├─ Lint
  └─ Compile

Level 2: Composite tasks (multiple commands)
  ├─ Build (Clean + Compile)
  └─ Test (Build + Run Tests)

Level 3: Workflow tasks (complete processes)
  └─ Deploy (Build + Test + Upload)
```

### Performance Tips

```json
{
  // Fast: Run in parallel
  "dependsOrder": "parallel",

  // Show only on errors
  "presentation": {
    "reveal": "silent",
    "revealProblems": "onProblem"
  },

  // Reuse terminals
  "presentation": {
    "panel": "shared"
  }
}
```

---

## 🚀 The Ultimate Template

My battle-tested expert template:

```json
{
  "version": "2.0.0",
  "tasks": [
    // ========================================
    // BUILD TASKS
    // ========================================
    {
      "label": "🧹 Clean",
      "type": "shell",
      "command": "rm -rf dist",
      "problemMatcher": []
    },
    {
      "label": "🔨 Build",
      "type": "shell",
      "command": "npm run build",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "dependsOn": ["🧹 Clean"],
      "problemMatcher": ["$tsc", "$eslint-compact"]
    },
    {
      "label": "👀 Watch",
      "type": "shell",
      "command": "npm run watch",
      "isBackground": true,
      "problemMatcher": "$tsc-watch"
    },

    // ========================================
    // TEST TASKS
    // ========================================
    {
      "label": "🧪 Test",
      "type": "shell",
      "command": "npm test",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "dependsOn": ["🔨 Build"]
    },
    {
      "label": "🧪 Test: Watch",
      "type": "shell",
      "command": "npm run test:watch",
      "isBackground": true
    },

    // ========================================
    // LINT TASKS
    // ========================================
    {
      "label": "🔍 Lint",
      "type": "shell",
      "command": "npm run lint",
      "problemMatcher": "$eslint-compact"
    },
    {
      "label": "🔧 Lint: Fix",
      "type": "shell",
      "command": "npm run lint:fix"
    },

    // ========================================
    // DOCKER TASKS
    // ========================================
    {
      "label": "🐳 Docker: Build",
      "type": "shell",
      "command": "docker compose build"
    },
    {
      "label": "🐳 Docker: Up",
      "type": "shell",
      "command": "docker compose up",
      "isBackground": true
    },
    {
      "label": "🐳 Docker: Down",
      "type": "shell",
      "command": "docker compose down"
    },

    // ========================================
    // WORKFLOW TASKS
    // ========================================
    {
      "label": "🚀 Deploy",
      "dependsOn": ["🔨 Build", "🧪 Test"],
      "dependsOrder": "sequence"
    }
  ]
}
```

---

**Expert insight: Automate everything. Your future self will thank you.** 🚀
