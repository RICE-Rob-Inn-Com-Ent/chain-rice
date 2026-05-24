//! Sovereign identity on **BN254** — Poseidon commitments, nullifiers, rotation, attestations, and
//! **cryptographic** authorization for ceremony updates.
//!
//! **Policy stays upstream:** this module derives public handles and verifies Groth16 **identity-opening**
//! math; “who may rotate keys” is still [`crate::setup`] + OS policy. [`ParameterUpdateAuthorization`]
//! binds an epoch (replay window) to a concrete opening proof checked against the **current**
//! verifying key on disk before [`ParameterStore::persist_groth16_params`] overwrites bytes.

pub use ark_bn254::Bn254;
pub use ark_groth16::{Proof, ProvingKey, VerifyingKey};

use std::fmt;

use ark_ff::Field;
use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};
use util::bytes::encode_hex_lower as hex_encode;
use rand::RngCore;
use sha2::{Digest, Sha256};

use crate::circuit::CLERK_IDENTITY_POSEIDON_DOMAIN;
use crate::error::PrivateError;
use crate::field::{
    FrBn254, Scalar, poseidon_commit_digest_bn254, poseidon_nullifier_digest_bn254,
    prime_field_from_be_bytes_strict,
};
use crate::serial::{ComplianceMask, ComplianceOperation, VaultEnvelope, VaultMasterKeySource};
use crate::setup::{IdentityOpeningSetup, ParameterStore};
use crate::verify;

/// Qdrant / vector index collection name for spent nullifiers (wire with SMITH ingest).
pub const CLERK_ZK_NULLIFIER_COLLECTION_ENV: &str = "CLERK_ZK_NULLIFIER_COLLECTION";

/// Minimum high-entropy seed length (e.g. decoded mnemonic entropy, OS RNG blob).
pub const SOVEREIGN_SEED_MIN_BYTES: usize = 32;

pub type IdentityProof = Proof<Bn254>;

// ---------------------------------------------------------------------------
// Core identity material
// ---------------------------------------------------------------------------

/// Secret triple for identity: the user’s opening to their Poseidon commitment.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SovereignIdentity {
    pub secret: FrBn254,
    pub blinding: FrBn254,
    pub nullifier_key: FrBn254,
}

/// Back-compat name for the same witness used by [`crate::prove::prove_identity`].
pub type IdentityWitness = SovereignIdentity;

impl SovereignIdentity {
    /// Derive field elements from high-entropy seed bytes (SHA-256 expansion with rejection).
    ///
    /// **Not** a BIP39 parser — pass **already decoded** mnemonic entropy or a CSPRNG output.
    pub fn from_high_entropy_seed(entropy: &[u8]) -> Result<Self, PrivateError> {
        if entropy.len() < SOVEREIGN_SEED_MIN_BYTES {
            return Err(PrivateError::IdentityMalformedKey(format!(
                "sovereign seed must be at least {SOVEREIGN_SEED_MIN_BYTES} bytes (got {})",
                entropy.len()
            )));
        }
        Ok(Self {
            secret: derive_fr_from_seed(entropy, 0)?,
            blinding: derive_fr_from_seed(entropy, 1)?,
            nullifier_key: derive_fr_from_seed(entropy, 2)?,
        })
    }

    /// Poseidon commitment published to the world (`CLERK_IDENTITY_POSEIDON_DOMAIN` domain tag).
    #[inline]
    pub fn public_commitment(&self) -> PublicIdentityCommitment {
        PublicIdentityCommitment(poseidon_commit_digest_bn254(
            CLERK_IDENTITY_POSEIDON_DOMAIN,
            self.secret,
            self.blinding,
        ))
    }

    /// Nullifier with arbitrary **external** field (protocol-specific domain separation).
    #[inline]
    pub fn nullifier(&self, external: FrBn254) -> IdentityNullifier {
        IdentityNullifier(poseidon_nullifier_digest_bn254(self.secret, external, self.nullifier_key))
    }

    /// Default opening nullifier (`external = 0`), matching [`crate::circuit::IdentityOpeningCircuit`].
    #[inline]
    pub fn nullifier_for_identity_opening(&self) -> IdentityNullifier {
        self.nullifier(FrBn254::ZERO)
    }

    /// Public statement tuple for Groth16 identity opening (commitment, nullifier with `external = 0`).
    #[inline]
    pub fn public_statement_opening(&self) -> (FrBn254, FrBn254) {
        let c = self.public_commitment().0;
        let n = self.nullifier_for_identity_opening().0;
        (c, n)
    }

    /// Rotate: retire this identity’s commitment by publishing [`IdentityRotationReceipt`], then adopt new secrets.
    ///
    /// **History:** Callers record `receipt.nullifier_spent` in the nullifier set and optionally anchor
    /// `receipt.retired_commitment` + new commitment in the same ledger transaction so continuity is provable.
    pub fn rotate(self, new_seed_entropy: &[u8]) -> Result<(SovereignIdentity, IdentityRotationReceipt), PrivateError> {
        let next = SovereignIdentity::from_high_entropy_seed(new_seed_entropy)?;
        let receipt = IdentityRotationReceipt {
            retired_commitment: self.public_commitment(),
            nullifier_spent: self.nullifier_for_identity_opening(),
        };
        Ok((next, receipt))
    }
}

// ---------------------------------------------------------------------------
// Public handles
// ---------------------------------------------------------------------------

/// Public identity commitment (safe to put in logs / on-chain).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash, CanonicalSerialize, CanonicalDeserialize)]
pub struct PublicIdentityCommitment(pub FrBn254);

impl PublicIdentityCommitment {
    #[inline]
    pub fn as_field(&self) -> FrBn254 {
        self.0
    }
}

impl fmt::Display for PublicIdentityCommitment {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let h = Sha256::digest(self.0.to_be_bytes_fixed());
        write!(f, "{}", hex_encode(&h[..4]))
    }
}

/// Spent tag derived from the secret identity (double-spend prevention).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash, CanonicalSerialize, CanonicalDeserialize)]
pub struct IdentityNullifier(pub FrBn254);

impl IdentityNullifier {
    #[inline]
    pub fn as_field(&self) -> FrBn254 {
        self.0
    }
}

impl fmt::Display for IdentityNullifier {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let h = Sha256::digest(self.0.to_be_bytes_fixed());
        write!(f, "{}", hex_encode(&h[..4]))
    }
}

/// Artifacts to publish when moving to a new [`SovereignIdentity`].
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct IdentityRotationReceipt {
    pub retired_commitment: PublicIdentityCommitment,
    pub nullifier_spent: IdentityNullifier,
}

// ---------------------------------------------------------------------------
// Attestation payload (vault)
// ---------------------------------------------------------------------------

/// Plaintext binding between a **public commitment** and an off-chain claim (“over 18”, “admin”, …).
#[derive(Clone, Debug, Eq, PartialEq, CanonicalSerialize, CanonicalDeserialize)]
pub struct IdentityAttestationPayload {
    /// UTF-8 claim (e.g. `b"age_over_18"`).
    pub claim_utf8: Vec<u8>,
    pub binding_commitment: FrBn254,
}

impl IdentityAttestationPayload {
    #[inline]
    pub fn new(claim_utf8: impl Into<Vec<u8>>, binding_commitment: FrBn254) -> Self {
        Self {
            claim_utf8: claim_utf8.into(),
            binding_commitment,
        }
    }
}

/// Seal an attestation so only vault policy can open it; **AAD** should carry routing / tenant context.
#[inline]
pub fn seal_identity_attestation(
    payload: &IdentityAttestationPayload,
    key_src: &impl VaultMasterKeySource,
    mask: &ComplianceMask,
    op: ComplianceOperation,
    user_aad: &[u8],
    rng: &mut impl RngCore,
) -> Result<VaultEnvelope<IdentityAttestationPayload>, PrivateError> {
    VaultEnvelope::seal_artifact(payload, key_src, mask, op, user_aad, rng)
}

// ---------------------------------------------------------------------------
// Parameter update authorization (Groth16 identity opening)
// ---------------------------------------------------------------------------

/// Authorizes writing ceremony material: must verify an **identity-opening** proof under the **current**
/// [`IdentityOpeningSetup`] VK in [`ParameterStore`] before keys are replaced.
#[derive(Clone, Debug, PartialEq)]
pub struct ParameterUpdateAuthorization {
    /// Replay / policy epoch (operator-defined).
    pub attestation_epoch: u64,
    pub identity_commitment: FrBn254,
    pub identity_nullifier: FrBn254,
    pub identity_opening_proof: Proof<Bn254>,
}

impl ParameterUpdateAuthorization {
    #[inline]
    pub fn new(
        attestation_epoch: u64,
        identity_commitment: FrBn254,
        identity_nullifier: FrBn254,
        identity_opening_proof: Proof<Bn254>,
    ) -> Self {
        Self {
            attestation_epoch,
            identity_commitment,
            identity_nullifier,
            identity_opening_proof,
        }
    }

    /// Verify the bundled proof against **`store`’s current** identity VK and these public inputs.
    ///
    /// **Important:** On first install the identity VK may be missing — use non-production paths or
    /// bootstrap without this token; when rotating, this checks the proof under the **existing** VK.
    pub fn verify_identity_gate(&self, store: &ParameterStore) -> Result<(), PrivateError> {
        verify::verify_with_store::<IdentityOpeningSetup, Bn254>(
            store,
            &[self.identity_commitment, self.identity_nullifier],
            &self.identity_opening_proof,
        )
    }
}

// ---------------------------------------------------------------------------
// Nullifier index (Qdrant / SMITH hooks)
// ---------------------------------------------------------------------------

/// Configuration for a nullifier collection (set [`CLERK_ZK_NULLIFIER_COLLECTION_ENV`] in deployment).
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct NullifierIndexConfig {
    pub collection_name: String,
}

impl NullifierIndexConfig {
    #[inline]
    pub fn from_env() -> Result<Self, PrivateError> {
        let collection_name = std::env::var(CLERK_ZK_NULLIFIER_COLLECTION_ENV).map_err(|_| {
            PrivateError::SetupMissing(format!("{CLERK_ZK_NULLIFIER_COLLECTION_ENV} is not set (nullifier index)"))
        })?;
        if collection_name.is_empty() {
            return Err(PrivateError::SetupMissing("nullifier collection name is empty".into()));
        }
        Ok(Self { collection_name })
    }
}

/// Abstraction for “has this nullifier been spent?” — implement with Qdrant, Yugabyte, or an in-memory map in tests.
pub trait NullifierSpendBook {
    fn is_nullifier_spent(&self, nullifier: &IdentityNullifier) -> Result<bool, PrivateError>;

    /// Optional hook: reserve a nullifier before proof lands (default: same as [`is_nullifier_spent`](NullifierSpendBook::is_nullifier_spent)).
    fn assert_nullifier_unused(&self, nullifier: &IdentityNullifier) -> Result<(), PrivateError> {
        if self.is_nullifier_spent(nullifier)? {
            return Err(PrivateError::IdentityNullifierCollision(format!(
                "nullifier {} already spent",
                nullifier
            )));
        }
        Ok(())
    }
}

/// Placeholder until SMITH wires Qdrant; [`NullifierSpendBook::is_nullifier_spent`] always errors with [`PrivateError::SetupMissing`].
#[derive(Clone, Copy, Debug, Default)]
pub struct QdrantNullifierBookPlaceholder;

impl NullifierSpendBook for QdrantNullifierBookPlaceholder {
    fn is_nullifier_spent(&self, _nullifier: &IdentityNullifier) -> Result<bool, PrivateError> {
        let _cfg = NullifierIndexConfig::from_env()?;
        Err(PrivateError::SetupMissing(
            "Qdrant nullifier book not implemented in `private` crate — implement NullifierSpendBook in SMITH".into(),
        ))
    }
}

// ---------------------------------------------------------------------------
// Seed derivation
// ---------------------------------------------------------------------------

fn derive_fr_from_seed(entropy: &[u8], lane: u32) -> Result<FrBn254, PrivateError> {
    for attempt in 0u64..256 {
        let mut h = Sha256::new();
        h.update(b"rice.sovereign.seed.v1");
        h.update(entropy);
        h.update(lane.to_le_bytes());
        h.update(attempt.to_le_bytes());
        let out = h.finalize();
        if let Ok(fr) = prime_field_from_be_bytes_strict::<FrBn254>(&out) {
            return Ok(fr);
        }
    }
    Err(PrivateError::FieldInvalid(
        "failed to derive Fr from seed after 256 attempts".into(),
    ))
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::sync::Mutex;

    use ark_ff::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use super::*;
    use crate::prove::prove_identity;
    use crate::serial::StaticVaultKey;
    use crate::setup::ParameterStore;

    static ID_ENV_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn sovereign_seed_derivation_deterministic() {
        let entropy = [9u8; 40];
        let a = SovereignIdentity::from_high_entropy_seed(&entropy).unwrap();
        let b = SovereignIdentity::from_high_entropy_seed(&entropy).unwrap();
        assert_eq!(a, b);
    }

    #[test]
    fn commitment_matches_native_poseidon() {
        let mut rng = StdRng::from_seed([1u8; 32]);
        let id = SovereignIdentity {
            secret: FrBn254::rand(&mut rng),
            blinding: FrBn254::rand(&mut rng),
            nullifier_key: FrBn254::rand(&mut rng),
        };
        let c = id.public_commitment();
        let expected = poseidon_commit_digest_bn254(CLERK_IDENTITY_POSEIDON_DOMAIN, id.secret, id.blinding);
        assert_eq!(c.0, expected);
    }

    #[test]
    fn parameter_auth_verifies_real_proof() {
        let _g = ID_ENV_LOCK.lock().expect("lock");
        unsafe {
            std::env::remove_var("CLERK_ENV");
        }
        let mut rng = StdRng::from_seed([2u8; 32]);
        let root = std::env::temp_dir().join(format!("rice-id-auth-{}", line!()));
        let _ = fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root.clone());

        let id = SovereignIdentity {
            secret: FrBn254::rand(&mut rng),
            blinding: FrBn254::rand(&mut rng),
            nullifier_key: FrBn254::rand(&mut rng),
        };
        let (commitment, nullifier) = id.public_statement_opening();
        let proof = prove_identity(&store, id, &mut rng).unwrap();

        let auth = ParameterUpdateAuthorization::new(42, commitment, nullifier, proof);
        auth.verify_identity_gate(&store).unwrap();

        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn rotation_changes_commitment() {
        let e1 = [3u8; 32];
        let e2 = [4u8; 32];
        let old = SovereignIdentity::from_high_entropy_seed(&e1).unwrap();
        let (new_id, receipt) = old.rotate(&e2).unwrap();
        assert_ne!(old.public_commitment(), new_id.public_commitment());
        assert_eq!(receipt.retired_commitment, old.public_commitment());
        assert_eq!(receipt.nullifier_spent, old.nullifier_for_identity_opening());
    }

    #[test]
    fn attestation_seal_roundtrip() {
        let mut rng = StdRng::from_seed([5u8; 32]);
        let id = SovereignIdentity::from_high_entropy_seed(&[7u8; 40]).unwrap();
        let c = id.public_commitment().0;
        let payload = IdentityAttestationPayload::new(b"age_over_18".as_slice(), c);
        let key = StaticVaultKey([11u8; 32]);
        let mask = crate::serial::ComplianceMask::global_default();
        let env =
            seal_identity_attestation(&payload, &key, &mask, ComplianceOperation::LocalVault, b"tenant-test", &mut rng)
                .unwrap();
        let opened = env.open(&key, &mask, b"tenant-test").unwrap();
        assert_eq!(opened.claim_utf8, b"age_over_18");
        assert_eq!(opened.binding_commitment, c);
    }
}
