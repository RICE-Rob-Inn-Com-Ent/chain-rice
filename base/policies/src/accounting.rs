//! Ledger-oriented constraints — periods, currencies, and closing rules.

use chrono::{DateTime, Utc};
use iso_currency::Currency;
use serde::{Deserialize, Serialize};

// [ ] — hledger-lib bridge, calc/ Haskell
// [ ] double-entry balance; chart of accounts from RICE_CHART_OF_ACCOUNTS; period close; reconciliation; VAT via calc/Tax.hs

/// A fiscal period boundary for policy evaluation.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct LedgerPeriod {
    pub currency: Currency,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
}

impl LedgerPeriod {
    pub fn contains(&self, t: DateTime<Utc>) -> bool {
        t >= self.period_start && t <= self.period_end
    }
}
