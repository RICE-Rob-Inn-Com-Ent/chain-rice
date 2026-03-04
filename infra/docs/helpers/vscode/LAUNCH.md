# 🐛 `launch.json` - The Debugging Master Guide

> **Comprehensive guide to debugging in VS Code**

## 🎯 The Essence of Debugging

With years of debugging experience, Here's the fundamental truth: **`launch.json` is the blueprint for how you interrogate
your code**. It's not just about running programs—it's about seeing into the soul of your application, line by line,
variable by variable.

---

## 📖 Table of Contents

1. [The Debug Lifecycle](#1-the-debug-lifecycle)
2. [JSON Structure](#2-json-structure)
3. [Configuration Types](#3-configuration-types)
4. [Debugger Types](#4-debugger-types)
5. [Launch vs Attach](#5-launch-vs-attach)
6. [Environment & Variables](#6-environment--variables)
7. [Multi-Target Debugging](#7-multi-target-debugging)
8. [Advanced Debugging](#8-advanced-debugging)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. The Debug Lifecycle

Understanding the flow is crucial:

```text
1. User presses F5 or clicks "Run and Debug"
   ↓
2. VS Code reads launch.json
   ↓
3. Presents configuration selector (if multiple)
   ↓
4. Runs preLaunchTask (if specified)
   ↓
5. Starts debugger based on "type"
   ↓
6. Launches or attaches to program
   ↓
7. Hits breakpoints, shows variables
   ↓
8. User steps through code
   ↓
9. Program ends or user stops
```

### The Debug Adapter Protocol

VS Code uses **Debug Adapter Protocol (DAP)**:

```text
VS Code UI ←→ Debug Adapter ←→ Debugger ←→ Your Program
```

Each language has its own adapter:

- Python: `debugpy`
- JavaScript/TypeScript: `vscode-node-debug2`
- Go: `delve`
- Rust: `lldb` or `gdb`
- C/C++: `lldb`, `gdb`, or `cppvsdbg`

---

## 2. JSON Structure

### The Core Schema

```json
{
  "version": "0.2.0", // Schema version (don't change)

  "configurations": [
    // Array of debug configurations
    {
      "name": "Configuration Name", // Shown in dropdown
      "type": "debugger-type", // Which debugger to use
      "request": "launch", // "launch" or "attach"
      "program": "${workspaceFolder}/app.py" // What to run
      // ... more properties
    }
  ],

  "compounds": [
    // Optional: Debug multiple at once
    {
      "name": "Full Stack",
      "configurations": ["Backend", "Frontend"]
    }
  ]
}
```

### Essential Properties

Every configuration **must** have:

```json
{
  "name": "Human-readable name",     // Required
  "type": "debugger-type",           // Required
  "request": "launch" | "attach"     // Required
}
```

### Common Optional Properties

```json
{
  "program": "path/to/file", // What to execute
  "args": ["--flag", "value"], // Command-line arguments
  "cwd": "${workspaceFolder}", // Working directory
  "env": {
    // Environment variables
    "VAR": "value"
  },
  "envFile": "${workspaceFolder}/.env", // Load env from file
  "preLaunchTask": "build", // Task to run before debugging
  "postDebugTask": "cleanup", // Task to run after debugging
  "console": "integratedTerminal", // Where to show output
  "stopOnEntry": false, // Pause at first line
  "justMyCode": true // Skip library code (Python)
}
```

---

## 3. Configuration Types

### By Request Type

#### Launch Configuration

```json
{
  "name": "Launch App",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",
  "console": "integratedTerminal"
}
```

**Use when**: Starting a new process

#### Attach Configuration

```json
{
  "name": "Attach to Process",
  "type": "debugpy",
  "request": "attach",
  "connect": {
    "host": "localhost",
    "port": 5678
  }
}
```

**Use when**: Connecting to already-running process

---

## 4. Debugger Types

### Python (`debugpy`)

```json
{
  "name": "Python: Current File",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",
  "console": "integratedTerminal",
  "cwd": "${fileDirname}",
  "env": {
    "PYTHONPATH": "${workspaceFolder}"
  },
  "justMyCode": false // Debug into libraries
}
```

**Key properties**:

- `justMyCode`: `true` = skip library code, `false` = debug everything
- `django`: Set to `true` for Django projects
- `module`: Launch module instead of file: `"module": "pytest"`
- `python`: Path to Python interpreter

**Pytest debugging**:

```json
{
  "name": "Python: Pytest",
  "type": "debugpy",
  "request": "launch",
  "module": "pytest",
  "args": ["${file}", "-v", "-s"], // -s shows print statements
  "console": "integratedTerminal",
  "justMyCode": false
}
```

### Node.js / JavaScript (`node`)

```json
{
  "name": "Node: Current File",
  "type": "node",
  "request": "launch",
  "program": "${file}",
  "skipFiles": ["<node_internals>/**"], // Skip Node.js internals
  "console": "integratedTerminal",
  "runtimeArgs": ["--experimental-modules"] // Node flags
}
```

**Key properties**:

- `skipFiles`: Array of glob patterns to skip
- `runtimeExecutable`: `"npm"` or `"yarn"` to run scripts
- `runtimeArgs`: Arguments to Node.js itself
- `args`: Arguments to your program
- `protocol`: `"inspector"` (modern) or `"legacy"`

**Debugging npm scripts**:

```json
{
  "name": "npm run dev",
  "type": "node",
  "request": "launch",
  "runtimeExecutable": "npm",
  "runtimeArgs": ["run", "dev"],
  "port": 9229,
  "skipFiles": ["<node_internals>/**"]
}
```

### TypeScript (`node` + `ts-node`)

```json
{
  "name": "TypeScript: Current File",
  "type": "node",
  "request": "launch",
  "program": "${file}",
  "runtimeArgs": ["-r", "ts-node/register"],
  "console": "integratedTerminal",
  "internalConsoleOptions": "neverOpen",
  "skipFiles": ["<node_internals>/**"]
}
```

### Browser Debugging (`chrome`, `msedge`)

```json
{
  "name": "Chrome: Debug",
  "type": "chrome",
  "request": "launch",
  "url": "http://localhost:3000",
  "webRoot": "${workspaceFolder}",
  "sourceMapPathOverrides": {
    "webpack:///./~/*": "${webRoot}/node_modules/*",
    "webpack:///./*": "${webRoot}/*"
  }
}
```

**Key properties**:

- `url`: Where to launch browser
- `webRoot`: Project root for source maps
- `sourceMapPathOverrides`: Map bundled paths to source

### Go (`go`)

```json
{
  "name": "Go: Launch",
  "type": "go",
  "request": "launch",
  "mode": "auto", // or "debug", "test", "exec"
  "program": "${file}",
  "env": {},
  "args": []
}
```

**Modes**:

- `auto`: Automatically detect (file vs package)
- `debug`: Debug compiled binary
- `test`: Debug tests
- `exec`: Debug pre-built binary

### Rust (`lldb` or `gdb`)

```json
{
  "name": "Rust: Debug",
  "type": "lldb",
  "request": "launch",
  "program": "${workspaceFolder}/target/debug/${workspaceFolderBasename}",
  "args": [],
  "cwd": "${workspaceFolder}",
  "preLaunchTask": "cargo build"
}
```

**Alternative with CodeLLDB**:

```json
{
  "name": "Rust: Debug with CodeLLDB",
  "type": "lldb",
  "request": "launch",
  "cargo": {
    "args": ["build", "--bin=myapp", "--package=mypackage"]
  },
  "args": [],
  "cwd": "${workspaceFolder}"
}
```

### Java (`java`)

```json
{
  "name": "Java: Launch",
  "type": "java",
  "request": "launch",
  "mainClass": "com.example.Main",
  "projectName": "myproject",
  "args": [],
  "classPaths": ["target/classes"]
}
```

### Docker (`docker`)

```json
{
  "name": "Docker: Attach",
  "type": "node",
  "request": "attach",
  "port": 9229,
  "address": "localhost",
  "localRoot": "${workspaceFolder}",
  "remoteRoot": "/app"
}
```

---

## 5. Launch vs Attach

### Launch: Start Fresh

**When to use**:

- Debugging during development
- Need full control over process
- Want to set environment variables
- Testing from clean state

**Example**: Launching Python script

```json
{
  "name": "Launch Script",
  "type": "debugpy",
  "request": "launch",
  "program": "${workspaceFolder}/app.py"
}
```

### Attach: Connect to Running

**When to use**:

- Process already running (e.g., web server)
- Production/staging debugging
- Long-running processes
- Docker containers

**Setup for Python**:

```python
# In your code
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()  # Optional: pause until debugger connects
```

```json
{
  "name": "Attach to Python",
  "type": "debugpy",
  "request": "attach",
  "connect": {
    "host": "localhost",
    "port": 5678
  },
  "pathMappings": [
    {
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "."
    }
  ]
}
```

**Setup for Node.js**:

```bash
# Start Node with inspector
node --inspect=9229 app.js

# Or use nodemon
nodemon --inspect=9229 app.js
```

```json
{
  "name": "Attach to Node",
  "type": "node",
  "request": "attach",
  "port": 9229,
  "restart": true // Reconnect on restart
}
```

---

## 6. Environment & Variables

### Setting Environment Variables

```json
{
  "name": "With Environment",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",
  "env": {
    "DEBUG": "true",
    "API_KEY": "dev-key-12345",  // pragma: allowlist secret
    "DATABASE_URL": "postgresql://localhost/mydb"
  }
}
```

### Loading from .env File

```json
{
  "name": "Load .env",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",
  "envFile": "${workspaceFolder}/.env.development"
}
```

### Variable Substitution

VS Code provides these variables:

```json
{
  "${workspaceFolder}": "/path/to/workspace",
  "${workspaceFolderBasename}": "workspace-name",
  "${file}": "/path/to/current/file.py",
  "${fileBasename}": "file.py",
  "${fileBasenameNoExtension}": "file",
  "${fileDirname}": "/path/to/current",
  "${fileExtname}": ".py",
  "${cwd}": "/current/working/directory",
  "${lineNumber}": "42",
  "${selectedText}": "highlighted text",
  "${env:HOME}": "environment variable",
  "${config:python.pythonPath}": "VS Code setting"
}
```

**Example usage**:

```json
{
  "name": "Debug Current File",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",
  "cwd": "${fileDirname}",
  "env": {
    "HOME": "${env:HOME}",
    "PROJECT_ROOT": "${workspaceFolder}"
  }
}
```

---

## 7. Multi-Target Debugging

### Compound Configurations

Debug multiple services simultaneously:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Backend API",
      "type": "debugpy",
      "request": "launch",
      "program": "${workspaceFolder}/backend/app.py"
    },
    {
      "name": "Frontend Dev Server",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "cwd": "${workspaceFolder}/frontend"
    }
  ],
  "compounds": [
    {
      "name": "🚀 Full Stack Debug",
      "configurations": ["Backend API", "Frontend Dev Server"],
      "stopAll": true, // Stop all when one stops
      "preLaunchTask": "build-all"
    }
  ]
}
```

### Use Cases for Compounds

1. **Microservices**: Debug multiple services
2. **Full-stack**: Backend + Frontend
3. **Multi-process**: Parent + Child processes
4. **Test + Server**: Test runner + API server

---

## 8. Advanced Debugging

### Conditional Breakpoints

Set in UI, but can configure behavior:

```json
{
  "name": "Advanced Debug",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",
  "justMyCode": false, // Debug into libraries
  "showReturnValue": true, // Show function return values
  "redirectOutput": true // Capture stdout/stderr
}
```

### Remote Debugging

Debug code running on another machine:

```json
{
  "name": "Remote Python",
  "type": "debugpy",
  "request": "attach",
  "connect": {
    "host": "192.168.1.100", // Remote machine IP
    "port": 5678
  },
  "pathMappings": [
    {
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "/app" // Path on remote machine
    }
  ]
}
```

### Docker Container Debugging

```json
{
  "name": "Docker: Python",
  "type": "debugpy",
  "request": "attach",
  "connect": {
    "host": "localhost",
    "port": 5678
  },
  "pathMappings": [
    {
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "/workspace"
    }
  ]
}
```

**Dockerfile setup**:

```dockerfile
# Install debugpy in container
RUN pip install debugpy

# Expose debug port
EXPOSE 5678

# Start with debugger
CMD python -m debugpy --listen 0.0.0.0:5678 --wait-for-client app.py
```

### Debugging Tests

```json
{
  "name": "Jest: Current File",
  "type": "node",
  "request": "launch",
  "program": "${workspaceFolder}/node_modules/.bin/jest",
  "args": [
    "${fileBasenameNoExtension}",
    "--config",
    "jest.config.js",
    "--runInBand" // Run serially, not parallel
  ],
  "console": "integratedTerminal",
  "internalConsoleOptions": "neverOpen"
}
```

### Source Maps

For transpiled languages (TypeScript, Babel, etc.):

```json
{
  "name": "TypeScript with Source Maps",
  "type": "node",
  "request": "launch",
  "program": "${workspaceFolder}/dist/index.js",
  "preLaunchTask": "tsc: build",
  "outFiles": ["${workspaceFolder}/dist/**/*.js"],
  "sourceMaps": true,
  "smartStep": true // Skip generated code
}
```

---

## 9. Troubleshooting

### Common Issues

#### Debugger Won't Start

```json
{
  // Check:
  "type": "debugpy", // ✅ Correct extension installed?
  "program": "${workspaceFolder}/app.py", // ✅ File exists?
  "python": "${config:python.pythonPath}" // ✅ Python found?
}
```

#### Breakpoints Not Hitting

**Possible causes**:

1. Source maps not working
2. Wrong file path
3. `justMyCode: true` skipping code
4. Optimization removed code

**Solutions**:

```json
{
  "justMyCode": false, // Debug into libraries
  "sourceMaps": true, // Enable source maps
  "outFiles": ["${workspaceFolder}/dist/**/*.js"] // Specify build output
}
```

#### Variables Not Showing

```json
{
  // Enable full debugging
  "showReturnValue": true,
  "redirectOutput": true,
  "console": "integratedTerminal" // vs "internalConsole"
}
```

### Debugging the Debugger

````bash
# Run VS Code with debug logging
code --log debug

# Check Debug Console (not terminal!)
# View → Debug Console
```text

---

## 🎓 Expert Insights

### The Debugging Mindset

1. **Start simple**: Debug current file before complex setups
2. **Use `console.log` / `print`**: Sometimes faster than debugger
3. **Master breakpoints**: Conditional, log points, hit counts
4. **Know your shortcuts**:
   - F5: Start debugging
   - F9: Toggle breakpoint
   - F10: Step over
   - F11: Step into
   - Shift+F11: Step out
   - Shift+F5: Stop debugging

### Configuration Patterns

#### Pattern 1: The Trinity

```json
{
  "configurations": [
    {
      "name": "1️⃣ Debug Current File",
      "type": "debugpy",
      "request": "launch",
      "program": "${file}"
    },
    {
      "name": "2️⃣ Debug Main App",
      "type": "debugpy",
      "request": "launch",
      "program": "${workspaceFolder}/app.py"
    },
    {
      "name": "3️⃣ Debug Tests",
      "type": "debugpy",
      "request": "launch",
      "module": "pytest",
      "args": ["-v"]
    }
  ]
}
````

#### Pattern 2: The Stack

```json
{
  "configurations": [
    { "name": "Backend", "type": "debugpy", "...": "..." },
    { "name": "Frontend", "type": "chrome", "...": "..." },
    { "name": "Database", "type": "node", "...": "..." }
  ],
  "compounds": [
    {
      "name": "Full Stack",
      "configurations": ["Backend", "Frontend", "Database"]
    }
  ]
}
```

### Performance Tips

```json
{
  // Faster debugging
  "console": "integratedTerminal", // vs internalConsole
  "internalConsoleOptions": "neverOpen", // Don't auto-open
  "showReturnValue": false, // Skip return values
  "justMyCode": true // Skip libraries
}
```

---

## 🚀 The Ultimate Template

My expert template for any project:

```json
{
  "version": "0.2.0",
  "configurations": [
    // ========================================
    // QUICK DEBUG (Most common use case)
    // ========================================
    {
      "name": "🚀 Debug Current File",
      "type": "debugpy", // or "node", "go", etc.
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": false
    },

    // ========================================
    // MAIN APPLICATION
    // ========================================
    {
      "name": "🏃 Run Main App",
      "type": "debugpy",
      "request": "launch",
      "program": "${workspaceFolder}/src/main.py",
      "env": {
        "DEBUG": "true"
      },
      "envFile": "${workspaceFolder}/.env.development"
    },

    // ========================================
    // TESTS
    // ========================================
    {
      "name": "🧪 Debug Tests",
      "type": "debugpy",
      "request": "launch",
      "module": "pytest",
      "args": ["-v", "-s"],
      "console": "integratedTerminal"
    },

    // ========================================
    // ATTACH TO RUNNING PROCESS
    // ========================================
    {
      "name": "🔗 Attach to Server",
      "type": "debugpy",
      "request": "attach",
      "connect": {
        "host": "localhost",
        "port": 5678
      }
    }
  ]
}
```

---

**Expert insight: Debug smarter, not harder. Configure once, debug forever.** 🚀
