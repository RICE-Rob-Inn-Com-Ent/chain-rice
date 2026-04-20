//! **Void Liczydło** — count anything, anywhere: fixed-point [`Amount`] = [`Decimal`] + [`AssetTag`].
//!
//! This module is **agnostic**: it does not embed ISO lists, locales, or “what counts as money”.
//! [`Asset`] / [`AssetTag`] carry a runtime **`label`** and **`precision`** (fractional decimal
//! places). Precision can be supplied directly or resolved through an [`AssetRegistry`] (policy
//! file, env, ISO adapter in `engine`, …).
//!
//! Parsing is **ASCII-exact** ([`Decimal::from_str_exact`]): no thousands separators, decimal point
//! is `'.'`. Normalize regional human input in [`crate::engine`] (or elsewhere), then call
//! [`parse_decimal_ascii_exact`] or [`Amount::from_decimal_str_exact`].
//!
//! Checked arithmetic: mismatched tags → [`CurrencyError::CrossAsset`]; decimal overflow →
//! [`PolicyError::Finance`].

use std::collections::HashMap;
use std::fmt;

use rust_decimal::Decimal;
use serde::{Deserialize, Deserializer, Serialize, Serializer};

use crate::error::{CurrencyError, FinanceError, PolicyError, PolicyResult};

// --- Registry ----------------------------------------------------------------

/// Dynamic precision lookup by asset label (policy table, database, ISO bridge built in `engine`, …).
pub trait AssetRegistry {
    /// Minor-unit precision: maximum number of digits permitted right of the decimal point.
    fn precision_for(&self, label: &str) -> Result<u8, CurrencyError>;
}

impl AssetRegistry for HashMap<String, u8> {
    fn precision_for(&self, label: &str) -> Result<u8, CurrencyError> {
        self.get(label)
            .copied()
            .ok_or_else(|| CurrencyError::UnknownAssetLabel(label.to_string()))
    }
}

/// Convenience name for a `HashMap`-backed registry.
pub type HashMapRegistry = HashMap<String, u8>;

// --- Asset / tag -------------------------------------------------------------

/// Measurable unit: opaque **`label`** and **`precision`** (fractional digits). No built-in semantics.
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Asset {
    pub label: String,
    pub precision: u8,
}

/// Type alias: the tag paired with a [`Decimal`] in [`Amount`].
pub type AssetTag = Asset;

impl Asset {
    /// Validate label and precision, then construct.
    pub fn new(label: impl Into<String>, precision: u8) -> Result<Self, CurrencyError> {
        let label = normalize_label(label.into())?;
        validate_precision(precision)?;
        Ok(Self { label, precision })
    }

    /// Resolve precision from a registry; label must still pass [`normalize_label`].
    pub fn resolve(label: impl AsRef<str>, registry: &impl AssetRegistry) -> Result<Self, CurrencyError> {
        let label = normalize_label(label.as_ref().to_string())?;
        let precision = registry.precision_for(&label)?;
        validate_precision(precision)?;
        Ok(Self { label, precision })
    }

    #[inline]
    #[must_use]
    pub fn precision(&self) -> u8 {
        self.precision
    }
}

impl fmt::Display for Asset {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}@{}", self.label, self.precision)
    }
}

// --- Raw decimal tools (locale-agnostic) -------------------------------------

/// Parse a strict ASCII decimal (`1.25`, `-3`, no grouping). For localized input, normalize upstream.
#[inline]
pub fn parse_decimal_ascii_exact(s: &str) -> Result<Decimal, PolicyError> {
    Decimal::from_str_exact(s).map_err(|e| PolicyError::Finance(e.into()))
}

// --- Amount ------------------------------------------------------------------

/// Fixed-point quantity: [`Decimal`] value + [`AssetTag`].
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Amount {
    value: Decimal,
    tag: AssetTag,
}

impl Amount {
    /// Enforce fractional width ≤ `tag.precision`.
    pub fn new(value: Decimal, tag: AssetTag) -> PolicyResult<Self> {
        let v = enforce_scale(value, &tag)?;
        Ok(Self { value: v, tag })
    }

    /// [`parse_decimal_ascii_exact`] then [`Amount::new`].
    pub fn from_decimal_str_exact(s: &str, tag: AssetTag) -> PolicyResult<Self> {
        let d = parse_decimal_ascii_exact(s)?;
        Self::new(d, tag)
    }

    #[inline]
    #[must_use]
    pub fn value(&self) -> Decimal {
        self.value
    }

    #[inline]
    #[must_use]
    pub fn tag(&self) -> &AssetTag {
        &self.tag
    }

    /// Same as [`Self::tag`] — reads naturally as “unit metadata”.
    #[inline]
    #[must_use]
    pub fn asset(&self) -> &Asset {
        &self.tag
    }

    pub fn try_add(&self, rhs: &Self) -> PolicyResult<Self> {
        self.ensure_same_tag(rhs)?;
        let sum = self.value.checked_add(rhs.value).ok_or_else(|| {
            PolicyError::Finance(FinanceError::Overflow {
                operation: "amount_add".into(),
            })
        })?;
        Amount::new(sum, self.tag.clone())
    }

    pub fn try_sub(&self, rhs: &Self) -> PolicyResult<Self> {
        self.ensure_same_tag(rhs)?;
        let diff = self.value.checked_sub(rhs.value).ok_or_else(|| {
            PolicyError::Finance(FinanceError::Overflow {
                operation: "amount_sub".into(),
            })
        })?;
        Amount::new(diff, self.tag.clone())
    }

    #[must_use]
    pub fn checked_add(&self, rhs: &Self) -> Option<Self> {
        self.try_add(rhs).ok()
    }

    #[must_use]
    pub fn checked_sub(&self, rhs: &Self) -> Option<Self> {
        self.try_sub(rhs).ok()
    }

    fn ensure_same_tag(&self, rhs: &Self) -> PolicyResult<()> {
        if self.tag != rhs.tag {
            return Err(PolicyError::Currency(CurrencyError::CrossAsset {
                left: self.tag.to_string(),
                right: rhs.tag.to_string(),
            }));
        }
        Ok(())
    }
}

impl Serialize for Amount {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        amount_wire::AmountWire::from(self).serialize(serializer)
    }
}

impl<'de> Deserialize<'de> for Amount {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        let wire = amount_wire::AmountWire::deserialize(deserializer)?;
        wire.try_into_amount().map_err(serde::de::Error::custom)
    }
}

// --- Internal ----------------------------------------------------------------

fn validate_precision(precision: u8) -> Result<(), CurrencyError> {
    if u32::from(precision) > Decimal::MAX_SCALE {
        return Err(CurrencyError::InvalidAssetLabel(format!(
            "precision {precision} exceeds Decimal::MAX_SCALE ({})",
            Decimal::MAX_SCALE
        )));
    }
    Ok(())
}

fn normalize_label(raw: String) -> Result<String, CurrencyError> {
    let label = raw.trim().to_string();
    if label.is_empty() {
        return Err(CurrencyError::InvalidAssetLabel(raw));
    }
    if label.len() > 64 {
        return Err(CurrencyError::InvalidAssetLabel(format!(
            "label exceeds 64 chars: {:?}…",
            label.chars().take(16).collect::<String>()
        )));
    }
    Ok(label)
}

fn wire_value_string(d: Decimal, precision: u8) -> String {
    let neg = d.is_sign_negative();
    let d = d.abs().normalize();
    if precision == 0 {
        let s = d.to_string();
        let whole = s.split('.').next().unwrap_or(&s);
        return if neg {
            format!("-{whole}")
        } else {
            whole.to_string()
        };
    }
    let s = d.to_string();
    let (int_part, frac_part) = match s.split_once('.') {
        Some((i, f)) => (i.to_string(), f.to_string()),
        None => (s, String::new()),
    };
    let mut frac = frac_part;
    debug_assert!(
        frac.len() <= precision as usize,
        "precision should have been enforced at construction"
    );
    while frac.len() < precision as usize {
        frac.push('0');
    }
    let body = format!("{int_part}.{frac}");
    if neg {
        format!("-{body}")
    } else {
        body
    }
}

fn enforce_scale(value: Decimal, tag: &AssetTag) -> Result<Decimal, PolicyError> {
    let expected = tag.precision;
    let v = value.normalize();
    let actual_scale = v.scale();
    if actual_scale > u32::from(expected) {
        return Err(PolicyError::Currency(CurrencyError::ScaleMismatch {
            asset: tag.label.clone(),
            expected,
            actual: u8::try_from(actual_scale).unwrap_or(u8::MAX),
        }));
    }
    Ok(v)
}

mod amount_wire {
    use super::*;

    /// Canonical interchange: self-describing label + precision + exact decimal string.
    #[derive(Serialize, Deserialize)]
    pub(super) struct AmountWire {
        pub value: String,
        pub label: String,
        pub precision: u8,
    }

    impl From<&Amount> for AmountWire {
        fn from(a: &Amount) -> Self {
            Self {
                value: wire_value_string(a.value(), a.tag.precision),
                label: a.tag.label.clone(),
                precision: a.tag.precision,
            }
        }
    }

    impl AmountWire {
        pub fn try_into_amount(self) -> Result<Amount, String> {
            let tag = Asset::new(self.label, self.precision).map_err(|e| e.to_string())?;
            let d = Decimal::from_str_exact(&self.value).map_err(|e| format!("decimal parse: {e}"))?;
            Amount::new(d, tag).map_err(|e| e.to_string())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn reg_aed_trust() -> HashMapRegistry {
        HashMap::from([("AED".to_string(), 2u8), ("TrustPoints".to_string(), 0u8)])
    }

    #[test]
    fn amount_wire_roundtrip() {
        let tag = Asset::new("AED", 2).unwrap();
        let a = Amount::from_decimal_str_exact("100.00", tag).unwrap();
        let j = serde_json::to_string(&a).unwrap();
        assert_eq!(
            j,
            r#"{"value":"100.00","label":"AED","precision":2}"#
        );
        let b: Amount = serde_json::from_str(&j).unwrap();
        assert_eq!(a, b);
    }

    #[test]
    fn trust_points_zero_precision() {
        let tag = Asset::resolve("TrustPoints", &reg_aed_trust()).unwrap();
        let a = Amount::from_decimal_str_exact("42", tag).unwrap();
        let j = serde_json::to_string(&a).unwrap();
        assert_eq!(
            j,
            r#"{"value":"42","label":"TrustPoints","precision":0}"#
        );
    }

    #[test]
    fn registry_unknown_label() {
        let reg = reg_aed_trust();
        let err = Asset::resolve("NOPE", &reg).unwrap_err();
        match err {
            CurrencyError::UnknownAssetLabel(_) => {}
            o => panic!("unexpected {o:?}"),
        }
    }

    #[test]
    fn rejects_excess_fractional_digits() {
        let tag = Asset::new("COMMODITY", 2).unwrap();
        let err = Amount::from_decimal_str_exact("10.001", tag).unwrap_err();
        match err {
            PolicyError::Currency(CurrencyError::ScaleMismatch { expected: 2, .. }) => {}
            o => panic!("unexpected {o:?}"),
        }
    }

    #[test]
    fn cross_asset_add_errors() {
        let a = Amount::from_decimal_str_exact("1", Asset::new("USD", 2).unwrap()).unwrap();
        let b = Amount::from_decimal_str_exact("1", Asset::new("EUR", 2).unwrap()).unwrap();
        let err = a.try_add(&b).unwrap_err();
        match err {
            PolicyError::Currency(CurrencyError::CrossAsset { .. }) => {}
            o => panic!("unexpected {o:?}"),
        }
        assert!(a.checked_add(&b).is_none());
    }

    #[test]
    fn checked_add_same_tag() {
        let tag = Asset::new("POINTS", 2).unwrap();
        let a = Amount::from_decimal_str_exact("0.01", tag.clone()).unwrap();
        let b = Amount::from_decimal_str_exact("0.02", tag).unwrap();
        let c = a.checked_add(&b).unwrap();
        assert_eq!(c.value(), Decimal::from_str_exact("0.03").unwrap());
    }

    #[test]
    fn zero_precision_rejects_fraction() {
        let tag = Asset::new("JPY_STYLE", 0).unwrap();
        assert!(Amount::from_decimal_str_exact("100.5", tag).is_err());
        let ok = Amount::from_decimal_str_exact("100", Asset::new("JPY_STYLE", 0).unwrap()).unwrap();
        assert_eq!(ok.value().scale(), 0);
    }
}
