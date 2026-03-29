//! Policy serialization — JSON for APIs, XML for legal / document interchange.

use serde::{de::DeserializeOwned, Deserialize, Serialize};

use crate::error::ParseError;

// [ ] https://docs.rs/cel-interpreter/ — serde_json, quick-xml, prost
// [ ] JSON/XML export; signed audit export RICE_AUDIT_SIGN_KEY; prost envelopes from base/gen/

/// Serialize a policy DTO to pretty JSON.
pub fn to_json<T: Serialize>(value: &T) -> Result<String, ParseError> {
    serde_json::to_string_pretty(value).map_err(ParseError::from)
}

/// Deserialize JSON policy data.
pub fn from_json<T: DeserializeOwned>(s: &str) -> Result<T, ParseError> {
    serde_json::from_str(s).map_err(ParseError::from)
}

/// Serialize with `quick-xml` (root element name is the struct name by default).
pub fn to_xml<T: Serialize>(value: &T) -> Result<String, ParseError> {
    quick_xml::se::to_string(value).map_err(ParseError::from)
}

/// Deserialize XML into a policy DTO.
pub fn from_xml<'a, T: Deserialize<'a>>(s: &'a str) -> Result<T, ParseError> {
    quick_xml::de::from_str(s).map_err(ParseError::from)
}
