/**
 * ╔════════════════════════════════════════════════════════════════════════════╗
 * ║                    PRETTIER CONFIGURATION                                  ║
 * ║                         RICE MONOREPO                                      ║
 * ╚════════════════════════════════════════════════════════════════════════════╝
 *
 * Enterprise-grade code formatting for JavaScript, TypeScript, JSON, YAML, Markdown
 */

module.exports = {
  // ============================================================================
  // GENERAL SETTINGS
  // ============================================================================
  printWidth: 120,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: false,
  quoteProps: "as-needed",
  trailingComma: "es5",
  bracketSpacing: true,
  bracketSameLine: false,
  arrowParens: "always",
  endOfLine: "lf",
  embeddedLanguageFormatting: "auto",

  // ============================================================================
  // FILE-SPECIFIC OVERRIDES
  // ============================================================================
  overrides: [
    // ==========================================================================
    // TYPESCRIPT / JAVASCRIPT
    // ==========================================================================
    {
      files: ["*.ts", "*.tsx", "*.js", "*.jsx", "*.mjs", "*.cjs"],
      options: {
        parser: "typescript",
        printWidth: 120,
        tabWidth: 2,
        semi: true,
        singleQuote: false,
        trailingComma: "es5",
      },
    },

    // ==========================================================================
    // JSON
    // ==========================================================================
    {
      files: ["*.json", "*.jsonc"],
      options: {
        parser: "json",
        printWidth: 120,
        tabWidth: 2,
        trailingComma: "none",
      },
    },
    {
      files: ["package.json", "tsconfig.json"],
      options: {
        parser: "json",
        printWidth: 120,
        tabWidth: 2,
        trailingComma: "none",
      },
    },

    // ==========================================================================
    // YAML
    // ==========================================================================
    {
      files: ["*.yml", "*.yaml"],
      options: {
        parser: "yaml",
        printWidth: 120,
        tabWidth: 2,
        singleQuote: false,
        proseWrap: "always",
      },
    },
    {
      files: [".github/**/*.yml", ".github/**/*.yaml"],
      options: {
        parser: "yaml",
        printWidth: 120,
        tabWidth: 2,
      },
    },

    // ==========================================================================
    // MARKDOWN
    // ==========================================================================
    {
      files: ["*.md", "*.markdown"],
      options: {
        parser: "markdown",
        printWidth: 120,
        tabWidth: 2,
        proseWrap: "always",
        singleQuote: false,
      },
    },

    // ==========================================================================
    // HTML
    // ==========================================================================
    {
      files: ["*.html"],
      options: {
        parser: "html",
        printWidth: 120,
        tabWidth: 2,
        htmlWhitespaceSensitivity: "css",
      },
    },

    // ==========================================================================
    // CSS / SCSS / LESS
    // ==========================================================================
    {
      files: ["*.css", "*.scss", "*.sass", "*.less"],
      options: {
        parser: "css",
        printWidth: 120,
        tabWidth: 2,
        singleQuote: false,
      },
    },

    // ==========================================================================
    // GRAPHQL
    // ==========================================================================
    {
      files: ["*.graphql", "*.gql"],
      options: {
        parser: "graphql",
        printWidth: 120,
        tabWidth: 2,
      },
    },

    // ==========================================================================
    // PROTO - Protocol Buffers
    // ==========================================================================
    {
      files: ["*.proto"],
      options: {
        printWidth: 100,
        tabWidth: 2,
      },
    },

    // ==========================================================================
    // TERRAFORM
    // ==========================================================================
    {
      files: ["*.tf", "*.tfvars"],
      options: {
        printWidth: 120,
        tabWidth: 2,
      },
    },

    // ==========================================================================
    // KUBERNETES / HELM
    // ==========================================================================
    {
      files: ["*.k8s", "*.k8s.yaml"],
      options: {
        parser: "yaml",
        printWidth: 120,
        tabWidth: 2,
      },
    },

    // ==========================================================================
    // DOCKER
    // ==========================================================================
    {
      files: ["Dockerfile", "*.dockerfile"],
      options: {
        printWidth: 120,
        tabWidth: 2,
      },
    },

    // ==========================================================================
    // SHELL SCRIPTS
    // ==========================================================================
    {
      files: ["*.sh", "*.bash"],
      options: {
        printWidth: 120,
        tabWidth: 2,
      },
    },

    // ==========================================================================
    // BAZEL
    // ==========================================================================
    {
      files: ["*.bzl", "*.bazel", "BUILD", "WORKSPACE", "MODULE.bazel"],
      options: {
        printWidth: 120,
        tabWidth: 4,
      },
    },

    // ==========================================================================
    // SPECIAL FILES
    // ==========================================================================
    {
      files: [".releaserc.js"],
      options: {
        printWidth: 120,
        tabWidth: 2,
        trailingComma: "es5",
      },
    },

    {
      files: "*.sol",
      options: {
        printWidth: 120,
        tabWidth: 4,
        useTabs: false,
        singleQuote: false,
        bracketSpacing: true,
        explicitTypes: "always",
      },
    },
  ],

  // ============================================================================
  // PLUGIN CONFIGURATION
  // ============================================================================
  plugins: [
    // Add plugins as needed:
    // "prettier-plugin-organize-imports",
    // "prettier-plugin-tailwindcss",
  ],
};
