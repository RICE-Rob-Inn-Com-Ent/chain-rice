package package

languageRust: {
  manager:       "cargo"
  manifestFile:  "Cargo.toml"
  workspaceRoot: "base/Cargo.toml"

  manifests: [
    "base/Cargo.toml",
    "base/bench/Cargo.toml",
    "base/contract/Cargo.toml",
    "base/mint/Cargo.toml",
    "base/policies/Cargo.toml",
    "base/private/Cargo.toml",
    "base/util/Cargo.toml",
  ]

  workspace: {
    members: ["contract", "policies", "private", "mint", "bench", "util"]
    resolver: "2"
    packageMeta: {
      version:    "0.1.0"
      edition:    "2024"
      authors:    ["Code-Rice"]
      license:    "AGPL-3.0-only"
      repository: "https://github.com/RICE-Rob-Inn-Com-Ent/rice"
    }
    // Single source of truth for external crates.
    // Module-level dependencies must reference entries from this map.
    workspaceDependencies: {
      thiserror:            "2.0"
      libloading:           "0.8"
      libc:                 "0.2"
      proptest:             "1.6"
      prost:                {version: "0.13", defaultFeatures: false, features: ["std", "derive"]}
      bytes:                "1.10"
      hex:                  {version: "0.4", features: ["serde"]}
      constant_time_eq:     "0.3"
      serde:                {version: "1.0", features: ["derive"]}
      serde_json:           "1.0"
      tracing:              {version: "0.1", defaultFeatures: false, features: ["std"]}
      rayon:                "1.10"
      cosmwasm_std:         "2.2"
      cosmwasm_schema:      "2.2"
      cw_storage_plus:      "2.0"
      cw2:                  "2.0"
      cw_multi_test:        "2.2"
      sylvia:               "1.3"
      rust_decimal:         {version: "1.36", features: ["serde"]}
      num_bigint:           "0.4"
      num_traits:           "0.2"
      getrandom:            {version: "0.2", features: ["custom"]}
      ed25519_dalek:        {version: "2.1", features: ["rand_core"]}
      sha2:                 "0.10"
      sha3:                 "0.10"
      aes_gcm:              "0.10"
      chacha20poly1305:     "0.10"
      k256:                 "0.13"
      pqcrypto:             {version: "0.17", defaultFeatures: false, features: ["pqcrypto-dilithium", "pqcrypto-falcon"]}
      cel_interpreter:      {version: "0.9", features: ["json"]}
      cel_parser:           "0.8.1"
      fefix:                "0.7"
      quick_xml:            {version: "0.37", features: ["serialize"]}
      iso_currency:         {version: "0.4", features: ["with-serde"]}
      chrono:               {version: "0.4", features: ["serde"]}
      ulid:                 {version: "1.1", features: ["serde"]}
      nats:                 "0.24"
      memmap2:              "0.9"
      ark_groth16:          {version: "0.4", features: ["r1cs", "parallel"]}
      ark_bn254:            {version: "0.4", features: ["curve"]}
      ark_bls12_381:        {version: "0.4", features: ["curve"]}
      ark_ff:               {version: "0.4", features: ["std", "parallel"]}
      ark_ec:               {version: "0.4", features: ["std", "parallel"]}
      ark_serialize:        {version: "0.4", features: ["derive", "std"]}
      ark_std:              {version: "0.4", features: ["std"]}
      ark_relations:        {version: "0.4", features: ["std"]}
      ark_r1cs_std:         {version: "0.4", defaultFeatures: false, features: ["std", "parallel"]}
      ark_snark:            "0.4"
      ark_crypto_primitives:{version: "0.4", defaultFeatures: false, features: ["snark", "r1cs", "std", "parallel", "merkle_tree", "crh", "commitment", "sponge", "encryption", "signature", "prf"]}
      logos:                "0.15"
      chumsky:              "0.10"
      rowan:                "0.16"
      salsa:                "0.19"
      miette:               {version: "7.4", features: ["fancy"]}
      minijinja:            "2.5"
      tower_lsp:            "0.20"
      petgraph:             "0.6"
      tokio:                {version: "1", features: ["macros", "rt-multi-thread", "io-std", "time"]}
      async_trait:          "0.1"
      criterion:            {version: "0.5", features: ["html_reports"]}
      tracing_subscriber:   {version: "0.3", features: ["fmt", "env-filter"]}
      rand:                 {version: "0.8", features: ["std_rng"]}
    }
  }

  // Full module manifests (normalized model).
  modules: {
    util: {
      path: "base/util/Cargo.toml"
      package: {
        name:        "util"
        description: "Near-metal utilities, FFI bridges, and byte manipulation"
        build:       "build.rs"
      }
      libPath: "src/lib.rs"
      features: {
        default:      ["test-utils"]
        "test-utils":   ["dep:proptest"]
        "calc-bridge":  ["dep:libloading", "dep:libc", "dep:serde", "dep:serde_json"]
        "zig-warden":   []
      }
      dependencies: {
        thiserror:         {workspace: true}
        prost:             {workspace: true}
        bytes:             {workspace: true}
        hex:               {workspace: true}
        constant_time_eq:  {workspace: true}
        proptest:          {workspace: true, optional: true}
        tracing:           {workspace: true}
        libloading:        {workspace: true, optional: true}
        libc:              {workspace: true, optional: true}
        serde:             {workspace: true, optional: true}
        serde_json:        {workspace: true, optional: true}
      }
      internalDependencies: {}
    }
    bench: {
      path: "base/bench/Cargo.toml"
      package: {
        name:        "bench"
        description: "RICE criterion benchmarks — integration across contract, ZK, compiler, policies"
      }
      libPath: "src/lib.rs"
      bins: [{name: "bench", path: "src/main.rs"}]
      dependencies: {
        criterion:          {workspace: true}
        tracing_subscriber: {workspace: true}
        serde:              {workspace: true}
        serde_json:         {workspace: true}
      }
      internalDependencies: {
        util:     {path: "../util", defaultFeatures: false}
        contract: {path: "../contract"}
        private:  {path: "../private"}
        mint:     {path: "../mint"}
        policies: {path: "../policies"}
      }
      features: {
        default:           []
        "bench-pq":           ["contract/post-quantum"]
        "calc-parity":        ["policies/calc-bridge"]
        "calc-bench":         ["util/calc-bridge"]
        "zig-security-bench": ["util/zig-warden"]
        "full-native-benches":["util/zig-warden", "policies/calc-bridge"]
      }
    }
    contract: {
      path: "base/contract/Cargo.toml"
      package: {
        name:        "contract"
        description: "RICE CosmWasm contract (Sylvia, cw-storage-plus)"
      }
      libCrateType: ["cdylib", "rlib"]
      dependencies: {
        cosmwasm_std:    {workspace: true}
        cosmwasm_schema: {workspace: true}
        cw_storage_plus: {workspace: true}
        cw2:             {workspace: true}
        sylvia:          {workspace: true}
        serde:           {workspace: true}
        serde_json:      {workspace: true}
        thiserror:       {workspace: true}
        rust_decimal:    {workspace: true}
        num_bigint:      {workspace: true}
        ed25519_dalek:   {workspace: true}
        sha2:            {workspace: true}
        sha3:            {workspace: true}
        aes_gcm:         {workspace: true}
        k256:            {workspace: true}
        pqcrypto:        {workspace: true, optional: true}
      }
      internalDependencies: {
        util:  {path: "../util"}
        bench: {path: "../bench"}
      }
      features: {
        default:      []
        library:      []
        "post-quantum": ["dep:pqcrypto"]
      }
      targetDependencies: {
        wasm32: {
          getrandom: {workspace: true}
        }
      }
      devDependencies: {
        cw_multi_test: {workspace: true}
        rand:          {workspace: true}
        sylvia:        {workspace: true, features: ["mt"]}
      }
    }
    mint: {
      path: "base/mint/Cargo.toml"
      package: {
        name:        "mint"
        description: "Compiler — lexer, parser, rowan CST, salsa queries, LSP"
      }
      libPath: "src/lib.rs"
      bins: [{name: "rice-lsp", path: "src/lsp.rs"}]
      dependencies: {
        serde_json:  {workspace: true}
        logos:       {workspace: true}
        chumsky:     {workspace: true}
        rowan:       {workspace: true}
        salsa:       {workspace: true}
        miette:      {workspace: true}
        minijinja:   {workspace: true}
        tower_lsp:   {workspace: true}
        petgraph:    {workspace: true}
        thiserror:   {workspace: true}
        tokio:       {workspace: true}
        async_trait: {workspace: true}
      }
      internalDependencies: {
        util:  {path: "../util"}
        bench: {path: "../bench"}
      }
      features: {
        default:  []
        "lsp-perf": []
      }
    }
    policies: {
      path: "base/policies/Cargo.toml"
      package: {
        name:        "policies"
        description: "Policy — CEL, FIX, ISO 4217, schedules, audit"
      }
      libPath: "src/lib.rs"
      dependencies: {
        cel_interpreter: {workspace: true}
        cel_parser:      {workspace: true}
        fefix:           {workspace: true, optional: true}
        quick_xml:       {workspace: true}
        iso_currency:    {workspace: true}
        k256:            {workspace: true}
        chrono:          {workspace: true}
        serde:           {workspace: true}
        serde_json:      {workspace: true}
        thiserror:       {workspace: true}
        hex:             {workspace: true}
        rust_decimal:    {workspace: true}
        rayon:           {workspace: true}
        sha2:            {workspace: true}
        ulid:            {workspace: true}
        prost:           {workspace: true, optional: true}
        nats:            {workspace: true, optional: true}
      }
      internalDependencies: {
        util:  {path: "../util"}
        bench: {path: "../bench"}
      }
      features: {
        default:         ["fix-protocol"]
        "calc-bridge":   ["util/calc-bridge"]
        "audit-proto":   ["dep:prost"]
        "audit-nats":    ["dep:nats"]
        "fix-protocol":  ["dep:fefix"]
        "xml-interchange":[]
      }
    }
    private: {
      path: "base/private/Cargo.toml"
      package: {
        name:        "private"
        description: "ZK layer — Groth16, BN254/BLS12-381 circuits, proof lifecycle"
      }
      libPath: "src/lib.rs"
      dependencies: {
        num_bigint:            {workspace: true}
        num_traits:            {workspace: true}
        ark_bls12_381:         {workspace: true}
        ark_bn254:             {workspace: true}
        ark_crypto_primitives: {workspace: true}
        ark_ec:                {workspace: true}
        ark_ff:                {workspace: true}
        ark_groth16:           {workspace: true}
        ark_serialize:         {workspace: true}
        ark_relations:         {workspace: true}
        ark_r1cs_std:          {workspace: true}
        ark_snark:             {workspace: true}
        ark_std:               {workspace: true}
        thiserror:             {workspace: true}
        rand:                  {workspace: true}
        sha2:                  {workspace: true}
        tracing:               {workspace: true}
        rayon:                 {workspace: true}
        chacha20poly1305:      {workspace: true}
        memmap2:               {workspace: true}
      }
      internalDependencies: {
        util:  {path: "../util"}
        bench: {path: "../bench"}
      }
    }
  }

  // Hermetic dependency policy:
  // - util and bench are the only globally shared internal modules.
  // - all non-core modules depend on util + bench directly.
  // - no non-core module may directly depend on another non-core module.
  constraints: {
    sharedInternalModules: ["util", "bench"]
    hermeticModules:       ["contract", "mint", "policies", "private"]

    for moduleName, module in modules if moduleName != "util" && moduleName != "bench" {
      _mustUseUtil:  module.internalDependencies.util.path  == "../util"
      _mustUseBench: module.internalDependencies.bench.path == "../bench"
      for depName, _ in module.internalDependencies
      if depName != "util" && depName != "bench" {
        _forbidden: _|_ // forbidden non-hermetic edge
      }
    }
  }

  // Render hints consumed by package index exporter/build system.
  render: {
    workspaceToml: {
      path: workspaceRoot
      kind: "cargo-workspace"
      data: workspace
    }
    moduleTomls: [
      {name: "util",     path: modules.util.path,     kind: "cargo-manifest", data: modules.util},
      {name: "bench",    path: modules.bench.path,    kind: "cargo-manifest", data: modules.bench},
      {name: "contract", path: modules.contract.path, kind: "cargo-manifest", data: modules.contract},
      {name: "mint",     path: modules.mint.path,     kind: "cargo-manifest", data: modules.mint},
      {name: "policies", path: modules.policies.path, kind: "cargo-manifest", data: modules.policies},
      {name: "private",  path: modules.private.path,  kind: "cargo-manifest", data: modules.private},
    ]
  }
  emitFiles: [
    {
      path: "base/.clippy.toml"
      content: #"""
avoid-breaking-exported-api = false
avoid-missing-docs-in-crate-items = false
avoid-missing-docs-in-implementations = false
avoid-missing-docs-in-traits = false
single-char-binding-names-threshold = 4
too-many-arguments-threshold = 7
type-complexity-threshold = 250
verbose-group-macro-expansion = false
disallowed-methods = []
disallowed-types = []
disallowed-macros = []
"""#
    },
    {
      path: "base/rustfmt.toml"
      content: #"""
edition = "2021"
max_width = 120
hard_tabs = false
tab_spaces = 4
newline_style = "Unix"
reorder_imports = true
use_small_heuristics = "Default"
fn_call_width = 80
attr_fn_like_width = 80
struct_lit_width = 40
struct_variant_width = 40
array_width = 80
chain_width = 80
single_line_if_else_max_width = 60
use_field_init_shorthand = true
use_try_shorthand = true
force_explicit_abi = true
remove_nested_parens = true
match_arm_leading_pipes = "Never"
match_block_trailing_comma = true
ignore = []
"""#
    },
    {
      path: "base/fourmolu.yaml"
      content: #"""
# Fourmolu – Haskell formatter | Rice monorepo
# https://github.com/fourmolu/fourmolu

indentation: 4
column-limit: 100
function-arrows: leading
comma-style: leading
import-export-style: leading
record-brace-space: true
indent-wheres: true
record-style: mixed
newlines-between-decls: 1
haddock-style: single-line
haddock-style-module: single-line
let-style: auto
in-style: right-align
single-constraint-parens: always
unicode: never
respectful: true
fixity-declarations: inline
reexport-style: mixed
"""#
    },
  ]
}