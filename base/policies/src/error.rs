//! The **guardian of order** for the policy layer — typed failures that bridge human-readable legal
//! and compliance intent with engine-executable checks.
//!
//! [`PolicyError`] is the single arbiter when *code-as-law* refuses to proceed: asset / unit rules,
//! decimal arithmetic invariants, CEL evaluation, schedule windows, specification translation, and
//! the **banker's rule** (value conservation). Auditors read the variants; [`engine`](crate::engine)
//! matches on them to halt, retry, or escalate across the CLERK boundary via [`util::Error`].

use thiserror::Error;
use util::Error;

// --- Financial & currency ----------------------------------------------------

/// Asset / unit typing — unknown labels in a registry, scale violations, or illegal cross-asset math.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum CurrencyError {
    /// Label is not present in the supplied [`crate::currency::AssetRegistry`].
    #[error("unknown asset label in registry: {0}")]
    UnknownAssetLabel(String),

    /// Fractional digit count exceeds the asset's declared precision.
    #[error("precision mismatch: expected at most {expected} fractional digits, got {actual} ({asset})")]
    ScaleMismatch {
        asset: String,
        expected: u8,
        actual: u8,
    },

    /// Combined two [`crate::currency::Amount`] values with different [`crate::currency::AssetTag`]s.
    #[error("cross-asset arithmetic without conversion: {left} vs {right}")]
    CrossAsset { left: String, right: String },

    /// Asset label failed structural validation (empty, too long, disallowed characters).
    #[error("invalid asset label: {0}")]
    InvalidAssetLabel(String),
}

/// Fixed-point decimal and ledger arithmetic failures (`rust_decimal` and policy-checked ops).
#[derive(Error, Debug)]
pub enum FinanceError {
    /// Result or intermediate exceeded representable range.
    #[error("decimal overflow during `{operation}`")]
    Overflow { operation: String },

    /// Division with a zero divisor (engine must not substitute “near zero”).
    #[error("division by zero in `{operation}`")]
    DivisionByZero { operation: String },

    /// Rounding or rescaling would silently discard material precision — refused.
    #[error("precision loss refused in `{operation}`: {detail}")]
    PrecisionLoss { operation: String, detail: String },

    /// `rust_decimal` parse, rescale, or conversion error.
    #[error(transparent)]
    Decimal(#[from] rust_decimal::Error),

    #[error("basis points {got} invalid (must be 0..={max})")]
    InvalidBasisPoints { got: i64, max: i64 },

    #[error("unit ratio must be in [0, 1], got {0}")]
    InvalidUnitRatio(String),

    #[error("policy limit `{key}` not found")]
    LimitNotFound { key: String },

    #[error("bracket configuration invalid: {0}")]
    InvalidBrackets(String),
}

// --- Rules (CEL) -------------------------------------------------------------

/// Common Expression Language — parse, execute, and binding failures.
#[derive(Error, Debug)]
pub enum RuleError {
    #[error(transparent)]
    Parse(#[from] cel_interpreter::ParseError),

    #[error(transparent)]
    Eval(#[from] cel_interpreter::ExecutionError),

    #[error("CEL rule not registered: `{0}`")]
    NotFound(String),

    #[error("CEL binding failed for `{name}`: {reason}")]
    Binding { name: String, reason: String },

    #[error("CEL source exceeds max length: {len} bytes (limit {max} bytes)")]
    SourceTooLarge { len: usize, max: usize },

    #[error("CEL expression too complex: {nodes} AST nodes (limit {max_nodes})")]
    AstTooLarge { nodes: usize, max_nodes: usize },

    #[error("CEL expression nesting too deep: depth {depth} (limit {max_depth})")]
    AstTooDeep { depth: usize, max_depth: usize },

    #[error("amount `{asset}` does not fit minor-unit integer for CEL (i64): {detail}")]
    MinorUnitOverflow { asset: String, detail: String },
}

/// Narrow wrapper when an API only surfaces execution failures (alias-style clarity).
#[derive(Error, Debug)]
pub enum EvalError {
    #[error(transparent)]
    Cel(#[from] cel_interpreter::ExecutionError),
}

// --- Specification (human intent → machine schedule) -------------------------

/// The policy DSL / interchange could not translate author intent into an executable schedule.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum SpecificationError {
    #[error("rule identifier must be non-empty")]
    EmptyRuleIdentifier,

    #[error("ambiguous human intent: {0}")]
    AmbiguousIntent(String),

    #[error("unsupported policy construct `{construct}` (line={line:?})")]
    UnsupportedConstruct { construct: String, line: Option<u32> },

    #[error("could not translate schedule intent: {reason} (source: {source_excerpt})")]
    TranslationFailed { source_excerpt: String, reason: String },

    #[error("policy identifier must be non-empty")]
    EmptyPolicyIdentifier,

    #[error("policy must contain at least one rule")]
    EmptyRuleSet,

    #[error("duplicate rule id: `{0}`")]
    DuplicateRuleId(String),

    #[error("limit map key must be non-empty")]
    EmptyLimitKey,

    #[error("invalid limit `{key}`: {reason}")]
    InvalidLimitEntry { key: String, reason: String },

    #[error("unsupported policy specification schema {major}.{minor}")]
    UnsupportedSpecificationVersion { major: u16, minor: u16 },
}

// --- Temporal ----------------------------------------------------------------

/// Deadlines, recurrence, and ordering of financial events.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum ScheduleError {
    #[error("invalid time window: end is before start")]
    InvalidPeriod,

    #[error("deadline breached: due {due_rfc3339}, now {now_rfc3339}")]
    DeadlineBreached { due_rfc3339: String, now_rfc3339: String },

    #[error("invalid recurrence specification: {0}")]
    InvalidRecurrence(String),

    /// Event or posting timestamp moved backwards relative to the journal tail (“time travel”).
    #[error("event timestamp {event_rfc3339} precedes last sealed log time {last_sealed_rfc3339}")]
    TimeTravel {
        event_rfc3339: String,
        last_sealed_rfc3339: String,
    },
}

// --- Accounting (double-entry ledger) -----------------------------------------

/// Double-entry ledger and balance partition violations.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum AccountingError {
    #[error(
        "ledger legs do not conserve value for {asset}: total in {sum_in} != total out {sum_out}"
    )]
    UnbalancedLegs {
        asset: String,
        sum_in: String,
        sum_out: String,
    },

    #[error(
        "insufficient balance: account `{account}` partition {partition:?} asset {asset} need {need} have {have}"
    )]
    InsufficientBalance {
        account: String,
        partition: String,
        asset: String,
        need: String,
        have: String,
    },

    #[error("ledger posting amount must be strictly positive")]
    NonPositiveAmount,

    #[error("account id must be non-empty")]
    EmptyAccountId,

    #[error("all legs in one entry must share the same asset tag")]
    CrossAssetInEntry,

    #[error("ledger entry must contain at least one leg")]
    EmptyLedgerEntry,
}

// --- Banker's rule (value conservation) ---------------------------------------

/// **Banker's rule:** no spontaneous creation or destruction of nominal value across a closed policy
/// evaluation. The engine returns this error instead of panicking — a **safe halt** with structured
/// detail for audit trails.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum BankersRuleError {
    #[error("double-entry imbalance: debits {debits_minor} != credits {credits_minor} ({currency})")]
    UnbalancedLedger {
        currency: String,
        debits_minor: String,
        credits_minor: String,
    },

    #[error("settlement residual must be zero: remainder {residual_minor} ({currency}), context: {context}")]
    NonZeroResidual {
        currency: String,
        residual_minor: String,
        context: String,
    },

    #[error(
        "flow conservation violated: expected total {expected_minor}, observed {actual_minor} ({currency}) — {narrative}"
    )]
    FlowMismatch {
        currency: String,
        expected_minor: String,
        actual_minor: String,
        narrative: String,
    },
}

// --- Legal / jurisdictional firewall -----------------------------------------

/// Machine-verifiable legal constraints: forbidden CEL fragments, mandatory policy text, identity
/// keys, and fair-exchange (code vs payment) guards.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum LegalError {
    /// A [`crate::legal::LegalManifest::forbidden_actions`] substring matched a rule's CEL source.
    #[error("forbidden CEL fragment `{pattern}` present in rule `{rule_id}`")]
    ForbiddenCel { pattern: String, rule_id: String },

    /// A [`crate::legal::LegalManifest::mandates`] substring was not found in the policy surface
    /// (rules, metadata, limit keys).
    #[error("mandatory policy fragment not present in policy surface: {mandate}")]
    MandateMissing { mandate: String },

    /// Code / IP style policy without a verified escrow path or required limit keys.
    #[error("fair exchange: {detail}")]
    FairExchange { detail: String },

    /// SEC1 public key bytes are not a valid non-trivial secp256k1 point.
    #[error("legal identity: invalid secp256k1 public key ({detail})")]
    InvalidIdentityKey { detail: String },
}

// --- Wire / document interchange --------------------------------------------

/// JSON / XML policy interchange — distinct from CEL [`RuleError::Parse`].
#[derive(Error, Debug)]
pub enum ParseError {
    #[error(transparent)]
    Json(#[from] serde_json::Error),

    #[error(transparent)]
    XmlSerialize(#[from] quick_xml::SeError),

    #[error(transparent)]
    XmlDeserialize(#[from] quick_xml::DeError),

    /// Document [`crate::serial::PolicySchemaVersion`] is not supported by this build (use a migrator or older verifier).
    #[error(
        "unsupported policy schema {major}.{minor} (this build expects {expected_major}.{expected_minor})"
    )]
    UnsupportedSchema {
        major: u16,
        minor: u16,
        expected_major: u16,
        expected_minor: u16,
    },
}

// --- Top level ---------------------------------------------------------------

/// Ultimate policy failure — contract rules, finance, CEL, schedules, conservation, or CLERK boundary.
#[derive(Error, Debug)]
pub enum PolicyError {
    #[error(transparent)]
    Currency(#[from] CurrencyError),

    #[error(transparent)]
    Finance(#[from] FinanceError),

    #[error(transparent)]
    Rule(#[from] RuleError),

    #[error(transparent)]
    Specification(#[from] SpecificationError),

    #[error(transparent)]
    Schedule(#[from] ScheduleError),

    #[error(transparent)]
    Accounting(#[from] AccountingError),

    /// Value conservation / double-entry — maps to [`Error::Finance`] when lifted.
    #[error(transparent)]
    BankersRule(#[from] BankersRuleError),

    #[error(transparent)]
    InterchangeParse(#[from] ParseError),

    #[error(transparent)]
    Legal(#[from] LegalError),

    /// Upstream/downstream CLERK or `util` failure wrapped for `?` inside the policy engine.
    #[error(transparent)]
    Clerk(#[from] Error),
}

/// Standard [`Result`] alias for policy operations.
pub type PolicyResult<T> = Result<T, PolicyError>;

impl PolicyError {
    /// `true` when nominal value conservation failed — treat as **non-retryable** without new inputs.
    #[must_use]
    pub fn is_bankers_rule_violation(&self) -> bool {
        matches!(self, PolicyError::BankersRule(_))
    }

    /// Conservative hint for workers: only transient I/O inside a wrapped [`Error`] may retry.
    #[must_use]
    pub fn is_retryable(&self) -> bool {
        match self {
            PolicyError::Clerk(e) => e.is_retryable(),
            _ => false,
        }
    }
}

impl From<PolicyError> for Error {
    fn from(e: PolicyError) -> Self {
        match e {
            PolicyError::Clerk(r) => r,
            PolicyError::BankersRule(b) => Error::finance(b.to_string()),
            PolicyError::Finance(f) => Error::finance(f.to_string()),
            PolicyError::Currency(c) => Error::policy(c.to_string()),
            PolicyError::Rule(r) => Error::policy(r.to_string()),
            PolicyError::Specification(s) => Error::policy(s.to_string()),
            PolicyError::Schedule(s) => Error::policy(s.to_string()),
            PolicyError::Accounting(a) => Error::policy(a.to_string()),
            PolicyError::InterchangeParse(p) => Error::policy(p.to_string()),
            PolicyError::Legal(l) => Error::policy(l.to_string()),
        }
    }
}

impl BankersRuleError {
    /// Build a [`PolicyError`] for an unbalanced ledger line set.
    #[must_use]
    pub fn unbalanced_ledger(
        currency: impl Into<String>,
        debits_minor: impl Into<String>,
        credits_minor: impl Into<String>,
    ) -> PolicyError {
        PolicyError::BankersRule(Self::UnbalancedLedger {
            currency: currency.into(),
            debits_minor: debits_minor.into(),
            credits_minor: credits_minor.into(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bankers_rule_maps_to_rice_finance() {
        let p: PolicyError = BankersRuleError::NonZeroResidual {
            currency: "USD".into(),
            residual_minor: "1".into(),
            context: "close batch".into(),
        }
        .into();
        let r = Error::from(p);
        match r {
            Error::Finance(msg) => assert!(msg.contains("settlement residual")),
            other => panic!("expected Finance, got {other:?}"),
        }
    }

    #[test]
    fn clerk_unwraps_to_inner_rice_error() {
        let p = PolicyError::Clerk(Error::invalid_argument("bad"));
        let out: Error = p.into();
        match out {
            Error::InvalidArgument(_) => {},
            _ => panic!("expected InvalidArgument"),
        }
    }
}
