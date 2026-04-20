//! Groth16 verification — **math only**: no policy, no ledger I/O.
//!
//! **Technical vs invalid:** structural or backend failures return [`PrivateError::VerifyMalformed`];
//! a well-formed check that rejects the proof returns [`PrivateError::ProofInvalid`].
//!
//! **Telemetry:** spans use the `rice.zk.verify` target (OpenTelemetry via a `tracing` subscriber at
//! the OS boundary). **Batch:** [`batch_verify_proofs`] uses a random linear combination (one
//! `final_exponentiation` per chunk) when a chunk has length ≥ 2; chunk size is capped by
//! [`RICE_ZK_VERIFY_BATCH_SIZE_ENV`] when set.

use std::fmt;
use std::marker::PhantomData;

use crate::error::PrivateError;
use crate::setup::{ParameterStore, RiceCircuit};
use ark_crypto_primitives::snark::SNARK;
use ark_ec::pairing::Pairing;
use ark_ec::{AffineRepr, CurveGroup};
use ark_ff::{Field, PrimeField, UniformRand};
use ark_groth16::{Groth16, PreparedVerifyingKey, Proof, VerifyingKey, prepare_verifying_key};
use ark_relations::r1cs::ConstraintSynthesizer;
use ark_serialize::CanonicalSerialize;
use hex::encode as hex_encode;
use num_traits::{One, Zero};
use rand::rngs::OsRng;
use sha2::{Digest, Sha256};

/// Max proofs per random-linear batch chunk (`None` / invalid → no limit).
pub const RICE_ZK_VERIFY_BATCH_SIZE_ENV: &str = "RICE_ZK_VERIFY_BATCH_SIZE";

/// Short fingerprint for logs (first 4 bytes of SHA-256 over compressed public inputs).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct PublicInputsFingerprint(pub [u8; 4]);

impl fmt::Display for PublicInputsFingerprint {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", hex_encode(self.0))
    }
}

/// Canonical compressed encoding of `public_inputs`, then SHA-256 prefix (safe for logs).
pub fn public_inputs_fingerprint<E: Pairing>(
    public_inputs: &[E::ScalarField],
) -> Result<PublicInputsFingerprint, PrivateError> {
    let mut buf = Vec::new();
    for x in public_inputs {
        x.serialize_compressed(&mut buf)
            .map_err(|e| PrivateError::VerifyMalformed(e.to_string()))?;
    }
    let h = Sha256::digest(&buf);
    Ok(PublicInputsFingerprint(
        h[..4].try_into().expect("sha256 yields at least 4 bytes"),
    ))
}

#[inline]
fn expected_instance_len<E: Pairing>(vk: &VerifyingKey<E>) -> usize {
    vk.gamma_abc_g1.len().saturating_sub(1)
}

/// Ensures public input **count** matches the VK’s IC layout (order is the slice order).
#[inline]
pub fn assert_public_inputs_layout<E: Pairing>(
    vk: &VerifyingKey<E>,
    public_inputs: &[E::ScalarField],
) -> Result<(), PrivateError> {
    let expected = expected_instance_len(vk);
    let got = public_inputs.len();
    if got != expected {
        return Err(PrivateError::VerifyMalformed(format!(
            "public input count {got} does not match verifying key (expected {expected} for this circuit)"
        )));
    }
    Ok(())
}

#[inline]
fn verify_inner_processed<E: Pairing>(
    pvk: &PreparedVerifyingKey<E>,
    public_inputs: &[E::ScalarField],
    proof: &Proof<E>,
) -> Result<(), PrivateError> {
    match Groth16::<E>::verify_with_processed_vk(pvk, public_inputs, proof) {
        Ok(true) => Ok(()),
        Ok(false) => Err(PrivateError::ProofInvalid),
        Err(e) => Err(PrivateError::VerifyMalformed(e.to_string())),
    }
}

/// Fast path when the verifying key is already prepared (e.g. hot ledger loop).
pub fn verify_proof_prepared<E: Pairing>(
    pvk: &PreparedVerifyingKey<E>,
    public_inputs: &[E::ScalarField],
    proof: &Proof<E>,
) -> Result<(), PrivateError> {
    assert_public_inputs_layout(&pvk.vk, public_inputs)?;
    verify_inner_processed(pvk, public_inputs, proof)
}

/// Stateless Groth16 check: **VK + public inputs + proof** → ok or typed error.
pub fn verify_proof<E: Pairing>(
    vk: &VerifyingKey<E>,
    public_inputs: &[E::ScalarField],
    proof: &Proof<E>,
) -> Result<(), PrivateError> {
    assert_public_inputs_layout(vk, public_inputs)?;
    let inputs_fp = public_inputs_fingerprint::<E>(public_inputs).unwrap_or(PublicInputsFingerprint([0; 4]));
    let span = tracing::trace_span!(target: "rice.zk.verify", "groth16 verify", inputs_fp = %inputs_fp);
    let _g = span.enter();
    let pvk = prepare_verifying_key(vk);
    verify_inner_processed(&pvk, public_inputs, proof)
}

/// [`verify_proof`] but collapses all failures to `false` (use [`verify_proof`] when you need
/// [`ProofInvalid`] vs [`VerifyMalformed`](PrivateError::VerifyMalformed)).
#[inline]
pub fn verify_proof_bool<E: Pairing>(vk: &VerifyingKey<E>, public_inputs: &[E::ScalarField], proof: &Proof<E>) -> bool {
    verify_proof(vk, public_inputs, proof).is_ok()
}

/// Type-directed alias: ties the VK to a concrete `RiceCircuit` synthesizer at the callsite.
#[inline]
pub fn verify_proof_for_circuit<E, CS>(
    vk: &VerifyingKey<E>,
    public_inputs: &[E::ScalarField],
    proof: &Proof<E>,
) -> Result<(), PrivateError>
where
    E: Pairing,
    CS: ConstraintSynthesizer<E::ScalarField>,
{
    let _ = PhantomData::<CS>;
    verify_proof(vk, public_inputs, proof)
}

#[inline]
fn verify_batch_chunk_cap() -> usize {
    std::env::var(RICE_ZK_VERIFY_BATCH_SIZE_ENV)
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .filter(|&n| n > 0)
        .unwrap_or(usize::MAX)
}

fn batch_verify_chunk<E: Pairing>(
    pvk: &PreparedVerifyingKey<E>,
    items: &[(&[E::ScalarField], &Proof<E>)],
) -> Result<(), PrivateError> {
    if items.is_empty() {
        return Ok(());
    }
    if items.len() == 1 {
        return verify_proof_prepared(pvk, items[0].0, items[0].1);
    }

    let mut rng = OsRng;
    let mut scalars = Vec::with_capacity(items.len());
    scalars.push(E::ScalarField::one());
    for _ in 1..items.len() {
        scalars.push(E::ScalarField::rand(&mut rng));
    }
    let sum: E::ScalarField = scalars.iter().copied().fold(E::ScalarField::zero(), |a, b| a + b);

    let mut g1s = Vec::with_capacity(items.len() * 3);
    let mut g2s = Vec::with_capacity(items.len() * 3);

    for ((pub_in, proof), &s) in items.iter().zip(&scalars) {
        assert_public_inputs_layout(&pvk.vk, pub_in)?;
        let ic = Groth16::<E>::prepare_inputs(pvk, pub_in).map_err(|e| PrivateError::VerifyMalformed(e.to_string()))?;
        let sa = proof.a.into_group() * s;
        let sic = ic * s;
        let sc = proof.c.into_group() * s;
        g1s.push(sa.into_affine());
        g1s.push(sic.into_affine());
        g1s.push(sc.into_affine());
        g2s.push(proof.b.into());
        g2s.push(pvk.gamma_g2_neg_pc.clone());
        g2s.push(pvk.delta_g2_neg_pc.clone());
    }

    let qap = E::multi_miller_loop(g1s, g2s);
    let test = E::final_exponentiation(qap)
        .ok_or_else(|| PrivateError::VerifyMalformed("pairing final_exponentiation failed".into()))?;
    let expected = pvk.alpha_g1_beta_g2.pow(sum.into_bigint());

    if test.0 == expected {
        Ok(())
    } else {
        Err(PrivateError::ProofInvalid)
    }
}

/// Verify many proofs under the **same** verifying key; uses batched pairing when chunks are large.
pub fn batch_verify_proofs<E: Pairing>(
    vk: &VerifyingKey<E>,
    items: &[(&[E::ScalarField], &Proof<E>)],
) -> Result<(), PrivateError> {
    if items.is_empty() {
        return Ok(());
    }
    let cap = verify_batch_chunk_cap();
    let pvk = prepare_verifying_key(vk);
    let span = tracing::info_span!(
        target: "rice.zk.verify.batch",
        "groth16 batch verify",
        n = items.len(),
        chunk_cap = cap,
        vk_inputs = expected_instance_len(vk),
    );
    let _g = span.enter();
    for chunk in items.chunks(cap) {
        let cspan = tracing::trace_span!(
            target: "rice.zk.verify.batch",
            "chunk",
            chunk = chunk.len(),
        );
        let _c = cspan.enter();
        batch_verify_chunk(&pvk, chunk)?;
    }
    Ok(())
}

/// Load the mmap’d verifying key for `RC` and run [`verify_proof`].
pub fn verify_with_store<RC, E>(
    store: &ParameterStore,
    public_inputs: &[E::ScalarField],
    proof: &Proof<E>,
) -> Result<(), PrivateError>
where
    RC: RiceCircuit<E>,
    E: Pairing,
{
    let (vk, vk_id) = store.load_verifying_key::<RC, E>()?;
    let inputs_fp = public_inputs_fingerprint::<E>(public_inputs).unwrap_or(PublicInputsFingerprint([0; 4]));
    let span = tracing::debug_span!(
        target: "rice.zk.verify",
        "verify with parameter store",
        vk_id = %vk_id,
        inputs_fp = %inputs_fp,
        circuit = RC::circuit_id(),
    );
    let _g = span.enter();
    verify_proof(&vk, public_inputs, proof)
}

/// [`crate::circuit::MulCircuit`] integration — one public input (the product).
pub fn verify_mul<E: Pairing>(
    vk: &VerifyingKey<E>,
    public_c: E::ScalarField,
    proof: &Proof<E>,
) -> Result<(), PrivateError> {
    verify_proof(vk, &[public_c], proof)
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use ark_bn254::Bn254;
    use ark_ff::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use super::*;
    use crate::prove::prove_mul;
    use crate::setup::{MulCircuitRice, ParameterStore, get_or_generate_params, trusted_setup};

    static VERIFY_ENV_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn wrong_public_input_count_malformed() {
        let mut rng = StdRng::from_seed([3u8; 32]);
        let (pk, vk) = trusted_setup::<Bn254, _>(&mut rng).unwrap();
        let a = crate::field::FrBn254::rand(&mut rng);
        let b = crate::field::FrBn254::rand(&mut rng);
        let proof = prove_mul(&pk, a, b, &mut rng).unwrap();
        let err = verify_proof(&vk, &[], &proof).unwrap_err();
        assert!(matches!(err, PrivateError::VerifyMalformed(_)));
    }

    #[test]
    fn invalid_proof_rejected() {
        let mut rng = StdRng::from_seed([4u8; 32]);
        let (pk, vk) = trusted_setup::<Bn254, _>(&mut rng).unwrap();
        let a = crate::field::FrBn254::rand(&mut rng);
        let b = crate::field::FrBn254::rand(&mut rng);
        let mut c = a;
        c *= b;
        let mut proof = prove_mul(&pk, a, b, &mut rng).unwrap();
        proof.a = proof.c;
        let err = verify_mul(&vk, c, &proof).unwrap_err();
        assert!(matches!(err, PrivateError::ProofInvalid));
    }

    #[test]
    fn batch_two_mul_proofs() {
        let mut rng = StdRng::from_seed([5u8; 32]);
        let (pk, vk) = trusted_setup::<Bn254, _>(&mut rng).unwrap();
        let a1 = crate::field::FrBn254::rand(&mut rng);
        let b1 = crate::field::FrBn254::rand(&mut rng);
        let mut c1 = a1;
        c1 *= b1;
        let a2 = crate::field::FrBn254::rand(&mut rng);
        let b2 = crate::field::FrBn254::rand(&mut rng);
        let mut c2 = a2;
        c2 *= b2;
        let p1 = prove_mul(&pk, a1, b1, &mut rng).unwrap();
        let p2 = prove_mul(&pk, a2, b2, &mut rng).unwrap();
        batch_verify_proofs(&vk, &[(&[c1], &p1), (&[c2], &p2)]).unwrap();
    }

    #[test]
    fn verify_with_store_smoke() {
        let _guard = VERIFY_ENV_LOCK.lock().expect("verify test lock poisoned");
        unsafe {
            std::env::remove_var("RICE_ENV");
        }
        let root = std::env::temp_dir().join(format!(
            "rice-zk-verify-store-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_nanos())
                .unwrap_or(0)
        ));
        let _ = std::fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root.clone());
        let mut rng = StdRng::from_seed([8u8; 32]);
        let params = get_or_generate_params::<MulCircuitRice, Bn254, _>(&store, &mut rng).unwrap();
        let a = crate::field::FrBn254::rand(&mut rng);
        let b = crate::field::FrBn254::rand(&mut rng);
        let mut c = a;
        c *= b;
        let proof = prove_mul(&params.pk, a, b, &mut rng).unwrap();
        verify_with_store::<MulCircuitRice, Bn254>(&store, &[c], &proof).unwrap();
        let _ = std::fs::remove_dir_all(&root);
    }

    #[test]
    fn fingerprint_changes_with_inputs() {
        let a = crate::field::FrBn254::from(3u64);
        let b = crate::field::FrBn254::from(4u64);
        assert_ne!(
            public_inputs_fingerprint::<Bn254>(&[a]).unwrap(),
            public_inputs_fingerprint::<Bn254>(&[b]).unwrap()
        );
    }
}
