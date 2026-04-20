//! **Sędzia** — judgment via CEL: raw law strings, injected [`RuleContext`], and a **caller-owned**
//! [`Context`](cel_interpreter::Context) (stdlib + any host functions you choose).
//!
//! ## Precision
//!
//! [`Amount`] is exposed to CEL as a map with **`value_milli`** (`int`): nominal value in the asset’s
//! smallest unit (\\(10^{precision}\\) scaling). Compare with integer ops only — no `double` drift.
//! **`value_exact`** holds the canonical decimal string for audit; **`label`** and **`precision`**
//! describe the unit.
//!
//! ## Resource bounds
//!
//! [`cel_interpreter`] has no runtime “fuel” hook. This module enforces a **static budget**:
//! maximum source size, AST node count, and nesting depth before execution. Treat any
//! [`PolicyError::Rule`] as a **veto** at the policy boundary when you need deny-by-default semantics
//! ([`Rule::allows`]).
//!
//! ## Lazy bindings
//!
//! With [`FactBindMode::ReferencedOnly`] (default), only variables **referenced** by the expression
//! are materialized as CEL values, reducing allocations for large fact maps.
//!
//! ## Schedule
//!
//! [`RuleContext::with_schedule`] injects `schedule` (see [`crate::schedule::schedule_to_cel_value`])
//! so CEL can use `schedule.is_active` and RFC 3339 string fields.

use std::collections::HashMap;

use cel_interpreter::{Context, Program, Value};
use cel_parser::{Expression, ExpressionReferences, Member, parse as parse_cel};
use chrono::{DateTime, FixedOffset, Utc};
use rust_decimal::Decimal;
use rust_decimal::prelude::ToPrimitive;
use serde::{Deserialize, Serialize};

use crate::currency::Amount;
use crate::error::{PolicyError, PolicyResult, RuleError, SpecificationError};
use crate::schedule::{ScheduleWindow, TimeTolerance, schedule_to_cel_value};

// --- Limits & bind mode ------------------------------------------------------

/// Static bounds applied **before** CEL execution (the interpreter does not expose step/gas hooks).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct EvaluationLimits {
    /// Maximum UTF-8 byte length of the CEL source string.
    pub max_source_bytes: usize,
    /// Maximum number of AST nodes (approximate work proxy).
    pub max_ast_nodes: usize,
    /// Maximum AST nesting depth (stack / recursion guard).
    pub max_ast_depth: usize,
    /// How [`RuleContext`] fields are mapped into the evaluation scope.
    pub bind_mode: FactBindMode,
}

/// Whether to bind every fact key or only those the expression references.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum FactBindMode {
    /// Bind only variables appearing in the CEL (fewer allocations).
    #[default]
    ReferencedOnly,
    /// Bind all entries from [`RuleContext`] (safe if reference collection misses dynamic edge cases).
    All,
}

impl Default for EvaluationLimits {
    fn default() -> Self {
        Self {
            max_source_bytes: 64 * 1024,
            max_ast_nodes: 4096,
            max_ast_depth: 128,
            bind_mode: FactBindMode::default(),
        }
    }
}

impl EvaluationLimits {
    fn check_source_len(&self, source: &str) -> Result<(), RuleError> {
        let len = source.len();
        if len > self.max_source_bytes {
            return Err(RuleError::SourceTooLarge { len, max: self.max_source_bytes });
        }
        Ok(())
    }

    fn check_ast(&self, ast: &Expression) -> Result<(), RuleError> {
        let nodes = count_ast_nodes(ast);
        if nodes > self.max_ast_nodes {
            return Err(RuleError::AstTooLarge { nodes, max_nodes: self.max_ast_nodes });
        }
        let depth = ast_max_depth(ast);
        if depth > self.max_ast_depth {
            return Err(RuleError::AstTooDeep { depth, max_depth: self.max_ast_depth });
        }
        Ok(())
    }
}

fn count_ast_nodes(expr: &Expression) -> usize {
    use Expression::*;
    match expr {
        Arithmetic(a, _, b) | Relation(a, _, b) | Or(a, b) | And(a, b) => 1 + count_ast_nodes(a) + count_ast_nodes(b),
        Ternary(a, b, c) => 1 + count_ast_nodes(a) + count_ast_nodes(b) + count_ast_nodes(c),
        Unary(_, a) => 1 + count_ast_nodes(a),
        Member(e, m) => 1 + count_ast_nodes(e) + count_member_nodes(m),
        FunctionCall(f, target, args) => {
            let mut n = 1 + count_ast_nodes(f);
            if let Some(t) = target {
                n += count_ast_nodes(t);
            }
            for arg in args {
                n += count_ast_nodes(arg);
            }
            n
        },
        List(items) => 1 + items.iter().map(count_ast_nodes).sum::<usize>(),
        Map(pairs) => {
            1 + pairs
                .iter()
                .map(|(k, v)| count_ast_nodes(k) + count_ast_nodes(v))
                .sum::<usize>()
        },
        Atom(_) | Ident(_) => 1,
    }
}

fn count_member_nodes(m: &Member) -> usize {
    match m {
        Member::Attribute(_) => 0,
        Member::Index(e) => count_ast_nodes(e),
        Member::Fields(fs) => fs.iter().map(|(_, e)| count_ast_nodes(e)).sum(),
    }
}

fn ast_max_depth(expr: &Expression) -> usize {
    use Expression::*;
    let child_max = match expr {
        Arithmetic(a, _, b) | Relation(a, _, b) | Or(a, b) | And(a, b) => ast_max_depth(a).max(ast_max_depth(b)),
        Ternary(a, b, c) => ast_max_depth(a).max(ast_max_depth(b)).max(ast_max_depth(c)),
        Unary(_, a) => ast_max_depth(a),
        Member(e, m) => ast_max_depth(e).max(member_max_depth(m)),
        FunctionCall(f, target, args) => {
            let mut m = ast_max_depth(f);
            if let Some(t) = target {
                m = m.max(ast_max_depth(t));
            }
            for arg in args {
                m = m.max(ast_max_depth(arg));
            }
            m
        },
        List(items) => items.iter().map(ast_max_depth).max().unwrap_or(0),
        Map(pairs) => pairs
            .iter()
            .map(|(k, v)| ast_max_depth(k).max(ast_max_depth(v)))
            .max()
            .unwrap_or(0),
        Atom(_) | Ident(_) => 0,
    };
    child_max.saturating_add(1)
}

fn member_max_depth(m: &Member) -> usize {
    match m {
        Member::Attribute(_) => 0,
        Member::Index(e) => ast_max_depth(e),
        Member::Fields(fs) => fs.iter().map(|(_, e)| ast_max_depth(e)).max().unwrap_or(0),
    }
}

// --- Law text ----------------------------------------------------------------

/// Raw UTF-8 CEL source. Serializes as a plain string (transparent).
#[derive(Clone, Debug, Default, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct CelExpression(pub String);

impl CelExpression {
    #[must_use]
    pub fn as_str(&self) -> &str {
        self.0.as_str()
    }

    /// Parse, inject [`RuleContext`], execute; errors → [`PolicyError::Rule`].
    pub fn evaluate<'a>(
        &self,
        host: &'a Context<'a>,
        facts: &RuleContext,
        limits: &EvaluationLimits,
    ) -> PolicyResult<Value> {
        evaluate_cel(self.as_str(), host, facts, limits)
    }

    pub fn evaluate_bool<'a>(
        &self,
        host: &'a Context<'a>,
        facts: &RuleContext,
        limits: &EvaluationLimits,
    ) -> PolicyResult<bool> {
        value_as_bool(&self.evaluate(host, facts, limits)?)
    }

    /// Deny-by-default gate: any error → `false`.
    #[must_use]
    pub fn allows<'a>(&self, host: &'a Context<'a>, facts: &RuleContext, limits: &EvaluationLimits) -> bool {
        self.evaluate_bool(host, facts, limits).unwrap_or(false)
    }
}

impl From<String> for CelExpression {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for CelExpression {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

// --- Context (pure facts) ----------------------------------------------------

/// Facts visible to rules: author, named [`Amount`]s, optional `now`, and arbitrary CEL values.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct RuleContext {
    /// Opaque principal (matches envelope / ZK identity strings at your boundary).
    pub author_identity: Option<String>,
    pub amounts: HashMap<String, Amount>,
    /// Named subjects: strings, bools, maps, lists — e.g. identity claims, flags.
    pub subjects: HashMap<String, Value>,
    /// When set, binds CEL variable `now` as a timestamp (UTC offset +00:00).
    pub now: Option<DateTime<Utc>>,
}

impl RuleContext {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_author_identity(mut self, id: impl Into<String>) -> Self {
        self.author_identity = Some(id.into());
        self
    }

    pub fn with_now(mut self, t: DateTime<Utc>) -> Self {
        self.now = Some(t);
        self
    }

    pub fn with_amount(mut self, name: impl Into<String>, amount: Amount) -> Self {
        self.amounts.insert(name.into(), amount);
        self
    }

    pub fn with_subject(mut self, name: impl Into<String>, value: Value) -> Self {
        self.subjects.insert(name.into(), value);
        self
    }

    /// Binds CEL variable `schedule` with [`schedule_to_cel_value`] (see `schedule.is_active`, RFC 3339 fields).
    pub fn with_schedule(mut self, window: &ScheduleWindow, now: DateTime<Utc>, tol: TimeTolerance) -> Self {
        self.subjects.insert("schedule".into(), schedule_to_cel_value(window, now, tol));
        self
    }
}

// --- Amount ↔ CEL ------------------------------------------------------------

fn amount_minor_i64(amount: &Amount) -> Result<i64, RuleError> {
    let asset = amount.tag().label.clone();
    let p = u32::from(amount.tag().precision);
    let mut scale = Decimal::ONE;
    for _ in 0..p {
        scale = scale.checked_mul(Decimal::TEN).ok_or_else(|| RuleError::MinorUnitOverflow {
            asset: asset.clone(),
            detail: "scale factor overflow".into(),
        })?;
    }
    let minor_dec = amount.value().checked_mul(scale).ok_or_else(|| RuleError::MinorUnitOverflow {
        asset: asset.clone(),
        detail: "minor-unit multiply overflow".into(),
    })?;
    let minor = minor_dec.trunc();
    minor.to_i64().ok_or_else(|| RuleError::MinorUnitOverflow {
        asset,
        detail: "minor units do not fit i64 (use smaller magnitude or coarser asset)".into(),
    })
}

/// Map [`Amount`] to a CEL `map`: `value_milli` (`int`, minor units), `value_exact` (`string`),
/// `label`, `precision` (`int`).
#[must_use]
pub fn amount_to_cel_value(amount: &Amount) -> Result<Value, RuleError> {
    let value_milli = amount_minor_i64(amount)?;
    let dec = amount.value();
    let mut m: HashMap<&str, Value> = HashMap::new();
    m.insert("value_milli", Value::Int(value_milli));
    m.insert("value_exact", Value::String(dec.to_string().into()));
    m.insert("label", Value::String(amount.tag().label.clone().into()));
    m.insert("precision", Value::Int(i64::from(amount.tag().precision)));
    Ok(Value::Map(m.into()))
}

// --- Rule --------------------------------------------------------------------

/// Declarative rule: UTF-8 [`cel`](Rule::cel) body evaluated against a [`RuleContext`].
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Rule {
    pub id: String,
    pub cel: String,
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub action: Option<String>,
}

impl Rule {
    pub fn validate(&self) -> Result<(), SpecificationError> {
        if self.id.is_empty() {
            return Err(SpecificationError::EmptyRuleIdentifier);
        }
        Ok(())
    }

    /// Compile only (no context). Parse errors are [`cel_interpreter::ParseError`].
    pub fn compile(&self) -> Result<Program, cel_interpreter::ParseError> {
        Program::compile(&self.cel)
    }

    /// Validate rule id → parse + budget → bind facts → execute under `host`.
    pub fn evaluate<'a>(
        &self,
        host: &'a Context<'a>,
        facts: &RuleContext,
        limits: &EvaluationLimits,
    ) -> PolicyResult<Value> {
        self.validate().map_err(PolicyError::from)?;
        evaluate_cel(&self.cel, host, facts, limits)
    }

    /// [`evaluate`](Self::evaluate) then require a CEL `bool`.
    pub fn evaluate_bool<'a>(
        &self,
        host: &'a Context<'a>,
        facts: &RuleContext,
        limits: &EvaluationLimits,
    ) -> PolicyResult<bool> {
        value_as_bool(&self.evaluate(host, facts, limits)?)
    }

    /// Deny-by-default: parse/eval/budget/type errors → `false`.
    #[must_use]
    pub fn allows<'a>(&self, host: &'a Context<'a>, facts: &RuleContext, limits: &EvaluationLimits) -> bool {
        self.evaluate_bool(host, facts, limits).unwrap_or(false)
    }
}

/// Evaluate arbitrary CEL with the same pipeline as [`Rule::evaluate`].
pub fn evaluate_cel<'a>(
    source: &str,
    host: &'a Context<'a>,
    facts: &RuleContext,
    limits: &EvaluationLimits,
) -> PolicyResult<Value> {
    limits.check_source_len(source)?;
    let ast = parse_cel(source).map_err(RuleError::from)?;
    limits.check_ast(&ast)?;
    let refs = ast.references();
    let program = Program::compile(source).map_err(RuleError::from)?;
    let cel_ctx = inject_facts(host, facts, &refs, limits.bind_mode)?;
    program.execute(&cel_ctx).map_err(|e| PolicyError::Rule(e.into()))
}

/// Convenience: standard CEL stdlib host ([`Context::default`]) — no custom host functions.
pub fn evaluate_cel_std(source: &str, facts: &RuleContext, limits: &EvaluationLimits) -> PolicyResult<Value> {
    let host = Context::default();
    evaluate_cel(source, &host, facts, limits)
}

fn inject_facts<'a>(
    host: &'a Context<'a>,
    facts: &RuleContext,
    refs: &ExpressionReferences<'_>,
    mode: FactBindMode,
) -> Result<Context<'a>, PolicyError> {
    let bind = |name: &str| match mode {
        FactBindMode::All => true,
        FactBindMode::ReferencedOnly => refs.has_variable(name),
    };

    let mut ctx = host.new_inner_scope();

    if bind("author_identity") {
        if let Some(ref id) = facts.author_identity {
            ctx.add_variable_from_value("author_identity", Value::String(id.clone().into()));
        }
    }
    if bind("now") {
        if let Some(now) = facts.now {
            let fo = now.with_timezone(&FixedOffset::east_opt(0).unwrap());
            ctx.add_variable_from_value("now", Value::Timestamp(fo));
        }
    }

    for (name, amount) in &facts.amounts {
        if bind(name) {
            let v = amount_to_cel_value(amount)?;
            ctx.add_variable_from_value(name, v);
        }
    }
    for (name, v) in &facts.subjects {
        if bind(name) {
            ctx.add_variable_from_value(name, v.clone());
        }
    }

    Ok(ctx)
}

/// Marker type documenting the intentional sandbox (stdlib + injected facts only).
#[derive(Debug, Default, Clone, Copy)]
pub struct SandboxEvaluator;

impl SandboxEvaluator {
    pub fn evaluate<'a>(
        rule: &Rule,
        host: &'a Context<'a>,
        facts: &RuleContext,
        limits: &EvaluationLimits,
    ) -> PolicyResult<Value> {
        rule.evaluate(host, facts, limits)
    }
}

fn value_as_bool(v: &Value) -> PolicyResult<bool> {
    match v {
        Value::Bool(b) => Ok(*b),
        Value::Null => Ok(false),
        _ => Err(PolicyError::Rule(RuleError::Binding {
            name: "result".into(),
            reason: format!("expected bool, got {}", v.type_of()),
        })),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::currency::Asset;
    use crate::schedule::ScheduleWindow;

    fn std_limits() -> EvaluationLimits {
        EvaluationLimits::default()
    }

    #[test]
    fn amount_milli_relation_is_integer_clean() {
        let amt = Amount::from_decimal_str_exact("150.00", Asset::new("PTS", 2).unwrap()).unwrap();
        let ctx = RuleContext::new().with_amount("x", amt);
        let host = Context::default();
        let v = evaluate_cel("x.value_milli > 10000", &host, &ctx, &std_limits()).unwrap();
        assert_eq!(v, Value::Bool(true));
    }

    #[test]
    fn author_identity_visible() {
        let ctx = RuleContext::new().with_author_identity("did:rice:bob");
        let host = Context::default();
        let v = evaluate_cel(r#"author_identity == "did:rice:bob""#, &host, &ctx, &std_limits()).unwrap();
        assert_eq!(v, Value::Bool(true));
    }

    #[test]
    fn rule_evaluate_maps_to_policy_error_on_bad_cel() {
        let rule = Rule {
            id: "r".into(),
            cel: "(".into(),
            description: None,
            action: None,
        };
        let host = Context::default();
        assert!(matches!(
            rule.evaluate(&host, &RuleContext::new(), &std_limits()),
            Err(PolicyError::Rule(_))
        ));
    }

    #[test]
    fn source_too_large_is_rule_error() {
        let limits = EvaluationLimits {
            max_source_bytes: 2,
            ..EvaluationLimits::default()
        };
        let host = Context::default();
        let r = evaluate_cel("1+1", &host, &RuleContext::new(), &limits);
        assert!(matches!(r, Err(PolicyError::Rule(RuleError::SourceTooLarge { .. }))));
    }

    #[test]
    fn ast_too_deep_is_rule_error() {
        let limits = EvaluationLimits {
            max_ast_depth: 3,
            ..EvaluationLimits::default()
        };
        let host = Context::default();
        let r = evaluate_cel("1+1+1+1+1", &host, &RuleContext::new(), &limits);
        assert!(matches!(r, Err(PolicyError::Rule(RuleError::AstTooDeep { .. }))));
    }

    #[test]
    fn allows_is_false_on_error() {
        let rule = Rule {
            id: "r".into(),
            cel: "(".into(),
            description: None,
            action: None,
        };
        let host = Context::default();
        assert!(!rule.allows(&host, &RuleContext::new(), &std_limits()));
    }

    #[test]
    fn minor_overflow_is_rule_error() {
        let tag = Asset::new("BIG", 0).unwrap();
        let amt = Amount::from_decimal_str_exact("9223372036854775808", tag).unwrap();
        let e = amount_to_cel_value(&amt).unwrap_err();
        assert!(matches!(e, RuleError::MinorUnitOverflow { .. }));
    }

    #[test]
    fn referenced_only_skips_unused_amount() {
        let a = Amount::from_decimal_str_exact("1", Asset::new("A", 0).unwrap()).unwrap();
        let b = Amount::from_decimal_str_exact("2", Asset::new("B", 0).unwrap()).unwrap();
        let ctx = RuleContext::new().with_amount("heavy", a).with_amount("x", b);
        let host = Context::default();
        let v = evaluate_cel("x.value_milli == 2", &host, &ctx, &std_limits()).unwrap();
        assert_eq!(v, Value::Bool(true));
    }

    #[test]
    fn cel_schedule_is_active_field() {
        let start = DateTime::parse_from_rfc3339("2026-01-01T00:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let end = DateTime::parse_from_rfc3339("2026-12-31T23:59:59Z")
            .unwrap()
            .with_timezone(&Utc);
        let win = ScheduleWindow { start, end, recurrence: None };
        let now = DateTime::parse_from_rfc3339("2026-06-15T12:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let ctx = RuleContext::new().with_schedule(&win, now, TimeTolerance::ZERO);
        let host = Context::default();
        let v = evaluate_cel("schedule.is_active == true", &host, &ctx, &std_limits()).unwrap();
        assert_eq!(v, Value::Bool(true));
    }
}
