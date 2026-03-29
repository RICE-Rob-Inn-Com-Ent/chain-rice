//! Audit trail — decision records and lightweight execution traces for compliance.

use serde::{Deserialize, Serialize};

// [ ] https://docs.rs/cel-interpreter/ — NATS, serde_json, quick-xml
// [ ] AuditEvent — rule_id, actor, result, context_hash, block_height; NATS RICE_POLICY_AUDIT_SUBJECT
// [ ] RICE_AUDIT_FORMAT json|xml; paginated query filters

/// One policy evaluation outcome suitable for persistence or logging.
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
