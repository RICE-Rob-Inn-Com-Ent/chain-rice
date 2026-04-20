//! Compiler error taxonomy — combine `thiserror` with `miette` in [`crate::diagnostic`] for display.

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use thiserror::Error;

// [ ] https://docs.rs/miette/ https://docs.rs/logos/ https://docs.rs/chumsky/
// [ ] LexError, ParseError, CheckError, LowerError, CodegenError, GraphCycle, IoError, TemplateError

#[derive(Debug, Error)]
pub enum CompileError {
    #[error(transparent)]
    Parse(#[from] ParseError),
    #[error(transparent)]
    Type(#[from] TypeError),
    #[error(transparent)]
    Codegen(#[from] CodegenError),
}

#[derive(Debug, Error)]
pub enum ParseError {
    #[error("parse error: {0}")]
    Message(String),
}

#[derive(Debug, Error)]
pub enum TypeError {
    #[error("type checking not implemented")]
    Unimplemented,
}

#[derive(Debug, Error)]
pub enum CodegenError {
    #[error(transparent)]
    Template(#[from] minijinja::Error),
}
