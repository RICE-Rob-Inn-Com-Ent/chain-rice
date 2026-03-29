//! Typed errors for the policy layer — CEL, evaluation, interchange parsing, validation.

use thiserror::Error;

// [ ] https://docs.rs/cel-interpreter/
// [ ] CelParseError, CelEvalError, RuleNotFound, ValidationFailed, AuditPublishError, XmlParseError, FixProtocolError, CurrencyError, ScheduleError

/// Top-level error for policy operations (CEL, IO, validation).
#[derive(Error, Debug)]
pub enum PolicyError {
    #[error(transparent)]
    CelParse(#[from] cel_interpreter::ParseError),

    #[error(transparent)]
    CelExec(#[from] cel_interpreter::ExecutionError),

    #[error(transparent)]
    Parse(#[from] ParseError),

    #[error(transparent)]
    Validation(#[from] ValidationError),
}

/// CEL evaluation failures (alias-style wrapper for clarity in APIs).
#[derive(Error, Debug)]
pub enum EvalError {
    #[error(transparent)]
    Cel(#[from] cel_interpreter::ExecutionError),
}

/// Policy interchange and document parsing (JSON/XML), distinct from CEL parse errors.
#[derive(Error, Debug)]
pub enum ParseError {
    #[error(transparent)]
    Json(#[from] serde_json::Error),

    #[error(transparent)]
    XmlSerialize(#[from] quick_xml::SeError),

    #[error(transparent)]
    XmlDeserialize(#[from] quick_xml::DeError),
}

/// Business validation — currencies, periods, rule invariants.
#[derive(Error, Debug, PartialEq, Eq)]
pub enum ValidationError {
    #[error("unknown ISO 4217 currency code: {0}")]
    UnknownCurrency(String),

    #[error("empty rule identifier")]
    EmptyRuleId,

    #[error("invalid time period: end before start")]
    InvalidPeriod,
}
