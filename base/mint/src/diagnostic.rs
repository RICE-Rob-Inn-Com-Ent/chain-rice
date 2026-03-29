//! User-facing diagnostics — re-export `miette` primitives; build [`Report`](miette::Report) at call sites.

// [ ] https://docs.rs/miette/ — tower_lsp Diagnostic mapping, RICE_DIAGNOSTIC_THEME

pub use miette::{Diagnostic, LabeledSpan, NamedSource, Report, SourceSpan};
