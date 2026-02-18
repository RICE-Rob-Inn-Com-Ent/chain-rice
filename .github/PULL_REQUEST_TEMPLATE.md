<!--
Thank you for contributing to Rice Monorepo! 🎉
Please fill out this template to help us review your pull request efficiently.
-->

## 📝 Description

<!-- Provide a clear and concise description of what this PR does -->

### What does this PR do?

<!-- Example: Adds real-time WebSocket notifications to the backend service -->

### Why is this change needed?

<!-- Explain the motivation and context for this change -->

### Related Issues

<!-- Link to related issues using #issue_number -->

- Fixes #
- Closes #
- Related to #

---

## 🏷️ Type of Change

<!-- Mark the relevant option with an 'x' -->

- [ ] 🐛 **Bug fix** (non-breaking change that fixes an issue)
- [ ] ✨ **New feature** (non-breaking change that adds functionality)
- [ ] 💥 **Breaking change** (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 **Documentation** (changes to documentation only)
- [ ] 🎨 **Style** (formatting, missing semicolons, etc; no code logic change)
- [ ] ♻️ **Refactor** (code change that neither fixes a bug nor adds a feature)
- [ ] ⚡ **Performance** (code change that improves performance)
- [ ] ✅ **Test** (adding or updating tests)
- [ ] 🔧 **Chore** (updating build tasks, package manager configs, etc)
- [ ] 🔒 **Security** (security-related improvements or fixes)
- [ ] ♿ **Accessibility** (accessibility improvements)
- [ ] 🌐 **Internationalization** (i18n/l10n changes)

---

## 🎯 Component(s) Affected

<!-- Mark all that apply with an 'x' -->

- [ ] Backend - Database Service (Go)
- [ ] Backend - Token Chain (Go/Cosmos)
- [ ] Backend - Rust Smart Contracts
- [ ] Backend - Solidity Smart Contracts
- [ ] Frontend - Web (TypeScript)
- [ ] Frontend - Flutter (Dart)
- [ ] Frontend - Android (Kotlin)
- [ ] Frontend - iOS (Swift)
- [ ] Bot - Core (Python)
- [ ] Bot - Integrations (Python)
- [ ] Schema - Protocol Buffers
- [ ] Infrastructure - Docker/K8s
- [ ] Infrastructure - Terraform/Ansible
- [ ] DevContainer
- [ ] CI/CD - GitHub Actions
- [ ] Documentation
- [ ] Build System - Bazel

---

## 🧪 Testing

### How has this been tested?

<!-- Describe the tests you ran to verify your changes -->

- [ ] **Unit tests** - All existing tests pass
- [ ] **Unit tests** - New tests added for this change
- [ ] **Integration tests** - Tested integration with other components
- [ ] **E2E tests** - End-to-end testing completed
- [ ] **Manual testing** - Manually tested the changes
- [ ] **Load/Performance testing** - Performance impact assessed

### Test Configuration

<!-- Provide details about your test configuration -->

- **OS**: <!-- e.g., Ubuntu 22.04, macOS 14, Windows 11 -->
- **Runtime versions**:
  - Go: <!-- e.g., 1.22.0 -->
  - Python: <!-- e.g., 3.12.1 -->
  - Node.js: <!-- e.g., 20.11.0 -->
  - Rust: <!-- e.g., 1.76.0 -->
  - Other: <!-- any other relevant versions -->
- **Browser** (if applicable): <!-- e.g., Chrome 120, Firefox 121 -->

### Test Evidence

<!-- Provide evidence that your changes work -->

<details>
<summary>Test Results</summary>

```bash
# Paste test output here
# Example: pytest output, go test output, etc.
```

</details>

<details>
<summary>Screenshots/Videos</summary>

<!-- Drag and drop screenshots or videos here -->

</details>

---

## 📋 Checklist

### Code Quality

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My code is formatted with the appropriate formatters (`black`, `gofmt`, `prettier`, etc.)
- [ ] I have run linters and fixed all issues (`ruff`, `golangci-lint`, `eslint`, etc.)
- [ ] I have removed debug code, console.logs, and commented-out code

### Testing

- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] All integration tests pass
- [ ] I have tested on multiple environments/browsers (if applicable)

### Documentation

- [ ] I have updated relevant documentation (README, API docs, architecture docs)
- [ ] I have added/updated code comments where necessary
- [ ] I have updated the CHANGELOG.md (if applicable)
- [ ] I have added/updated examples or usage instructions
- [ ] I have updated relevant OpenAPI/Swagger documentation (if applicable)

### Dependencies

- [ ] I have updated dependency lock files (poetry.lock, go.sum, package-lock.json, Cargo.lock)
- [ ] All new dependencies are necessary and justified
- [ ] I have verified that dependencies have acceptable licenses
- [ ] I have checked for security vulnerabilities in dependencies

### Performance & Security

- [ ] My changes don't introduce performance regressions
- [ ] I have considered security implications of my changes
- [ ] I have not committed secrets, API keys, or sensitive information
- [ ] I have sanitized user inputs and validated data
- [ ] I have followed security best practices (OWASP guidelines)

### Breaking Changes

- [ ] This PR does **NOT** introduce breaking changes
- [ ] OR: I have documented all breaking changes below
- [ ] OR: I have provided a migration guide for breaking changes
- [ ] OR: I have updated the major version number

### Git & Commits

- [ ] My commits follow the Conventional Commits specification
- [ ] My commit messages are clear and descriptive
- [ ] I have rebased on the latest `main` branch
- [ ] I have resolved all merge conflicts
- [ ] My branch is up to date with the base branch

---

## 💥 Breaking Changes

<!-- If this introduces breaking changes, describe them here -->

<details>
<summary>Breaking Changes Details</summary>

### What breaks?

<!-- Describe what functionality will break -->

### Why is this necessary?

<!-- Explain why the breaking change is required -->

### Migration Guide

<!-- Provide step-by-step migration instructions -->

#### Before (Old API/Behavior)

```typescript
// Old code example
```

#### After (New API/Behavior)

```typescript
// New code example
```

### Deprecation Timeline

<!-- When will the old behavior be removed? -->

- [ ] Old behavior will be deprecated in version: X.Y.Z
- [ ] Old behavior will be removed in version: X.Y.Z
- [ ] Documentation updated with deprecation notices

</details>

---

## 📊 Performance Impact

<!-- Describe any performance implications -->

<details>
<summary>Performance Metrics</summary>

### Before

<!-- Baseline performance metrics -->

- **Response time**:
- **Memory usage**:
- **CPU usage**:
- **Bundle size** (if frontend):

### After

<!-- Performance metrics after changes -->

- **Response time**:
- **Memory usage**:
- **CPU usage**:
- **Bundle size** (if frontend):

### Benchmark Results

```bash
# Paste benchmark results here
```

</details>

---

## 🔒 Security Considerations

<!-- Describe any security implications -->

- [ ] This PR does not introduce security vulnerabilities
- [ ] I have run security scans (`trivy`, `gitleaks`, etc.)
- [ ] I have followed OWASP security guidelines
- [ ] I have considered common vulnerabilities (XSS, SQL injection, CSRF, etc.)

<details>
<summary>Security Analysis</summary>

<!-- Provide details about security considerations -->

### Attack Vectors Considered

-

### Mitigations Implemented

-

</details>

---

## 📦 Deployment Notes

<!-- Any special deployment considerations? -->

<details>
<summary>Deployment Instructions</summary>

### Prerequisites

<!-- What needs to be in place before deploying? -->

- [ ] Database migrations required
- [ ] Configuration changes required
- [ ] Environment variables to be added/updated
- [ ] Infrastructure changes required

### Deployment Steps

1.
2.
3.

### Rollback Plan

<!-- How to rollback if something goes wrong -->

1.
2.

### Post-Deployment Verification

<!-- How to verify the deployment was successful -->

- [ ] Check health endpoints
- [ ] Verify logs for errors
- [ ] Run smoke tests
- [ ] Monitor metrics for anomalies

</details>

---

## 🔗 Additional Context

<!-- Any other information that reviewers should know -->

### Screenshots

<!-- Add screenshots if applicable -->

### Related PRs

<!-- Link to related PRs -->

-

### External References

<!-- Links to external resources, RFCs, design docs, etc. -->

-

### Future Improvements

<!-- Known limitations or future enhancements -->

-

---

## 👥 Reviewers

<!-- Tag specific people who should review this PR -->

### Required Reviewers

<!-- Code owners will be automatically assigned based on CODEOWNERS file -->

@mrDinkelman

### Optional Reviewers

<!-- Anyone else whose input would be valuable -->

---

## 📝 Reviewer Notes

<!-- Space for reviewers to add notes -->

### Review Checklist (For Reviewers)

- [ ] Code is readable and maintainable
- [ ] Tests are comprehensive and meaningful
- [ ] Documentation is clear and complete
- [ ] No security vulnerabilities introduced
- [ ] Performance is acceptable
- [ ] Architecture aligns with project goals
- [ ] Edge cases are handled
- [ ] Error handling is appropriate

---

<!--
🎉 Thank you for your contribution!

After submitting this PR:
1. Ensure all CI checks pass (build, test, lint, security)
2. Respond to reviewer feedback promptly
3. Keep the PR updated with the latest changes from main
4. Be patient - reviews may take some time

For questions or help, please:
- Comment on this PR
- Ask in GitHub Discussions
- Check the contributing guide

-->

---

**By submitting this pull request, I confirm that my contribution is made under the terms of the project's license and I
have read and agree to the [Code of Conduct](../blob/main/.doc/docs/CODE_OF_CONDUCT.md).**
