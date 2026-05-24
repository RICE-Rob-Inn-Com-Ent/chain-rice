package workspace

// cue cmd embed — regenerated from repo files
emitFiles_ws: [
		{
			path:    "rice.code-workspace"
			content: #"""
{
  "folders": [
    {
      "name": "👨‍🍳CHIEF",
      "path": "custom"
    },
    {
      "name": "🧑‍🔬SAGE",
      "path": "function"
    },
    {
      "name": "🧑‍🎤BARD",
      "path": "frontend"
    },
    {
      "name": "👨‍💼CLERK",
      "path": "base"
    },
    {
      "name": "🧑‍🏭SMITH",
      "path": "service"
    },
    {
      "name": "👷MASON",
      "path": "infra"
    },
    {
      "name": "🫅KING",
      "path": "."
    }
  ],
  "settings": {
    // ── editor — global ───────────────────────────────────
    "workbench.colorTheme": "Cursor Dark Midnight",
    "workbench.iconTheme": "material-icon-theme",
    "material-icon-theme.activeIconPack": "react_redux",
    "material-icon-theme.folders.theme": "specific",
    // `.k8s/gpu` — папка `gpu`: клон «shader» + колір NVIDIA (без логотипу Kubernetes).
    // Щоб використати SVG з репо: скопіюй `.vscode/extensions/icons/folder-gpu*.svg` →
    //   `~/.vscode/extensions/icons/` (або `~/.cursor/extensions/icons/` у Cursor),
    //   далі в User settings додай folders.associations: { "gpu": "../../../../icons/folder-gpu" }
    //   (кількість `../` залежить від шляху встановлення Material Icon Theme — див. README розширення).
    // `custom/*`: кастомні папки `folder-project*.svg` (лого вшито в SVG, один файл без залежності).
    //   У Material Icon Theme кастомні folder SVG зареєстровані офіційно лише через User settings —
    //   див. ~/.config/Cursor/User/settings.json → `material-icon-theme.folders.associations`.
    //   Іконки: скопіюй з `.vscode/extensions/icons/folder-project*.svg` у `…/cursor/extensions/icons/`.
    //   Новий каталог під `custom/`: додай ключ (точне ім’я папки) у тій самій секції User settings (glob недоступний).
    "material-icon-theme.folders.customClones": [
      {
        "name": "gpu-nvidia-shader",
        "base": "shader",
        "color": "#76B900",
        "lightColor": "#5a8f00",
        "folderNames": [
          "gpu"
        ]
      }
    ],
    "material-icon-theme.saturation": 1,
    "material-icon-theme.opacity": 1,
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.cursorBlinking": "smooth",
    "editor.smoothScrolling": true,
    "editor.fontFamily": "'Fira Code', 'JetBrains Mono', monospace",
    "editor.fontLigatures": true,
    "editor.minimap.enabled": true,
    "editor.scrollbar.vertical": "hidden",
    "editor.renderLineHighlight": "all",
    "editor.letterSpacing": 0.33,
    "editor.lineHeight": 25,
    "editor.linkedEditing": true,
    "editor.formatOnSave": true,
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": "active",
    // ── files — global ────────────────────────────────────
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.associations": {
      "Justfile": "just",
      "*.mojo": "mojo",
      "*.bacon": "toml",
      ".envrc": "shellscript",
      "*.cue": "cue",
      "*.tf.json": "json",
      "*.frag": "glsl",
      "*.vert": "glsl",
      "*.glsl": "glsl",
      "*.odin": "odin",
      "*.rice": "rice"
    },
    // ── explorer ──────────────────────────────────────────
    "explorer.confirmDragAndDrop": false,
    "outline.showVariables": false,
    "outline.showFields": false,
    "scm.diffDecorations": "gutter",
    "git.openRepositoryInParentFolders": "always",
    // ── error lens ────────────────────────────────────────
    "errorLens.enabledDiagnosticLevels": [
      "error",
      "warning"
    ],
    "errorLens.fontStyleItalic": true,
    // ── todo tree ─────────────────────────────────────────
    "todo-tree.highlights.defaultHighlight": {
      "type": "text",
      "fontWeight": "bold",
      "borderRadius": "4px"
    },
    "todo-tree.highlights.customHighlight": {
      "TODO": {
        "foreground": "#ffffff",
        "background": "#3a3a3a",
        "iconColour": "#ffffff",
        "icon": "check"
      },
      "FIXME": {
        "foreground": "#ff5555",
        "background": "#3a0000",
        "iconColour": "#ff5555",
        "icon": "flame"
      },
      "HACK": {
        "foreground": "#ffb86c",
        "background": "#3a2000",
        "iconColour": "#ffb86c",
        "icon": "alert"
      },
      "NOTE": {
        "foreground": "#8be9fd",
        "background": "#00202a",
        "iconColour": "#8be9fd",
        "icon": "info"
      }
    },
    "todo-tree.regex.regex": "(//|#|--|\\*|<!--)\\s*($TAGS)|\\[ \\]|\\[x\\]",
    "todo-tree.general.tags": [
      "TODO",
      "FIXME",
      "HACK",
      "NOTE",
      "[ ]",
      "[x]"
    ],
    // ── vscode-pets ───────────────────────────────────────
    "vscode-pets.petSize": "medium",
    "vscode-pets.theme": "forest",
    "vscode-pets.throwBallWithMouse": true,
    // ── formatters per language ───────────────────────────
    // 🫅 KING — JSON/JSONC
    "[json]": {
      "editor.defaultFormatter": "vscode.json-language-features"
    },
    "[jsonc]": {
      "editor.defaultFormatter": "vscode.json-language-features"
    },
    // 👷 MASON — CUE + Proto + YAML + TOML
    "[cue]": {
      "editor.defaultFormatter": "Dart-Code.dart-code",
      "editor.formatOnSave": true
    },
    "[proto3]": {
      "editor.defaultFormatter": "zxh404.vscode-proto3",
      "editor.formatOnSave": true
    },
    "[yaml]": {
      "editor.defaultFormatter": "redhat.vscode-yaml",
      "editor.formatOnSave": true
    },
    "[toml]": {
      "editor.defaultFormatter": "tamasfe.even-better-toml",
      "editor.formatOnSave": true
    },
    // 🧑‍🏭 SMITH — Go + Elixir
    "[go]": {
      "editor.defaultFormatter": "golang.go",
      "editor.formatOnSave": true,
      "editor.codeActionsOnSave": {
        "source.organizeImports": "explicit"
      }
    },
    "[elixir]": {
      "editor.defaultFormatter": "elixir-lsp.elixir-ls",
      "editor.formatOnSave": true
    },
    "[eex]": {
      "editor.defaultFormatter": "elixir-lsp.elixir-ls",
      "editor.formatOnSave": true
    },
    "[html-eex]": {
      "editor.defaultFormatter": "elixir-lsp.elixir-ls",
      "editor.formatOnSave": true
    },
    // 👨‍💼 CLERK — Rust + Haskell + Zig
    "[rust]": {
      "editor.defaultFormatter": "rust-lang.rust-analyzer",
      "editor.formatOnSave": true
    },
    "[haskell]": {
      "editor.defaultFormatter": "haskell.haskell",
      "editor.formatOnSave": true
    },
    "[zig]": {
      "editor.defaultFormatter": "ziglang.vscode-zig",
      "editor.formatOnSave": true
    },
    // 🧑‍🔬 SAGE — Python + Mojo
    "[python]": {
      "editor.defaultFormatter": "charliermarsh.ruff",
      "editor.formatOnSave": true,
      "editor.codeActionsOnSave": {
        "source.organizeImports": "explicit"
      }
    },
    "[mojo]": {
      "editor.defaultFormatter": "modular-mojotools.vscode-mojo",
      "editor.formatOnSave": true
    },
    // 🧑‍🎤 BARD — TypeScript + Dart + Odin + GLSL
    "[typescript][javascript][typescriptreact][javascriptreact]": {
      "editor.defaultFormatter": "biomejs.biome",
      "editor.formatOnSave": true
    },
    "[dart]": {
      "editor.defaultFormatter": "Dart-Code.flutter",
      "editor.formatOnSave": true
    },
    // BARD — Dart/Flutter: hide generated noise in Explorer / search (files still exist for tooling)
    "dart.enableSdkFormatter": true,
    "files.watcherExclude": {
      "**/.dart_tool/**": true,
      "**/frontend/**/build/**": true,
      "**/target/**": true,
      "**/.zig-cache/**": true,
      "**/zig-out/**": true,
      "**/buck-out/**": true,
      "**/.buck-cache/**": true
    },
    "files.exclude": {
      "**/.dart_tool": true,
      "**/.flutter-plugins-dependencies": true,
      "**/target": true,
      "**/.zig-cache": true,
      "**/zig-out": true,
      "**/buck-out": true,
      "**/.buck-cache": true
    },
    "search.exclude": {
      "**/.dart_tool": true,
      "**/frontend/**/build/**": true,
      "**/target": true,
      "**/.zig-cache": true,
      "**/zig-out": true,
      "**/buck-out": true,
      "**/.buck-cache": true
    },
    "[odin]": {
      "editor.defaultFormatter": "DanielGavin.ols",
      "editor.formatOnSave": true
    },
    "[glsl]": {
      "editor.defaultFormatter": "slevesque.vscode-glsl",
      "editor.formatOnSave": false
    },
    "[opentofu]": {
      "editor.defaultFormatter": "hashicorp.terraform",
      "editor.formatOnSave": false
    },
    // ── language server settings ──────────────────────────
    // 🧑‍🏭 SMITH — Go
    "go.toolsManagement.autoUpdate": false,
    "go.useLanguageServer": true,
    "go.lintTool": "golangci-lint",
    "go.lintFlags": [
      "--fast"
    ],
    "go.formatTool": "gofumpt",
    // 🧑‍🏭 SMITH — ElixirLS
    "elixirLS.projectDir": "service",
    "elixirLS.mixEnv": "dev",
    "elixirLS.fetchDeps": false,
    "elixirLS.dialyzerEnabled": true,
    "elixirLS.suggestSpecs": true,
    // 👨‍💼 CLERK — Haskell (pixi supplies ghc/hls/stack)
    "haskell.manageHLS": "PATH",
    "haskell.serverEnvironment": {
      "PATH": "${workspaceFolder:🫅KING}/.pixi/envs/default/bin${pathSeparator}${env:PATH}"
    },
    "haskell.formattingProvider": "fourmolu",
    "zig.path": "${env:HOME}/.config/Cursor/User/globalStorage/ziglang.vscode-zig/zig/x86_64-linux-0.15.2/zig",
    "zig.zls.path": "${env:HOME}/.config/Cursor/User/globalStorage/ziglang.vscode-zig/zls/x86_64-linux-0.15.1/zls",
    // 🧑‍🎤 BARD — Odin
    "ols.server.path": "${workspaceFolder:🫅KING}/.pixi/envs/default/bin/ols",
    // 👷 MASON — CUE
    "cue.path": "${workspaceFolder:🫅KING}/.pixi/envs/default/bin/cue",
    // ── remote ────────────────────────────────────────────
    // Remote-SSH: `remote.SSH.remotePlatform` is not applied from .code-workspace
    // (VS Code reads it from User settings before connect — see microsoft/vscode#238783).
    // 1. Set RICE_REMOTE_HOST in .envrc to your SSH `Host` name (~/.ssh/config).
    // 2. In User settings.json (JSON), merge — use the same host string as the key:
    //    "remote.SSH.remotePlatform": { "your-host-alias": "linux" }
    // Direnv can expose RICE_REMOTE_HOST to the editor; the mapping must still live
    // in User settings because keys cannot reference ${env:...} reliably.
    // ── terminal ──────────────────────────────────────────
    "terminal.integrated.env.linux": {
      "PATH": "${workspaceFolder:🫅KING}/.pixi/envs/default/bin:${env:PATH}",
      "CARGO_TARGET_DIR": "${workspaceFolder:🫅KING}/.build/rust",
      "ZIG_CACHE_DIR": "${workspaceFolder:🫅KING}/.build/zig-cache"
    },
    "terminal.integrated.env.osx": {
      "PATH": "${workspaceFolder:🫅KING}/.pixi/envs/default/bin:${env:PATH}"
    }
  },
  "tasks": {
    "version": "2.0.0",
    "inputs": [
      {
        "id": "project",
        "type": "promptString",
        "description": "Project name (custom/{project}/)"
      },
      {
        "id": "role",
        "type": "pickString",
        "description": "Rice role to delegate to",
        "options": [
          "mason",
          "smith",
          "clerk",
          "sage",
          "bard",
          "chief"
        ]
      },
      {
        "id": "task",
        "type": "promptString",
        "description": "Task description for the role"
      }
    ],
    "tasks": [
      {
        "label": "Rice: pour",
        "type": "shell",
        "command": "rice pour",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "Rice: forge",
        "type": "shell",
        "command": "rice forge",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": {
          "kind": "build",
          "isDefault": true
        },
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "Rice: think",
        "type": "shell",
        "command": "rice think",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "Rice: audit",
        "type": "shell",
        "command": "rice audit",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": {
          "kind": "test",
          "isDefault": true
        },
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "Rice: cook",
        "type": "shell",
        "command": "rice cook ${input:project}",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "Rice: serve",
        "type": "shell",
        "command": "rice serve ${input:project}",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "Rice: prepare",
        "type": "shell",
        "command": "rice prepare ${input:project}",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "Rice: rule",
        "type": "shell",
        "command": "rice rule ${input:role} \"${input:task}\"",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "always",
          "panel": "dedicated"
        }
      },
      {
        "label": "MASON: genMonorepo (pour)",
        "type": "shell",
        "command": "cue cmd genMonorepo ./infra/_tool.cue",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "silent",
          "panel": "shared"
        }
      },
      {
        "label": "CHIEF: genChief (cook)",
        "type": "shell",
        "command": "cue cmd genChief ./infra/_tool.cue",
        "options": {
          "cwd": "${workspaceFolder:🫅KING}"
        },
        "group": "build",
        "presentation": {
          "reveal": "silent",
          "panel": "shared"
        }
      }
    ]
  },
  "extensions": {
    "recommendations": [
      // ── editor UX ─────────────────────────────────────
      "emeraldwalk.runonsave",
      "enkia.tokyo-night",
      "pkief.material-icon-theme",
      "usernamehw.errorlens",
      "tonybaloney.vscode-pets",
      "oderwat.indent-rainbow",
      "aaron-bond.better-comments",
      "gruntfuggly.todo-tree",
      // ── 🫅 KING ───────────────────────────────────────
      "skellock.just",
      "mkhl.direnv",
      "signageos.signagoes-vscode-sops",
      "github.vscode-github-actions",
      "antfu.browse-lite",
      // ── 👷 MASON ──────────────────────────────────────
      "cuelangorg.vscode-cue",
      "zxh404.vscode-proto3",
      "redhat.vscode-yaml",
      "tamasfe.even-better-toml",
      "gamunu.vscode-opentofu",
      "bierner.markdown-mermaid",
      "aquasecurity.trivy-vulnerability-scanner",
      // ── 🧑‍🏭 SMITH ─────────────────────────────────────
      "golang.go",
      "JakeBecker.elixir-ls",
      // ── 👨‍💼 CLERK ─────────────────────────────────────
      "rust-lang.rust-analyzer",
      "haskell.haskell",
      "ziglang.vscode-zig",
      "iden3.circom",
      // ── 🧑‍🔬 SAGE ──────────────────────────────────────
      "charliermarsh.ruff",
      "modular-mojotools.mojo",
      // ── 🧑‍🎤 BARD ──────────────────────────────────────
      "biomejs.biome",
      "dart-code.flutter",
      "DanielGavin.ols",
      "slevesque.vscode-glsl",
      "circledev.glsl-canvas"
    ]
  }
}






"""#
		}
,
		{
			path:    ".editorconfig"
			content: #"""
# .editorconfig
# Generated by: cue export infra/configs/editorconfig.cue
# Do not edit manually — edit infra/configs/editorconfig.cue instead

root = true

# ── global defaults ───────────────────────────────────────
[*]
charset                  = utf-8
end_of_line              = lf
insert_final_newline     = true
trim_trailing_whitespace = true
indent_style             = space
indent_size              = 2

# ── MASON — CUE + Proto + docs ────────────────────────────
[*.cue]
indent_style = space
indent_size  = 4
max_line_length = 100

[*.proto]
indent_style = space
indent_size  = 2
max_line_length = 100

[*.md]
trim_trailing_whitespace = false
max_line_length          = off

# ── SMITH — Go + Elixir ───────────────────────────────────
[*.go]
indent_style    = tab           # gofmt enforces tabs — never spaces
indent_size     = 4
max_line_length = 120

[*.{ex,exs}]
indent_style    = space
indent_size     = 2
max_line_length = 120

# ── SAGE — Python + Mojo ──────────────────────────────────
[*.py]
indent_style    = space
indent_size     = 4             # PEP8
max_line_length = 88            # ruff default

[*.mojo]
indent_style    = space
indent_size     = 4
max_line_length = 88

# ── BARD — Odin + TypeScript + Dart ──────────────────────
[*.odin]
indent_style    = space
indent_size     = 4
max_line_length = 120

[*.{ts,tsx,js,jsx}]
indent_style    = space
indent_size     = 2
max_line_length = 100

[*.dart]
indent_style    = space
indent_size     = 2
max_line_length = 120

# ── CLERK — Rust + Haskell + Zig ─────────────────────────
[*.rs]
indent_style    = space
indent_size     = 4
max_line_length = 100           # rustfmt default

[*.{hs,lhs}]
indent_style    = space
indent_size     = 2
max_line_length = 100

[*.zig]
indent_style    = space
indent_size     = 4
max_line_length = 100

# ── CHIEF — .rice language ────────────────────────────────
[*.rice]
indent_style    = space
indent_size     = 2
max_line_length = 120

# ── build system — tab sensitive ─────────────────────────
[justfile]
indent_style = tab
indent_size  = 4

[{BUCK,BUCK2,.buckversion}]
indent_style = space
indent_size  = 4

# ── config formats ────────────────────────────────────────
[*.{yaml,yml}]
indent_style = space
indent_size  = 2

[*.{json,jsonc}]
indent_style = space
indent_size  = 2

[*.toml]
indent_style = space
indent_size  = 2

[*.{tf,tfvars}]
indent_style    = space
indent_size     = 2
max_line_length = 120

# ── shell ─────────────────────────────────────────────────
[*.sh]
indent_style = space
indent_size  = 2

# ── never touch ───────────────────────────────────────────
[*.lock]
insert_final_newline     = false
trim_trailing_whitespace = false

[{*.min.js,*.min.css}]
insert_final_newline     = false
trim_trailing_whitespace = false






"""#
		}
]
