//! Sovereign primitives for the `.rice` VM — CosmWasm JSON/schema-facing types with no business rules.
//!
//! Wire shapes favor **Protobuf / MASON** interop: `Uint128` amounts map to `string` in proto3 JSON;
//! decimal work uses [`SovereignValue`] (canonical decimal string) or [`Decimal`] via [`TokenAmount::to_decimal`].

use core::fmt;

use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Binary, Uint128};
use num_bigint::BigUint;
use rust_decimal::Decimal;

// --- Version -----------------------------------------------------------------

/// Monotonic contract schema version (bump in `migration.rs` when storage layout changes).
pub type ContractVersion = u64;

// --- Numeric sovereign value (Decimal semantics, string on the wire) ---------

/// Fixed-point numeric for policy / intent math — **not** a stored chain balance.
///
/// Serialized as a **canonical decimal string** so `JsonSchema` stays a plain `string` and maps cleanly
/// to Protobuf `string` (or UTF-8 `bytes`) fields generated from CUE.
#[cw_serde]
pub struct SovereignValue {
    repr: String,
}

impl SovereignValue {
    /// Zero (`"0"`).
    #[must_use]
    pub fn zero() -> Self {
        Self { repr: "0".into() }
    }

    #[must_use]
    pub fn from_decimal(d: Decimal) -> Self {
        Self { repr: d.normalize().to_string() }
    }

    /// Parse wire/string form into [`Decimal`].
    pub fn to_decimal(&self) -> Result<Decimal, rust_decimal::Error> {
        Decimal::from_str_exact(&self.repr)
    }

    /// Borrow the canonical decimal string (Protobuf-friendly).
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.repr
    }
}

impl fmt::Display for SovereignValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.repr.fmt(f)
    }
}

impl TryFrom<&str> for SovereignValue {
    type Error = rust_decimal::Error;

    fn try_from(s: &str) -> Result<Self, Self::Error> {
        let d = Decimal::from_str_exact(s)?;
        Ok(Self::from_decimal(d))
    }
}

// --- Identity ------------------------------------------------------------------

/// Principal that can authorize or bind state — **contract address** or **raw public key material**.
#[cw_serde]
pub enum IdentityPrincipal {
    /// CosmWasm [`Addr`] (bech32 contract or account).
    #[serde(rename = "contract")]
    Contract(Addr),
    /// Opaque key bytes (encoding is a higher layer; Protobuf: `bytes`).
    #[serde(rename = "public_key")]
    PublicKey { key: Binary },
}

// --- VM configuration blueprint ----------------------------------------------

/// `.rice` VM / contract configuration snapshot (admin, policy hook, pause, capability flags).
#[cw_serde]
pub struct ContractConfig {
    /// Superuser for migrations / emergency pause (Protobuf: `string` bech32 in many stacks).
    pub admin: Addr,
    /// Optional policy engine contract; unset when not yet wired.
    pub policy_engine_address: Option<Addr>,
    pub is_paused: bool,
    pub zk_enabled: bool,
    pub pq_enabled: bool,
}

impl ContractConfig {
    #[must_use]
    pub fn new(admin: Addr) -> Self {
        Self {
            admin,
            policy_engine_address: None,
            is_paused: false,
            zk_enabled: false,
            pq_enabled: false,
        }
    }
}

// --- On-chain integer amounts (Uint128 storage) --------------------------------

/// Token or vault amount as **raw integer** minor units — JSON/Schema use CosmWasm `Uint128`.
///
/// For Protobuf, prefer mapping this field to `string` (JSON interop) or a 128-bit integer type in `.proto`.
#[cw_serde]
pub struct TokenAmount {
    pub raw: Uint128,
}

impl TokenAmount {
    pub const fn zero() -> Self {
        Self { raw: Uint128::zero() }
    }

    #[must_use]
    pub const fn new(raw: Uint128) -> Self {
        Self { raw }
    }

    /// Integer → [`Decimal`] for fractional math off-chain / in execute (rounding policy is caller-defined).
    #[must_use]
    pub fn to_decimal(&self) -> Decimal {
        uint128_to_decimal(self.raw)
    }
}

/// Named balance cell — same storage rules as [`TokenAmount`].
#[cw_serde]
pub struct Balance {
    pub amount: Uint128,
}

impl Balance {
    pub const fn zero() -> Self {
        Self { amount: Uint128::zero() }
    }

    #[must_use]
    pub const fn new(amount: Uint128) -> Self {
        Self { amount }
    }

    #[must_use]
    pub fn to_decimal(&self) -> Decimal {
        uint128_to_decimal(self.amount)
    }
}

// --- Cryptographic audit / proof trace (keyed by trace_id in state) ------------

/// Status of a proof or audit trace indexed on-chain (e.g. CLERK `trace_id` / ZK verify pipeline).
#[cw_serde]
#[derive(Default)]
pub enum ProofStatus {
    #[default]
    Pending,
    Verified,
    Rejected {
        reason: String,
    },
}

// --- Int helpers (num-bigint) -------------------------------------------------

/// Zero as [`BigUint`] for integer-only paths (fees, counters) without `f64`.
#[must_use]
pub fn big_zero() -> BigUint {
    BigUint::default()
}

/// Convert a [`Uint128`] amount to [`Decimal`] for internal calculation.
#[must_use]
pub fn uint128_to_decimal(amount: Uint128) -> Decimal {
    Decimal::from(amount.u128())
}
