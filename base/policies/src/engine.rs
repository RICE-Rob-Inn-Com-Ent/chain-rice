//! **Always-on policy aggregator** — CLERK validates intent 24/7. Human calendar gates (weekends,
//! office hours) are **not** deny reasons. When an external dependency is down, phase-1–clean
//! intents are **escrowed** (optional ledger lock) and **buffered** in an FCFS chamber for SMITH to
//! drain as a batch when the gate opens (“Monday morning shock”).
//!
//! Pipeline: **Policy window (informational)** → **Legal** → **Finance** → **Privacy (phase-1)** →
//! **CEL** → **Escrow (if buffering)** → **External gate** (`Allow` vs `Buffered`).
//!
//! Set `RICE_POLICY_PARALLEL=1` (or `true` / `yes` / `on`) for parallel rule evaluation.

// TODO(rice):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] OTel spans per stage; release escrow on settlement ACK from SMITH.

use std::collections::{HashMap, VecDeque};
use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex};

use cel_interpreter::objects::{Key, Map};
use cel_interpreter::{Context, ExecutionError, Program, Value};
use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use ulid::Ulid;

use crate::accounting::{BalancePartition, Ledger, LedgerPeriod, SettlementMode, Transfer};
use crate::audit::{audit_event_from_decision, actor_identity_for_audit, block_height_from_env, dispatch_audit_streams};
use crate::currency::{Amount, Asset, AssetTag};
use crate::error::{LegalError, PolicyError, PolicyResult, SpecificationError};
use crate::finance::{
    amount_from_basis_points, ensure_per_transaction_cap, ensure_within_policy_limit, ledger_outbound_volume,
};
use crate::legal::{FairExchangeGuarantee, LegalIdentity, LegalManifest, validate_contract_safety};
use crate::rule::{EvaluationLimits, Rule, RuleContext, amount_to_cel_value};
use crate::schedule::TimeTolerance;
use crate::specification::Policy;

// --- Policy decision & trace -------------------------------------------------

/// Final outcome: immediate allow, hard deny (phase-1 / CEL failure), or **buffered** awaiting
/// external gate (not a deny).
#[derive(Debug)]
pub enum PolicyDecision {
    Allow {
        trace: ResolutionTrace,
    },
    Deny {
        trace: ResolutionTrace,
        reason: PolicyError,
    },
    /// Intent passed phase-1 + CEL; funds optionally escrowed; queued for SMITH when gate closed.
    Buffered {
        trace: ResolutionTrace,
        intent_id: u64,
        /// Chamber size **after** this enqueue (FCFS).
        chamber_depth: usize,
        cel_effects: Vec<CelHostEffect>,
    },
}

impl PolicyDecision {
    #[must_use]
    pub fn trace(&self) -> &ResolutionTrace {
        match self {
            PolicyDecision::Allow { trace }
            | PolicyDecision::Deny { trace, .. }
            | PolicyDecision::Buffered { trace, .. } => trace,
        }
    }

    #[must_use]
    pub fn deny_reason_string(&self) -> Option<String> {
        match self {
            PolicyDecision::Deny { reason, .. } => Some(reason.to_string()),
            _ => None,
        }
    }

    #[must_use]
    pub fn is_buffered(&self) -> bool {
        matches!(self, PolicyDecision::Buffered { .. })
    }

    #[must_use]
    pub fn buffered_intent_id(&self) -> Option<u64> {
        match self {
            PolicyDecision::Buffered { intent_id, .. } => Some(*intent_id),
            _ => None,
        }
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct ResolutionTrace {
    pub stages: Vec<ResolutionStageRecord>,
    pub rule_results: Vec<RuleEvalRecord>,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct ResolutionStageRecord {
    pub stage: ResolutionStage,
    pub detail: String,
    pub passed: bool,
}

#[derive(Clone, Copy, Debug, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "snake_case")]
pub enum ResolutionStage {
    /// Schedule is informational only — never a deny in always-on mode.
    PolicyWindow,
    Legal,
    Financial,
    Privacy,
    Logic,
    Escrow,
    ExternalGate,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct RuleEvalRecord {
    pub rule_id: String,
    pub passed: bool,
    pub note: Option<String>,
}

// --- CEL side effects & host options -----------------------------------------

/// Recorded when rules call [`queue_intent`](build_sovereign_host) / [`lock_resources_for_external`].
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum CelHostEffect {
    QueueIntent { target_api: String },
    LockResources,
}

/// Shared handles for sovereign CEL extensions (`external_available`, chamber depth, effect log).
///
/// [`live_telemetry`](Self::live_telemetry) is merged into the rule [`RuleContext`] as a CEL map
/// variable `telemetry` on each evaluation (SMITH injects gas, latency, etc.).
pub struct SovereignHostOptions {
    pub external_gate_open: Arc<AtomicBool>,
    pub chamber_intent_count: Arc<AtomicU64>,
    pub cel_effect_log: Arc<Mutex<Vec<CelHostEffect>>>,
    /// Runtime facts keyed by string; exposed to CEL as `telemetry.<key>` via a map subject.
    pub live_telemetry: Arc<Mutex<HashMap<String, Value>>>,
}

impl SovereignHostOptions {
    /// Gate open, empty chamber, fresh effect log — for tests and one-off CEL runs.
    #[must_use]
    pub fn for_isolated_eval() -> Self {
        Self {
            external_gate_open: Arc::new(AtomicBool::new(true)),
            chamber_intent_count: Arc::new(AtomicU64::new(0)),
            cel_effect_log: Arc::new(Mutex::new(Vec::new())),
            live_telemetry: Arc::new(Mutex::new(HashMap::new())),
        }
    }
}

// --- Transaction request -----------------------------------------------------

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct VelocityFact {
    pub account: String,
    pub asset: AssetTag,
    #[serde(default)]
    pub partition: Option<BalancePartition>,
    pub period: LedgerPeriod,
}

#[derive(Clone, Debug, PartialEq)]
pub struct TransactionRequest {
    pub policy_id: String,
    pub now: DateTime<Utc>,
    pub time_tolerance: TimeTolerance,
    pub legal_identity: Option<LegalIdentity>,
    pub require_identity_presence: bool,
    pub ledger_escrow_verified: bool,
    pub principal_amount: Amount,
    pub limit_key: Option<String>,
    pub already_consumed_toward_limit: Decimal,
    pub per_transaction_cap: Option<Amount>,
    pub fee_basis_points: Option<i64>,
    pub velocity: Option<VelocityFact>,
    pub available_balance: Option<Amount>,
    pub rule_context: RuleContext,
    /// Phase-1 privacy / policy attestation — `false` is a hard deny.
    pub privacy_attestation_ok: bool,
    /// Ledger account to debit **available** when buffering (escrow lock).
    pub escrow_source_account: Option<String>,
    /// Ledger account to credit **reserved** (escrow pool) when buffering.
    pub escrow_sink_account: Option<String>,
}

impl Default for TransactionRequest {
    fn default() -> Self {
        Self {
            policy_id: String::new(),
            now: Utc::now(),
            time_tolerance: TimeTolerance::ZERO,
            legal_identity: None,
            require_identity_presence: false,
            ledger_escrow_verified: false,
            principal_amount: Amount::from_decimal_str_exact("0", Asset::new("USD", 2).unwrap()).unwrap(),
            limit_key: None,
            already_consumed_toward_limit: Decimal::ZERO,
            per_transaction_cap: None,
            fee_basis_points: None,
            velocity: None,
            available_balance: None,
            rule_context: RuleContext::new(),
            privacy_attestation_ok: true,
            escrow_source_account: None,
            escrow_sink_account: None,
        }
    }
}

// --- Intent chamber (FCFS) -----------------------------------------------------

/// Snapshot of a buffered intent for SMITH to replay / batch-flush when the external gate opens.
#[derive(Clone, Debug, PartialEq)]
pub struct QueuedIntent {
    pub id: u64,
    pub enqueued_at: DateTime<Utc>,
    pub request: TransactionRequest,
    pub cel_effects_snapshot: Vec<CelHostEffect>,
}

// --- Engine ------------------------------------------------------------------

/// CLERK core: ledger, law, policies, external gate flag, and FCFS intent chamber.
#[derive(Debug)]
pub struct PolicyEngine {
    ledger: Ledger,
    manifest: LegalManifest,
    policies: HashMap<String, Policy>,
    fair_exchange: Option<FairExchangeGuarantee>,
    evaluation_limits: EvaluationLimits,
    external_gate_open: Arc<AtomicBool>,
    /// SMITH / orchestration: inject CEL-visible telemetry (`telemetry` map) per evaluation.
    live_telemetry: Arc<Mutex<HashMap<String, Value>>>,
    intent_chamber: VecDeque<QueuedIntent>,
    next_intent_id: u64,
}

impl PolicyEngine {
    #[must_use]
    pub fn new(manifest: LegalManifest) -> Self {
        Self::with_ledger(manifest, Ledger::new())
    }

    #[must_use]
    pub fn with_ledger(manifest: LegalManifest, ledger: Ledger) -> Self {
        Self {
            ledger,
            manifest,
            policies: HashMap::new(),
            fair_exchange: None,
            evaluation_limits: EvaluationLimits::default(),
            external_gate_open: Arc::new(AtomicBool::new(true)),
            live_telemetry: Arc::new(Mutex::new(HashMap::new())),
            intent_chamber: VecDeque::new(),
            next_intent_id: 1,
        }
    }

    #[must_use]
    pub fn policies(&self) -> &HashMap<String, Policy> {
        &self.policies
    }

    #[must_use]
    pub fn ledger(&self) -> &Ledger {
        &self.ledger
    }

    pub fn ledger_mut(&mut self) -> &mut Ledger {
        &mut self.ledger
    }

    #[must_use]
    pub fn manifest(&self) -> &LegalManifest {
        &self.manifest
    }

    pub fn set_manifest(&mut self, m: LegalManifest) {
        self.manifest = m;
    }

    #[must_use]
    pub fn fair_exchange(&self) -> Option<&FairExchangeGuarantee> {
        self.fair_exchange.as_ref()
    }

    pub fn set_fair_exchange(&mut self, g: Option<FairExchangeGuarantee>) {
        self.fair_exchange = g;
    }

    #[must_use]
    pub fn evaluation_limits(&self) -> &EvaluationLimits {
        &self.evaluation_limits
    }

    pub fn set_evaluation_limits(&mut self, limits: EvaluationLimits) {
        self.evaluation_limits = limits;
    }

    /// SMITH: mirror upstream connectivity — when `false`, successful intents are **buffered**, not denied.
    pub fn set_external_gate_open(&self, open: bool) {
        self.external_gate_open.store(open, Ordering::SeqCst);
    }

    #[must_use]
    pub fn external_gate_is_open(&self) -> bool {
        self.external_gate_open.load(Ordering::SeqCst)
    }

    /// Share handle for [`SovereignHostOptions::live_telemetry`] — SMITH sets gas price, API latency, etc.
    #[must_use]
    pub fn live_telemetry(&self) -> Arc<Mutex<HashMap<String, Value>>> {
        Arc::clone(&self.live_telemetry)
    }

    /// Insert one telemetry key for the next CEL evaluation (`telemetry.key` in rules).
    pub fn inject_telemetry(&self, key: impl Into<String>, value: Value) {
        self.live_telemetry.lock().unwrap().insert(key.into(), value);
    }

    /// Remove a telemetry key.
    pub fn remove_telemetry(&self, key: &str) {
        self.live_telemetry.lock().unwrap().remove(key);
    }

    /// Clear all live telemetry.
    pub fn clear_telemetry(&self) {
        self.live_telemetry.lock().unwrap().clear();
    }

    /// How many intentions are currently in the chamber (SAGE/BARD observability).
    #[must_use]
    pub fn intent_chamber_len(&self) -> usize {
        self.intent_chamber.len()
    }

    /// **Monday morning shock**: drain FCFS buffer as one batch for high-velocity downstream replay.
    pub fn drain_intent_chamber(&mut self) -> Vec<QueuedIntent> {
        self.intent_chamber.drain(..).collect()
    }

    #[must_use]
    pub fn policy(&self, id: &str) -> Option<&Policy> {
        self.policies.get(id)
    }

    pub fn insert_policy(&mut self, policy: Policy) -> PolicyResult<()> {
        policy.validate().map_err(PolicyError::from)?;
        let id = policy.id.clone();
        self.policies.insert(id, policy);
        Ok(())
    }

    pub fn remove_policy(&mut self, id: &str) -> Option<Policy> {
        self.policies.remove(id)
    }

    pub fn reload_policies_from_dir(&mut self, dir: &Path) -> PolicyResult<usize> {
        let mut loaded = 0usize;
        let entries = std::fs::read_dir(dir).map_err(|e| PolicyError::Clerk(util::RiceError::from(e)))?;
        for ent in entries {
            let ent = ent.map_err(|e| PolicyError::Clerk(util::RiceError::from(e)))?;
            let path = ent.path();
            if path.extension().and_then(|s| s.to_str()) != Some("json") {
                continue;
            }
            let text = std::fs::read_to_string(&path).map_err(|e| PolicyError::Clerk(util::RiceError::from(e)))?;
            let policy: Policy = crate::serial::from_json(&text)?;
            policy.validate().map_err(PolicyError::from)?;
            let id = policy.id.clone();
            self.policies.insert(id, policy);
            loaded += 1;
        }
        Ok(loaded)
    }

    /// Two-phase evaluation: phase-1 (legal, finance, privacy) hard deny; then CEL; then escrow +
    /// buffer if external gate closed, else `Allow`.
    pub fn evaluate(&mut self, req: &TransactionRequest) -> PolicyDecision {
        let mut trace = ResolutionTrace::default();

        let Some(policy) = self.policies.get(&req.policy_id) else {
            let reason = PolicyError::Specification(SpecificationError::AmbiguousIntent(format!(
                "unknown policy id `{}`",
                req.policy_id
            )));
            trace.stages.push(ResolutionStageRecord {
                stage: ResolutionStage::PolicyWindow,
                detail: reason.to_string(),
                passed: false,
            });
            return PolicyDecision::Deny { trace, reason };
        };

        // --- Policy window (informational; never deny on calendar) ---
        let sched_note = if policy.schedule.is_some() {
            "schedule present — always-on mode: calendar window does not veto intent".into()
        } else {
            "no policy schedule".into()
        };
        trace.stages.push(ResolutionStageRecord {
            stage: ResolutionStage::PolicyWindow,
            detail: sched_note,
            passed: true,
        });

        // --- Legal ---
        let mut legal_notes = Vec::<String>::new();
        if let Some(ref id) = req.legal_identity {
            match id.verify_public_key() {
                Ok(_) => legal_notes.push("identity: valid secp256k1 key".into()),
                Err(e) => {
                    legal_notes.push(format!("identity: invalid signing key ({e})"));
                    trace.stages.push(ResolutionStageRecord {
                        stage: ResolutionStage::Legal,
                        detail: legal_notes.join("; "),
                        passed: false,
                    });
                    return PolicyDecision::Deny { trace, reason: e };
                },
            }
            if req.require_identity_presence
                && (id.verified_at_rfc3339.as_ref().map(String::is_empty).unwrap_or(true)
                    || id.registry_presence_ref.as_ref().map(String::is_empty).unwrap_or(true))
            {
                legal_notes.push("identity: missing verified_at_rfc3339 or registry_presence_ref".into());
                trace.stages.push(ResolutionStageRecord {
                    stage: ResolutionStage::Legal,
                    detail: legal_notes.join("; "),
                    passed: false,
                });
                return PolicyDecision::Deny {
                    trace,
                    reason: LegalError::InvalidIdentityKey {
                        detail: "require_identity_presence: need verified_at_rfc3339 and registry_presence_ref".into(),
                    }
                    .into(),
                };
            }
            if req.require_identity_presence {
                legal_notes.push("identity: presence metadata present".into());
            }
        } else {
            legal_notes.push("identity: not provided".into());
        }

        match validate_contract_safety(
            policy,
            &self.manifest,
            self.fair_exchange.as_ref().map(|g| (g, req.ledger_escrow_verified)),
        ) {
            Ok(()) => {
                legal_notes.push("manifest & fair-exchange: ok".into());
                trace.stages.push(ResolutionStageRecord {
                    stage: ResolutionStage::Legal,
                    detail: legal_notes.join("; "),
                    passed: true,
                });
            },
            Err(e) => {
                legal_notes.push(format!("manifest/fair-exchange: {e}"));
                trace.stages.push(ResolutionStageRecord {
                    stage: ResolutionStage::Legal,
                    detail: legal_notes.join("; "),
                    passed: false,
                });
                return PolicyDecision::Deny { trace, reason: e };
            },
        }

        // --- Finance ---
        let mut fin_msgs = Vec::new();
        let mut fin_ok = true;
        let mut fin_err: Option<PolicyError> = None;

        if let Some(cap) = &req.per_transaction_cap {
            if let Err(e) = ensure_per_transaction_cap(&req.principal_amount, cap) {
                fin_ok = false;
                fin_err.get_or_insert(e);
                fin_msgs.push(fin_err.as_ref().unwrap().to_string());
            }
        }

        if fin_ok {
            if let Some(ref key) = req.limit_key {
                if let Err(e) =
                    ensure_within_policy_limit(policy, key, &req.principal_amount, req.already_consumed_toward_limit)
                {
                    fin_ok = false;
                    fin_err.get_or_insert(e);
                    fin_msgs.push(fin_err.as_ref().unwrap().to_string());
                }
            }
        }

        if fin_ok {
            if let Some(ref avail) = req.available_balance {
                if avail.tag() == req.principal_amount.tag() {
                    if req.principal_amount.value() > avail.value() {
                        fin_ok = false;
                        let e = PolicyError::Specification(SpecificationError::AmbiguousIntent(format!(
                            "principal {} exceeds available_balance {}",
                            req.principal_amount.value(),
                            avail.value()
                        )));
                        fin_err.get_or_insert(e);
                        fin_msgs.push(fin_err.as_ref().unwrap().to_string());
                    } else {
                        fin_msgs.push("principal within available_balance (same asset)".into());
                    }
                } else {
                    fin_msgs.push("available_balance asset differs from principal; skipped balance cap check".into());
                }
            }
        }

        let fee_amt = if fin_ok {
            match req.fee_basis_points {
                Some(bps) => match amount_from_basis_points(&req.principal_amount, bps) {
                    Ok(f) => Some(f),
                    Err(e) => {
                        fin_ok = false;
                        fin_err.get_or_insert(e);
                        fin_msgs.push(fin_err.as_ref().unwrap().to_string());
                        None
                    },
                },
                None => None,
            }
        } else {
            None
        };

        if fin_ok {
            if let Some(ref vf) = req.velocity {
                match ledger_outbound_volume(&self.ledger, &vf.account, &vf.asset, vf.partition, &vf.period) {
                    Ok(v) => fin_msgs.push(format!("velocity outbound in period: {v}")),
                    Err(e) => {
                        fin_ok = false;
                        fin_err.get_or_insert(e);
                        fin_msgs.push(fin_err.as_ref().unwrap().to_string());
                    },
                }
            }
        }

        if fin_ok {
            if let Some(ref fee) = fee_amt {
                fin_msgs.push(format!(
                    "calculated_fee: {} {} (minor precision {})",
                    fee.value(),
                    fee.tag().label,
                    fee.tag().precision
                ));
            }
        }

        trace.stages.push(ResolutionStageRecord {
            stage: ResolutionStage::Financial,
            detail: fin_msgs.join("; "),
            passed: fin_ok,
        });

        if !fin_ok {
            let reason = fin_err.unwrap_or_else(|| {
                PolicyError::Finance(crate::error::FinanceError::Overflow { operation: "financial_stage".into() })
            });
            return PolicyDecision::Deny { trace, reason };
        }

        // --- Privacy (phase-1) ---
        let priv_ok = req.privacy_attestation_ok;
        trace.stages.push(ResolutionStageRecord {
            stage: ResolutionStage::Privacy,
            detail: if priv_ok {
                "privacy / policy attestation: ok (phase-1)".into()
            } else {
                "privacy / policy attestation: FAILED (phase-1 hard deny)".into()
            },
            passed: priv_ok,
        });
        if !priv_ok {
            return PolicyDecision::Deny {
                trace,
                reason: PolicyError::Specification(SpecificationError::AmbiguousIntent(
                    "privacy_attestation_ok is false".into(),
                )),
            };
        }

        // --- CEL ---
        let policy_arc = Arc::new(policy.clone());
        let chamber_count = Arc::new(AtomicU64::new(self.intent_chamber.len() as u64));
        let effect_log = Arc::new(Mutex::new(Vec::<CelHostEffect>::new()));
        {
            let mut g = effect_log.lock().unwrap();
            g.clear();
        }
        let host_opts = SovereignHostOptions {
            external_gate_open: Arc::clone(&self.external_gate_open),
            chamber_intent_count: Arc::clone(&chamber_count),
            cel_effect_log: Arc::clone(&effect_log),
            live_telemetry: Arc::clone(&self.live_telemetry),
        };
        let host = build_sovereign_host(policy_arc, &host_opts);

        let mut ctx = req.rule_context.clone();
        ctx.now = Some(req.now);
        ctx = ctx.with_subject("request", cel_request_snapshot(req));
        if let Some(w) = &policy.schedule {
            ctx = ctx.with_schedule(w, req.now, req.time_tolerance);
        }
        let zero_fee = Amount::new(Decimal::ZERO, req.principal_amount.tag().clone())
            .unwrap_or_else(|_| req.principal_amount.clone());
        ctx = ctx
            .with_amount("principal", req.principal_amount.clone())
            .with_amount("calculated_fee", fee_amt.clone().unwrap_or(zero_fee));
        if let Some(b) = &req.available_balance {
            ctx = ctx.with_amount("available_balance", b.clone());
        }
        if let Some(vf) = &req.velocity {
            if let Ok(vol) = ledger_outbound_volume(&self.ledger, &vf.account, &vf.asset, vf.partition, &vf.period) {
                ctx = ctx.with_subject("velocity_outbound", Value::String(vol.to_string().into()));
            }
        }
        {
            let guard = self.live_telemetry.lock().unwrap();
            if !guard.is_empty() {
                let m: HashMap<String, Value> = guard.iter().map(|(k, v)| (k.clone(), v.clone())).collect();
                ctx = ctx.with_subject("telemetry", Value::Map(Map::from(m)));
            }
        }

        let fee_computed = fee_amt.is_some();
        let parallel = parallel_rules_from_env();
        let mut rule_results: Vec<RuleEvalRecord> = if parallel {
            use rayon::prelude::*;
            policy
                .rules
                .par_iter()
                .map(|rule| eval_rule_record(rule, &host, &ctx, &self.evaluation_limits))
                .collect()
        } else {
            policy
                .rules
                .iter()
                .map(|rule| eval_rule_record(rule, &host, &ctx, &self.evaluation_limits))
                .collect()
        };
        rule_results.sort_by(|a, b| a.rule_id.cmp(&b.rule_id));
        trace.rule_results = rule_results.clone();

        let all_pass = rule_results.iter().all(|r| r.passed);
        trace.stages.push(ResolutionStageRecord {
            stage: ResolutionStage::Logic,
            detail: format!("CEL rules evaluated (parallel={parallel}, fee_computed={fee_computed})"),
            passed: all_pass,
        });

        if !all_pass {
            let note = rule_results
                .iter()
                .find(|r| !r.passed)
                .and_then(|r| r.note.clone())
                .unwrap_or_else(|| "one or more rules failed".into());
            return PolicyDecision::Deny {
                trace,
                reason: PolicyError::Rule(crate::error::RuleError::Binding { name: "rules".into(), reason: note }),
            };
        }

        let cel_effects: Vec<CelHostEffect> = effect_log.lock().unwrap().clone();

        let gate_open = self.external_gate_open.load(Ordering::SeqCst);

        // --- Escrow: lock principal when we must buffer (prevents double-spend while queued). ---
        if !gate_open {
            if let (Some(src), Some(sink)) = (&req.escrow_source_account, &req.escrow_sink_account) {
                let tx = Transfer {
                    source: src.clone(),
                    source_partition: BalancePartition::Available,
                    destination: sink.clone(),
                    destination_partition: BalancePartition::Reserved,
                    amount: req.principal_amount.clone(),
                    purpose: format!("clerk_escrow_awaiting_external policy={}", req.policy_id),
                    policy_id: Some(req.policy_id.clone()),
                    settlement: SettlementMode::Deferred { settle_by: None },
                };
                match self.ledger.apply_transfer(tx, req.now, None) {
                    Ok(_) => {
                        trace.stages.push(ResolutionStageRecord {
                            stage: ResolutionStage::Escrow,
                            detail: format!(
                                "escrow: {src} available -> {sink} reserved ({})",
                                req.principal_amount.tag().label
                            ),
                            passed: true,
                        });
                    },
                    Err(e) => {
                        trace.stages.push(ResolutionStageRecord {
                            stage: ResolutionStage::Escrow,
                            detail: format!("escrow transfer failed: {e}"),
                            passed: false,
                        });
                        return PolicyDecision::Deny { trace, reason: e };
                    },
                }
            } else {
                trace.stages.push(ResolutionStageRecord {
                    stage: ResolutionStage::Escrow,
                    detail: "escrow skipped (set escrow_source_account + escrow_sink_account to lock funds)".into(),
                    passed: true,
                });
            }
        } else {
            trace.stages.push(ResolutionStageRecord {
                stage: ResolutionStage::Escrow,
                detail: "external gate open: no buffering escrow in this path".into(),
                passed: true,
            });
        }

        // --- External gate ---
        if gate_open {
            trace.stages.push(ResolutionStageRecord {
                stage: ResolutionStage::ExternalGate,
                detail: "external gate OPEN — immediate allow".into(),
                passed: true,
            });
            PolicyDecision::Allow { trace }
        } else {
            let intent_id = self.next_intent_id;
            self.next_intent_id = self.next_intent_id.saturating_add(1);
            self.intent_chamber.push_back(QueuedIntent {
                id: intent_id,
                enqueued_at: req.now,
                request: req.clone(),
                cel_effects_snapshot: cel_effects.clone(),
            });
            let depth = self.intent_chamber.len();
            trace.stages.push(ResolutionStageRecord {
                stage: ResolutionStage::ExternalGate,
                detail: format!(
                    "external gate CLOSED — intent {intent_id} buffered (chamber depth {depth}); not a deny"
                ),
                passed: true,
            });
            PolicyDecision::Buffered {
                trace,
                intent_id,
                chamber_depth: depth,
                cel_effects,
            }
        }
    }

    /// Evaluate `req`, capture ledger digests, build a sealed [`crate::audit::AuditEvent`], then run [`dispatch_audit_streams`].
    ///
    /// For hash-chain linkage and explicit block height, see [`Self::evaluate_intent_with_audit`].
    pub fn evaluate_intent(&mut self, req: &TransactionRequest) -> PolicyResult<crate::audit::AuditEvent> {
        self.evaluate_intent_with_audit(req, None, None)
    }

    /// Like [`Self::evaluate_intent`], but optionally advances `audit_chain` and overrides block height
    /// (else `RICE_POLICY_BLOCK_HEIGHT` is merged when set).
    pub fn evaluate_intent_with_audit(
        &mut self,
        req: &TransactionRequest,
        audit_chain: Option<&mut crate::audit::AuditChain>,
        block_height: Option<u64>,
    ) -> PolicyResult<crate::audit::AuditEvent> {
        let digest_before = self.ledger().state_digest();
        let decision = self.evaluate(req);
        let digest_after = self.ledger().state_digest();

        let rules = self
            .policy(&req.policy_id)
            .map(|p| p.rules.as_slice())
            .unwrap_or(&[]);

        let chain_tip = audit_chain.as_ref().and_then(|c| c.tip());
        let bh = block_height.or_else(block_height_from_env);

        let event = audit_event_from_decision(
            Ulid::new(),
            req.now,
            req.policy_id.clone(),
            actor_identity_for_audit(req),
            &decision,
            rules,
            digest_before,
            digest_after,
            bh,
            chain_tip,
        );

        if let Some(chain) = audit_chain {
            chain.advance_from_sealed_event(&event);
        }

        dispatch_audit_streams(&event)?;
        Ok(event)
    }
}

/// Convenience: [`PolicyEngine::evaluate_intent`].
pub fn evaluate_intent(req: &TransactionRequest, engine: &mut PolicyEngine) -> PolicyResult<crate::audit::AuditEvent> {
    engine.evaluate_intent(req)
}

/// Convenience: [`PolicyEngine::evaluate_intent_with_audit`].
pub fn evaluate_intent_with_audit(
    req: &TransactionRequest,
    engine: &mut PolicyEngine,
    audit_chain: Option<&mut crate::audit::AuditChain>,
    block_height: Option<u64>,
) -> PolicyResult<crate::audit::AuditEvent> {
    engine.evaluate_intent_with_audit(req, audit_chain, block_height)
}

fn eval_rule_record(rule: &Rule, host: &Context<'_>, facts: &RuleContext, limits: &EvaluationLimits) -> RuleEvalRecord {
    match rule.evaluate_bool(host, facts, limits) {
        Ok(true) => RuleEvalRecord {
            rule_id: rule.id.clone(),
            passed: true,
            note: None,
        },
        Ok(false) => RuleEvalRecord {
            rule_id: rule.id.clone(),
            passed: false,
            note: Some("expression evaluated to false".into()),
        },
        Err(e) => RuleEvalRecord {
            rule_id: rule.id.clone(),
            passed: false,
            note: Some(e.to_string()),
        },
    }
}

#[must_use]
pub fn parallel_rules_from_env() -> bool {
    match std::env::var("RICE_POLICY_PARALLEL") {
        Ok(v) => {
            let v = v.to_ascii_lowercase();
            matches!(v.as_str(), "1" | "true" | "yes" | "on")
        },
        Err(_) => false,
    }
}

/// Parse an oracle **price** for `convert` from CEL — **no `f64` path**: callers pass a decimal
/// string (`"1.25"`) or a non-negative integer; `float` literals are rejected so policy rules do
/// not depend on binary floating-point rounding.
fn decimal_from_cel_oracle_price(price_v: Value) -> Result<Decimal, ExecutionError> {
    match price_v {
        Value::String(s) => Decimal::from_str_exact(s.as_ref()).map_err(|_| ExecutionError::UnexpectedType {
            got: format!("price string is not an exact decimal: {s}"),
            want: "decimal string, e.g. oracle quote \"0.92\"".into(),
        }),
        Value::Int(i) if i >= 0 => Ok(Decimal::from(i)),
        Value::Int(i) => Err(ExecutionError::UnexpectedType {
            got: format!("negative int price: {i}"),
            want: "non-negative decimal string or integer".into(),
        }),
        Value::UInt(u) => Ok(Decimal::from(u)),
        Value::Float(_) => Err(ExecutionError::UnexpectedType {
            got: "float literal for convert price".into(),
            want: "decimal string (CEL string) or non-negative int; float rejected to avoid f64 drift"
                .into(),
        }),
        other => Err(ExecutionError::UnexpectedType {
            got: format!("{other:?}"),
            want: "decimal string or non-negative integer for oracle price".into(),
        }),
    }
}

fn cel_request_snapshot(req: &TransactionRequest) -> Value {
    let mut m = HashMap::<Key, Value>::new();
    m.insert(
        Key::String(Arc::new("policy_id".into())),
        Value::String(req.policy_id.clone().into()),
    );
    m.insert(
        Key::String(Arc::new("ledger_escrow_verified".into())),
        Value::Bool(req.ledger_escrow_verified),
    );
    m.insert(
        Key::String(Arc::new("require_identity_presence".into())),
        Value::Bool(req.require_identity_presence),
    );
    m.insert(
        Key::String(Arc::new("time_tolerance_seconds".into())),
        Value::Int(req.time_tolerance.as_duration().num_seconds()),
    );
    m.insert(
        Key::String(Arc::new("limit_key".into())),
        match &req.limit_key {
            Some(s) => Value::String(s.clone().into()),
            None => Value::Null,
        },
    );
    m.insert(
        Key::String(Arc::new("privacy_attestation_ok".into())),
        Value::Bool(req.privacy_attestation_ok),
    );
    Value::Map(Map { map: Arc::new(m) })
}

/// Sovereign stdlib extensions: `convert`, `has_limit`, `external_available`, `chamber_intent_count`,
/// `queue_intent`, `lock_resources_for_external`.
#[must_use]
pub fn build_sovereign_host(policy: Arc<Policy>, opts: &SovereignHostOptions) -> Context<'static> {
    let mut host = Context::default();

    let p_lim = Arc::clone(&policy);
    host.add_function("has_limit", move |key: Arc<String>| {
        p_lim.limits.as_ref().map(|m| m.contains_key(key.as_str())).unwrap_or(false)
    });

    let gate = Arc::clone(&opts.external_gate_open);
    host.add_function("external_available", move || gate.load(Ordering::SeqCst));

    let chamber = Arc::clone(&opts.chamber_intent_count);
    host.add_function("chamber_intent_count", move || chamber.load(Ordering::SeqCst) as i64);

    let effects_q = Arc::clone(&opts.cel_effect_log);
    host.add_function("queue_intent", move |target_api: Arc<String>| {
        effects_q
            .lock()
            .unwrap()
            .push(CelHostEffect::QueueIntent { target_api: target_api.as_ref().clone() });
        true
    });

    let effects_l = Arc::clone(&opts.cel_effect_log);
    host.add_function("lock_resources_for_external", move || {
        effects_l.lock().unwrap().push(CelHostEffect::LockResources);
        true
    });

    host.add_function(
        "convert",
        move |amount_v: Value, quote_label: Arc<String>, quote_precision: i64, price_v: Value| {
            let base = amount_from_cel_map(&amount_v)?;
            let quote = Asset::new(quote_label.as_ref().as_str(), quote_precision as u8).map_err(|e| {
                ExecutionError::UnexpectedType {
                    got: e.to_string(),
                    want: "valid quote asset".into(),
                }
            })?;
            let dec_price = decimal_from_cel_oracle_price(price_v)?;
            if dec_price < Decimal::ZERO {
                return Err(ExecutionError::UnexpectedType {
                    got: "negative price".into(),
                    want: "non-negative decimal".into(),
                });
            }
            let v = base
                .value()
                .checked_mul(dec_price)
                .ok_or_else(|| ExecutionError::UnexpectedType {
                    got: "decimal overflow in convert".into(),
                    want: "finite product".into(),
                })?;
            let v = v.round_dp(u32::from(quote.precision()));
            let out = Amount::new(v, quote).map_err(|e| ExecutionError::UnexpectedType {
                got: e.to_string(),
                want: "amount after convert".into(),
            })?;
            let cel = amount_to_cel_value(&out).map_err(|e| ExecutionError::UnexpectedType {
                got: e.to_string(),
                want: "amount_to_cel_value".into(),
            })?;
            Ok(cel)
        },
    );

    host
}

fn amount_from_cel_map(v: &Value) -> Result<Amount, ExecutionError> {
    let Value::Map(m) = v else {
        return Err(ExecutionError::UnexpectedType {
            got: format!("{:?}", v.type_of()),
            want: "map (amount)".into(),
        });
    };
    let ve = m
        .get(&Key::String(Arc::new("value_exact".into())))
        .ok_or_else(|| ExecutionError::NoSuchKey(Arc::new("value_exact".into())))?;
    let Value::String(s) = ve else {
        return Err(ExecutionError::UnexpectedType {
            got: format!("{:?}", ve.type_of()),
            want: "string value_exact".into(),
        });
    };
    let label_v = m
        .get(&Key::String(Arc::new("label".into())))
        .ok_or_else(|| ExecutionError::NoSuchKey(Arc::new("label".into())))?;
    let Value::String(label) = label_v else {
        return Err(ExecutionError::UnexpectedType {
            got: format!("{:?}", label_v.type_of()),
            want: "string label".into(),
        });
    };
    let prec_v = m
        .get(&Key::String(Arc::new("precision".into())))
        .ok_or_else(|| ExecutionError::NoSuchKey(Arc::new("precision".into())))?;
    let p = match prec_v {
        Value::Int(i) => *i,
        Value::UInt(u) => i64::try_from(*u).map_err(|_| ExecutionError::UnexpectedType {
            got: "precision uint too large".into(),
            want: "i64 precision".into(),
        })?,
        _ => {
            return Err(ExecutionError::UnexpectedType {
                got: format!("{:?}", prec_v.type_of()),
                want: "int precision".into(),
            });
        },
    };
    let p_u8 = u8::try_from(p).map_err(|_| ExecutionError::UnexpectedType {
        got: format!("precision {p}"),
        want: "u8".into(),
    })?;
    let tag = Asset::new(label.as_ref().as_str(), p_u8).map_err(|e| ExecutionError::UnexpectedType {
        got: e.to_string(),
        want: "asset tag".into(),
    })?;
    let dec = Decimal::from_str_exact(s.as_ref()).map_err(|e| ExecutionError::UnexpectedType {
        got: e.to_string(),
        want: "decimal value_exact".into(),
    })?;
    Amount::new(dec, tag).map_err(|e| ExecutionError::UnexpectedType {
        got: e.to_string(),
        want: "amount".into(),
    })
}

pub fn compile(source: &str) -> Result<Program, cel_interpreter::ParseError> {
    Program::compile(source)
}

pub fn evaluate(program: &Program, ctx: &Context) -> cel_interpreter::objects::ResolveResult {
    program.execute(ctx)
}

pub fn root_context() -> Context<'static> {
    Context::default()
}

pub fn bind_value(ctx: &mut Context<'_>, name: &str, value: Value) {
    ctx.add_variable_from_value(name, value);
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::legal::LegalManifest;
    use crate::rule::{evaluate_cel, Rule};
    use crate::serial::PolicySchemaVersion;

    fn usd_policy() -> Policy {
        Policy {
            id: "pol1".into(),
            version: PolicySchemaVersion::CURRENT,
            metadata: Default::default(),
            schedule: None,
            rules: vec![
                Rule {
                    id: "r1".into(),
                    cel: "principal.value_milli > 0 && has_limit(\"cap\") && request.policy_id == \"pol1\"".into(),
                    description: None,
                    action: None,
                },
                Rule {
                    id: "r2".into(),
                    cel: "external_available() || queue_intent(\"synthetic-fallback\")".into(),
                    description: None,
                    action: None,
                },
            ],
            limits: Some(HashMap::from([(
                "cap".into(),
                Amount::from_decimal_str_exact("1000.00", Asset::new("USD", 2).unwrap()).unwrap(),
            )])),
        }
    }

    #[test]
    fn engine_allow_when_gate_open() {
        let mut eng = PolicyEngine::new(LegalManifest::default());
        eng.insert_policy(usd_policy()).unwrap();
        eng.set_external_gate_open(true);
        let now = DateTime::parse_from_rfc3339("2026-04-14T12:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let req = TransactionRequest {
            policy_id: "pol1".into(),
            now,
            limit_key: Some("cap".into()),
            principal_amount: Amount::from_decimal_str_exact("10.00", Asset::new("USD", 2).unwrap()).unwrap(),
            ..Default::default()
        };
        match eng.evaluate(&req) {
            PolicyDecision::Allow { .. } => {},
            o => panic!("expected Allow, got {o:?}"),
        }
    }

    #[test]
    fn engine_buffers_when_gate_closed() {
        let mut eng = PolicyEngine::new(LegalManifest::default());
        eng.insert_policy(usd_policy()).unwrap();
        eng.set_external_gate_open(false);
        let now = DateTime::parse_from_rfc3339("2026-04-11T12:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let req = TransactionRequest {
            policy_id: "pol1".into(),
            now,
            limit_key: Some("cap".into()),
            principal_amount: Amount::from_decimal_str_exact("10.00", Asset::new("USD", 2).unwrap()).unwrap(),
            ..Default::default()
        };
        match eng.evaluate(&req) {
            PolicyDecision::Buffered {
                intent_id, chamber_depth, cel_effects, ..
            } => {
                assert_eq!(intent_id, 1);
                assert_eq!(chamber_depth, 1);
                assert!(
                    cel_effects.iter().any(|e| matches!(
                        e,
                        CelHostEffect::QueueIntent { target_api } if target_api == "synthetic-fallback"
                    )),
                    "{cel_effects:?}"
                );
            },
            o => panic!("expected Buffered, got {o:?}"),
        }
        assert_eq!(eng.intent_chamber_len(), 1);
    }

    #[test]
    fn engine_financial_denies_when_principal_exceeds_available() {
        let mut eng = PolicyEngine::new(LegalManifest::default());
        eng.insert_policy(usd_policy()).unwrap();
        let now = DateTime::parse_from_rfc3339("2026-04-14T12:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let req = TransactionRequest {
            policy_id: "pol1".into(),
            now,
            limit_key: Some("cap".into()),
            principal_amount: Amount::from_decimal_str_exact("500.00", Asset::new("USD", 2).unwrap()).unwrap(),
            available_balance: Some(Amount::from_decimal_str_exact("100.00", Asset::new("USD", 2).unwrap()).unwrap()),
            ..Default::default()
        };
        let d = eng.evaluate(&req);
        assert!(matches!(d, PolicyDecision::Deny { .. }));
        assert!(d.deny_reason_string().unwrap().contains("exceeds available_balance"));
    }

    #[test]
    fn engine_privacy_phase1_hard_deny() {
        let mut eng = PolicyEngine::new(LegalManifest::default());
        eng.insert_policy(usd_policy()).unwrap();
        eng.set_external_gate_open(true);
        let now = Utc::now();
        let req = TransactionRequest {
            policy_id: "pol1".into(),
            now,
            limit_key: Some("cap".into()),
            principal_amount: Amount::from_decimal_str_exact("10.00", Asset::new("USD", 2).unwrap()).unwrap(),
            privacy_attestation_ok: false,
            ..Default::default()
        };
        assert!(matches!(eng.evaluate(&req), PolicyDecision::Deny { .. }));
    }

    #[test]
    fn drain_chamber_fcfs_order() {
        let mut eng = PolicyEngine::new(LegalManifest::default());
        eng.insert_policy(usd_policy()).unwrap();
        eng.set_external_gate_open(false);
        let now = Utc::now();
        for i in 0..2u8 {
            let req = TransactionRequest {
                policy_id: "pol1".into(),
                now,
                limit_key: Some("cap".into()),
                principal_amount: Amount::from_decimal_str_exact(
                    &format!("{}.00", 10 + i as i32),
                    Asset::new("USD", 2).unwrap(),
                )
                .unwrap(),
                ..Default::default()
            };
            assert!(eng.evaluate(&req).is_buffered());
        }
        let batch = eng.drain_intent_chamber();
        assert_eq!(batch.len(), 2);
        assert!(batch[0].request.principal_amount.value() < batch[1].request.principal_amount.value());
    }

    #[test]
    fn sovereign_convert_host() {
        let p = Arc::new(usd_policy());
        let opts = SovereignHostOptions::for_isolated_eval();
        let host = build_sovereign_host(p, &opts);
        let amt = Amount::from_decimal_str_exact("100.00", Asset::new("USD", 2).unwrap()).unwrap();
        let now = DateTime::parse_from_rfc3339("2026-04-14T12:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let mut ctx = RuleContext::new().with_amount("x", amt);
        ctx = ctx.with_now(now);
        let v = evaluate_cel(
            "convert(x, \"EUR\", 2, \"0.92\").value_milli == 9200 && convert(x, \"EUR\", 2, \"0.92\").label == \"EUR\"",
            &host,
            &ctx,
            &EvaluationLimits::default(),
        )
        .unwrap();
        assert_eq!(v, Value::Bool(true));
    }
}
