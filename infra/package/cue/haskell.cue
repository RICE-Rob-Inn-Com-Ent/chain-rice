package package

languageHaskell: {
  manager:      "stack/cabal"
  manifestFile: "package.yaml"
  ecosystem:    "haskell"
  manifests: [
    "base/package.yaml",
  ]

  project: {
    path: "base/package.yaml"
    package: {
      name:    "rice-base"
      version: "0.1.0"
    }
    resolver: "lts-22.38"
    ghcOptions: ["-Wall", "-Werror"]
    dependencies: [
      "base >= 4.14 && < 5",
      "text",
      "aeson",
      "bytestring",
      "containers",
    ]
  }

  constraints: {
    _hasCoreBaseDep: project.dependencies[0] == "base >= 4.14 && < 5"
  }

  render: {
    packageYaml: {
      name: "base"
      path: project.path
      kind: "package-yaml"
      data: project
    }
  }
  emitFiles: [
    {
      path: "base/.hlint.yaml"
      content: #"""
# HLint – Haskell linter | Rice monorepo
# https://github.com/ndmitchell/hlint

- ignore: { name: "Use camelCase" }
- ignore: { name: "Reduce duplication" }
- hint: { lhs: "concat (map f x)", rhs: "concatMap f x", note: "Use concatMap" }
- hint: { lhs: "concat $ map f x", rhs: "concatMap f x", note: "Use concatMap" }
- hint: { lhs: "map f (map g x)", rhs: "map (f . g) x", note: "Use function composition" }
- hint: { lhs: "f $ g x", rhs: "f (g x)", note: "Unnecessary $" }
- group: { name: "general", enabled: true }
- group: { name: "brittany", enabled: false }
- group: { name: "camelCase", enabled: false }
- group: { name: "unused", enabled: true }
"""#
    },
    {
      path: "base/calc/calc.cabal"
      content: #"""
cabal-version: 3.8

-- Regenerate: `just _hpack-clerk` (hpack reads ../package.yaml, writes this file next to lib/).

name: calc
version: 0.1.0
synopsis:
  Clerk financial kernel — Decimal money, hledger-backed ledger, interest, tax, QuickCheck laws
author: Clerk contributors
maintainer: clerk@example.invalid
license: AGPL-3.0-only
build-type: Simple

source-repository head
  type: git
  location: https://github.com/mrDinkelman/rice

common shared
  default-language: GHC2024
  ghc-options:
    -Wall
    -Wcompat
    -Widentities
    -Wincomplete-record-updates
    -Wincomplete-uni-patterns
    -Wmissing-export-lists
    -Wmissing-home-modules
    -Wpartial-fields
    -Wredundant-constraints
    -O2
  default-extensions:
    OverloadedStrings
    DeriveGeneric
    DerivingStrategies
    GeneralizedNewtypeDeriving
    LambdaCase
    TupleSections

library
  import: shared
  exposed-modules:
    Lib
    Decimal
    Finance
    Ledger
    Risk
    FFI
    Wire
    Verify
  hs-source-dirs: lib
  build-depends:
    Decimal >= 0.5,
    QuickCheck >= 2.15,
    aeson >= 2.2,
    base >= 4.18 && < 5,
    bytestring >= 0.12,
    containers >= 0.7,
    hledger-lib >= 1.34,
    scientific >= 0.3,
    text >= 2.1,
    time >= 1.12,

test-suite clerk-calc-test
  import: shared
  type: exitcode-stdio-1.0
  main-is: LogicSpec.hs
  hs-source-dirs: test
  other-modules:
    AuditSpec
    FuzzSpec
  build-depends:
    base >= 4.18 && < 5,
    bytestring >= 0.12,
    calc,
    hspec >= 2.11,
    QuickCheck >= 2.15,

-- Rust util::calc dlopens FFI (C symbols calc_*); JSON via Wire; binary v1 in same FFI module.

foreign-library calc_ffi
  import: shared
  type: native-shared
  visibility: public
  ghc-options: -fPIC -threaded
  hs-source-dirs: lib
  other-modules: FFILink
  build-depends:
    base >= 4.18 && < 5,
    calc,
"""#
    },
    {
      path: "base/package.yaml"
      content: #"""
# Haskell workspace root (jak base/Cargo.toml). hpack czyta ten plik w base/;
# wygenerowany clerk-calc.cabal ląduje w base/calc/ (obok lib/) — just _hpack-clerk.
#
# dependencies jako mapa (jak npm package.json) — wtedy schema „package.yaml” w IDE nie krzyczy;
# hpack traktuje listę i mapę równoważnie (README hpack).

name: calc
version: 0.1.0
synopsis: Clerk financial kernel — Decimal money, hledger-backed ledger, interest, tax, QuickCheck laws
license: AGPL-3.0-only
author: Clerk contributors
maintainer: clerk@example.invalid
copyright: (c) 2026 Clerk contributors
github: mrDinkelman/rice

language: GHC2024

ghc-options:
  - -Wall
  - -Wcompat
  - -Widentities
  - -Wincomplete-record-updates
  - -Wincomplete-uni-patterns
  - -Wmissing-export-lists
  - -Wmissing-home-modules
  - -Wpartial-fields
  - -Wredundant-constraints
  - -O2

default-extensions:
  - OverloadedStrings
  - DeriveGeneric
  - DerivingStrategies
  - GeneralizedNewtypeDeriving
  - LambdaCase
  - TupleSections

dependencies:
  base: ">= 4.18 && < 5"
  scientific: ">= 0.3"
  Decimal: ">= 0.5"
  hledger-lib: ">= 1.34"
  QuickCheck: ">= 2.15"
  text: ">= 2.1"
  bytestring: ">= 0.12"
  containers: ">= 0.7"
  aeson: ">= 2.2"
  time: ">= 1.12"

# foreign-library calc_ffi is maintained in base/calc/calc.cabal (not generated here).

library:
  source-dirs: calc/lib
  exposed-modules:
    - Lib
    - Decimal
    - Finance
    - Ledger
    - Risk
    - FFI
    - Wire
    - Verify

tests:
  calc-test:
    main: LogicSpec.hs
    source-dirs: calc/test
    other-modules:
      - AuditSpec
      - FuzzSpec
    dependencies:
      calc: {}
      bytestring: ">= 0.12"
      hspec: ">= 2.11"
      QuickCheck: ">= 2.15"
"""#
    },
  ]
}
