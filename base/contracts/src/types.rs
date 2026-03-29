//! Domain types — decimals, token amounts, newtypes shared across execute/query.

use cosmwasm_schema::cw_serde;
use cosmwasm_std::Uint128;
use num_bigint::BigUint;
use num_traits::Zero;
use rust_decimal::Decimal;

/// Monotonic contract schema version (bump in `migration.rs` when storage layout changes).
pub type ContractVersion = u64;

/// Example on-chain token amount — `Uint128` satisfies JSON Schema / CosmWasm tooling.
/// Use `rust_decimal::Decimal` in `execute`/`query` when you need fixed-point math off the wire.
#[cw_serde]
pub struct TokenAmount {
    pub raw: Uint128,
}

impl TokenAmount {
    pub const fn zero() -> Self {
        Self {
            raw: Uint128::zero(),
        }
    }
}

/// Example use of `num-bigint` / `num-traits` for integer-only paths (fees, IDs).
#[must_use]
pub fn big_zero() -> BigUint {
    BigUint::zero()
}

/// Convert a `Uint128` amount to `Decimal` for fractional policies (rounding rules live in execute).
#[must_use]
pub fn uint128_to_decimal(amount: Uint128) -> Decimal {
    Decimal::from(amount.u128())
}
