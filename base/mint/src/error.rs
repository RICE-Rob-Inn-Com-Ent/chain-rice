//! Compiler error taxonomy — combine `thiserror` with `miette` in [`crate::diagnostic`] for display.

use thiserror::Error;

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
