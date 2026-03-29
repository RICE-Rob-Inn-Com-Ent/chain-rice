//! ISO 4217 currency validation and helpers.

use iso_currency::Currency;
use serde::{Deserialize, Serialize};

use crate::error::ValidationError;

// [ ] https://docs.rs/iso_currency/
// [ ] ISO 4217 validation; FX RICE_FX_RATE_SOURCE, RICE_FX_RATE_MAX_AGE_S; functional currency; rounding per minor units

/// Parsed ISO currency with stable serialization.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct CurrencyCode(pub Currency);

impl CurrencyCode {
    pub fn parse(code: &str) -> Result<Self, ValidationError> {
        Currency::from_code(code)
            .map(Self)
            .ok_or_else(|| ValidationError::UnknownCurrency(code.to_string()))
    }

    pub fn get(self) -> Currency {
        self.0
    }
}
