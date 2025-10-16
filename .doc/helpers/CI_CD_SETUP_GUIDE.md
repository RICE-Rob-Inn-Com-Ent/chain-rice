# 🚀 CI/CD Setup Guide - Rice Monorepo

> Complete guide to setting up all CI/CD integrations

---

## ✅ What You Already Have (Configured)

### Files in Place

```
✅ .codecov.yml                  - Codecov configuration
✅ renovate.json                 - Renovate Bot configuration
✅ sonar-project.properties      - SonarCloud configuration
```

### Workflows Active

```
✅ ci-build.yml          - Build verification
✅ ci-test.yml           - Test execution
✅ ci-lint.yml           - Code quality checks
✅ ci-typecheck.yml      - Type checking
✅ ci-format.yml         - Format verification
✅ cd-release.yml        - Release automation
✅ cd-sync-subrepos.yml  - Subrepo sync
✅ sec-audit.yml         - Security audits
✅ sec-codeql.yml        - CodeQL scanning
✅ sec-trivy.yml         - Container scanning
✅ sec-gitleaks.yml      - Secret detection
✅ docs-deploy.yml       - Documentation deployment
✅ meta-stale.yml        - Stale issue management
✅ sonarcloud.yml        - SonarCloud analysis (NEW!)
✅ codecov.yml           - Code coverage upload (NEW!)
```

---

## 🔐 Required Tokens/Secrets

You need to configure these in GitHub Settings → Secrets → Actions:

### 1. **SONAR_TOKEN** (SonarCloud)

**Time**: 5 minutes | **Cost**: FREE

```
SETUP:
1. Go to: https://sonarcloud.io/
2. Click "Log in with GitHub"
3. Click "Analyze new project"
4. Select "rice-mono" repository
5. Choose "With GitHub Actions"
6. Copy the SONAR_TOKEN
7. Go to GitHub: repo → Settings → Secrets → Actions → New secret
   Name: SONAR_TOKEN
   Value: [paste token]
```

### 2. **CODECOV_TOKEN** (Code Coverage)

**Time**: 3 minutes | **Cost**: FREE

```
SETUP:
1. Go to: https://codecov.io/login/gh
2. Click "Log in with GitHub"
3. Click "Add repository" → select rice-mono
4. Copy the token shown
5. Go to GitHub: repo → Settings → Secrets → Actions → New secret
   Name: CODECOV_TOKEN
   Value: [paste token]
```

### 3. **SNYK_TOKEN** (Security Scanning) - Optional

**Time**: 5 minutes | **Cost**: FREE for open source

```
SETUP:
1. Go to: https://app.snyk.io/signup
2. Click "Sign up with GitHub"
3. Account Settings → API Token → Show → Copy
4. Go to GitHub: repo → Settings → Secrets → Actions → New secret
   Name: SNYK_TOKEN
   Value: [paste token]
```

### 4. **NPM_TOKEN** (NPM Publishing) - Optional

**Time**: 3 minutes | **Cost**: FREE

```
SETUP (only if you want to publish to NPM):
1. Go to: https://www.npmjs.com/signup
2. Settings → Access Tokens → Generate New Token → Automation
3. Copy token
4. Go to GitHub: repo → Settings → Secrets → Actions → New secret
   Name: NPM_TOKEN
   Value: [paste token]
```

---

## 🤖 Automated Bots Setup

### Renovate Bot (Dependency Updates)

**Status**: ✅ CONFIGURED (renovate.json exists)

**Activation** (one-time):

```
1. Go to: https://github.com/apps/renovate
2. Click "Install" or "Configure"
3. Select "rice-mono" repository
4. Click "Install"
5. Bot will create first PR with configuration
6. Merge that PR
```

**What it does**:

- Weekly dependency updates (Mondays at 6 AM UTC)
- Auto-groups minor/patch updates
- Requires manual review for major updates
- Supports: Python, Go, Node.js, Rust, Terraform, Docker, GitHub Actions

---

### DeepSource (AI Code Review) - Optional

**Time**: 5 minutes | **Cost**: FREE

```
1. Go to: https://deepsource.io/signup/
2. Click "Continue with GitHub"
3. Click "Activate repository" → rice-mono
4. Select languages: Python, Go, JavaScript, Rust
5. Click "Activate"
```

---

## 📊 README Badges

Add these to your README.md for professional look:

### Status Badges

```markdown
<!-- Build & Test Status -->

![Build](https://img.shields.io/github/actions/workflow/status/mrDinkelman/rice-mono/ci-build.yml?branch=main&label=build)
![Tests](https://img.shields.io/github/actions/workflow/status/mrDinkelman/rice-mono/ci-test.yml?branch=main&label=tests)
![Security](https://img.shields.io/github/actions/workflow/status/mrDinkelman/rice-mono/sec-codeql.yml?branch=main&label=security)

<!-- Code Quality -->

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=rice-mono&metric=alert_status)](https://sonarcloud.io/dashboard?id=rice-mono)
[![codecov](https://codecov.io/gh/mrDinkelman/rice-mono/branch/main/graph/badge.svg)](https://codecov.io/gh/mrDinkelman/rice-mono)

<!-- Repository Info -->

![License](https://img.shields.io/github/license/mrDinkelman/rice-mono)
![Languages](https://img.shields.io/github/languages/count/mrDinkelman/rice-mono)
![Top Language](https://img.shields.io/github/languages/top/mrDinkelman/rice-mono)
![Code Size](https://img.shields.io/github/languages/code-size/mrDinkelman/rice-mono)
![Last Commit](https://img.shields.io/github/last-commit/mrDinkelman/rice-mono)

<!-- Community -->

![Contributors](https://img.shields.io/github/contributors/mrDinkelman/rice-mono)
![Issues](https://img.shields.io/github/issues/mrDinkelman/rice-mono)
![Pull Requests](https://img.shields.io/github/issues-pr/mrDinkelman/rice-mono)
![Stars](https://img.shields.io/github/stars/mrDinkelman/rice-mono?style=social)
```

**Note**: Replace `mrDinkelman/rice-mono` with your actual GitHub username/repo!

---

## 📋 Quick Setup Checklist

### Priority 1 - Must Have (15 minutes)

```
☐ Setup SONAR_TOKEN       (5 min)
☐ Setup CODECOV_TOKEN     (3 min)
☐ Activate Renovate Bot   (3 min)
☐ Add badges to README    (4 min)
```

### Priority 2 - Recommended (10 minutes)

```
☐ Setup SNYK_TOKEN        (5 min)
☐ Setup DeepSource        (5 min)
```

### Priority 3 - Optional (5 minutes)

```
☐ Setup NPM_TOKEN         (3 min) - only if publishing
☐ Setup WakaTime          (2 min) - time tracking
```

---

## 🔍 Verify Everything Works

After setting up tokens, check:

### 1. **Workflows are Running**

```
Go to: GitHub → Actions tab
You should see workflows running automatically
```

### 2. **SonarCloud Integration**

```
Go to: https://sonarcloud.io/
Login → Check rice-mono project
Should show analysis results
```

### 3. **Codecov Integration**

```
Go to: https://codecov.io/gh/mrDinkelman/rice-mono
Should show coverage graphs
```

### 4. **Renovate Bot**

```
Check for PR from Renovate Bot
Usually appears within 24h of activation
```

---

## 🎯 What Each Tool Does

| Tool           | Purpose                               | Impact                      |
| -------------- | ------------------------------------- | --------------------------- |
| **SonarCloud** | Code quality, bugs, security hotspots | Prevents bad code merging   |
| **Codecov**    | Test coverage tracking                | Ensures tests exist         |
| **Renovate**   | Automated dependency updates          | Keeps dependencies secure   |
| **Snyk**       | Security vulnerability scanning       | Finds security issues       |
| **DeepSource** | AI-powered code review                | Suggests improvements       |
| **CodeQL**     | Security analysis                     | Finds exploits              |
| **Trivy**      | Container security                    | Scans Docker images         |
| **GitLeaks**   | Secret detection                      | Prevents leaked credentials |

---

## 🚨 Important Notes

### Renovate vs Dependabot

```
✅ You have Renovate configured - IT'S BETTER than Dependabot
❌ Don't add Dependabot - they conflict with each other
✅ Renovate is smarter: groups updates, better UI, more features
```

### File Locations (All Correct!)

```
✅ renovate.json              → Root directory (correct)
✅ sonar-project.properties   → Root directory (correct)
✅ .codecov.yml               → Root directory (correct)
✅ All workflows              → .github/workflows/ (correct)
```

### Token Security

```
⚠️ NEVER commit tokens to git
✅ Always use GitHub Secrets
✅ Tokens with continue-on-error: true won't break builds if missing
```

---

## 💡 Pro Tips

### 1. Start Small

```
Day 1: SonarCloud + Codecov + Renovate (core quality tools)
Day 2: Add badges to README
Day 3: Optional tools (Snyk, DeepSource)
```

### 2. Badge Placement

```
Put badges at the top of README.md
Use shields.io for custom badges
Group by category (build, quality, community)
```

### 3. Workflow Monitoring

```
Check Actions tab daily first week
Fix any failing workflows immediately
Read Renovate PRs before merging
```

### 4. SonarCloud Configuration

```
sonar-project.properties is already configured for:
- All languages in your monorepo
- Proper exclusions (node_modules, etc)
- Coverage reporting
- Quality gates
```

---

## 📚 Official Documentation

- [SonarCloud Docs](https://docs.sonarcloud.io/)
- [Codecov Docs](https://docs.codecov.com/)
- [Renovate Docs](https://docs.renovatebot.com/)
- [Snyk Docs](https://docs.snyk.io/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Shields.io](https://shields.io/)

---

## ❓ FAQ

**Q: Which tokens are absolutely required?**
A: Only SONAR_TOKEN and CODECOV_TOKEN for core quality tracking.

**Q: What if I don't add a token?**
A: Workflows will skip that step (continue-on-error: true). No breaking.

**Q: Renovate or Dependabot?**
A: You have Renovate - it's better! Don't add Dependabot.

**Q: Where do I add tokens?**
A: GitHub → Your repo → Settings → Secrets and variables → Actions → New repository secret

**Q: Are all these tools free?**
A: YES! 100% free for open source projects.

**Q: How long does setup take?**
A: 15-30 minutes for everything.

---

## 🎉 You're Done

Once you've added the tokens and activated Renovate, your CI/CD is complete!

Check the Actions tab to see everything running automatically. 🚀

---

<div align="center">

**Questions?** Open an issue or check the [main CI/CD README](../../.github/README.md)

</div>
