//! Legal document parsing and compliance checks — XML-first interchange via `quick-xml`.
//!
//! Extend with domain-specific schemas (XSD, schematron) in your infra layer; keep policy types here.

use quick_xml::events::Event;
use quick_xml::Reader;
use serde::{Deserialize, Serialize};

// [ ] https://docs.rs/quick-xml/
// [ ] RICE_LEGAL_SCHEMA_PATH; GDPR/KYC/AML paths from env; contract lifecycle; chrono windows

/// Minimal compliance envelope used in examples and tests.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct ComplianceEnvelope {
    pub subject: String,
    pub jurisdiction: String,
    #[serde(default)]
    pub deadline_rfc3339: Option<String>,
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
            }
            Ok(Event::Eof) => return Ok(None),
            Err(e) => return Err(e),
            _ => {}
        }
    }
}
