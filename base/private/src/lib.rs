//! # The silent heart of `.rice`
//!
//! **`private`** is the zero-knowledge layer for the RICE operating system: the place where secrets
//! become **provable** without becoming **public**. SMITH, CLERK, and contracts should treat this
//! crate as the **single entry** for Groth16 lifecycle, vault serialization, identity, shielded
//! balance, and compliance math.
//!
//! ## Three pillars
//!
//! | Pillar | Question | Home in this crate |
//! |--------|----------|--------------------|
//! | **Who** | Which sovereign identity is speaking? | [`identity`], [`prove::prove_identity`], [`verify`] against [`setup::IdentityOpeningRice`] |
//! | **What** | Which hidden value moved, under which asset tag? | [`balance`], [`circuit::ShieldedTransferCircuit`], Pedersen in [`commitment`] |
//! | **How** | Which rules (policy, lists, quorum) were satisfied? | [`compliance`], [`error::PrivateError::ComplianceVeto`], policy digests |
//!
//! Curves: **BN254** for Groth16 (identity + shielded transfer); **BLS12-381** for compliance /
//! membership artifacts and future accumulator work.
//!
//! ## Errors
//!
//! Every failure path should surface as [`PrivateError`] (and [`PrivateResult`]). Use
//! [`PrivateError::into_rice`] at the CLERK / `util` boundary.
//!
//! ## Environment
//!
//! - **`RICE_ENV`**: `production` / `prod` (case-insensitive) → production ceremony discipline; see
//!   [`setup::is_production_rice_env`], [`rice_zk_environment`].
//! - **`RICE_ZK_MOCK_VERIFY`**: in **non-production** only, `1` / `true` / `yes` makes
//!   [`StandardRiceZkEngine`] **skip pairing checks** on verify paths (development only; never ship
//!   with real assets).

pub mod balance;
pub mod circuit;
pub mod commitment;
pub mod compliance;
pub mod curve;
pub mod error;
pub mod field;
pub mod identity;
pub mod prove;
pub mod serial;
pub mod setup;
pub mod verify;

// ---------------------------------------------------------------------------
// Master error surface
// ---------------------------------------------------------------------------

pub use error::{PrivateError, PrivateResult};

// ---------------------------------------------------------------------------
// Flattened “Rice public API” (most common types for SMITH / CLERK)
// ---------------------------------------------------------------------------

pub use balance::{
    AssetType, BalanceProof, MintAuthorization, ShieldedLedgerTransfer, ShieldedNote,
};
pub use compliance::{
    AggregatedComplianceStatement, ComplianceMerklePath, ComplianceMerkleTree, ComplianceProof,
    FrBls12, MembershipClaim, PolicyBinding, ThresholdCompliance,
};
pub use field::{FrBn254, RiceScalar};
pub use identity::{
    IdentityAttestationPayload, IdentityProof, IdentityRotationReceipt, IdentityWitness,
    ParameterUpdateAuthorization, PublicIdentityCommitment, SovereignIdentity,
};
pub use serial::{ComplianceMask, ComplianceOperation, VaultEnvelope};
pub use setup::{ParameterStore, get_or_generate_params, is_production_rice_env};

// ---------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------

/// Operating mode for ZK I/O and ceremony policy (derived from **`RICE_ENV`**).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub enum RiceZkEnvironment {
    /// Local / staging: may use dev caches, optional mock verify (see [`StandardRiceZkEngine`]).
    Development,
    /// Ceremony load-only, stricter persistence rules, mock verify **disabled**.
    Production,
}

/// Read [`RiceZkEnvironment`] from the process environment.
#[inline]
pub fn rice_zk_environment() -> RiceZkEnvironment {
    if is_production_rice_env() {
        RiceZkEnvironment::Production
    } else {
        RiceZkEnvironment::Development
    }
}

/// When set to `1` / `true` / `yes`, [`StandardRiceZkEngine`] may skip Groth16 verification in
/// **non-production** only. Ignored when [`rice_zk_environment`] is [`RiceZkEnvironment::Production`].
pub const RICE_ZK_MOCK_VERIFY_ENV: &str = "RICE_ZK_MOCK_VERIFY";

#[inline]
fn mock_verify_requested() -> bool {
    matches!(
        std::env::var(RICE_ZK_MOCK_VERIFY_ENV)
            .map(|s| s.to_ascii_lowercase())
            .as_deref(),
        Ok("1") | Ok("true") | Ok("yes")
    )
}

#[inline]
fn effective_mock_verify() -> bool {
    !is_production_rice_env() && mock_verify_requested()
}

// ---------------------------------------------------------------------------
// Trait-based orchestration
// ---------------------------------------------------------------------------

use ark_bn254::Bn254;
use ark_std::rand::{CryptoRng, RngCore};

/// High-level ZK **action suites** for hosts that prefer a trait over free functions.
///
/// Implementations may short-circuit verification in development when
/// [`RICE_ZK_MOCK_VERIFY_ENV`] is set; production builds must always run real pairing checks.
pub trait RiceZkEngine {
    fn environment(&self) -> RiceZkEnvironment;

    /// **Who:** prove identity opening (BN254 Groth16).
    fn identify(
        &self,
        store: &ParameterStore,
        who: SovereignIdentity,
        rng: &mut (impl RngCore + CryptoRng),
    ) -> Result<IdentityProof, PrivateError>;

    /// **Who:** verify identity opening proof.
    fn verify_identity(
        &self,
        store: &ParameterStore,
        identity_commitment: FrBn254,
        identity_nullifier: FrBn254,
        proof: &IdentityProof,
    ) -> Result<(), PrivateError>;

    /// **What:** prove shielded ledger transfer (BN254 Groth16).
    fn transfer(
        &self,
        store: &ParameterStore,
        xfer: &ShieldedLedgerTransfer,
        rng: &mut (impl RngCore + CryptoRng),
    ) -> Result<BalanceProof, PrivateError>;

    /// **What:** verify shielded transfer (`public_fee` field is third public input).
    fn verify_transfer(
        &self,
        store: &ParameterStore,
        identity_commitment: FrBn254,
        identity_nullifier: FrBn254,
        public_fee: FrBn254,
        proof: &BalanceProof,
    ) -> Result<(), PrivateError>;

    /// **How:** verify list / policy-side membership claim (Merkle on BLS12-381 `Fr`).
    fn comply(
        &self,
        claim: &MembershipClaim,
    ) -> Result<(), PrivateError>;
}

/// Default engine: real Groth16 prove; verify obeys [`RICE_ZK_MOCK_VERIFY_ENV`] outside production.
#[derive(Clone, Copy, Debug, Default)]
pub struct StandardRiceZkEngine {
    /// If `true`, identity and shielded **verifiers** return `Ok` without pairing (dev only).
    pub mock_verify: bool,
}

impl StandardRiceZkEngine {
    /// Production-safe: mock verify is **off** in production even if the env var is set.
    #[inline]
    pub fn from_env() -> Self {
        Self {
            mock_verify: effective_mock_verify(),
        }
    }

    #[inline]
    pub fn production_strict() -> Self {
        Self { mock_verify: false }
    }
}

impl RiceZkEngine for StandardRiceZkEngine {
    fn environment(&self) -> RiceZkEnvironment {
        rice_zk_environment()
    }

    fn identify(
        &self,
        store: &ParameterStore,
        who: SovereignIdentity,
        rng: &mut (impl RngCore + CryptoRng),
    ) -> Result<IdentityProof, PrivateError> {
        prove::prove_identity(store, who, rng)
    }

    fn verify_identity(
        &self,
        store: &ParameterStore,
        identity_commitment: FrBn254,
        identity_nullifier: FrBn254,
        proof: &IdentityProof,
    ) -> Result<(), PrivateError> {
        if self.mock_verify {
            tracing::warn!(
                target: "rice.zk",
                mock = true,
                "skipping Groth16 identity verification ({})",
                RICE_ZK_MOCK_VERIFY_ENV
            );
            return Ok(());
        }
        verify::verify_with_store::<setup::IdentityOpeningRice, Bn254>(
            store,
            &[identity_commitment, identity_nullifier],
            proof,
        )
    }

    fn transfer(
        &self,
        store: &ParameterStore,
        xfer: &ShieldedLedgerTransfer,
        rng: &mut (impl RngCore + CryptoRng),
    ) -> Result<BalanceProof, PrivateError> {
        balance::prove_shielded_ledger_transfer(store, xfer, rng)
    }

    fn verify_transfer(
        &self,
        store: &ParameterStore,
        identity_commitment: FrBn254,
        identity_nullifier: FrBn254,
        public_fee: FrBn254,
        proof: &BalanceProof,
    ) -> Result<(), PrivateError> {
        if self.mock_verify {
            tracing::warn!(
                target: "rice.zk",
                mock = true,
                "skipping Groth16 shielded transfer verification ({})",
                RICE_ZK_MOCK_VERIFY_ENV
            );
            return Ok(());
        }
        balance::verify_shielded_ledger_transfer(
            store,
            identity_commitment,
            identity_nullifier,
            public_fee,
            proof,
        )
    }

    fn comply(&self, claim: &MembershipClaim) -> Result<(), PrivateError> {
        claim.verify_inclusion()
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use ark_bn254::Bn254;
    use ark_ff::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use super::circuit::MulCircuit;
    use super::compliance::{ComplianceListKind, ComplianceMerkleTree};
    use super::prove::prove_mul;
    use super::serial::proof_to_bytes_compressed;
    use super::setup::trusted_setup;
    use super::verify::verify_mul;
    use super::*;

    static LIB_ENGINE_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn groth16_bn254_mul_roundtrip() {
        let mut rng = StdRng::from_seed([7u8; 32]);
        let (pk, vk) = trusted_setup::<Bn254, _>(&mut rng).unwrap();

        let a = FrBn254::rand(&mut rng);
        let b = FrBn254::rand(&mut rng);
        let mut c = a;
        c *= b;

        let proof = prove_mul(&pk, a, b, &mut rng).unwrap();
        verify_mul(&vk, c, &proof).unwrap();

        let bytes = proof_to_bytes_compressed(&proof).unwrap();
        assert!(!bytes.is_empty());

        let _sizing = MulCircuit::<FrBn254>::for_setup();
    }

    #[test]
    fn standard_engine_runs_identify_and_comply() {
        use std::fs;

        let _guard = LIB_ENGINE_LOCK.lock().expect("lib test lock");
        unsafe {
            std::env::remove_var("RICE_ENV");
            std::env::remove_var(RICE_ZK_MOCK_VERIFY_ENV);
        }

        let eng = StandardRiceZkEngine::from_env();
        assert_eq!(eng.environment(), RiceZkEnvironment::Development);

        let mut rng = StdRng::from_seed([99u8; 32]);
        let root = std::env::temp_dir().join(format!("rice-lib-engine-{}", line!()));
        let _ = fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root.clone());

        let who = SovereignIdentity::from_high_entropy_seed(&[5u8; 40]).unwrap();
        let proof = eng.identify(&store, who, &mut rng).unwrap();
        let (c, n) = who.public_statement_opening();
        eng.verify_identity(&store, c, n, &proof).unwrap();

        let leaves = vec![FrBls12::from(1u64), FrBls12::from(2u64)];
        let tree = ComplianceMerkleTree::with_depth(&leaves, 2).unwrap();
        let path = tree.prove(0).unwrap();
        let claim = MembershipClaim {
            list_kind: ComplianceListKind::Allow,
            root: tree.root(),
            leaf: leaves[0],
            path,
        };
        eng.comply(&claim).unwrap();

        let _ = fs::remove_dir_all(&root);
    }
}
