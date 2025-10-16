# 📚 Helper Documentation - Rice Monorepo

> Detailed guides for mastering every aspect of this monorepo

---

## 🎯 Quick Navigation

### 🔧 Development & Tooling

| Guide | Description | Topics Covered |
|-------|-------------|----------------|
| [**PRE_COMMIT_GUIDE.md**](PRE_COMMIT_GUIDE.md) | Pre-commit hooks & linting architecture | 3-layer architecture, VSCode extensions, CI/CD integration, performance optimization |
| [**CI_CD_SETUP_GUIDE.md**](CI_CD_SETUP_GUIDE.md) | CI/CD pipeline setup | GitHub Actions, secrets, workflows, deployment |
| [**ROOT_FILES.md**](ROOT_FILES.md) | Root configuration files | Purpose of each root file, when to modify |
| [**ROOT_FOLDERS.md**](ROOT_FOLDERS.md) | Monorepo structure | Directory organization, naming conventions |

### 🐙 GitHub & Workflows

| Guide | Description | Topics Covered |
|-------|-------------|----------------|
| [**github/WORKFLOWS.md**](github/WORKFLOWS.md) | Complete workflow guide | All 15 workflows, triggers, configuration |
| [**github/ISSUE_TEMPLATE.md**](github/ISSUE_TEMPLATE.md) | Issue templates guide | Bug reports, feature requests, best practices |
| [**github/PULL_REQUEST_TEMPLATE_GUIDE.md**](github/PULL_REQUEST_TEMPLATE_GUIDE.md) | PR template guide | PR sections, examples, review process |
| [**github/CODEOWNERS.md**](github/CODEOWNERS.md) | Code ownership guide | Review assignments, ownership patterns |
| [**github/FUNDING.md**](github/FUNDING.md) | Sponsorship guide | Funding platforms, benefits, transparency |

### 🛠️ VSCode

| Guide | Description | Topics Covered |
|-------|-------------|----------------|
| [**vscode/EXTENSIONS.md**](vscode/EXTENSIONS.md) | Recommended extensions | 50+ extensions by category |
| [**vscode/SETTINGS.md**](vscode/SETTINGS.md) | VSCode settings | Per-language configuration |
| [**vscode/LAUNCH.md**](vscode/LAUNCH.md) | Debug configurations | Launch configs for all languages |
| [**vscode/TASKS.md**](vscode/TASKS.md) | VSCode tasks | Build, test, lint tasks |

---

## 🚀 Getting Started

### For New Developers

**Start here** → [ROOT_FOLDERS.md](ROOT_FOLDERS.md) → Understand monorepo structure

**Then read** → [PRE_COMMIT_GUIDE.md](PRE_COMMIT_GUIDE.md) → Set up quality tools

**Finally** → [github/WORKFLOWS.md](github/WORKFLOWS.md) → Understand CI/CD

### For Contributors

**Before your first PR** → [github/PULL_REQUEST_TEMPLATE_GUIDE.md](github/PULL_REQUEST_TEMPLATE_GUIDE.md)

**For reporting issues** → [github/ISSUE_TEMPLATE.md](github/ISSUE_TEMPLATE.md)

### For Maintainers

**Code ownership** → [github/CODEOWNERS.md](github/CODEOWNERS.md)

**Release process** → [github/WORKFLOWS.md](github/WORKFLOWS.md#continuous-deployment-cd)

**CI/CD setup** → [CI_CD_SETUP_GUIDE.md](CI_CD_SETUP_GUIDE.md)

---

## 📖 Guide Purposes

### PRE_COMMIT_GUIDE.md
**When to read**: Setting up development environment, understanding linting architecture

**Key topics**:
- 3-layer quality assurance (VSCode + Pre-commit + CI/CD)
- Performance optimization (1-2s pre-commit)
- 26+ integrated tools
- Local vs CI/CD responsibilities
- Troubleshooting guide

---

### CI_CD_SETUP_GUIDE.md
**When to read**: Setting up CI/CD for first time, adding new workflows

**Key topics**:
- GitHub Actions setup
- Secrets management
- Workflow configuration
- Deployment pipelines
- Environment variables

---

### ROOT_FILES.md
**When to read**: Wondering what a root config file does

**Key topics**:
- Purpose of each file (.codecov.yml, renovate.json, etc.)
- When to modify them
- Configuration examples

---

### ROOT_FOLDERS.md
**When to read**: Understanding monorepo organization

**Key topics**:
- Directory structure
- Naming conventions
- Where to add new code
- Component organization

---

### github/WORKFLOWS.md
**When to read**: Understanding CI/CD pipelines, adding new workflows

**Key topics**:
- All 15 workflows explained
- Trigger patterns
- Job configuration
- Running workflows locally
- Debugging failed workflows

---

### github/ISSUE_TEMPLATE.md
**When to read**: Reporting bugs, requesting features

**Key topics**:
- Using issue templates
- Required information
- Best practices for reporters
- Template customization

---

### github/PULL_REQUEST_TEMPLATE_GUIDE.md
**When to read**: Before submitting your first PR

**Key topics**:
- PR template sections
- Writing good descriptions
- Review process
- Common mistakes
- Examples

---

### github/CODEOWNERS.md
**When to read**: Understanding review process, becoming a code owner

**Key topics**:
- How CODEOWNERS works
- Review requirements
- Ownership patterns
- Best practices for owners

---

### github/FUNDING.md
**When to read**: Supporting the project, setting up sponsorship

**Key topics**:
- Sponsorship platforms
- Benefits for sponsors
- Transparency
- Usage of funds

---

## 🔍 Finding What You Need

### By Topic

| Topic | Start Here |
|-------|-----------|
| **Setting up dev environment** | [PRE_COMMIT_GUIDE.md](PRE_COMMIT_GUIDE.md) |
| **Understanding CI/CD** | [github/WORKFLOWS.md](github/WORKFLOWS.md) |
| **Submitting PRs** | [github/PULL_REQUEST_TEMPLATE_GUIDE.md](github/PULL_REQUEST_TEMPLATE_GUIDE.md) |
| **Reporting issues** | [github/ISSUE_TEMPLATE.md](github/ISSUE_TEMPLATE.md) |
| **Monorepo structure** | [ROOT_FOLDERS.md](ROOT_FOLDERS.md) |
| **Configuration files** | [ROOT_FILES.md](ROOT_FILES.md) |
| **VSCode setup** | [vscode/SETTINGS.md](vscode/SETTINGS.md) |
| **Debugging** | [vscode/LAUNCH.md](vscode/LAUNCH.md) |

### By Role

**👨‍💻 Developer**:
1. [ROOT_FOLDERS.md](ROOT_FOLDERS.md) - Understand structure
2. [PRE_COMMIT_GUIDE.md](PRE_COMMIT_GUIDE.md) - Setup tools
3. [vscode/SETTINGS.md](vscode/SETTINGS.md) - Configure editor

**🤝 Contributor**:
1. [github/ISSUE_TEMPLATE.md](github/ISSUE_TEMPLATE.md) - Report issues
2. [github/PULL_REQUEST_TEMPLATE_GUIDE.md](github/PULL_REQUEST_TEMPLATE_GUIDE.md) - Submit PRs
3. [github/WORKFLOWS.md](github/WORKFLOWS.md) - Understand CI/CD

**👑 Maintainer**:
1. [github/CODEOWNERS.md](github/CODEOWNERS.md) - Manage reviews
2. [CI_CD_SETUP_GUIDE.md](CI_CD_SETUP_GUIDE.md) - Configure CI/CD
3. [github/WORKFLOWS.md](github/WORKFLOWS.md) - Manage pipelines

**💰 Sponsor**:
1. [github/FUNDING.md](github/FUNDING.md) - Support project

---

## 📝 Documentation Standards

All guides in this directory follow these standards:

- ✅ Clear table of contents
- ✅ Code examples with syntax highlighting
- ✅ Step-by-step instructions
- ✅ Troubleshooting sections
- ✅ Links to official documentation
- ✅ Real-world examples
- ✅ Best practices
- ✅ Common mistakes to avoid

---

## 🤝 Contributing to Documentation

Found an error or want to improve a guide?

1. Create issue: [Documentation Improvement](../../.github/issue_template/feature-request.yml)
2. Submit PR with changes
3. Tag with label: `documentation`

---

## 📞 Support

- 📖 **Full Documentation**: `../.doc/docs/`
- 💬 **Discussions**: [GitHub Discussions](../../discussions)
- 🐛 **Issues**: [GitHub Issues](../../issues)

---

<div align="center">

**📚 Knowledge is Power**

Made with ❤️ for developers who care about quality

[Report Issue](../../issues/new?template=bug-report.yml) ·
[Request Feature](../../issues/new?template=feature-request.yml) ·
[Ask Question](../../issues/new?template=question.yml)

</div>
