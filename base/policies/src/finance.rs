//! **Quantitative strategist** — high-precision [`rust_decimal`] helpers for fees, ratios, bracketed
//! rates, oracle-driven **valuation**, **velocity** over the factual [`Ledger`](crate::accounting::Ledger),
//! and **quota** checks against [`Policy`](crate::specification::Policy) limits. This is the *logic*
//! layer; [`crate::accounting`] records the *facts*.
//!
//! No baked-in tax tables: callers supply basis points, brackets, and [`Valuation`] implementations.

use std::cmp::Ordering;

use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

use crate::accounting::{BalancePartition, Flow, JournalRecord, Ledger, LedgerPeriod};
use crate::currency::{Amount, Asset, AssetTag};
use crate::error::{CurrencyError, FinanceError, PolicyError, PolicyResult};
use crate::specification::Policy;

// --- Constants ----------------------------------------------------------------

/// One hundred percent expressed in basis points (10_000 bps).
pub const BASIS_POINTS_ONE: i64 = 10_000;

/// Practical upper bound for basis points in a single call (10000% = 1_000_000 bps).
pub const BASIS_POINTS_MAX: i64 = 1_000_000;

// --- Basis points & ratios ----------------------------------------------------

/// Validate and return `bps` for fee/tax math.
pub fn validate_basis_points(bps: i64) -> PolicyResult<i64> {
    if !(0..=BASIS_POINTS_MAX).contains(&bps) {
        return Err(PolicyError::Finance(FinanceError::InvalidBasisPoints {
            got: bps,
            max: BASIS_POINTS_MAX,
        }));
    }
    Ok(bps)
}

/// `base * bps / 10_000` with overflow checks; result tagged like `base` (same [`AssetTag`]).
///
/// With feature **`calc-bridge`** on Unix, delegates to the Haskell CALC kernel via [`util::calc`]
/// when **`CLERK_USE_CALC_FFI=1`** is set; otherwise uses the in-crate Rust implementation.
/// Set **`CLERK_CALC_USE_BINARY=1`** with the CALC `.so` built from this repo to use the binary v1 ABI
/// (fast path); omit it to use JSON (slow path).
pub fn amount_from_basis_points(base: &Amount, bps: i64) -> PolicyResult<Amount> {
    #[cfg(all(feature = "calc-bridge", unix))]
    {
        if std::env::var("CLERK_USE_CALC_FFI").ok().as_deref() == Some("1") {
            return amount_from_basis_points_calc(base, bps);
        }
    }
    amount_from_basis_points_rust(base, bps)
}

/// Rust reference implementation (also used when CALC FFI is disabled).
pub fn amount_from_basis_points_rust(base: &Amount, bps: i64) -> PolicyResult<Amount> {
    let bps = validate_basis_points(bps)?;
    let num = Decimal::from(bps);
    let den = Decimal::from(BASIS_POINTS_ONE);
    let fee = base
        .value()
        .checked_mul(num)
        .and_then(|x| x.checked_div(den))
        .ok_or_else(|| PolicyError::Finance(FinanceError::Overflow { operation: "basis_points_fee".into() }))?;
    Amount::new(fee, base.tag().clone())
}

#[cfg(all(feature = "calc-bridge", unix))]
fn amount_from_basis_points_calc(base: &Amount, bps: i64) -> PolicyResult<Amount> {
    let bps = validate_basis_points(bps)?;
    let fee_str = util::calc::basis_points_fee_minor_units(&base.value().to_string(), bps).map_err(|e| {
        PolicyError::Finance(FinanceError::Overflow {
            operation: format!("calc-ffi: {e}"),
        })
    })?;
    let fee = Decimal::from_str_exact(fee_str.as_str()).map_err(|_| {
        PolicyError::Finance(FinanceError::Overflow {
            operation: format!("calc-ffi: invalid fee decimal {fee_str:?}"),
        })
    })?;
    Amount::new(fee, base.tag().clone())
}

/// Apply a **unit** ratio `r` in \[0, 1\] to `base` (same tag). Use for explicit percentages as decimals (e.g. `0.05` for 5%).
pub fn amount_from_unit_ratio(base: &Amount, unit_ratio: Decimal) -> PolicyResult<Amount> {
    if unit_ratio < Decimal::ZERO || unit_ratio > Decimal::ONE {
        return Err(PolicyError::Finance(FinanceError::InvalidUnitRatio(unit_ratio.to_string())));
    }
    let out = base
        .value()
        .checked_mul(unit_ratio)
        .ok_or_else(|| PolicyError::Finance(FinanceError::Overflow { operation: "unit_ratio".into() }))?;
    Amount::new(out, base.tag().clone())
}

// --- Tiered / progressive (marginal brackets) --------------------------------

/// One **marginal** slice: up to `width` units of the base quantity (or unlimited if `None`) taxed at `rate_bps`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct MarginalBracket {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub width: Option<Decimal>,
    pub rate_bps: i64,
}

/// Sum marginal duties: walk `quantity` left-to-right across brackets (exhaust `width` of each row before the next).
///
/// Returns a **decimal scalar** in the same unit as `quantity` (not an [`Amount`] — no asset until you tag a notional).
pub fn marginal_scalar_from_brackets(quantity: Decimal, brackets: &[MarginalBracket]) -> PolicyResult<Decimal> {
    if quantity < Decimal::ZERO {
        return Err(PolicyError::Finance(FinanceError::InvalidBrackets(
            "quantity must be non-negative".into(),
        )));
    }
    if brackets.is_empty() {
        return Ok(Decimal::ZERO);
    }

    let mut remaining = quantity;
    let mut acc = Decimal::ZERO;
    let mut last_open_ended = false;

    for (i, b) in brackets.iter().enumerate() {
        validate_basis_points(b.rate_bps)?;
        match b.width {
            Some(w) if w <= Decimal::ZERO => {
                return Err(PolicyError::Finance(FinanceError::InvalidBrackets(format!(
                    "bracket {i}: width must be positive or omitted"
                ))));
            },
            Some(w) => {
                let slice = remaining.min(w);
                let portion = slice
                    .checked_mul(Decimal::from(b.rate_bps))
                    .and_then(|x| x.checked_div(Decimal::from(BASIS_POINTS_ONE)))
                    .ok_or_else(|| {
                        PolicyError::Finance(FinanceError::Overflow { operation: "marginal_bracket".into() })
                    })?;
                acc = acc
                    .checked_add(portion)
                    .ok_or_else(|| PolicyError::Finance(FinanceError::Overflow { operation: "marginal_acc".into() }))?;
                remaining = remaining.checked_sub(slice).ok_or_else(|| {
                    PolicyError::Finance(FinanceError::Overflow { operation: "marginal_remaining".into() })
                })?;
                if remaining.is_zero() {
                    break;
                }
            },
            None => {
                if last_open_ended {
                    return Err(PolicyError::Finance(FinanceError::InvalidBrackets(
                        "only one open-ended tail bracket allowed".into(),
                    )));
                }
                last_open_ended = true;
                let portion = remaining
                    .checked_mul(Decimal::from(b.rate_bps))
                    .and_then(|x| x.checked_div(Decimal::from(BASIS_POINTS_ONE)))
                    .ok_or_else(|| {
                        PolicyError::Finance(FinanceError::Overflow { operation: "marginal_tail".into() })
                    })?;
                acc = acc
                    .checked_add(portion)
                    .ok_or_else(|| PolicyError::Finance(FinanceError::Overflow { operation: "marginal_acc".into() }))?;
                remaining = Decimal::ZERO;
                break;
            },
        }
    }

    if remaining > Decimal::ZERO && !last_open_ended {
        return Err(PolicyError::Finance(FinanceError::InvalidBrackets(
            "quantity exceeds final bracket (add open-ended tail)".into(),
        )));
    }

    Ok(acc)
}

/// Apply [`marginal_scalar_from_brackets`] and build an [`Amount`] with `base.tag()`.
pub fn marginal_amount_from_brackets(base: &Amount, brackets: &[MarginalBracket]) -> PolicyResult<Amount> {
    let s = marginal_scalar_from_brackets(base.value(), brackets)?;
    Amount::new(s, base.tag().clone())
}

// --- Piecewise flat tiers (non-marginal) --------------------------------------

/// Find the single **flat** rate for `quantity` from sorted tiers `threshold` ascending; `rate_bps` applies when `quantity > threshold`.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct FlatTier {
    /// Exclusive lower bound; first tier is typically `Decimal::ZERO`.
    pub threshold: Decimal,
    pub rate_bps: i64,
}

/// Pick the **highest** tier whose `threshold` is strictly `< quantity` (tiers must be sorted by `threshold` ascending).
pub fn flat_rate_bps_for_quantity(quantity: Decimal, tiers: &[FlatTier]) -> PolicyResult<i64> {
    if tiers.is_empty() {
        return Err(PolicyError::Finance(FinanceError::InvalidBrackets("no tiers".into())));
    }
    let mut chosen = None;
    for (i, t) in tiers.iter().enumerate() {
        validate_basis_points(t.rate_bps)?;
        if i > 0 && t.threshold <= tiers[i - 1].threshold {
            return Err(PolicyError::Finance(FinanceError::InvalidBrackets(
                "tiers must be strictly ascending by threshold".into(),
            )));
        }
        if quantity > t.threshold {
            chosen = Some(t.rate_bps);
        }
    }
    chosen.ok_or_else(|| {
        PolicyError::Finance(FinanceError::InvalidBrackets(
            "quantity does not exceed any tier threshold".into(),
        ))
    })
}

// --- Valuation / oracles --------------------------------------------------------

/// Deterministic **spot**: units of `quote` per **one** unit of `base`.
pub trait Valuation: Send + Sync {
    fn spot(&self, base: &AssetTag, quote: &AssetTag) -> PolicyResult<Decimal>;
}

/// Convert `amount` (in `base`) into an [`Amount`] denominated in `quote` using `price` = quote per 1 base.
pub fn convert_at_spot(amount: &Amount, quote: AssetTag, price_quote_per_base: Decimal) -> PolicyResult<Amount> {
    if price_quote_per_base < Decimal::ZERO {
        return Err(PolicyError::Finance(FinanceError::InvalidBrackets(
            "spot price must be non-negative".into(),
        )));
    }
    let v = amount
        .value()
        .checked_mul(price_quote_per_base)
        .ok_or_else(|| PolicyError::Finance(FinanceError::Overflow { operation: "convert_at_spot".into() }))?;
    Amount::new(v, quote)
}

/// [`convert_at_spot`] using an oracle.
pub fn convert_with_valuation(amount: &Amount, quote: AssetTag, oracle: &dyn Valuation) -> PolicyResult<Amount> {
    let p = oracle.spot(amount.tag(), &quote)?;
    convert_at_spot(amount, quote, p)
}

// --- Velocity (journal analytics) ---------------------------------------------

/// Sum absolute **`Flow::Out`** magnitudes for `account` / `asset` / optional `partition` inside `period`.
pub fn outbound_volume_in_period(
    journal: &[JournalRecord],
    account: &str,
    asset: &AssetTag,
    partition: Option<BalancePartition>,
    period: &LedgerPeriod,
) -> PolicyResult<Decimal> {
    let mut sum = Decimal::ZERO;
    for rec in journal {
        if !period.contains(rec.posted_at) {
            continue;
        }
        for leg in &rec.legs {
            if leg.account != account || leg.amount.tag() != asset {
                continue;
            }
            if let Some(p) = partition {
                if leg.partition != p {
                    continue;
                }
            }
            if matches!(leg.flow, Flow::Out) {
                sum = sum
                    .checked_add(leg.amount.value())
                    .ok_or_else(|| PolicyError::Finance(FinanceError::Overflow { operation: "velocity_sum".into() }))?;
            }
        }
    }
    Ok(sum)
}

/// Convenience: read [`Ledger::journal`].
pub fn ledger_outbound_volume(
    ledger: &Ledger,
    account: &str,
    asset: &AssetTag,
    partition: Option<BalancePartition>,
    period: &LedgerPeriod,
) -> PolicyResult<Decimal> {
    outbound_volume_in_period(ledger.journal(), account, asset, partition, period)
}

// --- Policy limits ------------------------------------------------------------

/// Resolve `limit_key` on `policy.limits` and ensure `proposed.value() + already_consumed <= limit.value()` (same tag).
pub fn ensure_within_policy_limit(
    policy: &Policy,
    limit_key: &str,
    proposed: &Amount,
    already_consumed: Decimal,
) -> PolicyResult<()> {
    let Some(ref map) = policy.limits else {
        return Ok(());
    };
    let cap = map
        .get(limit_key)
        .ok_or_else(|| PolicyError::Finance(FinanceError::LimitNotFound { key: limit_key.into() }))?;
    if cap.tag() != proposed.tag() {
        return Err(PolicyError::Currency(CurrencyError::CrossAsset {
            left: cap.tag().to_string(),
            right: proposed.tag().to_string(),
        }));
    }
    let total = already_consumed
        .checked_add(proposed.value())
        .ok_or_else(|| PolicyError::Finance(FinanceError::Overflow { operation: "limit_running_total".into() }))?;
    match total.cmp(&cap.value()) {
        Ordering::Greater => Err(PolicyError::Finance(FinanceError::PrecisionLoss {
            operation: "policy_limit".into(),
            detail: format!(
                "would exceed limit `{limit_key}`: cap {} proposed+consumed {}",
                cap.value(),
                total
            ),
        })),
        _ => Ok(()),
    }
}

/// Per-transaction ceiling: `proposed.value() <= per_tx_cap.value()` (same tag).
pub fn ensure_per_transaction_cap(proposed: &Amount, per_tx_cap: &Amount) -> PolicyResult<()> {
    if per_tx_cap.tag() != proposed.tag() {
        return Err(PolicyError::Currency(CurrencyError::CrossAsset {
            left: per_tx_cap.tag().to_string(),
            right: proposed.tag().to_string(),
        }));
    }
    if proposed.value() > per_tx_cap.value() {
        return Err(PolicyError::Finance(FinanceError::PrecisionLoss {
            operation: "per_transaction_cap".into(),
            detail: format!("proposed {} exceeds cap {}", proposed.value(), per_tx_cap.value()),
        }));
    }
    Ok(())
}

// --- FIX bridge (interop) -----------------------------------------------------

#[cfg(feature = "fix-protocol")]
pub use fefix::tagvalue;
#[cfg(feature = "fix-protocol")]
pub use fefix::{Dictionary, FixValue, TagU16};

#[cfg(feature = "fix-protocol")]
mod fix_bridge {
    use super::{Amount, TagU16};

    /// FIX tag **44** — Price.
    #[must_use]
    pub fn fix_tag_price() -> TagU16 {
        TagU16::new(44).expect("FIX tag 44")
    }

    /// FIX tag **54** — Side.
    #[must_use]
    pub fn fix_tag_side() -> TagU16 {
        TagU16::new(54).expect("FIX tag 54")
    }

    /// Tag 44 value from [`Amount`] (normalized decimal string).
    #[must_use]
    pub fn fix_price_string(amount: &Amount) -> String {
        amount.value().normalize().to_string()
    }

    /// Side = Buy (`1`).
    #[must_use]
    pub fn fix_side_buy() -> &'static str {
        "1"
    }

    /// Side = Sell (`2`).
    #[must_use]
    pub fn fix_side_sell() -> &'static str {
        "2"
    }

    /// Currency / instrument label from the amount’s asset (tag **15**-style usage).
    #[must_use]
    pub fn fix_currency_symbol(amount: &Amount) -> String {
        amount.tag().label.clone()
    }
}

#[cfg(feature = "fix-protocol")]
pub use fix_bridge::{fix_currency_symbol, fix_price_string, fix_side_buy, fix_side_sell, fix_tag_price, fix_tag_side};

use crate::error::ScheduleError;

/// Simple spend cap in minor units for an [`Asset`] and validity window (precision comes from the asset).
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BudgetLimit {
    pub asset: Asset,
    pub max_minor: i64,
    pub valid_from: DateTime<Utc>,
    pub valid_to: DateTime<Utc>,
}

impl BudgetLimit {
    pub fn validate(&self) -> Result<(), ScheduleError> {
        if self.valid_to >= self.valid_from {
            return Ok(());
        }
        Err(ScheduleError::InvalidPeriod)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::rule::Rule;
    use crate::serial::PolicySchemaVersion;
    use crate::specification::Policy;

    fn usd_amt(s: &str) -> Amount {
        Amount::from_decimal_str_exact(s, Asset::new("USD", 2).unwrap()).unwrap()
    }

    #[test]
    fn bps_fee_roundtrip_scale() {
        let base = usd_amt("100.00");
        let fee = amount_from_basis_points(&base, 250).unwrap();
        assert_eq!(fee.value(), Decimal::from_str_exact("2.50").unwrap());
    }

    #[test]
    fn marginal_brackets() {
        let brackets = vec![
            MarginalBracket {
                width: Some(Decimal::from(10)),
                rate_bps: 1000,
            },
            MarginalBracket { width: None, rate_bps: 2000 },
        ];
        // quantity 15: 10 @10% + 5 @20% = 1 + 1 = 2
        let s = marginal_scalar_from_brackets(Decimal::from(15), &brackets).unwrap();
        assert_eq!(s, Decimal::from(2));
    }

    struct StaticOracle {
        p: Decimal,
    }

    impl Valuation for StaticOracle {
        fn spot(&self, _base: &AssetTag, _quote: &AssetTag) -> PolicyResult<Decimal> {
            Ok(self.p)
        }
    }

    #[test]
    fn convert_via_oracle() {
        let usd = usd_amt("100.00");
        let eur = Asset::new("EUR", 2).unwrap();
        let out = convert_with_valuation(
            &usd,
            eur.clone(),
            &StaticOracle {
                p: Decimal::from_str_exact("0.92").unwrap(),
            },
        )
        .unwrap();
        assert_eq!(out.tag(), &eur);
        assert_eq!(out.value(), Decimal::from_str_exact("92.00").unwrap());
    }

    #[test]
    fn policy_limit_enforcement() {
        let mut limits = std::collections::HashMap::new();
        limits.insert("max_daily".into(), usd_amt("500.00"));
        let pol = Policy {
            id: "p".into(),
            version: PolicySchemaVersion::CURRENT,
            metadata: Default::default(),
            schedule: None,
            rules: vec![Rule {
                id: "r".into(),
                cel: "true".into(),
                description: None,
                action: None,
            }],
            limits: Some(limits),
        };
        ensure_within_policy_limit(&pol, "max_daily", &usd_amt("100.00"), Decimal::ZERO).unwrap();
        assert!(
            ensure_within_policy_limit(
                &pol,
                "max_daily",
                &usd_amt("450.00"),
                Decimal::from_str_exact("100.00").unwrap()
            )
            .is_err()
        );
    }
}
