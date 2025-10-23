/**
 * ╔════════════════════════════════════════════════════════════════════════════╗
 * ║                    ESLINT CONFIGURATION                                    ║
 * ║                         RICE MONOREPO                                      ║
 * ╚════════════════════════════════════════════════════════════════════════════╝
 *
 * Enterprise-grade ESLint configuration for TypeScript/JavaScript
 */

module.exports = {
  root: true,

  // ============================================================================
  // ENVIRONMENT
  // ============================================================================
  env: {
    browser: true,
    es2022: true,
    node: true,
    jest: true,
  },

  // ============================================================================
  // PARSER & PARSER OPTIONS
  // ============================================================================
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
    project: ['./tsconfig.json', '../../.project/tsconfig.json'],
  },

  // ============================================================================
  // EXTENDS - Base configurations
  // ============================================================================
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'plugin:import/recommended',
    'plugin:import/typescript',
    'prettier', // Must be last to override other configs
  ],

  // ============================================================================
  // PLUGINS
  // ============================================================================
  plugins: ['@typescript-eslint', 'import', 'unused-imports', 'simple-import-sort'],

  // ============================================================================
  // SETTINGS
  // ============================================================================
  settings: {
    'import/resolver': {
      typescript: {
        alwaysTryTypes: true,
        project: [
          './angular/tsconfig.json',
          './next/tsconfig.json',
          './nuxt/tsconfig.json',
          './svelte/tsconfig.json',
          './tsconfig.json',
        ],
      },
      node: {
        extensions: ['.js', '.jsx', '.ts', '.tsx'],
      },
    },
  },

  // ============================================================================
  // RULES - General
  // ============================================================================
  rules: {
    // ══════════════════════════════════════════════════════════════════════════
    // TYPESCRIPT RULES
    // ══════════════════════════════════════════════════════════════════════════
    '@typescript-eslint/no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
        caughtErrorsIgnorePattern: '^_',
      },
    ],
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-non-null-assertion': 'warn',
    '@typescript-eslint/consistent-type-imports': [
      'error',
      {
        prefer: 'type-imports',
        disallowTypeAnnotations: false,
      },
    ],
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/await-thenable': 'error',
    '@typescript-eslint/no-misused-promises': 'error',

    // ══════════════════════════════════════════════════════════════════════════
    // IMPORT RULES
    // ══════════════════════════════════════════════════════════════════════════
    'simple-import-sort/imports': 'error',
    'simple-import-sort/exports': 'error',
    'import/first': 'error',
    'import/newline-after-import': 'error',
    'import/no-duplicates': 'error',
    'import/no-unresolved': 'error',
    'unused-imports/no-unused-imports': 'error',

    // ══════════════════════════════════════════════════════════════════════════
    // CODE QUALITY
    // ══════════════════════════════════════════════════════════════════════════
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'no-debugger': 'error',
    'no-alert': 'error',
    'no-var': 'error',
    'prefer-const': 'error',
    'prefer-arrow-callback': 'error',
    'arrow-body-style': ['error', 'as-needed'],
    'object-shorthand': 'error',
    'prefer-template': 'error',
    'prefer-destructuring': ['error', { object: true, array: false }],

    // ══════════════════════════════════════════════════════════════════════════
    // BEST PRACTICES
    // ══════════════════════════════════════════════════════════════════════════
    eqeqeq: ['error', 'always', { null: 'ignore' }],
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-new-func': 'error',
    'no-return-await': 'error',
    'require-await': 'error',
    'no-await-in-loop': 'warn',
    'no-promise-executor-return': 'error',

    // ══════════════════════════════════════════════════════════════════════════
    // PERFORMANCE
    // ══════════════════════════════════════════════════════════════════════════
    'no-inner-declarations': 'error',
    'no-new-object': 'error',
    'no-array-constructor': 'error',
  },

  // ============================================================================
  // OVERRIDES - Framework-specific rules
  // ============================================================================
  overrides: [
    // ══════════════════════════════════════════════════════════════════════════
    // ANGULAR
    // ══════════════════════════════════════════════════════════════════════════
    {
      files: ['angular/**/*.ts'],
      extends: ['plugin:@angular-eslint/recommended', 'plugin:@angular-eslint/template/process-inline-templates'],
      rules: {
        '@angular-eslint/directive-selector': ['error', { type: 'attribute', prefix: 'app', style: 'camelCase' }],
        '@angular-eslint/component-selector': ['error', { type: 'element', prefix: 'app', style: 'kebab-case' }],
      },
    },
    {
      files: ['angular/**/*.html'],
      extends: ['plugin:@angular-eslint/template/recommended'],
      rules: {},
    },

    // ══════════════════════════════════════════════════════════════════════════
    // REACT / NEXT.JS
    // ══════════════════════════════════════════════════════════════════════════
    {
      files: ['next/**/*.{ts,tsx}'],
      extends: [
        'plugin:react/recommended',
        'plugin:react-hooks/recommended',
        'plugin:jsx-a11y/recommended',
        'next/core-web-vitals',
      ],
      rules: {
        'react/react-in-jsx-scope': 'off', // Not needed in Next.js
        'react/prop-types': 'off', // Using TypeScript
        'react-hooks/rules-of-hooks': 'error',
        'react-hooks/exhaustive-deps': 'warn',
      },
    },

    // ══════════════════════════════════════════════════════════════════════════
    // VUE / NUXT
    // ══════════════════════════════════════════════════════════════════════════
    {
      files: ['nuxt/**/*.{ts,tsx,vue}'],
      extends: ['plugin:vue/vue3-recommended', '@nuxtjs/eslint-config-typescript'],
      rules: {
        'vue/multi-word-component-names': 'off',
        'vue/no-v-html': 'warn',
      },
    },

    // ══════════════════════════════════════════════════════════════════════════
    // SVELTE
    // ══════════════════════════════════════════════════════════════════════════
    {
      files: ['svelte/**/*.{ts,svelte}'],
      extends: ['plugin:svelte/recommended'],
      parser: 'svelte-eslint-parser',
      parserOptions: {
        parser: '@typescript-eslint/parser',
      },
    },

    // ══════════════════════════════════════════════════════════════════════════
    // TEST FILES
    // ══════════════════════════════════════════════════════════════════════════
    {
      files: ['**/*.test.{ts,tsx,js,jsx}', '**/*.spec.{ts,tsx,js,jsx}'],
      env: {
        jest: true,
      },
      extends: ['plugin:jest/recommended'],
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        'no-console': 'off',
      },
    },

    // ══════════════════════════════════════════════════════════════════════════
    // JAVASCRIPT (non-TypeScript) FILES
    // ══════════════════════════════════════════════════════════════════════════
    {
      files: ['**/*.js', '**/*.jsx', '**/*.mjs', '**/*.cjs'],
      extends: ['eslint:recommended'],
      parser: 'espree',
      rules: {
        '@typescript-eslint/no-var-requires': 'off',
      },
    },

    // ══════════════════════════════════════════════════════════════════════════
    // CONFIGURATION FILES
    // ══════════════════════════════════════════════════════════════════════════
    {
      files: ['**/*.config.{ts,js}', '**/.*rc.{ts,js}', '**/.eslintrc.js', '**/vite.config.ts', '**/vitest.config.ts'],
      rules: {
        '@typescript-eslint/no-var-requires': 'off',
        'import/no-default-export': 'off',
      },
    },
  ],

  // ============================================================================
  // IGNORE PATTERNS
  // ============================================================================
  ignorePatterns: [
    'node_modules/',
    'dist/',
    'build/',
    'coverage/',
    '.next/',
    '.nuxt/',
    'bazel-*',
    '*.min.js',
    '*.bundle.js',
    '*.generated.*',
    '*_pb.js',
    '*_pb.ts',
  ],
};
