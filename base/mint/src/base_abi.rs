//! Registry of stable Rust paths for codegen / bowl manifests (`BASE_ABI` lookup).
//!
//! Downstream templates resolve these symbols when emitting crates that link against `base/`.

/// One logical type or trait surface exposed to templates.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AbiEntry {
    /// Short name used in bowl / minijinja context (e.g. `"Error"`).
    pub symbol: &'static str,
    /// Fully-qualified or crate-root path in this workspace.
    pub rust_path: &'static str,
}

/// Canonical entries for the default language toolchain (extend per `[language]` in bowl).
pub const BASE_ABI: &[AbiEntry] = &[
    AbiEntry {
        symbol: "Error",
        rust_path: "util::Error",
    },
    AbiEntry {
        symbol: "Result",
        rust_path: "util::Result",
    },
    AbiEntry {
        symbol: "ZkEngine",
        rust_path: "private::ZkEngine",
    },
    AbiEntry {
        symbol: "ZkEnvironment",
        rust_path: "private::ZkEnvironment",
    },
];

/// Look up a path by symbol, if present.
#[must_use]
pub fn resolve(symbol: &str) -> Option<&'static str> {
    BASE_ABI
        .iter()
        .find(|e| e.symbol == symbol)
        .map(|e| e.rust_path)
}
