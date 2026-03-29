//! Trading and treasury policy hooks — FIX primitives, budgets, and time-bounded limits.
//!
//! FerrumFIX (`fefix`) is intentionally low-level; pair it with CEL rules in `rules` / `engine`.

pub use fefix::{Dictionary, FixValue, TagU16};
pub use fefix::tagvalue;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::currency::CurrencyCode;
use crate::error::ValidationError;

// [ ] https://docs.rs/fefix/
// [ ] FIX 4.4/5.0 parse; RICE_FIX_VERSION; trading limits RICE_MAX_ORDER_SIZE; settlement; margin Decimal math

/// Simple spend cap in minor units (application-defined scale) for a currency and validity window.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BudgetLimit {
    pub currency: CurrencyCode,
    pub max_minor: i64,
    pub valid_from: DateTime<Utc>,
    pub valid_to: DateTime<Utc>,
}

impl BudgetLimit {
    pub fn validate(&self) -> Result<(), ValidationError> {
        if self.valid_to >= self.valid_from {
            return Ok(());
        }
        Err(ValidationError::InvalidPeriod)
    }
}
