//! User-facing diagnostics — re-export `miette` primitives; build [`Report`](miette::Report) at call sites.

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
// [ ] https://docs.rs/miette/ — tower_lsp Diagnostic mapping, RICE_DIAGNOSTIC_THEME

pub use miette::{Diagnostic, LabeledSpan, NamedSource, Report, SourceSpan};
