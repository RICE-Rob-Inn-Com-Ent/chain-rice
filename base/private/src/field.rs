//! Prime field arithmetic — the **scalar substrate** of the ZK layer.
//!
//! **Why:** These are the shadow scalars in which private balances, nullifiers, and commitments
//! live before they surface as Groth16 proofs. Wrong scalars break soundness or leak structure;
//! this module ties arkworks’ [`PrimeField`] types to [`Bytes`] (the same buffer type [`util`] uses
//! on the wire) and to [`PrivateError::FieldInvalid`](crate::error::PrivateError::FieldInvalid) so
//! out-of-range integers are **rejected**, not silently reduced mod the group order.
//!
//! BN254 and BLS12-381 scalars share the [`Scalar`] API via a blanket implementation for every
//! [`PrimeField`] + [`Copy`] type (ark’s [`Field`] already includes [`UniformRand`] for sampling).

use std::convert::TryFrom;
use std::sync::OnceLock;

use ark_crypto_primitives::sponge::poseidon::{find_poseidon_ark_and_mds, PoseidonConfig, PoseidonSponge};
use ark_crypto_primitives::sponge::{CryptographicSponge, FieldBasedCryptographicSponge};
use ark_ff::{BigInteger, Field, PrimeField};
use ark_std::rand::Rng;
use util::Bytes;
use num_bigint::BigUint;
use num_traits::Zero;

use crate::error::PrivateError;

// ---------------------------------------------------------------------------
// Curve scalar aliases
// ---------------------------------------------------------------------------

/// BLS12-381 scalar field element (`Fr`). Implements [`Scalar`] via the blanket impl.
pub type FrBls12 = ark_bls12_381::Fr;

/// BN254 scalar field element (`Fr`). Implements [`Scalar`] via the blanket impl.
pub type FrBn254 = ark_bn254::Fr;

// ---------------------------------------------------------------------------
// Poseidon parameter plumbing (placeholders)
// ---------------------------------------------------------------------------

/// Environment variable naming a Poseidon / Poseidon2 parameter bundle (round constants, MDS, width).
///
/// **Why:** Hash parameters must match proving and verifying circuits exactly; loading them from a
/// single configured path avoids baking ceremony material into binaries.
pub const CLERK_ZK_POSEIDON_PARAMS_ENV: &str = "CLERK_ZK_POSEIDON_PARAMS";

/// Placeholder for parsed Poseidon configuration until `CLERK_ZK_POSEIDON_PARAMS` loading is wired.
///
/// **Why:** Call sites can depend on this type while SMITH/infra finalize artifact formats.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct PoseidonParamsPlaceholder {
    _private: (),
}

impl PoseidonParamsPlaceholder {
    /// Reserved hook: will read [`CLERK_ZK_POSEIDON_PARAMS_ENV`] and deserialize params.
    ///
    /// **Today:** returns [`PrivateError::SetupMissing`] so callers fail closed instead of hashing
    /// with implicit defaults.
    pub fn from_env() -> Result<Self, PrivateError> {
        Err(PrivateError::SetupMissing(format!(
            "Poseidon parameters not loaded; set {CLERK_ZK_POSEIDON_PARAMS_ENV} to a parameter path (placeholder)"
        )))
    }
}

/// Compress field elements with a Poseidon sponge — **not implemented** until params exist.
///
/// **Why:** ZK-friendly hashing must use the same permutation as in-circuit gadgets; this stub
/// documents the legacy env-gated path. Prefer [`poseidon_config_bn254_rate2`] + sponge APIs for
/// BN254, or load [`CLERK_ZK_POSEIDON_PARAMS_ENV`] when SMITH finalizes artifacts.
#[inline]
pub fn poseidon_hash_field_elements_placeholder<F: PrimeField>(
    _inputs: &[F],
) -> Result<F, PrivateError> {
    PoseidonParamsPlaceholder::from_env()?;
    Err(PrivateError::SetupMissing(
        "Poseidon sponge hash not implemented past the parameter stub".into(),
    ))
}

// ---------------------------------------------------------------------------
// Poseidon (BN254 Fr) — rate-2 / constraints row, shared with in-circuit gadgets
// ---------------------------------------------------------------------------

static POSEIDON_BN254_FR_RATE2: OnceLock<PoseidonConfig<FrBn254>> = OnceLock::new();

#[inline]
fn poseidon_config_rate2<F: PrimeField>() -> PoseidonConfig<F> {
    let rate = 2usize;
    let full_rounds = 8u64;
    let partial_rounds = 31u64;
    let skip_matrices = 0u64;
    let prime_bits = F::MODULUS_BIT_SIZE as u64;
    let (ark, mds) = find_poseidon_ark_and_mds::<F>(
        prime_bits,
        rate,
        full_rounds,
        partial_rounds,
        skip_matrices,
    );
    PoseidonConfig {
        full_rounds: full_rounds as usize,
        partial_rounds: partial_rounds as usize,
        alpha: 17,
        ark,
        mds,
        rate,
        capacity: 1,
    }
}

/// Rate-2 Poseidon parameters for **BN254 `Fr`**, constraints-optimized (matches [`crate::circuit`] gadgets).
#[inline]
pub fn poseidon_config_bn254_rate2() -> &'static PoseidonConfig<FrBn254> {
    POSEIDON_BN254_FR_RATE2.get_or_init(|| poseidon_config_rate2::<FrBn254>())
}

/// Native Poseidon commitment digest: `Poseidon(domain, secret, blinding)` (same absorb order as in-circuit).
#[inline]
pub fn poseidon_commit_digest_bn254(domain: u64, secret: FrBn254, blinding: FrBn254) -> FrBn254 {
    let params = poseidon_config_bn254_rate2();
    let mut sponge = PoseidonSponge::new(params);
    sponge.absorb(&vec![FrBn254::from(domain), secret, blinding]);
    sponge.squeeze_native_field_elements(1)[0]
}

/// Native nullifier hook: `Poseidon(0x4E4C, secret, external, nullifier_key)` (aligned with [`crate::commitment::nullifier_from_poseidon_opening`] on BLS12-381; here **BN254** field).
#[inline]
pub fn poseidon_nullifier_digest_bn254(
    secret: FrBn254,
    external: FrBn254,
    nullifier_key: FrBn254,
) -> FrBn254 {
    let params = poseidon_config_bn254_rate2();
    let mut sponge = PoseidonSponge::new(params);
    sponge.absorb(&vec![
        FrBn254::from(0x4E4Cu64),
        secret,
        external,
        nullifier_key,
    ]);
    sponge.squeeze_native_field_elements(1)[0]
}

// ---------------------------------------------------------------------------
// Scalar
// ---------------------------------------------------------------------------

/// Shared scalar surface for BN254, BLS12-381, and future prime fields used in `.rice` ZK.
///
/// **Why:** Contracts and services should not special-case each curve for common reads/writes,
/// RNG draws, and equality checks.
pub trait Scalar: PrimeField + Copy {
    /// Parse a big-endian unsigned integer; **rejects** values ≥ field modulus (no silent reduction).
    #[inline]
    fn from_be_bytes_strict(bytes: &[u8]) -> Result<Self, PrivateError> {
        prime_field_from_be_bytes_strict(bytes)
    }

    /// Minimal big-endian encoding (no leading zero bytes, except `[0]` for zero).
    #[inline]
    fn to_be_bytes(self) -> Vec<u8> {
        self.into_bigint().to_bytes_be()
    }

    /// Fixed-width big-endian encoding (`ceil(modulus bits / 8)` bytes), left-padded with zeros.
    ///
    /// **Why:** Constant-time equality ([`Scalar::ct_eq`]) needs a stable width so comparisons
    /// do not leak the magnitude of scalars through length.
    #[inline]
    fn to_be_bytes_fixed(self) -> Vec<u8> {
        prime_field_to_be_bytes_fixed_width(self)
    }

    /// Canonical fixed-width bytes as a refcounted [`Bytes`] buffer (prost / CLERK interop).
    #[inline]
    fn to_util_bytes(self) -> Bytes {
        Bytes::copy_from_slice(&self.to_be_bytes_fixed())
    }

    /// Uniformly sample a non-structure-preserving scalar (standard Schnorr / Groth16 pattern).
    #[inline]
    fn random<R: Rng + ?Sized>(rng: &mut R) -> Self {
        Self::rand(rng)
    }

    /// Whether this scalar is zero (via [`Zero::is_zero`]; not guaranteed constant-time).
    ///
    /// **Call sites:** Use `Scalar::is_zero(x)` if method resolution is ambiguous.
    #[inline]
    fn is_zero(self) -> bool {
        Zero::is_zero(&self)
    }

    /// Constant-time equality using fixed-width encodings and [`util::bytes::secure_compare`].
    #[inline]
    fn ct_eq(self, other: Self) -> bool {
        scalar_ct_eq(self, other)
    }
}

impl<F> Scalar for F where F: PrimeField + Copy {}

// ---------------------------------------------------------------------------
// Strict bytes ↔ field (util::Bytes compatible)
// ---------------------------------------------------------------------------

/// Decode a **canonical** scalar from big-endian bytes: integer must be strictly less than the modulus.
///
/// **Why:** Wire formats must not rely on implicit `mod p`; accepting only canonical values catches
/// double encodings and bad prover inputs early.
#[inline]
pub fn prime_field_from_be_bytes_strict<F: PrimeField>(bytes: &[u8]) -> Result<F, PrivateError> {
    let n = BigUint::from_bytes_be(bytes);
    let modulus: BigUint = F::MODULUS.into();
    if n >= modulus {
        return Err(PrivateError::FieldInvalid(
            "big-endian integer is not canonical for this field (must be strictly less than the modulus)"
                .into(),
        ));
    }
    let repr = F::BigInt::try_from(n).map_err(|_| {
        PrivateError::FieldInvalid(
            "scalar does not fit the field limb representation after range check".into(),
        )
    })?;
    F::from_bigint(repr).ok_or_else(|| {
        PrivateError::FieldInvalid(
            "scalar rejected by field API despite canonical range (internal)".into(),
        )
    })
}

/// Decode from a [`Bytes`] buffer (same type as [`util::bytes`]).
#[inline]
pub fn prime_field_from_util_bytes<F: PrimeField>(buf: &Bytes) -> Result<F, PrivateError> {
    prime_field_from_be_bytes_strict::<F>(buf.as_ref())
}

/// Fixed-width big-endian bytes for a scalar (left-padded to the field’s byte width).
#[inline]
pub fn prime_field_to_be_bytes_fixed_width<F: PrimeField>(x: F) -> Vec<u8> {
    let byte_len = ((F::MODULUS_BIT_SIZE + 7) / 8) as usize;
    let mut be = x.into_bigint().to_bytes_be();
    debug_assert!(
        be.len() <= byte_len,
        "canonical repr exceeds modulus byte width"
    );
    if be.len() < byte_len {
        let mut padded = vec![0u8; byte_len - be.len()];
        padded.extend_from_slice(&be);
        be = padded;
    }
    be
}

/// Constant-time equality of two scalars via fixed-width big-endian encoding.
#[inline]
pub fn scalar_ct_eq<F: PrimeField>(a: F, b: F) -> bool {
    let ba = prime_field_to_be_bytes_fixed_width(a);
    let bb = prime_field_to_be_bytes_fixed_width(b);
    util::bytes::secure_compare(&ba, &bb)
}

// ---------------------------------------------------------------------------
// Basic field ops (hot path)
// ---------------------------------------------------------------------------

/// Multiply two field elements (R1CS gadgets mirror this relation in-circuit).
#[inline]
pub fn mul<F: Field>(a: F, b: F) -> F {
    a * b
}

/// Multiplicative inverse; [`None`] when `x` is zero (callers enforce circuit semantics).
#[inline]
pub fn inv<F: Field>(x: F) -> Option<F> {
    x.inverse()
}

/// Raise `base` to `exp` using a single-limb exponent (common small Hamming-weight patterns).
#[inline]
pub fn pow_u64<F: Field>(base: F, exp: u64) -> F {
    base.pow([exp])
}

/// Map a `u128` balance into the field (safe for BN254 / BLS12-381 scalars: modulus ≫ `u128::MAX`).
#[inline]
pub fn from_u128<F: PrimeField>(v: u128) -> F {
    F::from(v)
}

/// Montgomery’s batch inversion: replaces `out[i]` with `out[i]^{-1}` using one inversion.
///
/// **Why:** MSM-free proving and witness prep often need many inverses; this saves `O(n)` field
/// inversions to `O(1)` plus `O(n)` multiplies.
#[inline]
pub fn batch_inversion<F: Field>(out: &mut [F]) -> Result<(), PrivateError> {
    let n = out.len();
    if n == 0 {
        return Ok(());
    }

    let mut prefix = Vec::with_capacity(n);
    let mut acc = F::one();
    for x in out.iter() {
        if x.is_zero() {
            return Err(PrivateError::FieldInvalid(
                "batch inversion: zero element in batch".into(),
            ));
        }
        prefix.push(acc);
        acc *= *x;
    }

    let mut inv = acc.inverse().ok_or_else(|| {
        PrivateError::FieldInvalid(
            "batch inversion: product of batch elements is not invertible".into(),
        )
    })?;

    for i in (0..n).rev() {
        let old = out[i];
        let new_val = inv * prefix[i];
        inv *= old;
        out[i] = new_val;
    }
    Ok(())
}

/// Minimal big-endian encoding (variable length). Prefer [`prime_field_to_be_bytes_fixed_width`] on the wire.
#[inline]
pub fn fr_to_be_bytes<F: PrimeField>(x: F) -> Vec<u8> {
    x.into_bigint().to_bytes_be()
}

#[cfg(test)]
mod tests {
    use super::*;
    use ark_ff::UniformRand;
    use ark_std::rand::SeedableRng;
    use ark_std::One;
    use rand::rngs::StdRng;

    #[test]
    fn strict_parse_rejects_modulus() {
        let p_bytes = FrBn254::MODULUS.to_bytes_be();
        assert!(prime_field_from_be_bytes_strict::<FrBn254>(&p_bytes).is_err());
    }

    #[test]
    fn strict_parse_accepts_zero_and_one() {
        assert_eq!(
            prime_field_from_be_bytes_strict::<FrBn254>(&[0u8]).unwrap(),
            FrBn254::from(0u64)
        );
        assert_eq!(
            prime_field_from_be_bytes_strict::<FrBn254>(&[1u8]).unwrap(),
            FrBn254::from(1u64)
        );
    }

    #[test]
    fn batch_inversion_roundtrip() {
        let mut rng = StdRng::from_seed([3u8; 32]);
        let mut xs: Vec<FrBn254> = (0..5).map(|_| FrBn254::rand(&mut rng)).collect();
        let originals = xs.clone();
        batch_inversion(&mut xs).unwrap();
        for (x, orig) in xs.iter().zip(originals.iter()) {
            assert_eq!(*x * *orig, FrBn254::one());
        }
    }

    #[test]
    fn ct_eq_matches_eq_for_random_scalars() {
        let mut rng = StdRng::from_seed([9u8; 32]);
        let a = FrBls12::rand(&mut rng);
        let b = FrBls12::rand(&mut rng);
        assert!(Scalar::ct_eq(a, a));
        assert!(!Scalar::ct_eq(a, b) || a == b);
    }

    #[test]
    fn from_u128_roundtrip_be() {
        let v: u128 = 9_876_543_210;
        let fe = from_u128::<FrBn254>(v);
        let bytes = fe.to_be_bytes_fixed();
        let back = prime_field_from_be_bytes_strict::<FrBn254>(&bytes).unwrap();
        assert_eq!(fe, back);
    }
}
