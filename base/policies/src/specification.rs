//! **Blueprint of law** — the typed, versioned [`Policy`] DTO: identity, schema, metadata, optional
//! schedule, [`Rule`] set, and optional named [`Amount`] limits. Passes serde (JSON / YAML with a YAML
//! crate upstream, bincode, etc.) and [`Policy::validate`] before hand-off to the engine.
//!
//! This module is **not** the signed [`crate::serial::PolicyEnvelope`]; it is the **payload shape**
//! you can embed, hash, or store as a first-class document.

use std::collections::HashMap;
use std::collections::HashSet;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::currency::{Amount, Asset};
use crate::error::{CurrencyError, SpecificationError};
use crate::rule::Rule;
use crate::schedule::{ScheduleWindow, TimeTolerance};
use crate::serial::PolicySchemaVersion;

// --- Metadata ----------------------------------------------------------------

#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct PolicyMetadata {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub author: Option<String>,
}

// --- Policy -------------------------------------------------------------------

/// Rigid policy specification: unique id, wire schema version, human metadata, optional UTC
/// [`ScheduleWindow`], non-empty [`Rule`] list, and optional named limits.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Policy {
    /// Unique policy id (ULID recommended; stored as UTF-8).
    pub id: String,
    /// Schema version for this **specification** shape (aligns with [`PolicySchemaVersion`]).
    pub version: PolicySchemaVersion,
    #[serde(default, skip_serializing_if = "PolicyMetadata::is_empty")]
    pub metadata: PolicyMetadata,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub schedule: Option<ScheduleWindow>,
    pub rules: Vec<Rule>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub limits: Option<HashMap<String, Amount>>,
}

impl PolicyMetadata {
    fn is_empty(m: &PolicyMetadata) -> bool {
        m.title.is_none() && m.description.is_none() && m.author.is_none()
    }
}

impl Policy {
    #[must_use]
    pub fn new(id: impl Into<String>, version: PolicySchemaVersion, rules: Vec<Rule>) -> Self {
        Self {
            id: id.into(),
            version,
            metadata: PolicyMetadata::default(),
            schedule: None,
            rules,
            limits: None,
        }
    }

    /// Full structural validation: id, schema version, schedule, rules (ids + recursion), limits + tags.
    pub fn validate(&self) -> Result<(), SpecificationError> {
        if self.id.is_empty() {
            return Err(SpecificationError::EmptyPolicyIdentifier);
        }
        if !self.version.is_deserializable() {
            return Err(SpecificationError::UnsupportedSpecificationVersion {
                major: self.version.major,
                minor: self.version.minor,
            });
        }
        if self.rules.is_empty() {
            return Err(SpecificationError::EmptyRuleSet);
        }

        if let Some(ref win) = self.schedule {
            win.validate().map_err(map_schedule_err)?;
        }

        let mut seen = HashSet::<&str>::new();
        for rule in &self.rules {
            rule.validate()?;
            if !seen.insert(rule.id.as_str()) {
                return Err(SpecificationError::DuplicateRuleId(rule.id.clone()));
            }
        }

        if let Some(ref map) = self.limits {
            for (key, amount) in map {
                if key.is_empty() {
                    return Err(SpecificationError::EmptyLimitKey);
                }
                validate_amount_tag(amount)
                    .map_err(|e| SpecificationError::InvalidLimitEntry { key: key.clone(), reason: e.to_string() })?;
            }
        }

        Ok(())
    }

    /// Time dimension only: `true` if there is **no** schedule, or [`ScheduleWindow::is_active_at`]
    /// holds. Uses [`TimeTolerance::ZERO`]; use [`Self::is_executable_at_with_tolerance`] for skew.
    #[must_use]
    pub fn is_executable_at(&self, now: DateTime<Utc>) -> bool {
        self.is_executable_at_with_tolerance(now, TimeTolerance::ZERO)
    }

    #[must_use]
    pub fn is_executable_at_with_tolerance(&self, now: DateTime<Utc>, tol: TimeTolerance) -> bool {
        match &self.schedule {
            None => true,
            Some(w) => w.is_active_at(now, tol),
        }
    }
}

fn map_schedule_err(e: crate::error::ScheduleError) -> SpecificationError {
    SpecificationError::TranslationFailed {
        source_excerpt: "schedule".into(),
        reason: e.to_string(),
    }
}

/// Re-validate asset tag rules (label + precision) for an [`Amount`] already holding a tag.
fn validate_amount_tag(amount: &Amount) -> Result<(), CurrencyError> {
    let t = amount.tag();
    let _ = Asset::new(t.label.clone(), t.precision)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::currency::Asset;

    fn sample_rule(id: &str, cel: &str) -> Rule {
        Rule {
            id: id.into(),
            cel: cel.into(),
            description: None,
            action: None,
        }
    }

    #[test]
    fn validate_happy_path() {
        let p = Policy {
            id: "01ARZ3NDEKTSV4RRFFQ69G5FAV".into(),
            version: PolicySchemaVersion::CURRENT,
            metadata: PolicyMetadata {
                title: Some("Cap".into()),
                description: None,
                author: Some("clerk".into()),
            },
            schedule: None,
            rules: vec![sample_rule("r1", "true")],
            limits: None,
        };
        p.validate().unwrap();
        assert!(p.is_executable_at(Utc::now()));
    }

    #[test]
    fn rejects_empty_id_and_empty_rules() {
        let p = Policy::new("", PolicySchemaVersion::CURRENT, vec![]);
        assert_eq!(p.validate(), Err(SpecificationError::EmptyPolicyIdentifier));

        let p2 = Policy::new("p", PolicySchemaVersion::CURRENT, vec![]);
        assert_eq!(p2.validate(), Err(SpecificationError::EmptyRuleSet));
    }

    #[test]
    fn rejects_duplicate_rule_ids() {
        let p = Policy::new(
            "p1",
            PolicySchemaVersion::CURRENT,
            vec![sample_rule("same", "true"), sample_rule("same", "false")],
        );
        assert_eq!(p.validate(), Err(SpecificationError::DuplicateRuleId("same".into())));
    }

    #[test]
    fn limits_reject_invalid_asset_tag_and_empty_key() {
        // `Amount::new` does not re-validate label; bypass with raw `Asset` then catch in `validate`.
        let bad_tag = Asset { label: "".into(), precision: 2 };
        let amt_bad = Amount::new(rust_decimal::Decimal::ZERO, bad_tag).unwrap();
        let mut limits = HashMap::new();
        limits.insert("max".into(), amt_bad);
        let p = Policy {
            id: "p".into(),
            version: PolicySchemaVersion::CURRENT,
            metadata: PolicyMetadata::default(),
            schedule: None,
            rules: vec![sample_rule("r1", "true")],
            limits: Some(limits),
        };
        assert!(matches!(p.validate(), Err(SpecificationError::InvalidLimitEntry { .. })));

        let tag = Asset::new("OK", 2).unwrap();
        let amt = Amount::new(rust_decimal::Decimal::ZERO, tag).unwrap();
        let mut limits2 = HashMap::new();
        limits2.insert("".into(), amt);
        let p2 = Policy {
            limits: Some(limits2),
            ..Policy::new("p2", PolicySchemaVersion::CURRENT, vec![sample_rule("r1", "true")])
        };
        assert_eq!(p2.validate(), Err(SpecificationError::EmptyLimitKey));
    }

    #[test]
    fn json_roundtrip_skips_empty_optionals() {
        let p = Policy::new("doc-1", PolicySchemaVersion::CURRENT, vec![sample_rule("a", "1==1")]);
        let j = serde_json::to_string(&p).unwrap();
        assert!(!j.contains("schedule"));
        assert!(!j.contains("limits"));
        assert!(!j.contains("metadata"));
        let back: Policy = serde_json::from_str(&j).unwrap();
        assert_eq!(back, p);
    }

    #[test]
    fn unsupported_version() {
        let p = Policy::new("p", PolicySchemaVersion { major: 99, minor: 0 }, vec![sample_rule("r", "true")]);
        assert_eq!(
            p.validate(),
            Err(SpecificationError::UnsupportedSpecificationVersion { major: 99, minor: 0 })
        );
    }
}
