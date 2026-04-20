//! **Immutable vows** — Pedersen and Poseidon commitments for shielded state and Groth16 public inputs.
//!
//! **Pedersen** (`C = v·G + r·H` in additive notation) binds a scalar **value** `v` with **blinding**
//! `r` in **G1**. It is algebra-friendly for SNARKs. **Poseidon** uses rate-2 parameters from
//! `ark-crypto-primitives` (constraints-optimized row for BLS12-381 `Fr`), built via the public
//! `find_poseidon_ark_and_mds` helper — not the crate’s `sponge::test` field type, which is
//! `cfg(test)` only and cannot be imported from library code.
//!
//! **Nullifiers** here are **hooks**: they derive a fresh scalar from commitment material + a
//! user-supplied key so a spent commitment can be marked **used** without revealing *which*
//! commitment in the anonymity set (exact linking is protocol-specific).

use ark_crypto_primitives::sponge::{
    CryptographicSponge, FieldBasedCryptographicSponge,
    poseidon::{PoseidonConfig, PoseidonSponge, find_poseidon_ark_and_mds},
};
use ark_ec::pairing::Pairing;
use ark_ec::{AffineRepr, CurveGroup, Group};
use ark_ff::{BigInteger, PrimeField};
use ark_serialize::CanonicalSerialize;
use bytes::Bytes;
use rand::RngCore;
use sha2::{Digest, Sha256};
use std::sync::OnceLock;

use crate::error::PrivateError;
use crate::serial::{ComplianceMask, ComplianceOperation, VaultEnvelope, VaultMasterKeySource};

// Rate-2 row from `PoseidonDefaultConfig` (constraints) for BLS12-381 Fr in ark-crypto-primitives.
static POSEIDON_BLS12_FR_RATE2: OnceLock<PoseidonConfig<ark_bls12_381::Fr>> = OnceLock::new();

/// Rate-2 Poseidon params for **BLS12-381 `Fr`** (constraints row; shared with compliance / Merkle).
#[inline]
pub(crate) fn poseidon_config_bls12_fr_rate2() -> &'static PoseidonConfig<ark_bls12_381::Fr> {
    POSEIDON_BLS12_FR_RATE2.get_or_init(|| {
        let rate = 2usize;
        let full_rounds = 8u64;
        let partial_rounds = 31u64;
        let skip_matrices = 0u64;
        let prime_bits = ark_bls12_381::Fr::MODULUS_BIT_SIZE as u64;
        let (ark, mds) = find_poseidon_ark_and_mds::<ark_bls12_381::Fr>(
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
    })
}

// ---------------------------------------------------------------------------
// Opening (secret + blinding)
// ---------------------------------------------------------------------------

/// Witness to a commitment: the hidden message and the randomness used at sealing time.
///
/// **Why:** Groth16 statements relate public commitments to private openings; this struct is the
/// natural bundle for witness columns.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CommitmentOpening<F: PrimeField> {
    /// Hidden payload (e.g. balance chunk, identity handle).
    pub secret: F,
    /// Blinding / randomness (`r` in Pedersen; mixed into Poseidon inputs).
    pub blinding: F,
}

impl<F: PrimeField + Copy> CommitmentOpening<F> {
    #[inline]
    pub fn new(secret: F, blinding: F) -> Self {
        Self { secret, blinding }
    }

    /// Sample a random opening with explicit RNG (production: use `OsRng` / `StdRng`).
    #[inline]
    pub fn random<R: rand::RngCore + ?Sized>(secret: F, rng: &mut R) -> Self {
        Self { secret, blinding: F::rand(rng) }
    }

    /// Verify against a Pedersen commitment when `F` is the curve’s scalar field.
    #[inline]
    pub fn verify_pedersen<E: Pairing<ScalarField = F>>(
        &self,
        gens: &PedersenGenerators<E>,
        commitment: &PedersenCommitment<E>,
    ) -> bool {
        commitment.verify_opening(gens, self)
    }
}

// ---------------------------------------------------------------------------
// Pedersen (G1, pairing curves)
// ---------------------------------------------------------------------------

/// Independent **G1** generators for Pedersen (`G` and `H`).
#[derive(Clone, Debug)]
pub struct PedersenGenerators<E: Pairing> {
    /// Base generator scaled by the committed value.
    pub g: E::G1Affine,
    /// Blinding generator (must be discrete-log unknown w.r.t. `g` in deployment practice).
    pub h: E::G1Affine,
}

impl<E: Pairing> PedersenGenerators<E> {
    /// Construct from caller-supplied affine points (ceremony / CRS integration).
    #[inline]
    pub fn new(g: E::G1Affine, h: E::G1Affine) -> Self {
        Self { g, h }
    }

    /// Default-ish **non-interactive** second generator: `H = [nums]·G` with small NUMS scalar.
    ///
    /// **Why:** Enough for tests and devnets; production should use audited CRS / hash-to-curve.
    #[inline]
    pub fn derived_second_generator() -> Self {
        let g = E::G1::generator().into_affine();
        let h = (E::G1::generator() * E::ScalarField::from(0x52494345u64)).into_affine();
        Self { g, h }
    }
}

/// Pedersen commitment in **G1**: `C = v·G + r·H`.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PedersenCommitment<E: Pairing> {
    /// Affine public commitment point (typical **public input** to Groth16).
    pub point: E::G1Affine,
}

impl<E: Pairing> PedersenCommitment<E> {
    #[inline]
    pub fn commit(gens: &PedersenGenerators<E>, value: E::ScalarField, randomness: E::ScalarField) -> Self {
        let p = gens.g.into_group() * value + gens.h.into_group() * randomness;
        Self { point: p.into_affine() }
    }

    /// Check `opening` recomputes this commitment.
    #[inline]
    pub fn verify_opening(&self, gens: &PedersenGenerators<E>, opening: &CommitmentOpening<E::ScalarField>) -> bool {
        let c2 = Self::commit(gens, opening.secret, opening.blinding);
        c2.point == self.point
    }

    /// Canonical compressed **public** bytes ([`util::Bytes`]).
    #[inline]
    pub fn to_public_bytes(&self) -> Result<Bytes, PrivateError> {
        let mut buf = Vec::new();
        self.point.serialize_compressed(&mut buf)?;
        Ok(Bytes::from(buf))
    }

    /// Encrypt the commitment point into a [`VaultEnvelope`] (artifact = affine point).
    #[inline]
    pub fn seal_in_vault(
        &self,
        key_src: &impl VaultMasterKeySource,
        mask: &ComplianceMask,
        op: ComplianceOperation,
        user_aad: &[u8],
        rng: &mut impl RngCore,
    ) -> Result<VaultEnvelope<E::G1Affine>, PrivateError> {
        VaultEnvelope::seal_artifact(&self.point, key_src, mask, op, user_aad, rng)
    }
}

// ---------------------------------------------------------------------------
// Poseidon (BLS12-381 scalar field, rate-2 params aligned with ark-crypto-primitives defaults)
// ---------------------------------------------------------------------------

/// Hash commitment in the **shielded scalar field** (BLS12-381 `Fr`), ZK-friendly for upcoming gadgets.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PoseidonCommitment {
    /// Single-field digest (public input).
    pub digest: ark_bls12_381::Fr,
}

/// Poseidon sponge over **value**, **blinding**, and a **domain** tag (public).
///
/// **Why:** Matches the field used in Orchard-style circuits; parameters match arkworks’
/// constraints-optimized default for this modulus at sponge rate 2.
#[inline]
pub fn poseidon_commit(
    opening: &CommitmentOpening<ark_bls12_381::Fr>,
    domain: u64,
) -> Result<PoseidonCommitment, PrivateError> {
    let params = poseidon_config_bls12_fr_rate2();
    let mut sponge = PoseidonSponge::new(params);
    sponge.absorb(&vec![ark_bls12_381::Fr::from(domain), opening.secret, opening.blinding]);
    let out = sponge.squeeze_native_field_elements(1);
    Ok(PoseidonCommitment { digest: out[0] })
}

impl PoseidonCommitment {
    #[inline]
    pub fn verify_opening(
        &self,
        opening: &CommitmentOpening<ark_bls12_381::Fr>,
        domain: u64,
    ) -> Result<bool, PrivateError> {
        let c2 = poseidon_commit(opening, domain)?;
        Ok(c2.digest == self.digest)
    }

    #[inline]
    pub fn to_public_bytes(&self) -> Result<Bytes, PrivateError> {
        let mut buf = Vec::new();
        self.digest.serialize_compressed(&mut buf)?;
        Ok(Bytes::from(buf))
    }

    #[inline]
    pub fn seal_in_vault(
        &self,
        key_src: &impl VaultMasterKeySource,
        mask: &ComplianceMask,
        op: ComplianceOperation,
        user_aad: &[u8],
        rng: &mut impl RngCore,
    ) -> Result<VaultEnvelope<ark_bls12_381::Fr>, PrivateError> {
        VaultEnvelope::seal_artifact(&self.digest, key_src, mask, op, user_aad, rng)
    }
}

impl CommitmentOpening<ark_bls12_381::Fr> {
    #[inline]
    pub fn verify_poseidon(&self, c: &PoseidonCommitment, domain: u64) -> Result<bool, PrivateError> {
        c.verify_opening(self, domain)
    }
}

// ---------------------------------------------------------------------------
// Nullifier hooks (audit / anti–double-spend)
// ---------------------------------------------------------------------------

/// Derive a **nullifier scalar** from a Pedersen commitment and a user **nullifier key**.
///
/// **Why:** Published on-chain or in logs to prove “this commitment was consumed” without opening
/// `r`; the key should mix in user-only entropy (e.g. derived from `.rice` identity).
#[inline]
pub fn nullifier_from_pedersen<E: Pairing>(
    c: &PedersenCommitment<E>,
    nullifier_key: E::ScalarField,
) -> Result<E::ScalarField, PrivateError> {
    let mut pt = Vec::new();
    c.point.serialize_compressed(&mut pt)?;
    Ok(hash_to_scalar::<E>(b"rice.nullifier.pedersen.v1", &pt, nullifier_key))
}

/// Poseidon-style nullifier hook: sponge over **secret**, **external epoch/nonce**, and **key** material.
///
/// **Why:** Keeps nullifier derivation in the same algebraic world as [`poseidon_commit`].
#[inline]
pub fn nullifier_from_poseidon_opening(
    opening: &CommitmentOpening<ark_bls12_381::Fr>,
    external: ark_bls12_381::Fr,
    nullifier_key: ark_bls12_381::Fr,
) -> Result<ark_bls12_381::Fr, PrivateError> {
    let params = poseidon_config_bls12_fr_rate2();
    let mut sponge = PoseidonSponge::new(params);
    sponge.absorb(&vec![
        ark_bls12_381::Fr::from(0x4E4Cu64), // 'NL' domain
        opening.secret,
        external,
        nullifier_key,
    ]);
    let out = sponge.squeeze_native_field_elements(1);
    Ok(out[0])
}

#[inline]
fn hash_to_scalar<E: Pairing>(label: &[u8], commitment_bytes: &[u8], key: E::ScalarField) -> E::ScalarField {
    let mut h = Sha256::new();
    h.update(label);
    h.update(commitment_bytes);
    h.update(key.into_bigint().to_bytes_be());
    let d = h.finalize();
    E::ScalarField::from_le_bytes_mod_order(&d)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use ark_bn254::Bn254;
    use ark_ec::pairing::Pairing;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use crate::serial::StaticVaultKey;

    #[test]
    fn pedersen_opening_roundtrip() {
        let mut rng = StdRng::from_seed([2u8; 32]);
        let gens = PedersenGenerators::<Bn254>::derived_second_generator();
        let v = <Bn254 as Pairing>::ScalarField::from(42u64);
        let opening = CommitmentOpening::random(v, &mut rng);
        let c = PedersenCommitment::commit(&gens, opening.secret, opening.blinding);
        assert!(opening.verify_pedersen(&gens, &c));
        assert!(!c.verify_opening(
            &gens,
            &CommitmentOpening::new(<Bn254 as Pairing>::ScalarField::from(43u64), opening.blinding)
        ));
    }

    #[test]
    fn poseidon_opening_roundtrip() {
        let mut rng = StdRng::from_seed([11u8; 32]);
        let secret = ark_bls12_381::Fr::from(99u64);
        let opening = CommitmentOpening::random(secret, &mut rng);
        let c = poseidon_commit(&opening, 7).unwrap();
        assert!(c.verify_opening(&opening, 7).unwrap());
        assert!(!c.verify_opening(&opening, 8).unwrap());
    }

    #[test]
    fn pedersen_vault_seal_roundtrip() {
        let mut rng = StdRng::from_seed([21u8; 32]);
        let gens = PedersenGenerators::<Bn254>::derived_second_generator();
        let opening = CommitmentOpening::random(<Bn254 as Pairing>::ScalarField::from(5u64), &mut rng);
        let c = PedersenCommitment::commit(&gens, opening.secret, opening.blinding);
        let key = StaticVaultKey([3u8; 32]);
        let mask = ComplianceMask::global_default();
        let wire = c
            .seal_in_vault(&key, &mask, ComplianceOperation::LocalVault, b"ctx", &mut rng)
            .unwrap()
            .to_canonical_bytes();
        let back =
            crate::serial::from_encrypted_bytes::<<Bn254 as Pairing>::G1Affine>(&wire, &key, &mask, b"ctx").unwrap();
        assert_eq!(back, c.point);
    }
}
