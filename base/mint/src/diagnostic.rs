//! User-facing diagnostics — re-export `miette` primitives; build [`Report`](miette::Report) at call sites.

pub use miette::{Diagnostic, LabeledSpan, NamedSource, Report, SourceSpan};
