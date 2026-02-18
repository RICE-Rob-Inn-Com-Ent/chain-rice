package king

// =============================================================================
// KING FOLDERS (DOTFOLDERS AT ROOT)
// =============================================================================
//
// Single source of truth for root dotfolders.
// - .github: generated from CUE only (github_files below); no infra/github folder.
// - Other dotfolders: copied from infra (king_folder_outputs).
//
// Manifest (infra/manifest.cue) writes king_folder_file_outputs then syncs king_folder_outputs.
// =============================================================================

// -----------------------------------------------------------------------------
// .github – wszystkie pliki zdefiniowane tutaj (bez fizycznego infra/github)
// -----------------------------------------------------------------------------
github_files: {
	"CODEOWNERS": """
		# CODEOWNERS file for Rice Monorepo

		# Defines code ownership for automated review requests

		# See: <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners>

		# Default owner for everything (unless overridden below)

		- @mrDinkelman

		# Documentation files

		*.md @mrDinkelman
		/docs/ @mrDinkelman
		README @mrDinkelman
		CONTRIBUTING @mrDinkelman
		CODE_OF_CONDUCT @mrDinkelman
		SECURITY @mrDinkelman
		ARCHITECTURE @mrDinkelman
		CHANGELOG @mrDinkelman

		# Root configuration files

		/.editorconfig @mrDinkelman
		/.gitignore @mrDinkelman
		/.gitattributes @mrDinkelman
		/.devcontainer/node/.prettierrc* @mrDinkelman
		/.eslintrc* @mrDinkelman
		/.devcontainer/node/.releaserc.js @mrDinkelman
		/renovate.json @mrDinkelman
		/.devcontainer/node/tsconfig.json @mrDinkelman

		# Bazel build system

		/BUILD.bazel @mrDinkelman
		/MODULE.bazel @mrDinkelman
		/WORKSPACE @mrDinkelman
		/.bazelrc @mrDinkelman
		/rules/ @mrDinkelman

		# CI/CD and DevOps

		/.github/ @mrDinkelman
		/.circleci/ @mrDinkelman
		/.gitlab-ci.yml @mrDinkelman
		/Makefile @mrDinkelman
		/docker-compose.yml @mrDinkelman
		/Dockerfile @mrDinkelman
		/dev/terraform/ @mrDinkelman
		/dev/k8s/ @mrDinkelman

		# Backend - Go services

		/backend/**/*.go @mrDinkelman
		/backend/**/go.mod @mrDinkelman
		/backend/**/go.sum @mrDinkelman
		/backend/db/ @mrDinkelman
		/backend/token/ @mrDinkelman

		# Backend - Rust smart contracts

		/backend/contract/rust/ @mrDinkelman
		/backend/contract/rust/**/*.rs @mrDinkelman
		/backend/contract/rust/**/Cargo.toml @mrDinkelman

		# Backend - Solidity smart contracts

		/backend/contract/solidity/ @mrDinkelman
		/backend/contract/solidity/**/*.sol @mrDinkelman
		/backend/contract/solidity/**/hardhat.config.js @mrDinkelman

		# Frontend - Node.js/TypeScript applications

		/frontend/node/ @mrDinkelman
		/frontend/node/**/*.ts @mrDinkelman
		/frontend/node/**/*.tsx @mrDinkelman
		/frontend/node/**/*.js @mrDinkelman
		/frontend/node/**/*.jsx @mrDinkelman
		/frontend/node/angular/ @mrDinkelman
		/frontend/node/next/ @mrDinkelman
		/frontend/node/nuxt/ @mrDinkelman
		/frontend/node/svelte/ @mrDinkelman
		/frontend/node/shared/ @mrDinkelman

		# Frontend - Dart/Flutter

		/frontend/dart/ @mrDinkelman
		/frontend/dart/**/*.dart @mrDinkelman
		/frontend/dart/**/pubspec.yaml @mrDinkelman

		# Bots and AI services

		/bots/core/ @mrDinkelman
		/bots/core/**/*.py @mrDinkelman
		/bots/integration/ @mrDinkelman
		/bots/integration/**/*.py @mrDinkelman
		/bots/**/pyproject.toml @mrDinkelman
		/bots/**/poetry.lock @mrDinkelman
		/bots/**/requirements.txt @mrDinkelman

		# Protocol Buffers

		/proto/ @mrDinkelman
		/proto/**/*.proto @mrDinkelman

		# Security and compliance files

		SECURITY @mrDinkelman
		/.secrets.baseline @mrDinkelman
		/.snyk @mrDinkelman
		/.pre-commit-config.yaml @mrDinkelman

		# Dependency lock files

		package.json @mrDinkelman
		package-lock.json @mrDinkelman
		yarn.lock @mrDinkelman
		pnpm-lock.yaml @mrDinkelman
		**/pyproject.toml @mrDinkelman
		**/poetry.lock @mrDinkelman
		**/requirements.txt @mrDinkelman
		**/go.mod @mrDinkelman
		**/go.sum @mrDinkelman
		**/Cargo.toml @mrDinkelman
		**/Cargo.lock @mrDinkelman
		**/pubspec.yaml @mrDinkelman
		**/pubspec.lock @mrDinkelman

		# Test files

		**/*.test.* @mrDinkelman
		**/*.spec.* @mrDinkelman
		**/test/ @mrDinkelman
		**/tests/ @mrDinkelman

		# License and security policy

		/LICENSE @mrDinkelman
		/SECURITY.md @mrDinkelman
		"""

	"FUNDING.yml": """
		# 💰 Funding & Sponsorship Configuration
		# https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/displaying-a-sponsor-button-in-your-repository

		# GitHub Sponsors
		# https://github.com/sponsors
		github: [mrDinkelman]

		# Patreon
		# https://www.patreon.com/
		patreon: rice-mono

		# Open Collective
		# https://opencollective.com/
		open_collective: rice-mono

		# Ko-fi
		# https://ko-fi.com/
		ko_fi: mrdinkelman

		# Tidelift
		# https://tidelift.com/
		# tidelift: npm/rice-mono

		# Community Bridge
		# https://communitybridge.org/
		# community_bridge: rice-mono

		# Liberapay
		# https://liberapay.com/
		liberapay: mrDinkelman

		# IssueHunt
		# https://issuehunt.io/
		# issuehunt: rice-mono

		# Buy Me a Coffee
		# https://www.buymeacoffee.com/
		# buy_me_a_coffee: mrdinkelman

		# Otechie
		# https://otechie.com/
		# otechie: rice-mono

		# Custom sponsorship URLs
		custom:
		  - https://github.com/mrDinkelman/rice-mono/blob/main/.doc/docs/CONTRIBUTING.md#sponsorship
		  # Cryptocurrency donations
		  - https://github.com/mrDinkelman/rice-mono/wiki/Crypto-Donations
		  # Bank transfer / Wire transfer
		  - https://github.com/mrDinkelman/rice-mono/wiki/Bank-Transfer
		"""

	"PULL_REQUEST_TEMPLATE.md": """
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
		"""

	"issue_template/config.yml": """
		blank_issues_enabled: false
		contact_links:
		  - name: 💬 GitHub Discussions
		    url: https://github.com/mrDinkelman/rice-mono/discussions
		    about: Ask questions, share ideas, and connect with the community

		  - name: 📚 Documentation
		    url: https://github.com/mrDinkelman/rice-mono/tree/main/.doc/docs
		    about: Browse comprehensive documentation, guides, and architecture details

		  - name: 🔒 Security Vulnerability
		    url: https://github.com/mrDinkelman/rice-mono/security/advisories/new
		    about: Report security vulnerabilities privately (DO NOT create a public issue)

		  - name: 💡 Feature Discussions
		    url: https://github.com/mrDinkelman/rice-mono/discussions/categories/ideas
		    about: Discuss feature ideas with the community before creating a formal request

		  - name: 🗺️ Project Roadmap
		    url: https://github.com/mrDinkelman/rice-mono/discussions/categories/roadmap
		    about: View the project roadmap and planned features

		  - name: 🎓 Contributing Guide
		    url: https://github.com/mrDinkelman/rice-mono/blob/main/.doc/docs/CONTRIBUTING.md
		    about: Learn how to contribute to Rice Monorepo

		  - name: 📖 Architecture Documentation
		    url: https://github.com/mrDinkelman/rice-mono/blob/main/.doc/docs/ARCHITECTURE.md
		    about: Understand the architecture and design decisions

		  - name: 🐛 Stack Overflow
		    url: https://stackoverflow.com/questions/tagged/rice-mono
		    about: Ask technical questions on Stack Overflow with the 'rice-mono' tag
		"""

	"issue_template/bug-report.yml":      _bug_report_yml
	"issue_template/feature-request.yml": _feature_request_yml
	"issue_template/question.yml":        _question_yml
	"workflows/cd-project.yml":           _workflow_cd_project
	"workflows/cd-release.yml":           _workflow_cd_release
	"workflows/cd-sec.yml":               _workflow_cd_sec
	"workflows/ci-build.yml": """
		name: Build

		on:
		  workflow_call:
		  workflow_dispatch:

		permissions:
		  contents: read

		jobs:
		  make-build:
		    name: make build
		    runs-on: ubuntu-latest
		    timeout-minutes: 90

		    steps:
		      - name: Checkout repository
		        uses: actions/checkout@v4
		        with:
		          fetch-depth: 0

		      - name: Install build prerequisites
		        run: |
		          sudo apt-get update
		          sudo apt-get install -y python3 python3-pip jq
		          pip3 install --user poetry
		          echo "$HOME/.local/bin" >> "$GITHUB_PATH"

		      - name: Verify Docker
		        run: docker info

		      - name: Prepare environment
		        run: just config-workspace || true

		      - name: Execute build
		        env:
		          CI: "true"
		        run: just install && just c full || true
		"""
	"workflows/ci-format.yml":    _workflow_ci_format
	"workflows/ci-lint.yml":      _workflow_ci_lint
	"workflows/ci-test.yml":      _workflow_ci_test
	"workflows/ci-typecheck.yml": _workflow_ci_typecheck
	"workflows/deploy-aks.yml":   _workflow_deploy_aks
	"workflows/deploy-eks.yml":   _workflow_deploy_eks
	"workflows/deploy-gke.yml":   _workflow_deploy_gke
	"workflows/docs-deploy.yml": """
		name: Deploy Documentation

		on:
		    push:
		        branches: [main]
		        paths:
		            - ".doc/**"
		            - ".github/workflows/docs-deploy.yml"
		    workflow_dispatch:

		permissions:
		    contents: read
		    pages: write
		    id-token: write

		concurrency:
		    group: "pages"
		    cancel-in-progress: false

		jobs:
		    build:
		        name: Build Documentation
		        runs-on: ubuntu-latest
		        timeout-minutes: 15

		        steps:
		            - name: Checkout code
		              uses: actions/checkout@v4
		              with:
		                  fetch-depth: 0

		            - name: Set up Python
		              uses: actions/setup-python@v5
		              with:
		                  python-version: "3.12"
		                  cache: "pip"

		            - name: Install MkDocs and dependencies
		              run: |
		                  pip install \\
		                    mkdocs \\
		                    mkdocs-material \\
		                    mkdocs-mermaid2-plugin \\
		                    mkdocs-git-revision-date-localized-plugin \\
		                    mkdocs-minify-plugin \\
		                    pymdown-extensions \\
		                    mkdocs-awesome-pages-plugin

		            - name: Setup Pages
		              uses: actions/configure-pages@v4

		            - name: Build documentation
		              working-directory: .doc
		              run: |
		                  mkdocs build --strict --verbose

		            - name: Generate API documentation
		              run: |
		                  # Generate Go documentation
		                  echo "Generating Go API docs..."
		                  # Add godoc generation here

		                  # Generate Python documentation
		                  echo "Generating Python API docs..."
		                  # Add sphinx/pydoc generation here

		                  # Generate TypeScript documentation
		                  echo "Generating TypeScript API docs..."
		                  # Add typedoc generation here

		            - name: Upload artifact
		              uses: actions/upload-pages-artifact@v3
		              with:
		                  path: .doc/site

		    deploy:
		        name: Deploy to GitHub Pages
		        environment:
		            name: github-pages
		            url: ${{ steps.deployment.outputs.page_url }}
		        runs-on: ubuntu-latest
		        needs: build

		        steps:
		            - name: Deploy to GitHub Pages
		              id: deployment
		              uses: actions/deploy-pages@v4

		            - name: Create deployment summary
		              run: |
		                  echo "## 📚 Documentation Deployed" >> $GITHUB_STEP_SUMMARY
		                  echo "" >> $GITHUB_STEP_SUMMARY
		                  echo "🔗 **URL**: ${{ steps.deployment.outputs.page_url }}" >> $GITHUB_STEP_SUMMARY
		                  echo "" >> $GITHUB_STEP_SUMMARY
		                  echo "✅ Documentation successfully deployed to GitHub Pages!" >> $GITHUB_STEP_SUMMARY
		"""

	"workflows/meta-stale.yml": """
		name: Stale Issues and PRs

		on:
		    schedule:
		        - cron: "0 0 * * *"
		    workflow_dispatch:

		jobs:
		    project-context:
		        name: Load Project Context
		        runs-on: ubuntu-latest
		        steps:
		            - uses: actions/checkout@v4
		              with:
		                  fetch-depth: 0
		            - name: Load project context
		              id: context
		              uses: ./.github/actions/project-context
		            - name: Record project summary
		              run: |
		                  echo "### Project Context" >> $GITHUB_STEP_SUMMARY
		                  echo "" >> $GITHUB_STEP_SUMMARY
		                  echo "- Active project: **${{ steps.context.outputs.active_project_name || steps.context.outputs.active_project }}**" >> $GITHUB_STEP_SUMMARY

		    stale:
		        name: Mark Stale Issues and PRs
		        runs-on: ubuntu-latest
		        needs: project-context
		        permissions:
		            issues: write
		            pull-requests: write

		        steps:
		            - uses: actions/stale@v8
		              with:
		                  repo-token: ${{ secrets.GITHUB_TOKEN }}

		                  stale-issue-message: |
		                      This issue has been automatically marked as stale because it has not had
		                      recent activity. It will be closed if no further activity occurs within
		                      the next 7 days. Thank you for your contributions.
		                  close-issue-message: |
		                      This issue has been automatically closed due to inactivity.
		                      Please feel free to reopen if this is still relevant.
		                  stale-issue-label: "stale"
		                  exempt-issue-labels: "pinned,security,bug,enhancement"
		                  days-before-issue-stale: 60
		                  days-before-issue-close: 7

		                  stale-pr-message: |
		                      This pull request has been automatically marked as stale because it has
		                      not had recent activity. It will be closed if no further activity occurs
		                      within the next 7 days. Thank you for your contributions.
		                  close-pr-message: |
		                      This pull request has been automatically closed due to inactivity.
		                      Please feel free to reopen if you plan to continue working on this.
		                  stale-pr-label: "stale"
		                  exempt-pr-labels: "pinned,security,work-in-progress"
		                  days-before-pr-stale: 30
		                  days-before-pr-close: 7

		                  operations-per-run: 100
		                  remove-stale-when-updated: true
		                  ascending: false
		"""
}

// king_folder_file_outputs: lista {path, content} do zapisania przez manifest (np. .github/ z CUE).
king_folder_file_outputs: [for p, c in github_files {path: ".github/\(p)", content: c}]

// king_folder_outputs: tylko kopiowanie z infra (bez .github – .github z king_folder_file_outputs).
king_folder_outputs: [
	{source: "infra/kubernetes", target: ".kubernetes"},
	{source: "infra/terraform", target: ".terraform"},
	{source: "infra/reuse", target: ".reuse"},
	{source: "infra/markdown/devcontainer/vscode", target: ".vscode"},
]
