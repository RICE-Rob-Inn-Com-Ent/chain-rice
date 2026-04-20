//! **Immutable proof** — tamper-evident audit records for the CLERK triad (Legal → Engine → Audit).
//!
//! Each [`AuditEvent`] binds a ULID [`trace_id`](AuditEvent::trace_id), actor identity, engine
//! rule outcomes, optional ledger digests, and a SHA-256 **event hash** that may chain to the
//! previous event. JSON lines are the default wire form; Protobuf and NATS are optional **cargo
//! features** (`audit-proto`, `audit-nats`) for high-throughput paths and MASON-aligned schemas.
//!
//! ## Environment (streaming)
//!
//! | Variable | Effect |
//! |----------|--------|
//! | `RICE_POLICY_AUDIT_LOG` | If set, append one JSON line per [`try_append_audit_log_env`] call. |
//! | `RICE_POLICY_AUDIT_SUBJECT` | NATS subject when [`try_publish_audit_nats`] is used (requires `audit-nats`). |
//! | `NATS_URL` | Broker URL for NATS (default `nats://127.0.0.1:4222`). |
//! | `RICE_POLICY_AUDIT_STRICT` | If truthy, file / NATS audit failures become `PolicyError::Clerk`. |
//! | `RICE_POLICY_AUDIT_NATS_REQUIRED` | If truthy (with **audit-nats**), NATS publish failure is an error. |
//! | `RICE_POLICY_BLOCK_HEIGHT` | Optional `u64` merged into [`AuditEvent::block_height`] when unset in the API. |

use std::io::Write;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use ulid::Ulid;
use util::RiceError;

use crate::error::PolicyResult;

use crate::engine::{
    CelHostEffect, PolicyDecision, ResolutionStage, ResolutionStageRecord, ResolutionTrace, RuleEvalRecord,
};
use crate::rule::Rule;
use crate::specification::Policy;

// --- Legacy row ----------------------------------------------------------------

/// One rule’s outcome row (legacy helper). Prefer [`AuditEvent`] + [`RuleEvalRecord`] for new code.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct DecisionRecord {
    pub rule_id: String,
    pub cel_expression: String,
    pub passed: bool,
    #[serde(default)]
    pub trace: Vec<String>,
}

impl DecisionRecord {
    pub fn new(rule_id: impl Into<String>, cel_expression: impl Into<String>, passed: bool) -> Self {
        Self {
            rule_id: rule_id.into(),
            cel_expression: cel_expression.into(),
            passed,
            trace: Vec::new(),
        }
    }

    pub fn push_trace(&mut self, line: impl Into<String>) {
        self.trace.push(line.into());
    }
}

// --- Core types ----------------------------------------------------------------

/// High-level outcome mirrored from [`PolicyDecision`].
#[derive(Clone, Copy, Debug, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "snake_case")]
pub enum AuditDecisionKind {
    Allow,
    Deny,
    Buffered,
}

/// CEL source captured at audit time (aligned with [`Rule::id`] / [`Rule::cel`]).
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct RuleCelSnapshot {
    pub rule_id: String,
    pub cel: String,
}

/// BARD-facing copy tone.
#[derive(Clone, Copy, Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum AuditLanguage {
    #[default]
    English,
    Polish,
}

/// One immutable audit record (hash chain + ledger snapshots).
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct AuditEvent {
    pub trace_id: Ulid,
    pub policy_id: String,
    /// SEC1 or raw pubkey material (hex in JSON via [`hex::serde`]).
    #[serde(with = "hex::serde")]
    pub actor_identity: Vec<u8>,
    pub decision: AuditDecisionKind,
    /// Wall-clock time of observation (nanosecond precision in RFC 3339 when serialized).
    pub observed_at: DateTime<Utc>,
    /// Optional L1 / rollup height when the decision is anchored on-chain.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub block_height: Option<u64>,
    /// Engine pipeline stages (legal, finance, privacy, CEL, escrow, gate).
    pub pipeline_stages: Vec<ResolutionStageRecord>,
    /// Per-rule CEL outcomes from the engine.
    pub rule_evaluations: Vec<RuleEvalRecord>,
    /// CEL sources from the policy definition at evaluation time.
    pub rule_cel_sources: Vec<RuleCelSnapshot>,
    pub ledger_digest_before: [u8; 32],
    pub ledger_digest_after: [u8; 32],
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub buffered_intent_id: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub chamber_depth: Option<usize>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub deny_reason: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cel_host_effects: Option<Vec<CelHostEffect>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub previous_event_hash: Option<[u8; 32]>,
    pub event_hash: [u8; 32],
}

impl AuditEvent {
    /// Build an unsigned event (`event_hash` zeroed); call [`Self::seal`] or [`attach_to_chain`].
    #[allow(clippy::too_many_arguments)]
    pub fn new_unsigned(
        trace_id: Ulid,
        policy_id: impl Into<String>,
        actor_identity: Vec<u8>,
        decision: AuditDecisionKind,
        observed_at: DateTime<Utc>,
        block_height: Option<u64>,
        pipeline_stages: Vec<ResolutionStageRecord>,
        rule_evaluations: Vec<RuleEvalRecord>,
        rule_cel_sources: Vec<RuleCelSnapshot>,
        ledger_digest_before: [u8; 32],
        ledger_digest_after: [u8; 32],
        buffered_intent_id: Option<u64>,
        chamber_depth: Option<usize>,
        deny_reason: Option<String>,
        cel_host_effects: Option<Vec<CelHostEffect>>,
        previous_event_hash: Option<[u8; 32]>,
    ) -> Self {
        Self {
            trace_id,
            policy_id: policy_id.into(),
            actor_identity,
            decision,
            observed_at,
            block_height,
            pipeline_stages,
            rule_evaluations,
            rule_cel_sources,
            ledger_digest_before,
            ledger_digest_after,
            buffered_intent_id,
            chamber_depth,
            deny_reason,
            cel_host_effects,
            previous_event_hash,
            event_hash: [0u8; 32],
        }
    }

    /// Recompute the payload hash (everything except [`AuditEvent::event_hash`]).
    #[must_use]
    pub fn compute_payload_hash(&self) -> [u8; 32] {
        hash_payload_v1(self)
    }

    /// Whether [`event_hash`](AuditEvent::event_hash) matches the canonical preimage.
    #[must_use]
    pub fn verify_event_hash(&self) -> bool {
        self.compute_payload_hash() == self.event_hash
    }

    /// Set [`event_hash`](AuditEvent::event_hash) from the canonical preimage.
    pub fn seal(&mut self) {
        self.event_hash = self.compute_payload_hash();
    }

    /// Human-readable explanation for BARD / UI (not legal advice).
    #[must_use]
    pub fn to_human_explanation(&self, lang: AuditLanguage) -> String {
        human_explain(self, lang)
    }
}

// --- Explainability (BARD / UI) ------------------------------------------------

/// Human / UI explanations (English, Polish, …).
pub trait Explainable {
    /// UI-ready multi-line explanation for the given locale.
    fn explain(&self, lang: AuditLanguage) -> String;
}

impl Explainable for AuditEvent {
    fn explain(&self, lang: AuditLanguage) -> String {
        self.to_human_explanation(lang)
    }
}

impl Explainable for PolicyDecision {
    fn explain(&self, lang: AuditLanguage) -> String {
        match lang {
            AuditLanguage::English => explain_decision_en(self),
            AuditLanguage::Polish => explain_decision_pl(self),
        }
    }
}

fn explain_decision_en(d: &PolicyDecision) -> String {
    let mut lines = Vec::new();
    match d {
        PolicyDecision::Allow { trace } => {
            lines.push("Outcome: approved.".into());
            push_stage_summary_en(&mut lines, trace);
        },
        PolicyDecision::Deny { trace, reason } => {
            lines.push(format!("Outcome: denied — {reason}"));
            push_stage_summary_en(&mut lines, trace);
        },
        PolicyDecision::Buffered {
            trace,
            intent_id,
            chamber_depth,
            ..
        } => {
            lines.push(format!(
                "Outcome: buffered (not denied) — intent {intent_id}, chamber depth {chamber_depth}."
            ));
            push_stage_summary_en(&mut lines, trace);
        },
    }
    lines.join("\n")
}

fn explain_decision_pl(d: &PolicyDecision) -> String {
    let mut lines = Vec::new();
    match d {
        PolicyDecision::Allow { trace } => {
            lines.push("Wynik: zatwierdzono.".into());
            push_stage_summary_pl(&mut lines, trace);
        },
        PolicyDecision::Deny { trace, reason } => {
            lines.push(format!("Wynik: odmowa — {reason}"));
            push_stage_summary_pl(&mut lines, trace);
        },
        PolicyDecision::Buffered {
            trace,
            intent_id,
            chamber_depth,
            ..
        } => {
            lines.push(format!(
                "Wynik: buforowanie (bez odmowy) — intencja {intent_id}, głębokość komory {chamber_depth}."
            ));
            push_stage_summary_pl(&mut lines, trace);
        },
    }
    lines.join("\n")
}

fn push_stage_summary_en(lines: &mut Vec<String>, trace: &ResolutionTrace) {
    for s in &trace.stages {
        if !s.passed {
            lines.push(format!("Stage {:?}: {}", s.stage, s.detail));
        }
    }
    for r in &trace.rule_results {
        if !r.passed {
            lines.push(format!(
                "Rule `{}`: {}",
                r.rule_id,
                r.note.as_deref().unwrap_or("failed")
            ));
        }
    }
}

fn push_stage_summary_pl(lines: &mut Vec<String>, trace: &ResolutionTrace) {
    for s in &trace.stages {
        if !s.passed {
            lines.push(format!("Etap {:?}: {}", s.stage, s.detail));
        }
    }
    for r in &trace.rule_results {
        if !r.passed {
            lines.push(format!(
                "Reguła `{}`: {}",
                r.rule_id,
                r.note.as_deref().unwrap_or("nie przeszła")
            ));
        }
    }
}

/// Hash-chain tip; use [`attach_to_chain`] to link events.
#[derive(Clone, Debug, Default)]
pub struct AuditChain {
    tip: Option<[u8; 32]>,
}

impl AuditChain {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    #[must_use]
    pub fn tip(&self) -> Option<[u8; 32]> {
        self.tip
    }

    /// Link `event` after the current tip, seal it, advance the tip.
    pub fn seal(&mut self, mut event: AuditEvent) -> AuditEvent {
        attach_to_chain(self, &mut event);
        event
    }

    /// After [`audit_event_from_decision`](audit_event_from_decision) with `previous_event_hash ==
    /// self.tip()`, move the chain tip to this event’s [`event_hash`](AuditEvent::event_hash).
    pub fn advance_from_sealed_event(&mut self, event: &AuditEvent) {
        self.tip = Some(event.event_hash);
    }
}

/// Point `event.previous_event_hash` at `chain.tip`, compute `event.event_hash`, advance `chain.tip`.
pub fn attach_to_chain(chain: &mut AuditChain, event: &mut AuditEvent) {
    event.previous_event_hash = chain.tip;
    event.event_hash = event.compute_payload_hash();
    chain.tip = Some(event.event_hash);
}

// --- Builder from engine -------------------------------------------------------

/// Build an audit row from a policy evaluation. `rules` should be the same [`Policy::rules`] slice
/// used by the engine for `policy_id`.
#[allow(clippy::too_many_arguments)]
pub fn audit_event_from_decision(
    trace_id: Ulid,
    observed_at: DateTime<Utc>,
    policy_id: impl Into<String>,
    actor_identity: Vec<u8>,
    decision: &PolicyDecision,
    rules: &[Rule],
    ledger_digest_before: [u8; 32],
    ledger_digest_after: [u8; 32],
    block_height: Option<u64>,
    previous_event_hash: Option<[u8; 32]>,
) -> AuditEvent {
    let policy_id = policy_id.into();
    let trace = decision.trace();
    let rule_cel_sources: Vec<RuleCelSnapshot> = rules
        .iter()
        .map(|r| RuleCelSnapshot {
            rule_id: r.id.clone(),
            cel: r.cel.clone(),
        })
        .collect();

    let (kind, buf_id, depth, cel_fx, deny_reason) = match decision {
        PolicyDecision::Allow { .. } => (AuditDecisionKind::Allow, None, None, None, None),
        PolicyDecision::Deny { reason, .. } => (AuditDecisionKind::Deny, None, None, None, Some(reason.to_string())),
        PolicyDecision::Buffered {
            intent_id, chamber_depth, cel_effects, ..
        } => (
            AuditDecisionKind::Buffered,
            Some(*intent_id),
            Some(*chamber_depth),
            Some(cel_effects.clone()),
            None,
        ),
    };

    let mut event = AuditEvent::new_unsigned(
        trace_id,
        policy_id,
        actor_identity,
        kind,
        observed_at,
        block_height,
        trace.stages.clone(),
        trace.rule_results.clone(),
        rule_cel_sources,
        ledger_digest_before,
        ledger_digest_after,
        buf_id,
        depth,
        deny_reason,
        cel_fx,
        previous_event_hash,
    );
    if previous_event_hash.is_none() {
        event.seal();
    } else {
        event.event_hash = event.compute_payload_hash();
    }
    event
}

/// Convenience: [`audit_event_from_decision`] using [`Policy::id`] and [`Policy::rules`].
pub fn audit_event_from_decision_with_policy(
    trace_id: Ulid,
    observed_at: DateTime<Utc>,
    actor_identity: Vec<u8>,
    decision: &PolicyDecision,
    policy: &Policy,
    ledger_digest_before: [u8; 32],
    ledger_digest_after: [u8; 32],
    block_height: Option<u64>,
    previous_event_hash: Option<[u8; 32]>,
) -> AuditEvent {
    audit_event_from_decision(
        trace_id,
        observed_at,
        policy.id.clone(),
        actor_identity,
        decision,
        &policy.rules,
        ledger_digest_before,
        ledger_digest_after,
        block_height,
        previous_event_hash,
    )
}

// --- Persistence helpers -------------------------------------------------------

/// Serialize one JSON object and newline to `writer`.
pub fn write_audit_json_line<W: Write>(writer: &mut W, event: &AuditEvent) -> std::io::Result<()> {
    let line = serde_json::to_string(event).map_err(std::io::Error::other)?;
    writer.write_all(line.as_bytes())?;
    writeln!(writer)?;
    Ok(())
}

/// If `RICE_POLICY_AUDIT_LOG` is set, append a JSON line to that path.
pub fn try_append_audit_log_env(event: &AuditEvent) -> std::io::Result<()> {
    let Ok(path) = std::env::var("RICE_POLICY_AUDIT_LOG") else {
        return Ok(());
    };
    let mut f = std::fs::OpenOptions::new().create(true).append(true).open(path)?;
    write_audit_json_line(&mut f, event).map_err(std::io::Error::other)
}

/// Subject for NATS when using [`try_publish_audit_nats`] (`RICE_POLICY_AUDIT_SUBJECT`).
#[must_use]
pub fn audit_subject_from_env() -> Option<String> {
    std::env::var("RICE_POLICY_AUDIT_SUBJECT").ok()
}

// --- NATS (optional) -----------------------------------------------------------

#[cfg(feature = "audit-nats")]
#[derive(Debug, thiserror::Error)]
pub enum AuditPublishError {
    #[error("RICE_POLICY_AUDIT_SUBJECT is not set")]
    SubjectUnset,
    #[error("JSON serialization: {0}")]
    Json(#[from] serde_json::Error),
    #[error("NATS: {0}")]
    Nats(String),
}

#[cfg(feature = "audit-nats")]
impl AuditPublishError {
    fn nats(e: std::io::Error) -> Self {
        Self::Nats(e.to_string())
    }
}

/// Publish JSON payload to `RICE_POLICY_AUDIT_SUBJECT` (requires **audit-nats** feature).
#[cfg(feature = "audit-nats")]
pub fn try_publish_audit_nats(event: &AuditEvent) -> Result<(), AuditPublishError> {
    let subject = std::env::var("RICE_POLICY_AUDIT_SUBJECT").map_err(|_| AuditPublishError::SubjectUnset)?;
    let url = std::env::var("NATS_URL").unwrap_or_else(|_| "nats://127.0.0.1:4222".into());
    let nc = nats::connect(&url).map_err(AuditPublishError::nats)?;
    let payload = serde_json::to_vec(event)?;
    nc.publish(&subject, &payload).map_err(AuditPublishError::nats)?;
    Ok(())
}

fn env_truthy(key: &str) -> bool {
    matches!(
        std::env::var(key).map(|v| v.to_ascii_lowercase()),
        Ok(ref s) if matches!(s.as_str(), "1" | "true" | "yes" | "on")
    )
}

/// Optional block height from `RICE_POLICY_BLOCK_HEIGHT`.
#[must_use]
pub fn block_height_from_env() -> Option<u64> {
    std::env::var("RICE_POLICY_BLOCK_HEIGHT").ok()?.parse().ok()
}

/// Derive audit actor bytes: legal signing key, else rule-context author string, else empty.
#[must_use]
pub fn actor_identity_for_audit(req: &crate::engine::TransactionRequest) -> Vec<u8> {
    if let Some(id) = &req.legal_identity {
        return id.signing_key_sec1.clone();
    }
    if let Some(a) = &req.rule_context.author_identity {
        return a.as_bytes().to_vec();
    }
    Vec::new()
}

/// Append JSON audit line / optional NATS publish. Failures are ignored unless strict env flags are set.
pub fn dispatch_audit_streams(event: &AuditEvent) -> PolicyResult<()> {
    let strict = env_truthy("RICE_POLICY_AUDIT_STRICT");
    if let Err(e) = try_append_audit_log_env(event) {
        if strict {
            return Err(RiceError::message(e.to_string()).into());
        }
    }
    #[cfg(feature = "audit-nats")]
    if audit_subject_from_env().is_some() {
        if let Err(e) = try_publish_audit_nats(event) {
            if strict || env_truthy("RICE_POLICY_AUDIT_NATS_REQUIRED") {
                return Err(RiceError::message(e.to_string()).into());
            }
        }
    }
    Ok(())
}

// --- Protobuf (optional, MASON path) -----------------------------------------

#[cfg(feature = "audit-proto")]
mod proto_wire {
    use chrono::{DateTime, Utc};
    use prost::Message;

    use super::{AuditDecisionKind, AuditEvent, CelHostEffect, ResolutionStage, RuleCelSnapshot};
    use crate::engine::{ResolutionStageRecord, RuleEvalRecord};

    #[derive(Clone, PartialEq, Message)]
    pub struct RuleEvalPb {
        #[prost(string, tag = "1")]
        pub rule_id: String,
        #[prost(bool, tag = "2")]
        pub passed: bool,
        #[prost(string, optional, tag = "3")]
        pub note: Option<String>,
    }

    #[derive(Clone, PartialEq, Message)]
    pub struct StageRecordPb {
        #[prost(int32, tag = "1")]
        pub stage: i32,
        #[prost(string, tag = "2")]
        pub detail: String,
        #[prost(bool, tag = "3")]
        pub passed: bool,
    }

    #[derive(Clone, PartialEq, Message)]
    pub struct RuleCelPb {
        #[prost(string, tag = "1")]
        pub rule_id: String,
        #[prost(string, tag = "2")]
        pub cel: String,
    }

    #[derive(Clone, PartialEq, Message)]
    pub struct CelEffectPb {
        #[prost(int32, tag = "1")]
        pub kind: i32,
        #[prost(string, optional, tag = "2")]
        pub target_api: Option<String>,
    }

    #[derive(Clone, PartialEq, Message)]
    pub struct AuditEventPb {
        #[prost(string, tag = "1")]
        pub trace_id: String,
        #[prost(string, tag = "2")]
        pub policy_id: String,
        #[prost(bytes = "vec", tag = "3")]
        pub actor_identity: Vec<u8>,
        #[prost(int32, tag = "4")]
        pub decision: i32,
        #[prost(int64, tag = "5")]
        pub observed_at_unix_nanos: i64,
        #[prost(uint64, optional, tag = "6")]
        pub block_height: Option<u64>,
        #[prost(message, repeated, tag = "7")]
        pub pipeline_stages: Vec<StageRecordPb>,
        #[prost(message, repeated, tag = "8")]
        pub rule_evaluations: Vec<RuleEvalPb>,
        #[prost(message, repeated, tag = "9")]
        pub rule_cel_sources: Vec<RuleCelPb>,
        #[prost(bytes = "vec", tag = "10")]
        pub ledger_digest_before: Vec<u8>,
        #[prost(bytes = "vec", tag = "11")]
        pub ledger_digest_after: Vec<u8>,
        #[prost(uint64, optional, tag = "12")]
        pub buffered_intent_id: Option<u64>,
        #[prost(uint64, optional, tag = "13")]
        pub chamber_depth: Option<u64>,
        #[prost(string, optional, tag = "14")]
        pub deny_reason: Option<String>,
        #[prost(message, repeated, tag = "15")]
        pub cel_host_effects: Vec<CelEffectPb>,
        #[prost(bytes = "vec", optional, tag = "16")]
        pub previous_event_hash: Option<Vec<u8>>,
        #[prost(bytes = "vec", tag = "17")]
        pub event_hash: Vec<u8>,
    }

    fn stage_tag(s: ResolutionStage) -> i32 {
        match s {
            ResolutionStage::PolicyWindow => 0,
            ResolutionStage::Legal => 1,
            ResolutionStage::Financial => 2,
            ResolutionStage::Privacy => 3,
            ResolutionStage::Logic => 4,
            ResolutionStage::Escrow => 5,
            ResolutionStage::ExternalGate => 6,
        }
    }

    fn stage_from_tag(t: i32) -> Option<ResolutionStage> {
        match t {
            0 => Some(ResolutionStage::PolicyWindow),
            1 => Some(ResolutionStage::Legal),
            2 => Some(ResolutionStage::Financial),
            3 => Some(ResolutionStage::Privacy),
            4 => Some(ResolutionStage::Logic),
            5 => Some(ResolutionStage::Escrow),
            6 => Some(ResolutionStage::ExternalGate),
            _ => None,
        }
    }

    fn decision_tag(d: AuditDecisionKind) -> i32 {
        match d {
            AuditDecisionKind::Allow => 0,
            AuditDecisionKind::Deny => 1,
            AuditDecisionKind::Buffered => 2,
        }
    }

    impl From<&RuleEvalRecord> for RuleEvalPb {
        fn from(r: &RuleEvalRecord) -> Self {
            Self {
                rule_id: r.rule_id.clone(),
                passed: r.passed,
                note: r.note.clone(),
            }
        }
    }

    impl From<&RuleEvalPb> for RuleEvalRecord {
        fn from(r: &RuleEvalPb) -> Self {
            Self {
                rule_id: r.rule_id.clone(),
                passed: r.passed,
                note: r.note.clone(),
            }
        }
    }

    impl From<&ResolutionStageRecord> for StageRecordPb {
        fn from(s: &ResolutionStageRecord) -> Self {
            Self {
                stage: stage_tag(s.stage),
                detail: s.detail.clone(),
                passed: s.passed,
            }
        }
    }

    impl From<&RuleCelSnapshot> for RuleCelPb {
        fn from(r: &RuleCelSnapshot) -> Self {
            Self {
                rule_id: r.rule_id.clone(),
                cel: r.cel.clone(),
            }
        }
    }

    fn effect_to_pb(e: &CelHostEffect) -> CelEffectPb {
        match e {
            CelHostEffect::QueueIntent { target_api } => CelEffectPb {
                kind: 1,
                target_api: Some(target_api.clone()),
            },
            CelHostEffect::LockResources => CelEffectPb { kind: 2, target_api: None },
        }
    }

    fn effect_from_pb(e: &CelEffectPb) -> Option<CelHostEffect> {
        match e.kind {
            1 => Some(CelHostEffect::QueueIntent { target_api: e.target_api.clone()? }),
            2 => Some(CelHostEffect::LockResources),
            _ => None,
        }
    }

    impl From<&AuditEvent> for AuditEventPb {
        fn from(e: &AuditEvent) -> Self {
            let observed_at_unix_nanos = e.observed_at.timestamp_nanos_opt().unwrap_or(0);
            Self {
                trace_id: e.trace_id.to_string(),
                policy_id: e.policy_id.clone(),
                actor_identity: e.actor_identity.clone(),
                decision: decision_tag(e.decision),
                observed_at_unix_nanos,
                block_height: e.block_height,
                pipeline_stages: e.pipeline_stages.iter().map(StageRecordPb::from).collect(),
                rule_evaluations: e.rule_evaluations.iter().map(RuleEvalPb::from).collect(),
                rule_cel_sources: e.rule_cel_sources.iter().map(RuleCelPb::from).collect(),
                ledger_digest_before: e.ledger_digest_before.to_vec(),
                ledger_digest_after: e.ledger_digest_after.to_vec(),
                buffered_intent_id: e.buffered_intent_id,
                chamber_depth: e.chamber_depth.map(|d| d as u64),
                deny_reason: e.deny_reason.clone(),
                cel_host_effects: e
                    .cel_host_effects
                    .as_ref()
                    .map(|v| v.iter().map(effect_to_pb).collect())
                    .unwrap_or_default(),
                previous_event_hash: e.previous_event_hash.map(|h| h.to_vec()),
                event_hash: e.event_hash.to_vec(),
            }
        }
    }

    /// Encode as protobuf (length-delimited wire — single message bytes; prepend length in your bus layer if needed).
    pub fn encode_audit_event_protobuf(event: &AuditEvent) -> Vec<u8> {
        let pb = AuditEventPb::from(event);
        pb.encode_to_vec()
    }

    /// Decode protobuf bytes produced by [`encode_audit_event_protobuf`].
    pub fn decode_audit_event_protobuf(bytes: &[u8]) -> Result<AuditEvent, String> {
        let pb = AuditEventPb::decode(bytes).map_err(|e| e.to_string())?;
        let trace_id = pb.trace_id.parse().map_err(|e: ulid::DecodeError| e.to_string())?;
        let decision = match pb.decision {
            0 => AuditDecisionKind::Allow,
            1 => AuditDecisionKind::Deny,
            2 => AuditDecisionKind::Buffered,
            _ => AuditDecisionKind::Deny,
        };
        let observed_at = DateTime::from_timestamp(
            pb.observed_at_unix_nanos / 1_000_000_000,
            (pb.observed_at_unix_nanos % 1_000_000_000) as u32,
        )
        .unwrap_or_else(Utc::now);
        let pipeline_stages: Vec<ResolutionStageRecord> = pb
            .pipeline_stages
            .iter()
            .filter_map(|s| {
                Some(ResolutionStageRecord {
                    stage: stage_from_tag(s.stage)?,
                    detail: s.detail.clone(),
                    passed: s.passed,
                })
            })
            .collect();
        let rule_evaluations: Vec<RuleEvalRecord> = pb.rule_evaluations.iter().map(RuleEvalRecord::from).collect();
        let rule_cel_sources: Vec<RuleCelSnapshot> = pb
            .rule_cel_sources
            .iter()
            .map(|r| RuleCelSnapshot {
                rule_id: r.rule_id.clone(),
                cel: r.cel.clone(),
            })
            .collect();
        let ledger_digest_before: [u8; 32] = vec_to_32(pb.ledger_digest_before)?;
        let ledger_digest_after: [u8; 32] = vec_to_32(pb.ledger_digest_after)?;
        let event_hash: [u8; 32] = vec_to_32(pb.event_hash)?;
        let previous_event_hash = pb.previous_event_hash.filter(|v| !v.is_empty()).map(vec_to_32).transpose()?;
        let cel_host_effects = if pb.cel_host_effects.is_empty() {
            None
        } else {
            Some(pb.cel_host_effects.iter().filter_map(effect_from_pb).collect::<Vec<_>>())
        };
        Ok(AuditEvent {
            trace_id,
            policy_id: pb.policy_id,
            actor_identity: pb.actor_identity,
            decision,
            observed_at,
            block_height: pb.block_height,
            pipeline_stages,
            rule_evaluations,
            rule_cel_sources,
            ledger_digest_before,
            ledger_digest_after,
            buffered_intent_id: pb.buffered_intent_id,
            chamber_depth: pb.chamber_depth.map(|d| d as usize),
            deny_reason: pb.deny_reason,
            cel_host_effects,
            previous_event_hash,
            event_hash,
        })
    }

    fn vec_to_32(v: Vec<u8>) -> Result<[u8; 32], String> {
        if v.len() != 32 {
            return Err("digest must be exactly 32 bytes".into());
        }
        let mut a = [0u8; 32];
        a.copy_from_slice(&v);
        Ok(a)
    }
}

#[cfg(feature = "audit-proto")]
pub use proto_wire::{decode_audit_event_protobuf, encode_audit_event_protobuf};

// --- Hash preimage -------------------------------------------------------------

fn hash_payload_v1(e: &AuditEvent) -> [u8; 32] {
    let mut buf = Vec::new();
    const PREFIX: &[u8] = b"rice.audit.preimage.v1";

    buf.extend_from_slice(PREFIX);
    match e.previous_event_hash {
        Some(h) => {
            buf.push(1);
            buf.extend_from_slice(&h);
        },
        None => buf.push(0),
    }
    buf.extend_from_slice(&e.trace_id.to_bytes());
    push_str(&mut buf, &e.policy_id);
    push_bytes(&mut buf, &e.actor_identity);
    buf.push(match e.decision {
        AuditDecisionKind::Allow => 0,
        AuditDecisionKind::Deny => 1,
        AuditDecisionKind::Buffered => 2,
    });
    let nanos = e.observed_at.timestamp_nanos_opt().unwrap_or(0);
    buf.extend_from_slice(&nanos.to_le_bytes());
    match e.block_height {
        Some(h) => {
            buf.push(1);
            buf.extend_from_slice(&h.to_le_bytes());
        },
        None => buf.push(0),
    }

    buf.extend_from_slice(&(e.pipeline_stages.len() as u64).to_le_bytes());
    for s in &e.pipeline_stages {
        buf.push(stage_byte(s.stage));
        push_str(&mut buf, &s.detail);
        buf.push(if s.passed { 1 } else { 0 });
    }

    buf.extend_from_slice(&(e.rule_evaluations.len() as u64).to_le_bytes());
    for r in &e.rule_evaluations {
        push_str(&mut buf, &r.rule_id);
        buf.push(if r.passed { 1 } else { 0 });
        match &r.note {
            Some(n) => {
                buf.push(1);
                push_str(&mut buf, n);
            },
            None => buf.push(0),
        }
    }

    buf.extend_from_slice(&(e.rule_cel_sources.len() as u64).to_le_bytes());
    for c in &e.rule_cel_sources {
        push_str(&mut buf, &c.rule_id);
        push_str(&mut buf, &c.cel);
    }

    buf.extend_from_slice(&e.ledger_digest_before);
    buf.extend_from_slice(&e.ledger_digest_after);

    match e.buffered_intent_id {
        Some(i) => {
            buf.push(1);
            buf.extend_from_slice(&i.to_le_bytes());
        },
        None => buf.push(0),
    }
    match e.chamber_depth {
        Some(d) => {
            buf.push(1);
            buf.extend_from_slice(&(d as u64).to_le_bytes());
        },
        None => buf.push(0),
    }

    match &e.deny_reason {
        Some(s) => {
            buf.push(1);
            push_str(&mut buf, s);
        },
        None => buf.push(0),
    }

    match &e.cel_host_effects {
        Some(fx) => {
            buf.push(1);
            buf.extend_from_slice(&(fx.len() as u64).to_le_bytes());
            for eff in fx {
                match eff {
                    CelHostEffect::QueueIntent { target_api } => {
                        buf.push(1);
                        push_str(&mut buf, target_api);
                    },
                    CelHostEffect::LockResources => buf.push(2),
                }
            }
        },
        None => buf.push(0),
    }

    Sha256::digest(&buf).into()
}

fn stage_byte(s: ResolutionStage) -> u8 {
    match s {
        ResolutionStage::PolicyWindow => 0,
        ResolutionStage::Legal => 1,
        ResolutionStage::Financial => 2,
        ResolutionStage::Privacy => 3,
        ResolutionStage::Logic => 4,
        ResolutionStage::Escrow => 5,
        ResolutionStage::ExternalGate => 6,
    }
}

fn push_str(buf: &mut Vec<u8>, s: &str) {
    let b = s.as_bytes();
    buf.extend_from_slice(&(b.len() as u64).to_le_bytes());
    buf.extend_from_slice(b);
}

fn push_bytes(buf: &mut Vec<u8>, s: &[u8]) {
    buf.extend_from_slice(&(s.len() as u64).to_le_bytes());
    buf.extend_from_slice(s);
}

// --- Human explanation ---------------------------------------------------------

fn human_explain(ev: &AuditEvent, lang: AuditLanguage) -> String {
    let mut lines = Vec::new();
    let id = ev.trace_id.to_string();
    match lang {
        AuditLanguage::English => {
            lines.push(format!("Decision trace {id} for policy {}.", ev.policy_id));
            match ev.decision {
                AuditDecisionKind::Allow => lines.push("Outcome: approved — all checks passed.".into()),
                AuditDecisionKind::Deny => {
                    lines.push("Outcome: denied — see system reason below.".into());
                    if let Some(ref r) = ev.deny_reason {
                        lines.push(translate_deny_hint_en(r));
                    }
                },
                AuditDecisionKind::Buffered => {
                    lines.push(
                        "Outcome: buffered — external dependency was closed; intent is queued, not rejected.".into(),
                    );
                    if let (Some(i), Some(d)) = (ev.buffered_intent_id, ev.chamber_depth) {
                        lines.push(format!("Queued intent id {i}; chamber depth after enqueue: {d}."));
                    }
                },
            }
            for r in &ev.rule_evaluations {
                if !r.passed {
                    let note = r.note.as_deref().unwrap_or("no evaluator note");
                    lines.push(format!("Rule `{}` did not pass: {}", r.rule_id, humanize_rule_note_en(note)));
                }
            }
        },
        AuditLanguage::Polish => {
            lines.push(format!("Ślad decyzji {id} dla polityki {}.", ev.policy_id));
            match ev.decision {
                AuditDecisionKind::Allow => lines.push("Wynik: zatwierdzono — wszystkie etapy przeszły.".into()),
                AuditDecisionKind::Deny => {
                    lines.push("Wynik: odmowa — poniżej wskazówka systemowa.".into());
                    if let Some(ref r) = ev.deny_reason {
                        lines.push(translate_deny_hint_pl(r));
                    }
                },
                AuditDecisionKind::Buffered => {
                    lines.push(
                        "Wynik: buforowanie — zewnętrzna bramka była zamknięta; intencja w kolejce, nie odrzucona."
                            .into(),
                    );
                    if let (Some(i), Some(d)) = (ev.buffered_intent_id, ev.chamber_depth) {
                        lines.push(format!("Id intencji {i}; głębokość komory po dodaniu: {d}."));
                    }
                },
            }
            for r in &ev.rule_evaluations {
                if !r.passed {
                    let note = r.note.as_deref().unwrap_or("brak notatki");
                    lines.push(format!("Reguła `{}` nie przeszła: {}", r.rule_id, humanize_rule_note_pl(note)));
                }
            }
        },
    }
    lines.join("\n")
}

fn humanize_rule_note_en(note: &str) -> String {
    let n = note.to_lowercase();
    if n.contains("undeclared") || n.contains("no such") {
        return "The rule referenced a variable or function that is not defined in this context (check policy bindings)."
            .into();
    }
    if n.contains("parse") || n.contains("syntax") {
        return "The policy expression could not be parsed — it may be malformed CEL.".into();
    }
    if n.contains("too large") || n.contains("too deep") {
        return "The rule exceeded size or depth limits enforced for safety.".into();
    }
    note.to_string()
}

fn humanize_rule_note_pl(note: &str) -> String {
    let n = note.to_lowercase();
    if n.contains("undeclared") || n.contains("no such") {
        return "Reguła odwołuje się do niezdefiniowanej zmiennej lub funkcji (sprawdź powiązania polityki).".into();
    }
    if n.contains("parse") || n.contains("syntax") {
        return "Wyrażenie nie mogło być zparsowane — możliwy błąd składni CEL.".into();
    }
    if n.contains("too large") || n.contains("too deep") {
        return "Reguła przekroczyła limity rozmiaru lub głębokości.".into();
    }
    note.to_string()
}

fn translate_deny_hint_en(reason: &str) -> String {
    let r = reason.to_lowercase();
    if r.contains("privacy") || r.contains("attestation") {
        return "Privacy or attestation phase failed — the request did not satisfy mandatory policy proof.".into();
    }
    if r.contains("legal") || r.contains("mandate") || r.contains("forbidden") {
        return "Legal or jurisdictional checks failed — the action conflicts with configured law surface.".into();
    }
    if r.contains("finance") || r.contains("balance") || r.contains("limit") || r.contains("cap") {
        return "Financial checks failed — limits, balances, or fees did not allow this movement.".into();
    }
    format!("System detail: {reason}")
}

fn translate_deny_hint_pl(reason: &str) -> String {
    let r = reason.to_lowercase();
    if r.contains("privacy") || r.contains("attestation") {
        return "Faza prywatności / atestu nie przeszła — brak wymaganego dowodu polityki.".into();
    }
    if r.contains("legal") || r.contains("mandate") || r.contains("forbidden") {
        return "Warstwa prawna nie przeszła — działanie jest sprzeczne z konfiguracją.".into();
    }
    if r.contains("finance") || r.contains("balance") || r.contains("limit") || r.contains("cap") {
        return "Warstwa finansowa nie przeszła — limity lub salda nie pozwalają na operację.".into();
    }
    format!("Szczegół systemowy: {reason}")
}

// --- Tests ---------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::PolicyDecision;
    use crate::error::PolicyError;
    use util::RiceError;

    fn sample_trace() -> ResolutionTrace {
        ResolutionTrace {
            stages: vec![],
            rule_results: vec![RuleEvalRecord {
                rule_id: "r1".into(),
                passed: false,
                note: Some("UndeclaredReference(\"x\")".into()),
            }],
        }
    }

    #[test]
    fn event_hash_roundtrip() {
        let mut e = AuditEvent::new_unsigned(
            Ulid::new(),
            "pol-1",
            vec![1, 2, 3],
            AuditDecisionKind::Deny,
            Utc::now(),
            None,
            vec![],
            sample_trace().rule_results.clone(),
            vec![RuleCelSnapshot { rule_id: "r1".into(), cel: "true".into() }],
            [1u8; 32],
            [2u8; 32],
            None,
            None,
            Some("finance cap".into()),
            None,
            None,
        );
        e.seal();
        assert!(e.verify_event_hash());
    }

    #[test]
    fn chain_advances_tip() {
        let mut chain = AuditChain::new();
        let mut a = AuditEvent::new_unsigned(
            Ulid::new(),
            "p",
            vec![],
            AuditDecisionKind::Allow,
            Utc::now(),
            None,
            vec![],
            vec![],
            vec![],
            [0u8; 32],
            [0u8; 32],
            None,
            None,
            None,
            None,
            None,
        );
        attach_to_chain(&mut chain, &mut a);
        assert_eq!(chain.tip(), Some(a.event_hash));
        let mut b = AuditEvent::new_unsigned(
            Ulid::new(),
            "p",
            vec![],
            AuditDecisionKind::Deny,
            Utc::now(),
            None,
            vec![],
            vec![],
            vec![],
            [0u8; 32],
            [0u8; 32],
            None,
            None,
            Some("x".into()),
            None,
            None,
        );
        attach_to_chain(&mut chain, &mut b);
        assert_eq!(b.previous_event_hash, Some(a.event_hash));
        assert!(b.verify_event_hash());
    }

    #[test]
    fn from_decision_buffered() {
        let d = PolicyDecision::Buffered {
            trace: ResolutionTrace::default(),
            intent_id: 7,
            chamber_depth: 3,
            cel_effects: vec![CelHostEffect::QueueIntent { target_api: "api".into() }],
        };
        let ev = audit_event_from_decision(
            Ulid::new(),
            Utc::now(),
            "pid",
            vec![],
            &d,
            &[],
            [0u8; 32],
            [1u8; 32],
            Some(42),
            None,
        );
        assert_eq!(ev.decision, AuditDecisionKind::Buffered);
        assert_eq!(ev.buffered_intent_id, Some(7));
        assert_eq!(ev.chamber_depth, Some(3));
        assert!(ev.verify_event_hash());
    }

    #[test]
    fn from_decision_deny() {
        let d = PolicyDecision::Deny {
            trace: ResolutionTrace::default(),
            reason: PolicyError::Clerk(RiceError::message("privacy attestation missing")),
        };
        let ev = audit_event_from_decision(
            Ulid::new(),
            Utc::now(),
            "pid",
            vec![],
            &d,
            &[],
            [0u8; 32],
            [0u8; 32],
            None,
            None,
        );
        assert_eq!(ev.decision, AuditDecisionKind::Deny);
        let h = ev.to_human_explanation(AuditLanguage::English);
        assert!(h.to_lowercase().contains("denied") || h.to_lowercase().contains("privacy"));
    }

    #[cfg(feature = "audit-proto")]
    #[test]
    fn proto_roundtrip() {
        let mut ev = AuditEvent::new_unsigned(
            Ulid::new(),
            "pol",
            vec![0xab; 33],
            AuditDecisionKind::Buffered,
            Utc::now(),
            Some(9),
            vec![],
            vec![],
            vec![RuleCelSnapshot { rule_id: "r".into(), cel: "true".into() }],
            [3u8; 32],
            [4u8; 32],
            Some(1),
            Some(2),
            None,
            Some(vec![CelHostEffect::LockResources]),
            None,
        );
        ev.seal();
        let bytes = super::encode_audit_event_protobuf(&ev);
        let back = super::decode_audit_event_protobuf(&bytes).expect("decode");
        assert_eq!(back.trace_id, ev.trace_id);
        assert_eq!(back.decision, ev.decision);
        assert_eq!(back.event_hash, ev.event_hash);
    }
}
