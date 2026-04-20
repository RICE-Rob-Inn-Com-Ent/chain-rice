//! Proof generation — witness preflight, parallel Groth16, vault sealing, and telemetry hooks.
//!
//! **Pipeline:** [`preflight_witness_satisfied`] (or implicit via [`generate_proof`]) runs a scratch
//! constraint system; on failure you get [`PrivateError::WitnessInconsistent`] before the heavy
//! prover. Groth16 itself runs on a dedicated Rayon pool ([`RICE_ZK_RAYON_THREADS_ENV`]) so it stacks
//! with ark’s `parallel` feature.
//!
//! **Telemetry:** Spans use the `rice.zk.prove` target — wire `tracing` to OpenTelemetry at the OS
//! boundary. **CUDA:** read [`cuda_acceleration_requested`] / [`RICE_ZK_CUDA_ENV`] (placeholder).

use std::fmt;
use std::sync::OnceLock;

use ark_bn254::Bn254;
use ark_crypto_primitives::snark::SNARK;
use ark_ec::pairing::Pairing;
use ark_ff::Field;
use ark_groth16::{Groth16, Proof, ProvingKey};
use ark_relations::r1cs::{ConstraintSynthesizer, ConstraintSystem};
use ark_std::rand::{CryptoRng, RngCore};
use hex::encode as hex_encode;
use sha2::{Digest, Sha256};

use crate::circuit::{IdentityOpeningCircuit, MulCircuit, RICE_IDENTITY_POSEIDON_DOMAIN, ShieldedTransferCircuit};
use crate::error::PrivateError;
use crate::identity::IdentityWitness;
use crate::field::{FrBn254, poseidon_commit_digest_bn254, poseidon_nullifier_digest_bn254};
use crate::serial::{
    ComplianceMask, ComplianceOperation, VaultEnvelope, VaultMasterKeySource, proof_to_bytes_compressed,
};
use crate::setup::{IdentityOpeningRice, ParameterStore, RiceCircuit, ShieldedTransferRice, get_or_generate_params};

/// Hint for batch proving pipelines (scheduling / future amortization). `None` if unset or invalid.
pub const RICE_ZK_BATCH_SIZE_ENV: &str = "RICE_ZK_BATCH_SIZE";

/// When set to `1` / `true` / `yes`, a GPU prover may be selected once implemented ([`CudaProverPlaceholder`]).
pub const RICE_ZK_CUDA_ENV: &str = "RICE_ZK_CUDA";

/// Optional Rayon thread count for the dedicated ZK pool (defaults to Rayon’s global default).
pub const RICE_ZK_RAYON_THREADS_ENV: &str = "RICE_ZK_RAYON_THREADS";

static ZK_RAYON_POOL: OnceLock<rayon::ThreadPool> = OnceLock::new();

/// Dedicated Rayon pool for ZK (ark Groth16 `parallel` also uses Rayon globally; this pool is for
/// isolating thread counts via [`RICE_ZK_RAYON_THREADS_ENV`] when future work is `install`d here).
#[inline]
pub fn zk_rayon_pool() -> &'static rayon::ThreadPool {
    ZK_RAYON_POOL.get_or_init(|| {
        let threads = std::env::var(RICE_ZK_RAYON_THREADS_ENV)
            .ok()
            .and_then(|s| s.parse::<usize>().ok())
            .filter(|&n| n > 0)
            .unwrap_or_else(rayon::current_num_threads);
        rayon::ThreadPoolBuilder::new()
            .num_threads(threads)
            .thread_name(|i| format!("rice-zk-{i}"))
            .build()
            .expect("rice-zk rayon pool")
    })
}

#[inline]
pub fn batch_prove_configured_size_hint() -> Option<usize> {
    std::env::var(RICE_ZK_BATCH_SIZE_ENV).ok()?.parse().ok()
}

#[inline]
pub fn cuda_acceleration_requested() -> bool {
    matches!(
        std::env::var(RICE_ZK_CUDA_ENV).map(|s| s.to_ascii_lowercase()).as_deref(),
        Ok("1") | Ok("true") | Ok("yes")
    )
}

/// Reserved for a future CUDA / GPU prover backend.
#[derive(Clone, Copy, Debug, Default)]
pub struct CudaProverPlaceholder;

/// Short fingerprint for logs (first 4 bytes of SHA-256 over compressed proof).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct ProofId(pub [u8; 4]);

impl fmt::Display for ProofId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", hex_encode(self.0))
    }
}

#[inline]
pub fn proof_fingerprint<E: Pairing>(proof: &Proof<E>) -> Result<ProofId, PrivateError> {
    let b = proof_to_bytes_compressed(proof)?;
    let h = Sha256::digest(b.as_ref());
    Ok(ProofId(h[..4].try_into().expect("sha256 yields at least 4 bytes")))
}

/// Run `circuit` in a fresh constraint system and require `cs.is_satisfied()`.
pub fn preflight_witness_satisfied<E, CS>(circuit: CS) -> Result<(), PrivateError>
where
    E: Pairing,
    CS: ConstraintSynthesizer<E::ScalarField>,
{
    let cs = ConstraintSystem::<E::ScalarField>::new_ref();
    circuit.generate_constraints(cs.clone())?;
    if !cs.is_satisfied()? {
        return Err(PrivateError::WitnessInconsistent(
            "cs.is_satisfied() is false — witness does not match public inputs / constraints".into(),
        ));
    }
    Ok(())
}

/// Preflight + Groth16 prove on the ZK Rayon pool.
pub fn generate_proof<E, CS, R>(pk: &ProvingKey<E>, circuit: CS, rng: &mut R) -> Result<Proof<E>, PrivateError>
where
    E: Pairing,
    CS: ConstraintSynthesizer<E::ScalarField> + Clone,
    R: RngCore + CryptoRng,
{
    let span = tracing::info_span!(
        "rice.zk.prove",
        curve = core::any::type_name::<E>(),
        circuit = core::any::type_name::<CS>(),
    );
    let _enter = span.enter();

    if cuda_acceleration_requested() {
        tracing::debug!(target: "rice.zk.prove", "RICE_ZK_CUDA is set; GPU path not implemented in this crate");
    }
    if let Some(cap) = batch_prove_configured_size_hint() {
        tracing::trace!(target: "rice.zk.prove", batch_cap = cap, "RICE_ZK_BATCH_SIZE hint (single-proof call)");
    }

    preflight_witness_satisfied::<E, _>(circuit.clone())?;

    // Groth16 with `parallel` already parallelizes internally; keep prove on this thread so `rng` and
    // circuit need not be `Send` through a Rayon `install` boundary.
    let prove_span = tracing::debug_span!(parent: tracing::Span::current(), "rice.zk.prove.groth16");
    let _prove_enter = prove_span.enter();
    let proof = Groth16::<E>::prove(pk, circuit, rng)?;

    if let Ok(pid) = proof_fingerprint(&proof) {
        tracing::debug!(target: "rice.zk.prove", proof_id = %pid, "groth16 proof complete");
    }

    Ok(proof)
}

/// Load PK via [`ParameterStore::load_groth16_params`] for `RC`, then [`generate_proof`].
pub fn generate_proof_with_store<RC, E, R>(
    store: &ParameterStore,
    circuit: RC::CS,
    rng: &mut R,
) -> Result<Proof<E>, PrivateError>
where
    RC: RiceCircuit<E>,
    E: Pairing,
    RC::CS: ConstraintSynthesizer<E::ScalarField> + Clone,
    R: RngCore + CryptoRng,
{
    let params = store.load_groth16_params::<RC, E>()?;
    generate_proof(&params.pk, circuit, rng)
}

/// Prove many circuits **sequentially** (RNG advances). Honors [`RICE_ZK_BATCH_SIZE_ENV`] as a hard cap.
pub fn batch_generate_proofs<E, CS, R, I>(
    pk: &ProvingKey<E>,
    circuits: I,
    rng: &mut R,
) -> Result<Vec<Proof<E>>, PrivateError>
where
    E: Pairing,
    CS: ConstraintSynthesizer<E::ScalarField> + Clone,
    I: IntoIterator<Item = CS>,
    R: RngCore + CryptoRng,
{
    let _span = tracing::info_span!("rice.zk.prove.batch").entered();
    let cap = batch_prove_configured_size_hint();
    let mut proofs = Vec::new();
    for (idx, circuit) in circuits.into_iter().enumerate() {
        if let Some(max) = cap {
            if idx >= max {
                tracing::warn!(
                    target: "rice.zk.prove.batch",
                    index = idx,
                    max,
                    "RICE_ZK_BATCH_SIZE cap reached; stopping batch"
                );
                break;
            }
        }
        proofs.push(generate_proof(pk, circuit, rng)?);
    }
    Ok(proofs)
}

/// AEAD-wrap a proof for vault storage / transit ([`crate::serial`]).
pub fn seal_proof_for_vault<E: Pairing>(
    proof: &Proof<E>,
    key_src: &impl VaultMasterKeySource,
    mask: &ComplianceMask,
    op: ComplianceOperation,
    user_aad: &[u8],
    rng: &mut impl RngCore,
) -> Result<VaultEnvelope<Proof<E>>, PrivateError> {
    VaultEnvelope::seal_artifact(proof, key_src, mask, op, user_aad, rng)
}

// ---------------------------------------------------------------------------
// BN254 high-level provers
// ---------------------------------------------------------------------------

/// Identity opening proof: loads or dev-caches PK for [`IdentityOpeningRice`], builds the circuit, proves.
pub fn prove_identity<R: RngCore + CryptoRng>(
    store: &ParameterStore,
    w: IdentityWitness,
    rng: &mut R,
) -> Result<Proof<Bn254>, PrivateError> {
    let params = get_or_generate_params::<IdentityOpeningRice, Bn254, _>(store, rng)?;
    let commitment = poseidon_commit_digest_bn254(RICE_IDENTITY_POSEIDON_DOMAIN, w.secret, w.blinding);
    let nullifier = poseidon_nullifier_digest_bn254(w.secret, FrBn254::ZERO, w.nullifier_key);
    let circuit = IdentityOpeningCircuit {
        public_commitment_digest: Some(commitment),
        public_nullifier: Some(nullifier),
        secret: Some(w.secret),
        blinding: Some(w.blinding),
        nullifier_key: Some(w.nullifier_key),
    };
    generate_proof(&params.pk, circuit, rng)
}

/// Secret material for [`prove_shielded_transfer`].
pub struct ShieldedTransferWitness {
    pub secret: FrBn254,
    pub blinding: FrBn254,
    pub nullifier_key: FrBn254,
    pub v_in1: FrBn254,
    pub v_in2: FrBn254,
    pub v_out1: FrBn254,
    pub v_out2: FrBn254,
    pub fee: FrBn254,
}

/// Shielded transfer proof (balance + range + identity binding).
pub fn prove_shielded_transfer<R: RngCore + CryptoRng>(
    store: &ParameterStore,
    w: ShieldedTransferWitness,
    rng: &mut R,
) -> Result<Proof<Bn254>, PrivateError> {
    let params = get_or_generate_params::<ShieldedTransferRice, Bn254, _>(store, rng)?;
    let commitment = poseidon_commit_digest_bn254(RICE_IDENTITY_POSEIDON_DOMAIN, w.secret, w.blinding);
    let nullifier = poseidon_nullifier_digest_bn254(w.secret, FrBn254::ZERO, w.nullifier_key);
    let circuit = ShieldedTransferCircuit {
        public_commitment_digest: Some(commitment),
        public_nullifier: Some(nullifier),
        public_fee: Some(w.fee),
        secret: Some(w.secret),
        blinding: Some(w.blinding),
        nullifier_key: Some(w.nullifier_key),
        v_in1: Some(w.v_in1),
        v_in2: Some(w.v_in2),
        v_out1: Some(w.v_out1),
        v_out2: Some(w.v_out2),
    };
    generate_proof(&params.pk, circuit, rng)
}

/// Prove knowledge of `a`, `b` such that `a * b` equals the public input (see [`MulCircuit`]).
pub fn prove_mul<E: Pairing, R: RngCore + CryptoRng>(
    pk: &ProvingKey<E>,
    a: E::ScalarField,
    b: E::ScalarField,
    rng: &mut R,
) -> Result<Proof<E>, PrivateError> {
    let circuit = MulCircuit { a: Some(a), b: Some(b) };
    generate_proof(pk, circuit, rng)
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::sync::Mutex;

    use ark_std::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use super::*;
    use crate::setup::trusted_setup;

    static PROVE_ENV_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn witness_inconsistent_fails_fast() {
        let _g = PROVE_ENV_LOCK.lock().expect("lock");
        unsafe {
            std::env::remove_var("RICE_ENV");
        }
        let mut rng = StdRng::from_seed([5u8; 32]);
        let root = std::env::temp_dir().join(format!("rice-prove-preflight-{}", line!()));
        let _ = fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root.clone());
        let params = get_or_generate_params::<IdentityOpeningRice, Bn254, _>(&store, &mut rng).unwrap();

        let secret = FrBn254::from(11u64);
        let blinding = FrBn254::from(22u64);
        let nullifier_key = FrBn254::from(33u64);
        let commitment = poseidon_commit_digest_bn254(RICE_IDENTITY_POSEIDON_DOMAIN, secret, blinding);
        let nullifier_wrong = FrBn254::from(999u64);

        let circuit = IdentityOpeningCircuit {
            public_commitment_digest: Some(commitment),
            public_nullifier: Some(nullifier_wrong),
            secret: Some(secret),
            blinding: Some(blinding),
            nullifier_key: Some(nullifier_key),
        };
        let err = generate_proof(&params.pk, circuit, &mut rng).unwrap_err();
        assert!(matches!(err, PrivateError::WitnessInconsistent(_)));
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn prove_identity_smoke() {
        let _g = PROVE_ENV_LOCK.lock().expect("lock");
        unsafe {
            std::env::remove_var("RICE_ENV");
        }
        let mut rng = StdRng::from_seed([6u8; 32]);
        let root = std::env::temp_dir().join(format!("rice-prove-id-{}", line!()));
        let _ = fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root.clone());

        let w = IdentityWitness {
            secret: FrBn254::rand(&mut rng),
            blinding: FrBn254::rand(&mut rng),
            nullifier_key: FrBn254::rand(&mut rng),
        };
        let proof = prove_identity(&store, w, &mut rng).unwrap();
        let id = proof_fingerprint(&proof).unwrap();
        assert_eq!(id.to_string().len(), 8);
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn prove_mul_uses_pipeline() {
        let _g = PROVE_ENV_LOCK.lock().expect("lock");
        let mut rng = StdRng::from_seed([7u8; 32]);
        let pk = trusted_setup::<Bn254, _>(&mut rng).unwrap().0;
        let proof = prove_mul(&pk, FrBn254::from(3u64), FrBn254::from(4u64), &mut rng).unwrap();
        assert!(!proof_to_bytes_compressed(&proof).unwrap().is_empty());
    }
}
