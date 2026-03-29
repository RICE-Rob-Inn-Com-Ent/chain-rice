//! Rule definitions — identifiers, CEL bodies, and optional action mapping hooks.

use serde::{Deserialize, Serialize};

use crate::error::ValidationError;

// [ ] https://docs.rs/cel-interpreter/
// [ ] Rule — id, name, expression, domain, severity, enabled; RuleDomain; Severity
// [ ] Rule::validate; RuleSet from YAML/JSON at RICE_POLICY_RULES_DIR; MASON CUE validation on pour
// [ ] versioning; depends_on ordering

/// Declarative business rule: evaluate `cel` against a context to get a boolean or data outcome.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Rule {
    pub id: String,
    pub cel: String,
    #[serde(default)]
    pub description: Option<String>,
    /// Optional symbolic action name for orchestration (not interpreted by CEL itself).
    #[serde(default)]
    pub action: Option<String>,
}

impl Rule {
    pub fn validate(&self) -> Result<(), ValidationError> {
        if self.id.is_empty() {
            return Err(ValidationError::EmptyRuleId);
        }
        Ok(())
    }

    /// Compile the embedded CEL expression.
    pub fn compile(
        &self,
    ) -> Result<cel_interpreter::Program, cel_interpreter::ParseError> {
        cel_interpreter::Program::compile(&self.cel)
    }
}
