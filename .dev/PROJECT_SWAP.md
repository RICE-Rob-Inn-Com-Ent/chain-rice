# 🔄 Project Swap System

Dynamic project management system for rice-mono monorepo.

## 🎯 Concept

The `.project/` directory is a **dynamic slot** that can contain different projects. Each project is a separate git
repository that gets swapped in/out as needed.

## 📋 Architecture

```
rice-mono/                      # Main monorepo
├── .project/                   # Active project (git repo)
├── .project-active             # Tracks which project is active
├── .project-repos.json         # Configuration of all projects
├── .project-cache/             # Cached copies of each project
│   ├── infinir/
│   ├── code_rice/
│   └── ...
└── .github/workflows/
    └── cd-swap-project.yml     # Auto-sync to GitHub
```

## 🚀 Quick Start

### List Available Projects

```bash
make project-list
```

Output:

```
★ infinir - InfiniR (ACTIVE)
  ↳ https://github.com/RICE-Rob-Inn-Com-Ent/InfiniR.git

  code_rice - Code-Rice
  ↳ https://github.com/RICE-Rob-Inn-Com-Ent/Code-Rice.git
```

### Swap to Different Project

```bash
make swap
```

Interactive workflow:

1. **Checks** uncommitted changes in current project
2. **Prompts** for commit message (if changes exist)
3. **Auto-commits and pushes** to current project repo
4. **Caches** current project to `.project-cache/`
5. **Shows** list of available projects
6. **Pulls** selected project from GitHub
7. **Updates** `.project-active`

### Check Current Project

```bash
make project-status
```

## 📝 Configuration

### .project-repos.json

```json
{
  "projects": {
    "infinir": {
      "name": "InfiniR",
      "url": "https://github.com/RICE-Rob-Inn-Com-Ent/InfiniR.git",
      "branch": "main",
      "description": "Multi-Platform AI-Powered Infinite Reality"
    },
    "code_rice": {
      "name": "Code-Rice",
      "url": "https://github.com/RICE-Rob-Inn-Com-Ent/Code-Rice.git",
      "branch": "main",
      "description": "Code-Rice Project"
    }
  }
}
```

### .project-active

```
infinir
```

Simple text file containing the key of the active project.

## 🤖 GitHub Actions Integration

### Auto-Sync on Push

When you push changes to rice-mono that affect `.project/`:

1. GitHub Actions detects change
2. Reads `.project-active` to determine target repo
3. Reads `.project-repos.json` to get target URL
4. Clones target repository
5. Syncs `.project/` content to target repo
6. Commits and pushes to target repository

**File:** `.github/workflows/cd-swap-project.yml`

**Requires:** `PAT_TOKEN` secret with repo write access

## 🔧 Manual Commands

### Save Current Project to Cache

```bash
make project-save
```

### Sync Repository List from GitHub

```bash
make project-sync-repos
```

_Note: Currently only rice-mono exists in the org. Add other repos manually to .project-repos.json_

## 🎭 Workflow Example

### Day 1: Working on InfiniR

```bash
cd .project
# ... make changes ...
git add .
git commit -m "feat: add new feature"
git push
```

### Day 2: Switch to Code-Rice

```bash
cd ..
make swap
# Select: 2. code_rice

# Now .project/ contains Code-Rice
cd .project
# ... work on Code-Rice ...
```

### Day 3: Back to InfiniR

```bash
cd ..
make swap
# Select: 1. infinir

# Restored from cache + pulled latest
```

## 🔐 Security Notes

- `.project-active` is tracked in rice-mono
- `.project-repos.json` is tracked in rice-mono
- `.project-cache/` is ignored (local only)
- Each project has its own git history
- GitHub Actions requires PAT token for cross-repo sync

## 📦 Adding New Project

Edit `.project-repos.json`:

```json
{
  "projects": {
    "infinir": { ... },
    "code_rice": { ... },
    "new_project": {
      "name": "New-Project",
      "url": "https://github.com/RICE-Rob-Inn-Com-Ent/New-Project.git",
      "branch": "main",
      "description": "Description of new project"
    }
  }
}
```

Then: `make swap` → select new project

## 🛠️ Troubleshooting

### "jq not installed"

```bash
# Auto-install via Makefile
export PATH="$HOME/.local/bin:$PATH"
make project-list  # Will download jq automatically
```

### "Cannot swap with uncommitted changes"

```bash
cd .project
git add .
git commit -m "wip: work in progress"
git push
cd ..
make swap
```

### "Remote authentication failed"

Push requires GitHub authentication. Use:

- VSCode Git integration (recommended)
- GitHub CLI: `gh auth login`
- SSH keys in `~/.ssh/`

## 🎯 Best Practices

1. **Always commit** before swap
2. **Use descriptive** commit messages
3. **Keep .project thin** - reuse from `.frontend/`, `.backend/` etc.
4. **Update .project-repos.json** when adding new repos
5. **Let GitHub Actions** handle auto-sync to save time
