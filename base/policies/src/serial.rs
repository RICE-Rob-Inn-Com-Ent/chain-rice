//! **Universal translator** — JSON for AI/human dialogue, XML for legacy stacks, canonical bytes
//! for hashing and ZK / signatures alongside the **`private`** crate.
//!
//! [`PolicyEnvelope`] wraps any serializable payload with **schema version**, **document revision**,
//! **author identity** (opaque), and **context tags**. [`PolicyPayload`] is the polymorphic “body”
//! for rules ([`CelExpression`] / [`crate::rule::Rule`]), [`crate::currency::Amount`], and
//! schedules — all using the self-describing amount/asset wire shape from [`crate::currency`].
//!
//! ## CEL / “Law” readability
//!
//! Rules keep CEL as plain UTF-8 strings ([`crate::rule::Rule::cel`]). [`CelExpression`] is a
//! transparent newtype for APIs that want an explicit “this is law text” type without changing JSON
//! shape (`"cel": "..."` in [`Rule`]).
//!
//! ## Schema versioning & signatures
//!
//! - **Major** bumps: breaking wire or canonical signing rules — old signatures stay valid over
//!   *their* canonical bytes; verifiers must select the algorithm by [`PolicySchemaVersion`].
//! - **Minor** bumps: additive fields only; same canonicalizer until documented otherwise.
//! - Use [`PolicyEnvelope::canonical_signing_bytes`] for **compact JSON** (deterministic field order
//!   from struct layout). For legacy blobs, keep the original byte slice that was signed.
//! - [`policy_document_from_json_with_migration`] lets `engine` inject JSON transforms before decode.
//!
//! ## Multiformat
//!
//! [`envelope_to_json_pretty`] / [`envelope_from_json`], [`envelope_to_xml`] / [`envelope_from_xml`],
//! plus generic [`to_json`] / [`from_json`] for any DTO.
//!
//! **XML + [`PolicyPayload`]:** `quick-xml` does not reliably round-trip serde’s internally-tagged
//! enums. Prefer **JSON** for polymorphic [`PolicyDocument`]; for XML legacy bridges, wrap a JSON
//! document string (e.g. [`PolicyPayload::ArbitraryJsonText`]) or use a struct payload (see tests).

use std::fmt;

use serde::{Deserialize, Serialize, de::DeserializeOwned};

use crate::currency::Amount;
use crate::error::ParseError;
use crate::rule::Rule;

// --- Schema ------------------------------------------------------------------

/// Wire / signing schema for policy envelopes. Bump **major** only when canonical JSON rules break.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PolicySchemaVersion {
    pub major: u16,
    pub minor: u16,
}

impl PolicySchemaVersion {
    /// Current schema this crate emits and signs with [`PolicyEnvelope::canonical_signing_bytes`].
    pub const CURRENT: Self = Self { major: 1, minor: 0 };

    /// Largest **minor** accepted for `major == 1` when verifying canonical signatures (additive only).
    pub const MAX_SUPPORTED_MINOR_V1: u16 = 0;

    /// `true` if this version can be deserialized and used in policy evaluation (may still reject signing).
    #[must_use]
    pub fn is_deserializable(self) -> bool {
        self.major == 1 && self.minor <= Self::MAX_SUPPORTED_MINOR_V1
    }

    /// Versions for which [`PolicyEnvelope::canonical_signing_bytes`] is defined today.
    #[must_use]
    pub fn supports_canonical_signing(self) -> bool {
        self == Self::CURRENT
    }

    pub fn ensure_canonical_signing(self) -> Result<(), ParseError> {
        if self.supports_canonical_signing() {
            Ok(())
        } else {
            Err(ParseError::UnsupportedSchema {
                major: self.major,
                minor: self.minor,
                expected_major: Self::CURRENT.major,
                expected_minor: Self::CURRENT.minor,
            })
        }
    }
}

impl fmt::Display for PolicySchemaVersion {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}.{}", self.major, self.minor)
    }
}

// --- CEL ---------------------------------------------------------------------
pub use crate::rule::CelExpression;

// --- Schedule payload (serializable) -----------------------------------------

pub use crate::schedule::ScheduleWindow;

// --- Polymorphic payload ------------------------------------------------------

/// Tagged policy body: CEL rules, amounts, schedules, or extension text.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(tag = "payload_kind", rename_all = "snake_case")]
pub enum PolicyPayload {
    /// Single rule; CEL stays in [`Rule::cel`] as UTF-8.
    CelRule(Rule),
    CelRules {
        rules: Vec<Rule>,
    },
    Amount(Amount),
    Schedule(ScheduleWindow),
    /// Escape hatch: UTF-8 JSON text (human-auditable), not binary.
    ArbitraryJsonText {
        text: String,
    },
}

/// Envelope + default polymorphic payload.
pub type PolicyDocument = PolicyEnvelope<PolicyPayload>;

// --- Envelope ----------------------------------------------------------------

/// Metadata + payload for any policy artifact (rules, limits, schedules, …).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub struct PolicyEnvelope<T> {
    pub schema: PolicySchemaVersion,
    /// Monotonic or content-addressed revision — not interpreted here.
    pub document_version: u64,
    /// Opaque author identity (DID, key fingerprint, tenant principal, …).
    pub author_identity: String,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub context_tags: Vec<String>,
    pub payload: T,
}

impl<T: Serialize> PolicyEnvelope<T> {
    /// Compact JSON bytes suitable as a **signing preimage** (with schema [`PolicySchemaVersion::CURRENT`] only).
    ///
    /// Verifiers must use the same schema major/minor and field order as the signer. Preserve legacy
    /// byte slices for older schema versions instead of re-canonicalizing.
    pub fn canonical_signing_bytes(&self) -> Result<Vec<u8>, ParseError> {
        self.schema.ensure_canonical_signing()?;
        serde_json::to_vec(self).map_err(ParseError::from)
    }
}

impl<T> PolicyEnvelope<T> {
    pub fn new(author_identity: impl Into<String>, payload: T) -> Self {
        Self {
            schema: PolicySchemaVersion::CURRENT,
            document_version: 0,
            author_identity: author_identity.into(),
            context_tags: Vec::new(),
            payload,
        }
    }

    pub fn with_context_tags(mut self, tags: Vec<String>) -> Self {
        self.context_tags = tags;
        self
    }

    pub fn with_document_version(mut self, v: u64) -> Self {
        self.document_version = v;
        self
    }

    pub fn with_schema(mut self, schema: PolicySchemaVersion) -> Self {
        self.schema = schema;
        self
    }
}

// --- JSON --------------------------------------------------------------------

/// Pretty JSON for humans / AI review.
pub fn envelope_to_json_pretty<T: Serialize>(env: &PolicyEnvelope<T>) -> Result<String, ParseError> {
    serde_json::to_string_pretty(env).map_err(ParseError::from)
}

pub fn envelope_from_json<T: DeserializeOwned>(s: &str) -> Result<PolicyEnvelope<T>, ParseError> {
    serde_json::from_str(s).map_err(ParseError::from)
}

/// Deserialize a [`PolicyDocument`] after an optional JSON migration (engine supplies legacy → current mapping).
pub fn policy_document_from_json_with_migration(
    s: &str,
    migrate: impl FnOnce(serde_json::Value) -> Result<serde_json::Value, ParseError>,
) -> Result<PolicyDocument, ParseError> {
    let v: serde_json::Value = serde_json::from_str(s).map_err(ParseError::from)?;
    let v = migrate(v)?;
    serde_json::from_value(v).map_err(ParseError::from)
}

/// Convenience: parse current JSON with no migration hook.
pub fn policy_document_from_json(s: &str) -> Result<PolicyDocument, ParseError> {
    envelope_from_json(s)
}

/// Serialize a policy DTO to pretty JSON.
pub fn to_json<T: Serialize>(value: &T) -> Result<String, ParseError> {
    serde_json::to_string_pretty(value).map_err(ParseError::from)
}

/// Deserialize JSON policy data.
pub fn from_json<T: DeserializeOwned>(s: &str) -> Result<T, ParseError> {
    serde_json::from_str(s).map_err(ParseError::from)
}

/// Compact JSON for any serializable value (generic helper; prefer [`PolicyEnvelope::canonical_signing_bytes`] for envelopes).
pub fn to_json_compact<T: Serialize>(value: &T) -> Result<Vec<u8>, ParseError> {
    serde_json::to_vec(value).map_err(ParseError::from)
}

// --- XML ---------------------------------------------------------------------

/// Serialize envelope to XML (legacy / legal stacks). Root element follows serde struct naming.
pub fn envelope_to_xml<T: Serialize>(env: &PolicyEnvelope<T>) -> Result<String, ParseError> {
    quick_xml::se::to_string(env).map_err(ParseError::from)
}

pub fn envelope_from_xml<T: DeserializeOwned>(s: &str) -> Result<PolicyEnvelope<T>, ParseError> {
    quick_xml::de::from_str(s).map_err(ParseError::from)
}

/// Serialize with `quick-xml` (root element name is the struct name by default).
pub fn to_xml<T: Serialize>(value: &T) -> Result<String, ParseError> {
    quick_xml::se::to_string(value).map_err(ParseError::from)
}

/// Deserialize XML into a policy DTO.
pub fn from_xml<'a, T: Deserialize<'a>>(s: &'a str) -> Result<T, ParseError> {
    quick_xml::de::from_str(s).map_err(ParseError::from)
}

// --- MASON XML interchange (feature) -----------------------------------------

#[cfg(feature = "xml-interchange")]
mod mason_xml {
    use serde::de::DeserializeOwned;
    use serde::Serialize;

    use super::{PolicyEnvelope, envelope_from_xml, envelope_to_xml};
    use crate::error::ParseError;

    /// XML namespace URI for MASON legal documents (hint for generators / validators).
    #[must_use]
    pub fn mason_xml_namespace_uri() -> String {
        std::env::var("RICE_MASON_XML_NAMESPACE")
            .unwrap_or_else(|_| "https://schemas.rice.os/mason/legal/v1".into())
    }

    /// Serialize a [`PolicyEnvelope`] to XML (same as [`envelope_to_xml`], kept for MASON call sites).
    pub fn mason_envelope_to_xml<T: Serialize>(env: &PolicyEnvelope<T>) -> Result<String, ParseError> {
        envelope_to_xml(env)
    }

    /// Parse a [`PolicyEnvelope`] from XML.
    pub fn mason_envelope_from_xml<T: DeserializeOwned>(s: &str) -> Result<PolicyEnvelope<T>, ParseError> {
        envelope_from_xml(s)
    }
}

#[cfg(feature = "xml-interchange")]
pub use mason_xml::{mason_envelope_from_xml, mason_envelope_to_xml, mason_xml_namespace_uri};

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{DateTime, Utc};
    use crate::currency::Asset;

    #[test]
    fn policy_document_json_roundtrip() {
        let rule = Rule {
            id: "r1".into(),
            cel: "1 + 1 == 2".into(),
            description: None,
            action: None,
        };
        let doc = PolicyDocument::new("did:rice:alice", PolicyPayload::CelRule(rule.clone()))
            .with_document_version(7)
            .with_context_tags(vec!["tenant/dev".into()]);
        let j = envelope_to_json_pretty(&doc).unwrap();
        assert!(j.contains("1 + 1 == 2"));
        let back: PolicyDocument = envelope_from_json(&j).unwrap();
        assert_eq!(back, doc);
    }

    #[test]
    fn canonical_signing_stable() {
        let amount = Amount::from_decimal_str_exact("10.00", Asset::new("USD", 2).unwrap()).unwrap();
        let doc = PolicyDocument::new("author", PolicyPayload::Amount(amount));
        let b1 = doc.canonical_signing_bytes().unwrap();
        let b2 = doc.canonical_signing_bytes().unwrap();
        assert_eq!(b1, b2);
    }

    #[test]
    fn unsupported_schema_rejects_canonical() {
        let doc = PolicyDocument::new("a", PolicyPayload::ArbitraryJsonText { text: "{}".into() })
            .with_schema(PolicySchemaVersion { major: 99, minor: 0 });
        assert!(doc.canonical_signing_bytes().is_err());
    }

    #[test]
    fn envelope_xml_roundtrip_struct_payload() {
        let win = ScheduleWindow {
            start: DateTime::parse_from_rfc3339("2026-01-01T00:00:00Z")
                .unwrap()
                .with_timezone(&Utc),
            end: DateTime::parse_from_rfc3339("2026-12-31T23:59:59Z")
                .unwrap()
                .with_timezone(&Utc),
            recurrence: None,
        };
        let env: PolicyEnvelope<ScheduleWindow> = PolicyEnvelope::new("pk:abc", win.clone()).with_document_version(3);
        let xml = envelope_to_xml(&env).unwrap();
        let back: PolicyEnvelope<ScheduleWindow> = envelope_from_xml(&xml).unwrap();
        assert_eq!(back.author_identity, env.author_identity);
        assert_eq!(back.payload, win);
    }

    #[test]
    fn migration_hook_runs() {
        let raw = r#"{"schema":{"major":1,"minor":0},"document_version":0,"author_identity":"x","payload":{"payload_kind":"cel_rule","id":"i","cel":"ok","description":null,"action":null}}"#;
        let doc = policy_document_from_json_with_migration(raw, Ok).unwrap();
        match doc.payload {
            PolicyPayload::CelRule(r) => assert_eq!(r.cel, "ok"),
            _ => panic!("expected CelRule"),
        }
    }
}
