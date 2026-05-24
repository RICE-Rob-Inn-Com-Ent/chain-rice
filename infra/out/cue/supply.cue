package workspace

// cue cmd embed — regenerated from repo files
emitFiles_supply: [
		{
			path:    "renovate.json"
			content: #"""
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "description": "Renovate configuration for .rice OS monorepo",
  "extends": [
    "config:base",
    ":dependencyDashboard",
    ":semanticCommits",
    ":preserveSemverRanges",
    "group:monorepos",
    "group:recommended",
    "replacements:all",
    "workarounds:all"
  ],
  "timezone": "Europe/Warsaw",
  "schedule": [
    "before 6am on Monday"
  ],
  "prConcurrentLimit": 10,
  "prHourlyLimit": 5,
  "rebaseWhen": "conflicted",
  "automerge": false,
  "platformAutomerge": false,
  "rangeStrategy": "bump",
  "semanticCommits": "enabled",
  "commitMessagePrefix": "chore(deps):",
  "commitMessageAction": "update",
  "commitMessageTopic": "{{depName}}",
  "commitMessageExtra": "to {{#if isPinDigest}}{{{newDigestShort}}}{{else}}{{#if isMajor}}{{prettyNewMajor}}{{else}}{{#if isSingleVersion}}{{prettyNewVersion}}{{else}}{{#if newValue}}{{{newValue}}}{{else}}{{{newDigestShort}}}{{/if}}{{/if}}{{/if}}{{/if}}",
  "labels": [
    "dependencies",
    "renovate"
  ],
  "assignees": [
    "@mrDinkelman"
  ],
  "reviewers": [
    "@mrDinkelman"
  ],
  "vulnerabilityAlerts": {
    "labels": [
      "security",
      "dependencies"
    ],
    "automerge": false,
    "schedule": [
      "at any time"
    ]
  },
  "separateMajorMinor": true,
  "separateMultipleMajor": true,
  "separateMinorPatch": false,
  "ignoreUnstable": true,
  "respectLatest": true,
  "packageRules": [
    {
      "description": "Group all non-major updates",
      "matchUpdateTypes": [
        "minor",
        "patch",
        "pin",
        "digest"
      ],
      "groupName": "all non-major dependencies",
      "groupSlug": "all-minor-patch"
    },
    {
      "description": "Automerge non-major updates",
      "matchUpdateTypes": [
        "minor",
        "patch",
        "pin",
        "digest"
      ],
      "automerge": true,
      "automergeType": "pr",
      "platformAutomerge": true
    },
    {
      "description": "Major updates require manual review",
      "matchUpdateTypes": [
        "major"
      ],
      "automerge": false,
      "labels": [
        "dependencies",
        "major-update"
      ]
    },
    {
      "description": "KING — pixi.toml toolchain runtimes",
      "matchManagers": [
        "pixi"
      ],
      "matchPaths": [
        "pixi.toml"
      ],
      "groupName": "pixi toolchain",
      "labels": [
        "dependencies",
        "king",
        "toolchain",
        "pixi"
      ],
      "schedule": [
        "before 6am on Monday"
      ],
      "automerge": false,
      "commitMessagePrefix": "chore(tools):"
    },
    {
      "description": "MASON — infra CUE and Protobuf tooling",
      "matchPaths": [
        "infra/**"
      ],
      "groupName": "mason infra",
      "labels": [
        "dependencies",
        "mason",
        "infra"
      ]
    },
    {
      "description": "MASON — Timoni, Dagger, buf tooling",
      "matchPackageNames": [
        "timoni",
        "dagger",
        "buf"
      ],
      "groupName": "mason tooling",
      "labels": [
        "dependencies",
        "mason",
        "tooling"
      ],
      "automerge": false
    },
    {
      "description": "MASON — OpenTofu infrastructure",
      "matchManagers": [
        "terraform"
      ],
      "matchPaths": [
        ".opentofu/**"
      ],
      "groupName": "opentofu infrastructure",
      "labels": [
        "dependencies",
        "mason",
        "opentofu",
        "infrastructure"
      ],
      "automerge": false
    },
    {
      "description": "MASON — Kubernetes manifests",
      "matchManagers": [
        "kubernetes",
        "helm-values",
        "helmv3"
      ],
      "matchPaths": [
        ".k8s/**"
      ],
      "groupName": "kubernetes dependencies",
      "labels": [
        "dependencies",
        "mason",
        "kubernetes"
      ]
    },
    {
      "description": "SMITH — Go microservices",
      "matchManagers": [
        "gomod"
      ],
      "matchPaths": [
        "service/go.mod"
      ],
      "groupName": "smith go dependencies",
      "labels": [
        "dependencies",
        "smith",
        "go"
      ]
    },
    {
      "description": "SMITH — Elixir",
      "matchManagers": [
        "mix"
      ],
      "matchPaths": [
        "service/mix.exs"
      ],
      "groupName": "smith elixir dependencies",
      "labels": [
        "dependencies",
        "smith",
        "elixir"
      ]
    },
    {
      "description": "SMITH — Atlas database migrations",
      "matchPackageNames": [
        "atlas",
        "ariga.io/atlas"
      ],
      "groupName": "smith atlas",
      "labels": [
        "dependencies",
        "smith",
        "database"
      ],
      "automerge": false
    },
    {
      "description": "CLERK — Rust workspace",
      "matchManagers": [
        "cargo"
      ],
      "matchPaths": [
        "base/Cargo.toml"
      ],
      "groupName": "clerk rust dependencies",
      "labels": [
        "dependencies",
        "clerk",
        "rust"
      ]
    },
    {
      "description": "CLERK — Haskell",
      "matchManagers": [
        "cabal"
      ],
      "matchPaths": [
        "base/package.yaml"
      ],
      "groupName": "clerk haskell dependencies",
      "labels": [
        "dependencies",
        "clerk",
        "haskell"
      ]
    },
    {
      "description": "BARD — TypeScript browser",
      "matchManagers": [
        "bun"
      ],
      "matchPaths": [
        "frontend/package.json"
      ],
      "groupName": "bard typescript dependencies",
      "labels": [
        "dependencies",
        "bard",
        "typescript"
      ]
    },
    {
      "description": "BARD — Dart/Flutter screen",
      "matchManagers": [
        "pub"
      ],
      "matchPaths": [
        "frontend/pubspec.yaml"
      ],
      "groupName": "bard dart flutter dependencies",
      "labels": [
        "dependencies",
        "bard",
        "dart",
        "flutter"
      ]
    },
    {
      "description": "SAGE — Python AI pipelines",
      "matchManagers": [
        "uv"
      ],
      "matchPaths": [
        "function/pyproject.toml"
      ],
      "groupName": "sage python dependencies",
      "labels": [
        "dependencies",
        "sage",
        "python"
      ]
    },
    {
      "description": "GitHub Actions",
      "matchManagers": [
        "github-actions"
      ],
      "groupName": "github actions",
      "labels": [
        "dependencies",
        "github-actions"
      ],
      "schedule": [
        "before 6am on Monday"
      ],
      "pinDigests": true
    },
    {
      "description": "Security packages — immediate",
      "matchPackagePatterns": [
        "^security-",
        "^@security/"
      ],
      "schedule": [
        "at any time"
      ],
      "automerge": false,
      "labels": [
        "security",
        "dependencies"
      ]
    },
    {
      "description": "Vulnerability alerts — immediate",
      "matchUpdateTypes": [
        "pin",
        "digest"
      ],
      "matchPackagePatterns": [
        ".*"
      ],
      "schedule": [
        "at any time"
      ],
      "labels": [
        "security",
        "dependencies"
      ]
    },
    {
      "description": "React ecosystem",
      "matchPackagePatterns": [
        "^react",
        "^@types/react"
      ],
      "groupName": "react ecosystem",
      "labels": [
        "dependencies",
        "bard",
        "react"
      ]
    },
    {
      "description": "TanStack ecosystem",
      "matchPackagePatterns": [
        "^@tanstack/"
      ],
      "groupName": "tanstack ecosystem",
      "labels": [
        "dependencies",
        "bard",
        "tanstack"
      ]
    },
    {
      "description": "Radix UI ecosystem",
      "matchPackagePatterns": [
        "^@radix-ui/"
      ],
      "groupName": "radix ui ecosystem",
      "labels": [
        "dependencies",
        "bard",
        "radix"
      ]
    },
    {
      "description": "Three.js ecosystem",
      "matchPackagePatterns": [
        "^three",
        "^@react-three/"
      ],
      "groupName": "threejs ecosystem",
      "labels": [
        "dependencies",
        "bard",
        "three"
      ]
    },
    {
      "description": "Cosmos SDK ecosystem",
      "matchPackagePatterns": [
        "^cosmossdk",
        "^cosmos/",
        "^cometbft"
      ],
      "groupName": "cosmos sdk ecosystem",
      "labels": [
        "dependencies",
        "smith",
        "cosmos"
      ],
      "automerge": false
    },
    {
      "description": "CosmWasm ecosystem",
      "matchPackagePatterns": [
        "^cosmwasm",
        "^cw-"
      ],
      "groupName": "cosmwasm ecosystem",
      "labels": [
        "dependencies",
        "clerk",
        "cosmwasm"
      ],
      "automerge": false
    },
    {
      "description": "Ark cryptography ecosystem",
      "matchPackagePatterns": [
        "^ark-"
      ],
      "groupName": "ark crypto ecosystem",
      "labels": [
        "dependencies",
        "clerk",
        "crypto"
      ],
      "automerge": false
    },
    {
      "description": "Ory identity ecosystem",
      "matchPackagePatterns": [
        "^ory/",
        "^@ory/"
      ],
      "groupName": "ory identity ecosystem",
      "labels": [
        "dependencies",
        "smith",
        "auth"
      ],
      "automerge": false
    },
    {
      "description": "LangChain/LangGraph AI ecosystem",
      "matchPackagePatterns": [
        "^langchain",
        "^langgraph",
        "^langsmith"
      ],
      "groupName": "langchain ecosystem",
      "labels": [
        "dependencies",
        "sage",
        "ai"
      ]
    },
    {
      "description": "Qiskit quantum ecosystem",
      "matchPackagePatterns": [
        "^qiskit"
      ],
      "groupName": "qiskit ecosystem",
      "labels": [
        "dependencies",
        "sage",
        "quantum"
      ]
    },
    {
      "description": "OpenTelemetry ecosystem",
      "matchPackagePatterns": [
        "^opentelemetry",
        "^@opentelemetry/"
      ],
      "groupName": "opentelemetry ecosystem",
      "labels": [
        "dependencies",
        "smith",
        "observability"
      ]
    },
    {
      "description": "Testing packages",
      "matchPackagePatterns": [
        "vitest",
        "playwright",
        "pytest",
        "patrol",
        "mocktail"
      ],
      "groupName": "testing dependencies",
      "labels": [
        "dependencies",
        "testing"
      ]
    }
  ],
  "regexManagers": [
    {
      "description": "Update versions in CUE configs",
      "fileMatch": [
        "(^|/)infra/configs/.*\\.cue$"
      ],
      "matchStrings": [
        "// renovate: datasource=(?<datasource>.*?) depName=(?<depName>.*?)\\s.*version:\\s*\"(?<currentValue>.*)\""
      ],
      "versioningTemplate": "semver"
    }
  ],
  "docker": {
    "enabled": false
  },
  "prBodyColumns": [
    "Package",
    "Type",
    "Update",
    "Change",
    "Pending"
  ],
  "prBodyDefinitions": {
    "Age": "[![age](https://developer.mend.io/api/mc/badges/age/{{datasource}}/{{replace '/' '%2f' depName}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)",
    "Adoption": "[![adoption](https://developer.mend.io/api/mc/badges/adoption/{{datasource}}/{{replace '/' '%2f' depName}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)",
    "Passing": "[![passing](https://developer.mend.io/api/mc/badges/compatibility/{{datasource}}/{{replace '/' '%2f' depName}}/{{currentVersion}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)",
    "Confidence": "[![confidence](https://developer.mend.io/api/mc/badges/confidence/{{datasource}}/{{replace '/' '%2f' depName}}/{{currentVersion}}/{{newVersion}}?slim=true)](https://docs.renovatebot.com/merge-confidence/)"
  },
  "prBodyNotes": [
    "This PR was generated by [Renovate](https://github.com/renovatebot/renovate).",
    "⚠️ All version changes flow through `infra/configs/*.cue` — never edit manifests directly.",
    "After merging: run `rice pour` to regenerate all manifests from CUE.",
    "🔒 To pin a dependency, add it to `ignoreDeps` in `renovate.json`."
  ]
}






"""#
		}
,
		{
			path:    ".sops.yaml"
			content: #"""
# .sops.yaml
# Generated by: cue export infra/configs/sops.cue
# Do not edit manually — edit infra/configs/sops.cue instead
#
# Key hierarchy:
#   dev  → age key (local machine, ~/.config/sops/age/keys.txt)
#   ci   → age key (CI secret, SOPS_AGE_KEY env var)
#   prod → age key dev + cloud KMS (AWS/GCP/Azure — uncomment when ready)
#
# Setup:
#   age-keygen -o ~/.config/sops/age/keys.txt
#   cat ~/.config/sops/age/keys.txt | grep "public key" → paste below as age:

# TODO:
# [ ] replace age1REPLACE_WITH_YOUR_AGE_PUBLIC_KEY with actual dev age public key
#     generate: age-keygen -o ~/.config/sops/age/keys.txt
#     read public key: grep "public key" ~/.config/sops/age/keys.txt
#     this file IS committed — only public keys go here, never private keys
# [ ] replace age1REPLACE_WITH_CI_AGE_PUBLIC_KEY with CI age public key
#     store private key as SOPS_AGE_KEY secret in GitHub Actions / CI provider
# [ ] uncomment cloud KMS block when RICE_CLOUD_PROVIDER is set:
#     AWS: arn format — ACCOUNT_ID and KEY_ID read from .opentofu output
#     GCP: PROJECT_ID and KEY ring read from .opentofu output
#     Azure: VAULT name and KEY version read from .opentofu output
# [ ] add path_regex for custom/{project}/secrets/ — per-project encrypted secrets
#     CHIEF generates this path on rice prepare {project}

# ── named keys — edit public keys here ───────────────────
keys:
  - &dev age1REPLACE_WITH_YOUR_AGE_PUBLIC_KEY
  - &ci age1REPLACE_WITH_CI_AGE_PUBLIC_KEY
  # cloud KMS — uncomment when cloud provider is configured
  # - &aws  arn:aws:kms:eu-central-1:ACCOUNT_ID:key/KEY_ID
  # - &gcp  projects/PROJECT_ID/locations/global/keyRings/RING/cryptoKeys/KEY
  # - &az   https://VAULT.vault.azure.net/keys/KEY/VERSION

# ── creation rules — evaluated sequentially, first match wins ──
creation_rules:
  # ── local dev secrets — age only ─────────────────────────
  - path_regex: ^secrets\.enc\.env$
    key_groups:
      - age:
          - *dev
          - *ci

  # ── per-role secrets ──────────────────────────────────────
  - path_regex: ^infra/secrets/.*\.enc\.(env|yaml|json)$
    key_groups:
      - age:
          - *dev
          - *ci

  # ── model registry secrets (API keys, HuggingFace tokens) ─
  - path_regex: ^function/model/secrets/.*\.enc\.(env|yaml)$
    key_groups:
      - age:
          - *dev
          - *ci

  # ── cloud provider credentials ────────────────────────────
  - path_regex: ^\.opentofu/.*\.enc\.(tfvars|yaml)$
    key_groups:
      - age:
          - *dev
          - *ci
    # uncomment when cloud KMS is configured:
    # - kms:
    #     - arn: *aws

  # ── Kubernetes secrets ────────────────────────────────────
  - path_regex: ^\.k8s/.*secrets.*\.yaml$
    encrypted_regex: ^(data|stringData)$
    key_groups:
      - age:
          - *dev
          - *ci

  # ── catchall — anything .enc. not matched above ───────────
  - path_regex: .*\.enc\.(env|yaml|json|toml)$
    key_groups:
      - age:
          - *dev
          - *ci

# ── global options ────────────────────────────────────────
# compute MAC only over encrypted values — not entire file
# prevents false MAC failures on _unencrypted keys
mac_only_encrypted: true






"""#
		}
]
