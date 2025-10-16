/**
 * ╔════════════════════════════════════════════════════════════════════════════╗
 * ║                    COMMITLINT CONFIGURATION                                ║
 * ║                         RICE MONOREPO                                      ║
 * ╚════════════════════════════════════════════════════════════════════════════╝
 *
 * Enforces Conventional Commits specification
 * Format: <type>(<scope>): <subject>
 */

module.exports = {
  extends: ["@commitlint/config-conventional"],

  // ============================================================================
  // RULES
  // ============================================================================
  rules: {
    // Type requirements
    "type-enum": [
      2,
      "always",
      [
        // Standard types
        "feat", // New feature
        "fix", // Bug fix
        "docs", // Documentation only
        "style", // Code style (formatting, etc.)
        "refactor", // Code change that neither fixes a bug nor adds a feature
        "perf", // Performance improvement
        "test", // Adding missing tests
        "build", // Changes to build system or dependencies
        "ci", // Changes to CI configuration
        "chore", // Other changes that don't modify src or test files
        "revert", // Reverts a previous commit

        // Extended types for monorepo
        "ansible", // Ansible configuration changes
        "k8s", // Kubernetes changes
        "terraform", // Terraform IaC changes
        "proto", // Protocol buffer changes
        "token", // Token/blockchain changes
        "bazel", // Bazel build system changes
        "contract", // Smart contract changes
        "bot", // Bot/AI changes
        "mobile", // Mobile app changes
        "web", // Web app changes
        "api", // API changes
        "db", // Database changes
        "security", // Security fixes/improvements
        "deps", // Dependency updates
        "release", // Release commits
        "hotfix", // Critical hotfix
        "wip", // Work in progress (should not be in main)
      ],
    ],

    // Scope requirements (optional but recommended)
    "scope-enum": [
      2,
      "always",
      [
        // Infrastructure
        "dev/ansible",
        "dev/k8s",
        "dev/terraform",

        // Backend
        "backend/db",
        "backend/token",
        "backend/contract/rust",
        "backend/contract/solidity",

        // Bots
        "bots/core",
        "bots/integration",

        // Frontend
        "frontend/dart",
        "frontend/android",
        "frontend/ios",
        "frontend/node/angular",
        "frontend/node/next",
        "frontend/node/nuxt",
        "frontend/node/svelte",
        "frontend/node/shared",

        // Shared
        "proto",
        "rules",
        "config",
        "docs",
        "ci",
        "tools",
        "deps",
        "security",

        // Cross-cutting
        "monorepo",
        "workspace",
      ],
    ],

    // Body and footer
    "body-leading-blank": [2, "always"],
    "body-max-line-length": [2, "always", 100],
    "footer-leading-blank": [2, "always"],
    "footer-max-line-length": [2, "always", 100],

    // Header
    "header-max-length": [2, "always", 100],
    "subject-case": [2, "never", ["sentence-case", "start-case", "pascal-case", "upper-case"]],
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],

    // Type
    "type-case": [2, "always", "lower-case"],
    "type-empty": [2, "never"],

    // Scope
    "scope-case": [2, "always", "lower-case"],

    // References
    "references-empty": [1, "never"],
  },

  // ============================================================================
  // PARSER OPTIONS
  // ============================================================================
  parserPreset: {
    parserOpts: {
      // Issue prefixes
      issuePrefixes: ["#", "JIRA-", "RICE-"],

      // Note keywords for breaking changes
      noteKeywords: ["BREAKING CHANGE", "BREAKING CHANGES", "BREAKING"],

      // Reference actions
      referenceActions: ["close", "closes", "closed", "fix", "fixes", "fixed", "resolve", "resolves", "resolved"],
    },
  },

  // ============================================================================
  // HELP MESSAGE
  // ============================================================================
  helpUrl: "https://github.com/conventional-changelog/commitlint/#what-is-commitlint",

  // ============================================================================
  // PROMPTS (for commitizen)
  // ============================================================================
  prompt: {
    questions: {
      type: {
        description: "Select the type of change that you're committing:",
        enum: {
          feat: {
            description: "A new feature",
            title: "Features",
            emoji: "✨",
          },
          fix: {
            description: "A bug fix",
            title: "Bug Fixes",
            emoji: "🐛",
          },
          docs: {
            description: "Documentation only changes",
            title: "Documentation",
            emoji: "📚",
          },
          style: {
            description: "Changes that do not affect the meaning of the code (white-space, formatting, etc)",
            title: "Styles",
            emoji: "💎",
          },
          refactor: {
            description: "A code change that neither fixes a bug nor adds a feature",
            title: "Code Refactoring",
            emoji: "📦",
          },
          perf: {
            description: "A code change that improves performance",
            title: "Performance Improvements",
            emoji: "🚀",
          },
          test: {
            description: "Adding missing tests or correcting existing tests",
            title: "Tests",
            emoji: "🚨",
          },
          build: {
            description: "Changes that affect the build system or external dependencies",
            title: "Builds",
            emoji: "🛠",
          },
          ci: {
            description: "Changes to our CI configuration files and scripts",
            title: "Continuous Integrations",
            emoji: "⚙️",
          },
          chore: {
            description: "Other changes that don't modify src or test files",
            title: "Chores",
            emoji: "♻️",
          },
          revert: {
            description: "Reverts a previous commit",
            title: "Reverts",
            emoji: "🗑",
          },
        },
      },
      scope: {
        description: "What is the scope of this change (e.g. component or file name)",
      },
      subject: {
        description: "Write a short, imperative tense description of the change",
      },
      body: {
        description: "Provide a longer description of the change",
      },
      isBreaking: {
        description: "Are there any breaking changes?",
      },
      breakingBody: {
        description: "A BREAKING CHANGE commit requires a body. Please enter a longer description of the commit itself",
      },
      breaking: {
        description: "Describe the breaking changes",
      },
      isIssueAffected: {
        description: "Does this change affect any open issues?",
      },
      issuesBody: {
        description:
          "If issues are closed, the commit requires a body. Please enter a longer description of the commit itself",
      },
      issues: {
        description: 'Add issue references (e.g. "fix #123", "re #456".)',
      },
    },
  },
};
