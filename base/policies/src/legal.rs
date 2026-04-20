//! Legal document parsing and **jurisdictional firewall** types — XML interchange via `quick-xml`,
//! plus machine-verifiable [`LegalManifest`]s, [`LegalIdentity`], and [`FairExchangeGuarantee`].
//!
//! Extend with domain-specific XSD / Schematron in your infra layer; this crate keeps portable DTOs
//! and policy-surface checks only.

use std::collections::HashMap;

use k256::PublicKey;
use quick_xml::Reader;
use quick_xml::events::Event;
use serde::{Deserialize, Serialize};

use crate::error::{LegalError, PolicyResult};
use crate::specification::Policy;

/// Minimal compliance envelope used in examples and tests.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct ComplianceEnvelope {
    pub subject: String,
    pub jurisdiction: String,
    #[serde(default)]
    pub deadline_rfc3339: Option<String>,
}

/// Jurisdiction-scoped mandates and CEL fragment denylists — the static law the engine can enforce
/// without interpreting natural language.
#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct LegalManifest {
    /// ISO 3166-1 alpha-2, a registry id, or a sentinel such as `GLOBAL`.
    pub jurisdiction: String,
    /// Each entry must appear as a substring somewhere in the policy surface (rules, metadata, limits).
    #[serde(default)]
    pub mandates: Vec<String>,
    /// If any entry appears as a substring of a rule's CEL source, validation fails.
    #[serde(default)]
    pub forbidden_actions: Vec<String>,
}

/// **Anti-anonymity** anchor: a secp256k1 (Ethereum-style) key plus optional verified presence
/// metadata (registry / attestation). Call [`Self::verify_public_key`] before trusting the binding.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct LegalIdentity {
    /// SEC1-encoded public key (typically 33-byte compressed or 65-byte uncompressed).
    pub signing_key_sec1: Vec<u8>,
    /// When the key was verified against an external registry or attestation (RFC 3339).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub verified_at_rfc3339: Option<String>,
    /// Opaque reference to company registry, UBO record, or state filing.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub registry_presence_ref: Option<String>,
}

impl LegalIdentity {
    /// Parse and validate `signing_key_sec1` as a secp256k1 [`PublicKey`].
    pub fn verify_public_key(&self) -> PolicyResult<PublicKey> {
        PublicKey::from_sec1_bytes(&self.signing_key_sec1)
            .map_err(|e| LegalError::InvalidIdentityKey { detail: e.to_string() }.into())
    }
}

/// When a policy is flagged as involving code / IP, require either a **ledger attestation** of
/// escrow/payment or named [`Policy::limits`] keys (placeholders checked structurally here).
#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct FairExchangeGuarantee {
    /// Substrings that mark the policy as code/IP-heavy (matched on rule id, CEL, description,
    /// action, and metadata).
    #[serde(default)]
    pub code_involvement_markers: Vec<String>,
    /// Limit keys that must exist on the policy when a marker matches (e.g. `escrow_hold`).
    #[serde(default)]
    pub required_limit_keys_when_code: Vec<String>,
}

/// Filter for extracting compliance-oriented elements from XSD, Akoma Ntoso, or agency XML.
#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct ComplianceTagFilter {
    /// Element **local** names to record (e.g. `article`, `clause`, `requirement`).
    #[serde(default)]
    pub element_local_names: Vec<String>,
    /// Include any element that carries an `eId` attribute (Akoma fragment id).
    #[serde(default)]
    pub include_elements_with_eid: bool,
    /// Attribute **local** names that imply a compliance surface (`compliance`, `requirement`, …).
    #[serde(default)]
    pub compliance_attribute_hints: Vec<String>,
}

impl ComplianceTagFilter {
    /// Sensible defaults for Akoma-style legal XML: structural tags + `eId` + common hints.
    #[must_use]
    pub fn akoma_ntoso_hints() -> Self {
        Self {
            element_local_names: vec![
                "article".into(),
                "clause".into(),
                "section".into(),
                "paragraph".into(),
                "subsection".into(),
            ],
            include_elements_with_eid: true,
            compliance_attribute_hints: vec!["compliance".into(), "requirement".into()],
        }
    }
}

/// One element occurrence that matched [`ComplianceTagFilter`].
#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ComplianceTagRecord {
    pub element_local_name: String,
    pub attributes: HashMap<String, String>,
}

/// Scan a UTF-8 XML fragment for a root element name (no validation against XSD).
pub fn root_element_name(xml: &str) -> Result<Option<String>, quick_xml::Error> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    loop {
        match reader.read_event() {
            Ok(Event::Start(e)) => {
                let name = e.name().into_inner();
                let name = std::str::from_utf8(name.as_ref()).unwrap_or("");
                return Ok(Some(name.to_string()));
            },
            Ok(Event::Eof) => return Ok(None),
            Err(e) => return Err(e),
            _ => {},
        }
    }
}

/// Walk XML and collect elements matching [`ComplianceTagFilter`] (semantic anchors, not only root).
pub fn extract_compliance_tags(
    xml: &str,
    filter: &ComplianceTagFilter,
) -> Result<Vec<ComplianceTagRecord>, quick_xml::Error> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    let mut out = Vec::new();

    let name_set: std::collections::HashSet<&str> = filter.element_local_names.iter().map(String::as_str).collect();
    let hint_set: std::collections::HashSet<&str> =
        filter.compliance_attribute_hints.iter().map(String::as_str).collect();

    loop {
        match reader.read_event()? {
            Event::Start(e) | Event::Empty(e) => {
                let local = utf8_lossy(e.local_name().as_ref());
                let mut attrs = HashMap::<String, String>::new();
                let mut has_eid = false;
                for a in e.attributes() {
                    let a = a.map_err(quick_xml::Error::from)?;
                    let k = utf8_lossy(a.key.local_name().as_ref());
                    if k == "eId" {
                        has_eid = true;
                    }
                    let v = a.unescape_value()?;
                    attrs.insert(k, v.into_owned());
                }

                let mut matched = name_set.contains(local.as_str());
                if filter.include_elements_with_eid && has_eid {
                    matched = true;
                }
                if !matched && !hint_set.is_empty() {
                    for k in attrs.keys() {
                        if hint_set.contains(k.as_str()) {
                            matched = true;
                            break;
                        }
                    }
                }
                if matched {
                    out.push(ComplianceTagRecord {
                        element_local_name: local,
                        attributes: attrs,
                    });
                }
            },
            Event::Eof => break,
            _ => {},
        }
    }

    Ok(out)
}

fn utf8_lossy(b: &[u8]) -> String {
    String::from_utf8_lossy(b).into_owned()
}

/// Concatenated policy surface for substring mandates (rules, metadata, limit keys).
#[must_use]
pub fn policy_surface_text(policy: &Policy) -> String {
    let mut s = String::new();
    s.push_str(&policy.id);
    s.push('\n');
    if let Some(t) = &policy.metadata.title {
        s.push_str(t);
        s.push('\n');
    }
    if let Some(d) = &policy.metadata.description {
        s.push_str(d);
        s.push('\n');
    }
    if let Some(a) = &policy.metadata.author {
        s.push_str(a);
        s.push('\n');
    }
    for r in &policy.rules {
        s.push_str(&r.id);
        s.push('\n');
        s.push_str(&r.cel);
        s.push('\n');
        if let Some(d) = &r.description {
            s.push_str(d);
            s.push('\n');
        }
        if let Some(a) = &r.action {
            s.push_str(a);
            s.push('\n');
        }
    }
    if let Some(limits) = &policy.limits {
        let mut keys: Vec<_> = limits.keys().cloned().collect();
        keys.sort();
        for k in keys {
            s.push_str(&k);
            s.push('\n');
        }
    }
    s
}

/// `true` if any [`FairExchangeGuarantee::code_involvement_markers`] matches the policy surface.
#[must_use]
pub fn policy_involves_code_markers(policy: &Policy, guarantee: &FairExchangeGuarantee) -> bool {
    let surface = policy_surface_text(policy);
    guarantee
        .code_involvement_markers
        .iter()
        .any(|m| !m.is_empty() && surface.contains(m.as_str()))
}

/// Enforce [`FairExchangeGuarantee`] when code markers hit: need ledger attestation **or** all
/// required limit keys on the policy.
pub fn validate_fair_exchange(
    policy: &Policy,
    guarantee: &FairExchangeGuarantee,
    ledger_escrow_verified: bool,
) -> PolicyResult<()> {
    if !policy_involves_code_markers(policy, guarantee) {
        return Ok(());
    }
    if ledger_escrow_verified {
        return Ok(());
    }
    let Some(limits) = &policy.limits else {
        return Err(LegalError::FairExchange {
            detail: "code/IP markers matched but policy has no limits and no ledger escrow attestation".into(),
        }
        .into());
    };
    for key in &guarantee.required_limit_keys_when_code {
        if key.is_empty() {
            continue;
        }
        if !limits.contains_key(key) {
            return Err(
                LegalError::FairExchange {
                    detail: format!(
                        "code/IP markers matched; missing required policy limit key `{key}` and no ledger escrow attestation"
                    ),
                }
                .into(),
            );
        }
    }
    if guarantee.required_limit_keys_when_code.is_empty() {
        return Err(LegalError::FairExchange {
            detail: "code/IP markers matched; configure required_limit_keys_when_code or pass ledger_escrow_verified"
                .into(),
        }
        .into());
    }
    Ok(())
}

/// Check `policy` against `manifest` (mandates + forbidden CEL substrings), then optionally
/// [`validate_fair_exchange`].
pub fn validate_contract_safety(
    policy: &Policy,
    manifest: &LegalManifest,
    fair_exchange: Option<(&FairExchangeGuarantee, bool)>,
) -> PolicyResult<()> {
    let surface = policy_surface_text(policy);
    for m in &manifest.mandates {
        if m.is_empty() {
            continue;
        }
        if !surface.contains(m.as_str()) {
            return Err(LegalError::MandateMissing { mandate: m.clone() }.into());
        }
    }

    for frag in &manifest.forbidden_actions {
        if frag.is_empty() {
            continue;
        }
        for r in &policy.rules {
            if r.cel.contains(frag) {
                return Err(LegalError::ForbiddenCel {
                    pattern: frag.clone(),
                    rule_id: r.id.clone(),
                }
                .into());
            }
        }
    }

    if let Some((guarantee, ledger_ok)) = fair_exchange {
        validate_fair_exchange(policy, guarantee, ledger_ok)?;
    }

    Ok(())
}

/// Declared API surface between CLERK policy payloads and on-chain contracts (`RICE_CLERK_CW_API_VERSION`).
///
/// CosmWasm types and execution live in the **`contract`** crate; this is a version string for wire alignment only.
#[must_use]
pub fn clerk_cw_api_version() -> String {
    std::env::var("RICE_CLERK_CW_API_VERSION").unwrap_or_else(|_| "clerk.policy.v1".into())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::currency::{Amount, Asset};
    use crate::error::PolicyError;
    use crate::rule::Rule;
    use crate::serial::PolicySchemaVersion;
    use rust_decimal::Decimal;

    fn sample_rule(id: &str, cel: &str) -> Rule {
        Rule {
            id: id.into(),
            cel: cel.into(),
            description: None,
            action: None,
        }
    }

    fn sample_policy(rules: Vec<Rule>, meta_desc: Option<&str>) -> Policy {
        let mut p = Policy::new("p1", PolicySchemaVersion::CURRENT, rules);
        if let Some(d) = meta_desc {
            p.metadata.description = Some(d.into());
        }
        p
    }

    #[test]
    fn root_element_name_finds_first_start() {
        let xml = r#"<?xml version="1.0"?><akomaNtoso><doc/></akomaNtoso>"#;
        assert_eq!(root_element_name(xml).unwrap(), Some("akomaNtoso".into()));
    }

    #[test]
    fn extract_compliance_tags_finds_eid() {
        let xml = r#"<akomaNtoso xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
            <article eId="art_7" name="data_processing"/>
        </akomaNtoso>"#;
        let tags = extract_compliance_tags(xml, &ComplianceTagFilter::akoma_ntoso_hints()).unwrap();
        assert_eq!(tags.len(), 1);
        assert_eq!(tags[0].element_local_name, "article");
        assert_eq!(tags[0].attributes.get("eId").map(String::as_str), Some("art_7"));
    }

    #[test]
    fn forbidden_cel_rejected() {
        let policy = sample_policy(vec![sample_rule("r1", "x && y")], None);
        let manifest = LegalManifest {
            jurisdiction: "EU".into(),
            mandates: vec![],
            forbidden_actions: vec!["x && y".into()],
        };
        let e = validate_contract_safety(&policy, &manifest, None).unwrap_err();
        match e {
            PolicyError::Legal(LegalError::ForbiddenCel { rule_id, .. }) => assert_eq!(rule_id, "r1"),
            o => panic!("unexpected {o:?}"),
        }
    }

    #[test]
    fn mandate_must_appear_in_surface() {
        let policy = sample_policy(vec![sample_rule("r1", "true")], None);
        let manifest = LegalManifest {
            jurisdiction: "DE".into(),
            mandates: vec!["data controller".into()],
            forbidden_actions: vec![],
        };
        assert!(validate_contract_safety(&policy, &manifest, None).is_err());

        let policy2 = sample_policy(vec![sample_rule("r1", "true")], Some("Must disclose data controller identity"));
        validate_contract_safety(&policy2, &manifest, None).unwrap();
    }

    #[test]
    fn fair_exchange_requires_escrow_or_limits() {
        let mut policy = sample_policy(vec![sample_rule("lic", "true")], Some("software_license grant"));
        let g = FairExchangeGuarantee {
            code_involvement_markers: vec!["software_license".into()],
            required_limit_keys_when_code: vec!["escrow_hold".into()],
        };
        let e = validate_contract_safety(&policy, &LegalManifest::default(), Some((&g, false))).unwrap_err();
        assert!(matches!(e, PolicyError::Legal(LegalError::FairExchange { .. })));

        let tag = Asset::new("USD", 2).unwrap();
        let amt = Amount::new(Decimal::ZERO, tag).unwrap();
        policy.limits = Some(HashMap::from([("escrow_hold".into(), amt)]));
        validate_contract_safety(&policy, &LegalManifest::default(), Some((&g, false))).unwrap();

        let policy_no_limits = sample_policy(vec![sample_rule("lic", "true")], Some("software_license grant"));
        validate_contract_safety(&policy_no_limits, &LegalManifest::default(), Some((&g, true))).unwrap();
    }

    #[test]
    fn legal_identity_rejects_garbage_key() {
        let id = LegalIdentity {
            signing_key_sec1: vec![0x00, 0x01],
            verified_at_rfc3339: None,
            registry_presence_ref: None,
        };
        assert!(id.verify_public_key().is_err());
    }

    #[test]
    fn legal_identity_accepts_generator_compressed() {
        // secp256k1 generator point, compressed SEC1.
        let bytes: [u8; 33] = [
            0x02, 0x79, 0xbe, 0x66, 0x7e, 0xf9, 0xdc, 0xbb, 0xac, 0x55, 0xa0, 0x62, 0x95, 0xce, 0x87, 0x0b, 0x07, 0x02,
            0x9b, 0xfc, 0xdb, 0x2d, 0xce, 0x28, 0xd9, 0x59, 0xf2, 0x81, 0x5b, 0x16, 0xf8, 0x17, 0x98,
        ];
        let id = LegalIdentity {
            signing_key_sec1: bytes.to_vec(),
            verified_at_rfc3339: Some("2026-01-01T00:00:00Z".into()),
            registry_presence_ref: Some("reg://example/123".into()),
        };
        id.verify_public_key().unwrap();
    }
}
