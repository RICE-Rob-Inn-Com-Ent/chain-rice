//! RICE policy layer — CEL evaluation, FIX/finance hooks, legal XML, accounting constraints,
//! currency validation, schedules, and auditable decisions.

// [ ] https://docs.rs/cel-interpreter/
// [ ] pub mod engine, rules, audit, accounting, currency, finance, legal, schedule, serial, error
// [ ] export PolicyEngine, PolicyResult, Rule, RuleSet, AuditEvent — feature flags fix_protocol, xml_interchange from cue

pub mod accounting;
pub mod audit;
pub mod currency;
pub mod engine;
pub mod error;
pub mod finance;
pub mod legal;
pub mod rules;
pub mod schedule;
pub mod serial;

pub use error::{EvalError, ParseError, PolicyError, ValidationError};
