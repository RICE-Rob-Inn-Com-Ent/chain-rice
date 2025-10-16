# 🚀 CI/CD Setup Guide - Rice Monorepo

## Overview

This guide helps you set up and configure the CI/CD pipeline for Rice Monorepo.

## Prerequisites

- GitHub repository with Actions enabled
- Admin access to repository
- Basic understanding of GitHub Actions

## Quick Setup (5 minutes)

### 1. Enable GitHub Actions

GitHub Actions should be enabled by default. Verify in:

```text
Repository Settings → Actions → General → Allow all actions
```

### 2. Configure Secrets

Navigate to: **Settings → Secrets and variables → Actions**

No secrets required for basic CI/CD! 🎉

Optional secrets for advanced features:

```yaml
# For NPM publishing (optional)
NPM_TOKEN: your_npm_token

# For Docker Hub (optional)
DOCKER_HUB_TOKEN: your_docker_token
DOCKER_HUB_USERNAME: your_username

# For SonarCloud (optional)
SONAR_TOKEN: your_sonar_token
```

### 3. Verify Workflows

Push a commit and check the **Actions** tab:

```bash
git add .
git commit -m "test: verify CI/CD works"
git push
```

You should see workflows running!

## Workflows Overview

### Continuous Integration

| Workflow           | Trigger  | Duration  | Purpose                |
| ------------------ | -------- | --------- | ---------------------- |
| `ci-build.yml`     | Push, PR | ~5-10min  | Build verification     |
| `ci-test.yml`      | Push, PR | ~10-15min | Test execution         |
| `ci-lint.yml`      | Push, PR | ~3-5min   | Code quality (14 jobs) |
| `ci-typecheck.yml` | Push, PR | ~5min     | Type safety            |
| `ci-format.yml`    | Push, PR | ~2min     | Format verification    |

### Continuous Deployment

| Workflow               | Trigger      | Duration  | Purpose            |
| ---------------------- | ------------ | --------- | ------------------ |
| `cd-release.yml`       | Tag `v*.*.*` | ~15-20min | Release automation |
| `cd-sync-subrepos.yml` | Push to main | ~5min     | Subrepo sync       |

### Security

| Workflow           | Trigger          | Duration  | Purpose              |
| ------------------ | ---------------- | --------- | -------------------- |
| `sec-audit.yml`    | Push, PR, Weekly | ~5-10min  | Dependency audit     |
| `sec-codeql.yml`   | Push, PR, Weekly | ~10-15min | Code scanning (SAST) |
| `sec-trivy.yml`    | Push, PR, Daily  | ~5min     | Container scanning   |
| `sec-gitleaks.yml` | Push, PR         | ~2min     | Secret detection     |

### Utilities

| Workflow          | Trigger      | Duration | Purpose            |
| ----------------- | ------------ | -------- | ------------------ |
| `meta-stale.yml`  | Daily        | ~1min    | Close stale issues |
| `docs-deploy.yml` | Push to main | ~3min    | Deploy docs        |
| `codecov.yml`     | Push, PR     | ~2min    | Coverage reporting |
| `sonarcloud.yml`  | Push, PR     | ~5-10min | Quality analysis   |

## Configuration Files

### Root Level

```text
.codecov.yml               - Code coverage settings
renovate.json              - Dependency updates
sonar-project.properties   - SonarCloud quality gates
```

### Per-Language

```text
.bot/
├── ruff.toml              - Python linter config
└── pyproject.toml         - Python tools config

.backend/
└── .golangci.yml          - Go linter config

.frontend/web/
└── .eslintrc.js           - TypeScript linter config

.backend/contract/rust/
├── .clippy.toml           - Rust linter config
└── .rustfmt.toml          - Rust formatter config
```

## Customization

### Adding a New Workflow

1. Create file in `.github/workflows/`:

```yaml
name: My New Workflow

on:
  push:
    branches: [main]

jobs:
  my-job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run command
        run: echo "Hello World"
```

2. Commit and push
3. Check Actions tab

### Modifying Existing Workflow

1. Edit workflow file in `.github/workflows/`
2. Test locally with [act](https://github.com/nektos/act):

```bash
act -j job-name
```

3. Commit and verify in Actions tab

### Disabling a Workflow

Add to workflow file:

```yaml
on:
  workflow_dispatch: # Manual only
```

Or delete/rename the file.

## Advanced Features

### Matrix Builds

Run same job with different parameters:

```yaml
strategy:
  matrix:
    component: [db, token]
    go-version: ["1.21", "1.22"]

steps:
  - name: Build
    run: go build ./...
    working-directory: .backend/${{ matrix.component }}
```

### Caching

Speed up workflows with caching:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/poetry.lock') }}
```

### Artifacts

Save build outputs:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 7
```

## Troubleshooting

### Workflow Not Running

1. Check workflow file is valid YAML
2. Verify trigger conditions match
3. Check Actions tab for errors
4. Ensure Actions are enabled in settings

### Permission Errors

Add permissions to workflow:

```yaml
permissions:
  contents: read
  pull-requests: write
```

### Slow Workflows

1. Use caching for dependencies
2. Run jobs in parallel
3. Use matrix strategy for similar jobs
4. Cancel old runs with `cancel-in-progress: true`

### Failed Jobs

1. Check job logs in Actions tab
2. Run commands locally to reproduce
3. Check for environment differences
4. Verify all dependencies are available

## Best Practices

### Performance

- ✅ Use caching for dependencies
- ✅ Run independent jobs in parallel
- ✅ Cancel old runs on new push
- ✅ Use matrix for similar jobs
- ✅ Fail fast when appropriate

### Security

- ✅ Use minimal permissions
- ✅ Pin action versions (`@v4`, not `@main`)
- ✅ Scan dependencies regularly
- ✅ Never commit secrets
- ✅ Use GitHub secrets for sensitive data

### Maintenance

- ✅ Keep action versions updated
- ✅ Monitor workflow execution times
- ✅ Review failed workflows promptly
- ✅ Document custom workflows
- ✅ Test changes locally first

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [act - Run workflows locally](https://github.com/nektos/act)
- [Workflow Examples](https://github.com/actions/starter-workflows)

---

**Made with ❤️ for Rice Monorepo** Last updated: October 2025
