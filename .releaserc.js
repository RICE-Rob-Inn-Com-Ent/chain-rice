/**
 * ╔════════════════════════════════════════════════════════════════════════════╗
 * ║                    SEMANTIC RELEASE CONFIGURATION                          ║
 * ║                         RICE MONOREPO                                      ║
 * ╚════════════════════════════════════════════════════════════════════════════╝
 *
 * Enterprise-grade semantic versioning and release automation
 * Supports: Go, Rust, Python, Node.js, Dart, Kotlin, Swift, Solidity, Terraform, K8s, Ansible
 */

module.exports = {
  // ============================================================================
  // BRANCH CONFIGURATION
  // ============================================================================
  branches: [
    "main", // Production releases
    { name: "develop", prerelease: true }, // Development prereleases
    { name: "beta", prerelease: true }, // Beta testing
    { name: "alpha", prerelease: true }, // Alpha testing
    { name: "rc", prerelease: "rc" }, // Release candidates
  ],

  // ============================================================================
  // PLUGINS CONFIGURATION
  // ============================================================================
  plugins: [
    // ==========================================================================
    // COMMIT ANALYZER - Parse commits and determine release type
    // ==========================================================================
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits",
        releaseRules: [
          // ====================================================================
          // 🏗️ INFRASTRUCTURE - DevOps & Cloud
          // ====================================================================

          // Ansible (Configuration Management)
          { type: "feat", scope: "dev/ansible", release: "minor" },
          { type: "fix", scope: "dev/ansible", release: "patch" },
          { type: "perf", scope: "dev/ansible", release: "patch" },
          { type: "refactor", scope: "dev/ansible", release: "patch" },
          { type: "docs", scope: "dev/ansible", release: "patch" },
          { type: "style", scope: "dev/ansible", release: "patch" },
          { type: "test", scope: "dev/ansible", release: "patch" },
          { type: "chore", scope: "dev/ansible", release: "patch" },
          { type: "build", scope: "dev/ansible", release: "patch" },
          { type: "ci", scope: "dev/ansible", release: "patch" },
          { type: "ansible", scope: "dev/ansible", release: "patch" },

          // Kubernetes (Container Orchestration)
          { type: "feat", scope: "dev/k8s", release: "minor" },
          { type: "fix", scope: "dev/k8s", release: "patch" },
          { type: "perf", scope: "dev/k8s", release: "patch" },
          { type: "refactor", scope: "dev/k8s", release: "patch" },
          { type: "docs", scope: "dev/k8s", release: "patch" },
          { type: "style", scope: "dev/k8s", release: "patch" },
          { type: "test", scope: "dev/k8s", release: "patch" },
          { type: "chore", scope: "dev/k8s", release: "patch" },
          { type: "build", scope: "dev/k8s", release: "patch" },
          { type: "ci", scope: "dev/k8s", release: "patch" },
          { type: "k8s", scope: "dev/k8s", release: "patch" },

          // Terraform (Infrastructure as Code)
          { type: "feat", scope: "dev/terraform", release: "minor" },
          { type: "fix", scope: "dev/terraform", release: "patch" },
          { type: "perf", scope: "dev/terraform", release: "patch" },
          { type: "refactor", scope: "dev/terraform", release: "patch" },
          { type: "docs", scope: "dev/terraform", release: "patch" },
          { type: "style", scope: "dev/terraform", release: "patch" },
          { type: "test", scope: "dev/terraform", release: "patch" },
          { type: "chore", scope: "dev/terraform", release: "patch" },
          { type: "build", scope: "dev/terraform", release: "patch" },
          { type: "ci", scope: "dev/terraform", release: "patch" },
          { type: "terraform", scope: "dev/terraform", release: "patch" },

          // ====================================================================
          // 🗄️ BACKEND - Databases, Tokens & Smart Contracts
          // ====================================================================

          // Database Layer
          { type: "feat", scope: "backend/db", release: "minor" },
          { type: "fix", scope: "backend/db", release: "patch" },
          { type: "perf", scope: "backend/db", release: "patch" },
          { type: "refactor", scope: "backend/db", release: "patch" },
          { type: "docs", scope: "backend/db", release: "patch" },
          { type: "style", scope: "backend/db", release: "patch" },
          { type: "test", scope: "backend/db", release: "patch" },
          { type: "chore", scope: "backend/db", release: "patch" },
          { type: "build", scope: "backend/db", release: "patch" },
          { type: "ci", scope: "backend/db", release: "patch" },

          // Token Service
          { type: "feat", scope: "backend/token", release: "minor" },
          { type: "fix", scope: "backend/token", release: "patch" },
          { type: "perf", scope: "backend/token", release: "patch" },
          { type: "refactor", scope: "backend/token", release: "patch" },
          { type: "docs", scope: "backend/token", release: "patch" },
          { type: "style", scope: "backend/token", release: "patch" },
          { type: "test", scope: "backend/token", release: "patch" },
          { type: "chore", scope: "backend/token", release: "patch" },
          { type: "build", scope: "backend/token", release: "patch" },
          { type: "ci", scope: "backend/token", release: "patch" },
          { type: "token", scope: "backend/token", release: "minor" },

          // Smart Contracts - Rust (CosmWasm)
          { type: "feat", scope: "backend/contract/rust", release: "minor" },
          { type: "fix", scope: "backend/contract/rust", release: "patch" },
          { type: "perf", scope: "backend/contract/rust", release: "patch" },
          { type: "refactor", scope: "backend/contract/rust", release: "patch" },
          { type: "docs", scope: "backend/contract/rust", release: "patch" },
          { type: "style", scope: "backend/contract/rust", release: "patch" },
          { type: "test", scope: "backend/contract/rust", release: "patch" },
          { type: "chore", scope: "backend/contract/rust", release: "patch" },
          { type: "build", scope: "backend/contract/rust", release: "patch" },
          { type: "ci", scope: "backend/contract/rust", release: "patch" },

          // Smart Contracts - Solidity (Ethereum/EVM)
          { type: "feat", scope: "backend/contract/solidity", release: "minor" },
          { type: "fix", scope: "backend/contract/solidity", release: "patch" },
          { type: "perf", scope: "backend/contract/solidity", release: "patch" },
          { type: "refactor", scope: "backend/contract/solidity", release: "patch" },
          { type: "docs", scope: "backend/contract/solidity", release: "patch" },
          { type: "style", scope: "backend/contract/solidity", release: "patch" },
          { type: "test", scope: "backend/contract/solidity", release: "patch" },
          { type: "chore", scope: "backend/contract/solidity", release: "patch" },
          { type: "build", scope: "backend/contract/solidity", release: "patch" },
          { type: "ci", scope: "backend/contract/solidity", release: "patch" },

          // ====================================================================
          // 🤖 BOTS - AI/ML Integration
          // ====================================================================

          // Bot Core (Python)
          { type: "feat", scope: "bots/core", release: "minor" },
          { type: "fix", scope: "bots/core", release: "patch" },
          { type: "perf", scope: "bots/core", release: "patch" },
          { type: "refactor", scope: "bots/core", release: "patch" },
          { type: "docs", scope: "bots/core", release: "patch" },
          { type: "style", scope: "bots/core", release: "patch" },
          { type: "test", scope: "bots/core", release: "patch" },
          { type: "chore", scope: "bots/core", release: "patch" },
          { type: "build", scope: "bots/core", release: "patch" },
          { type: "ci", scope: "bots/core", release: "patch" },

          // Bot Integrations (HuggingFace, OpenAI, etc.)
          { type: "feat", scope: "bots/integration", release: "minor" },
          { type: "fix", scope: "bots/integration", release: "patch" },
          { type: "perf", scope: "bots/integration", release: "patch" },
          { type: "refactor", scope: "bots/integration", release: "patch" },
          { type: "docs", scope: "bots/integration", release: "patch" },
          { type: "style", scope: "bots/integration", release: "patch" },
          { type: "test", scope: "bots/integration", release: "patch" },
          { type: "chore", scope: "bots/integration", release: "patch" },
          { type: "build", scope: "bots/integration", release: "patch" },
          { type: "ci", scope: "bots/integration", release: "patch" },

          // ====================================================================
          // 📱 FRONTEND - Mobile & Web
          // ====================================================================

          // Dart/Flutter (Cross-platform mobile)
          { type: "feat", scope: "frontend/dart", release: "minor" },
          { type: "fix", scope: "frontend/dart", release: "patch" },
          { type: "perf", scope: "frontend/dart", release: "patch" },
          { type: "refactor", scope: "frontend/dart", release: "patch" },
          { type: "docs", scope: "frontend/dart", release: "patch" },
          { type: "style", scope: "frontend/dart", release: "patch" },
          { type: "test", scope: "frontend/dart", release: "patch" },
          { type: "chore", scope: "frontend/dart", release: "patch" },
          { type: "build", scope: "frontend/dart", release: "patch" },
          { type: "ci", scope: "frontend/dart", release: "patch" },

          // Android (Kotlin)
          { type: "feat", scope: "frontend/android", release: "minor" },
          { type: "fix", scope: "frontend/android", release: "patch" },
          { type: "perf", scope: "frontend/android", release: "patch" },
          { type: "refactor", scope: "frontend/android", release: "patch" },
          { type: "docs", scope: "frontend/android", release: "patch" },
          { type: "style", scope: "frontend/android", release: "patch" },
          { type: "test", scope: "frontend/android", release: "patch" },
          { type: "chore", scope: "frontend/android", release: "patch" },
          { type: "build", scope: "frontend/android", release: "patch" },
          { type: "ci", scope: "frontend/android", release: "patch" },

          // iOS (Swift)
          { type: "feat", scope: "frontend/ios", release: "minor" },
          { type: "fix", scope: "frontend/ios", release: "patch" },
          { type: "perf", scope: "frontend/ios", release: "patch" },
          { type: "refactor", scope: "frontend/ios", release: "patch" },
          { type: "docs", scope: "frontend/ios", release: "patch" },
          { type: "style", scope: "frontend/ios", release: "patch" },
          { type: "test", scope: "frontend/ios", release: "patch" },
          { type: "chore", scope: "frontend/ios", release: "patch" },
          { type: "build", scope: "frontend/ios", release: "patch" },
          { type: "ci", scope: "frontend/ios", release: "patch" },

          // ====================================================================
          // 🌐 FRONTEND/NODE - Web Frameworks
          // ====================================================================

          // Angular (TypeScript SPA Framework)
          { type: "feat", scope: "frontend/node/angular", release: "minor" },
          { type: "fix", scope: "frontend/node/angular", release: "patch" },
          { type: "perf", scope: "frontend/node/angular", release: "patch" },
          { type: "refactor", scope: "frontend/node/angular", release: "patch" },
          { type: "docs", scope: "frontend/node/angular", release: "patch" },
          { type: "style", scope: "frontend/node/angular", release: "patch" },
          { type: "test", scope: "frontend/node/angular", release: "patch" },
          { type: "chore", scope: "frontend/node/angular", release: "patch" },
          { type: "build", scope: "frontend/node/angular", release: "patch" },
          { type: "ci", scope: "frontend/node/angular", release: "patch" },

          // Svelte (Compile-time Framework)
          { type: "feat", scope: "frontend/node/svelte", release: "minor" },
          { type: "fix", scope: "frontend/node/svelte", release: "patch" },
          { type: "perf", scope: "frontend/node/svelte", release: "patch" },
          { type: "refactor", scope: "frontend/node/svelte", release: "patch" },
          { type: "docs", scope: "frontend/node/svelte", release: "patch" },
          { type: "style", scope: "frontend/node/svelte", release: "patch" },
          { type: "test", scope: "frontend/node/svelte", release: "patch" },
          { type: "chore", scope: "frontend/node/svelte", release: "patch" },
          { type: "build", scope: "frontend/node/svelte", release: "patch" },
          { type: "ci", scope: "frontend/node/svelte", release: "patch" },

          // Next.js (React SSR/SSG Framework)
          { type: "feat", scope: "frontend/node/next", release: "minor" },
          { type: "fix", scope: "frontend/node/next", release: "patch" },
          { type: "perf", scope: "frontend/node/next", release: "patch" },
          { type: "refactor", scope: "frontend/node/next", release: "patch" },
          { type: "docs", scope: "frontend/node/next", release: "patch" },
          { type: "style", scope: "frontend/node/next", release: "patch" },
          { type: "test", scope: "frontend/node/next", release: "patch" },
          { type: "chore", scope: "frontend/node/next", release: "patch" },
          { type: "build", scope: "frontend/node/next", release: "patch" },
          { type: "ci", scope: "frontend/node/next", release: "patch" },

          // Nuxt.js (Vue SSR/SSG Framework)
          { type: "feat", scope: "frontend/node/nuxt", release: "minor" },
          { type: "fix", scope: "frontend/node/nuxt", release: "patch" },
          { type: "perf", scope: "frontend/node/nuxt", release: "patch" },
          { type: "refactor", scope: "frontend/node/nuxt", release: "patch" },
          { type: "docs", scope: "frontend/node/nuxt", release: "patch" },
          { type: "style", scope: "frontend/node/nuxt", release: "patch" },
          { type: "test", scope: "frontend/node/nuxt", release: "patch" },
          { type: "chore", scope: "frontend/node/nuxt", release: "patch" },
          { type: "build", scope: "frontend/node/nuxt", release: "patch" },
          { type: "ci", scope: "frontend/node/nuxt", release: "patch" },

          // Shared Frontend Libraries
          { type: "feat", scope: "frontend/node/shared", release: "minor" },
          { type: "fix", scope: "frontend/node/shared", release: "patch" },
          { type: "perf", scope: "frontend/node/shared", release: "patch" },
          { type: "refactor", scope: "frontend/node/shared", release: "patch" },
          { type: "docs", scope: "frontend/node/shared", release: "patch" },
          { type: "style", scope: "frontend/node/shared", release: "patch" },
          { type: "test", scope: "frontend/node/shared", release: "patch" },
          { type: "chore", scope: "frontend/node/shared", release: "patch" },
          { type: "build", scope: "frontend/node/shared", release: "patch" },
          { type: "ci", scope: "frontend/node/shared", release: "patch" },

          // ====================================================================
          // 🔌 PROTO - Protocol Buffers / gRPC
          // ====================================================================
          { type: "feat", scope: "proto", release: "minor" },
          { type: "fix", scope: "proto", release: "patch" },
          { type: "perf", scope: "proto", release: "patch" },
          { type: "refactor", scope: "proto", release: "patch" },
          { type: "docs", scope: "proto", release: "patch" },
          { type: "style", scope: "proto", release: "patch" },
          { type: "test", scope: "proto", release: "patch" },
          { type: "chore", scope: "proto", release: "patch" },
          { type: "build", scope: "proto", release: "patch" },
          { type: "ci", scope: "proto", release: "patch" },
          { type: "proto", scope: "proto", release: "patch" },

          // ====================================================================
          // 🏗️ BAZEL - Build System Rules
          // ====================================================================
          { type: "feat", scope: "rules", release: "minor" },
          { type: "fix", scope: "rules", release: "patch" },
          { type: "perf", scope: "rules", release: "patch" },
          { type: "refactor", scope: "rules", release: "patch" },
          { type: "docs", scope: "rules", release: "patch" },
          { type: "style", scope: "rules", release: "patch" },
          { type: "test", scope: "rules", release: "patch" },
          { type: "chore", scope: "rules", release: "patch" },
          { type: "build", scope: "rules", release: "patch" },
          { type: "ci", scope: "rules", release: "patch" },
          { type: "bazel", scope: "rules", release: "patch" },

          // ====================================================================
          // 🌍 GLOBAL RULES - Apply to any scope or no scope
          // ====================================================================
          { type: "perf", release: "patch" }, // Performance improvements
          { type: "revert", release: "patch" }, // Reverts
          { type: "refactor", release: "patch" }, // Code refactoring
          { type: "style", release: "patch" }, // Code style changes
          { type: "test", release: false }, // Tests don't trigger releases
          { type: "chore", release: false }, // Chores don't trigger releases
          { type: "build", release: "patch" }, // Build system changes
          { type: "ci", release: false }, // CI config changes
          { type: "docs", release: "patch" }, // Documentation
          { breaking: true, release: "major" }, // Breaking changes = MAJOR
        ],
        parserOpts: {
          noteKeywords: ["BREAKING CHANGE", "BREAKING CHANGES", "BREAKING"],
          issuePrefixes: ["#", "JIRA-", "RICE-"],
        },
      },
    ],

    // ==========================================================================
    // RELEASE NOTES GENERATOR - Create beautiful changelogs
    // ==========================================================================
    [
      "@semantic-release/release-notes-generator",
      {
        preset: "conventionalcommits",
        parserOpts: {
          noteKeywords: ["BREAKING CHANGE", "BREAKING CHANGES", "BREAKING"],
          issuePrefixes: ["#", "JIRA-", "RICE-"],
        },
        writerOpts: {
          commitsSort: ["scope", "subject"],
          groupBy: "scope",
        },
        presetConfig: {
          types: [
            { type: "feat", section: "✨ Features", hidden: false },
            { type: "fix", section: "🐛 Bug Fixes", hidden: false },
            { type: "perf", section: "⚡ Performance Improvements", hidden: false },
            { type: "refactor", section: "♻️ Code Refactoring", hidden: false },
            { type: "docs", section: "📚 Documentation", hidden: false },
            { type: "style", section: "💎 Styles", hidden: false },
            { type: "test", section: "✅ Tests", hidden: false },
            { type: "build", section: "🔧 Build System", hidden: false },
            { type: "ci", section: "👷 CI/CD", hidden: false },
            { type: "chore", section: "🔨 Chores", hidden: true },
            { type: "revert", section: "⏪ Reverts", hidden: false },
            { type: "ansible", section: "🎭 Ansible", hidden: false },
            { type: "k8s", section: "☸️ Kubernetes", hidden: false },
            { type: "terraform", section: "🏗️ Terraform", hidden: false },
            { type: "proto", section: "🔌 Protocol Buffers", hidden: false },
            { type: "token", section: "🪙 Token", hidden: false },
            { type: "bazel", section: "🏗️ Bazel", hidden: false },
          ],
        },
      },
    ],

    // ==========================================================================
    // CHANGELOG - Update CHANGELOG.md file
    // ==========================================================================
    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md",
        changelogTitle:
          "# 📋 Changelog\n\nAll notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).",
      },
    ],

    // ==========================================================================
    // NPM - Handle Node.js package (publish disabled for monorepo)
    // ==========================================================================
    [
      "@semantic-release/npm",
      {
        npmPublish: false,
        tarballDir: "dist",
      },
    ],

    // ==========================================================================
    // EXEC - Custom commands during release process
    // ==========================================================================
    [
      "@semantic-release/exec",
      {
        verifyReleaseCmd: "echo ${nextRelease.version} > .version",
        publishCmd: "echo '✅ Release ${nextRelease.version} ready for deployment'",
      },
    ],

    // ==========================================================================
    // GIT - Commit release assets back to repository
    // ==========================================================================
    [
      "@semantic-release/git",
      {
        assets: [
          // Documentation
          "CHANGELOG.md",
          ".version",

          // Node.js / JavaScript / TypeScript
          "package.json",
          "package-lock.json",
          "yarn.lock",
          "pnpm-lock.yaml",
          "bun.lockb",

          // Python
          "pyproject.toml",
          "poetry.lock",
          "Pipfile.lock",

          // Rust
          "Cargo.toml",
          "Cargo.lock",

          // Go
          "go.mod",
          "go.sum",

          // Dart / Flutter
          "pubspec.yaml",
          "pubspec.lock",

          // Kotlin / Android (Gradle)
          "build.gradle",
          "build.gradle.kts",
          "gradle.properties",
          "settings.gradle",
          "settings.gradle.kts",

          // Swift / iOS
          "Package.swift",
          "Package.resolved",
        ],
        message: "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}",
      },
    ],

    // ==========================================================================
    // GITHUB - Create GitHub releases and manage issues/PRs
    // ==========================================================================
    [
      "@semantic-release/github",
      {
        successComment:
          "🎉 This ${issue.pull_request ? 'PR is included' : 'issue has been resolved'} in version [${nextRelease.version}](${releases[0].url}) 🎉\n\nThe release is available on:\n- [GitHub Release](${releases[0].url})\n\n---\n*Automatic release by [semantic-release](https://github.com/semantic-release/semantic-release)*",
        failComment:
          "❌ The release from branch `${branch.name}` had failed due to the following errors:\n- ${errors.map(err => err.message).join('\\n- ')}",
        failTitle: "🚨 Release Failed: v${nextRelease.version}",
        labels: ["released"],
        releasedLabels: [
          'released<%= nextRelease.channel ? `-${nextRelease.channel}` : "" %>-v<%= nextRelease.version %>',
        ],
        addReleases: "bottom",
        assets: [
          {
            path: "dist/*.tgz",
            label: "Distribution archive",
          },
        ],
      },
    ],
  ],

  // ============================================================================
  // GLOBAL SETTINGS
  // ============================================================================
  tagFormat: "v${version}", // Git tag format
  repositoryUrl: "https://github.com/mrDinkelman/rice-mono", // Repository URL
  dryRun: false, // Actually perform releases
  ci: true, // Run in CI mode
  debug: false, // Debug logging disabled
};
