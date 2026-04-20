//! RICE policy layer — CEL evaluation, FIX/finance hooks, legal XML, accounting constraints,
//! currency validation, schedules, and auditable decisions.

pub mod accounting;
pub mod audit;
pub mod currency;
pub mod engine;
pub mod error;
pub mod finance;
pub mod legal;
pub mod rule;
pub mod schedule;
pub mod serial;
pub mod specification;

pub use accounting::{
    assert_double_entry_balanced, AutoSplit, BalancePartition, EntryId, Flow, JournalRecord, Ledger, LedgerLeg,
    LedgerPeriod, SettlementMode, SubAccountBalances, Transfer,
};
pub use audit::{
    actor_identity_for_audit, attach_to_chain, audit_event_from_decision, audit_event_from_decision_with_policy,
    audit_subject_from_env, block_height_from_env, dispatch_audit_streams, try_append_audit_log_env,
    write_audit_json_line, AuditChain, AuditDecisionKind, AuditEvent, AuditLanguage, DecisionRecord, Explainable,
    RuleCelSnapshot,
};
#[cfg(feature = "audit-nats")]
pub use audit::{try_publish_audit_nats, AuditPublishError};
#[cfg(feature = "audit-proto")]
pub use audit::{decode_audit_event_protobuf, encode_audit_event_protobuf};
pub use currency::{parse_decimal_ascii_exact, Amount, Asset, AssetRegistry, AssetTag, HashMapRegistry};
pub use engine::{
    bind_value, build_sovereign_host, compile, evaluate, evaluate_intent, evaluate_intent_with_audit, parallel_rules_from_env,
    root_context, CelHostEffect, PolicyDecision, PolicyEngine, QueuedIntent, ResolutionStage, ResolutionStageRecord,
    ResolutionTrace, RuleEvalRecord, SovereignHostOptions, TransactionRequest, VelocityFact,
};
pub use error::{
    AccountingError, BankersRuleError, CurrencyError, EvalError, FinanceError, LegalError, ParseError, PolicyError,
    PolicyResult, RuleError, ScheduleError, SpecificationError,
};
#[cfg(feature = "fix-protocol")]
pub use finance::{
    fix_currency_symbol, fix_price_string, fix_side_buy, fix_side_sell, fix_tag_price, fix_tag_side,
};
pub use finance::{
    amount_from_basis_points, amount_from_unit_ratio, convert_at_spot, convert_with_valuation, ensure_per_transaction_cap,
    ensure_within_policy_limit, flat_rate_bps_for_quantity, ledger_outbound_volume, marginal_amount_from_brackets,
    marginal_scalar_from_brackets, outbound_volume_in_period, validate_basis_points, BASIS_POINTS_MAX, BASIS_POINTS_ONE,
    BudgetLimit, FlatTier, MarginalBracket, Valuation,
};
pub use legal::{
    clerk_cw_api_version, extract_compliance_tags, policy_involves_code_markers, policy_surface_text, root_element_name,
    validate_contract_safety, validate_fair_exchange, ComplianceEnvelope, ComplianceTagFilter, ComplianceTagRecord,
    FairExchangeGuarantee, LegalIdentity, LegalManifest,
};
pub use rule::{
    amount_to_cel_value, evaluate_cel, evaluate_cel_std, CelExpression, EvaluationLimits, FactBindMode, Rule, RuleContext,
    SandboxEvaluator,
};
pub use schedule::{
    add_days, is_active_simple, is_within, schedule_to_cel_value, utc_seconds_from_midnight, weekday_bit, RecurrenceGate,
    ScheduleWindow, TimeTolerance, UtcDaytimeBand,
};
pub use serial::{
    envelope_from_json, envelope_from_xml, envelope_to_json_pretty, envelope_to_xml, from_json, from_xml,
    policy_document_from_json, policy_document_from_json_with_migration, to_json, to_json_compact, to_xml, PolicyDocument,
    PolicyEnvelope, PolicyPayload, PolicySchemaVersion,
};
#[cfg(feature = "xml-interchange")]
pub use serial::{mason_envelope_from_xml, mason_envelope_to_xml, mason_xml_namespace_uri};
pub use specification::{Policy, PolicyMetadata};

/// Build a [`Vec`] of [`LedgerLeg`] and fail the enclosing [`PolicyResult`] unless double-entry balances.
///
/// ```ignore
/// let legs = clerk_balanced_leg_vec!(debit, credit)?;
/// ```
#[macro_export]
macro_rules! clerk_balanced_leg_vec {
    ($($leg:expr),* $(,)?) => {{
        let v = vec![$($leg),*];
        match $crate::accounting::assert_double_entry_balanced(&v) {
            Ok(()) => ::std::result::Result::Ok(v),
            Err(e) => ::std::result::Result::Err(e),
        }
    }};
}
