//! RICE zero-knowledge layer — Groth16 over BN254 and BLS12-381, with auditable setup/prove/verify flow.
//!
//! The bundled [`circuit::MulCircuit`] is a minimal `a * b = public` R1CS for integration tests.
//! Domain modules (`identity`, `balance`, `compliance`) name the intended curves and proof types.

// [ ] https://docs.rs/ark-groth16/
// [ ] pub mod circuit, prove, verify, setup, identity, balance, compliance, curve, field, serial, error
// [ ] features bn254, bls12_381, parallel — paths from RICE_ZK_* env

pub mod balance;
pub mod circuit;
pub mod compliance;
pub mod curve;
pub mod error;
pub mod field;
pub mod identity;
pub mod prove;
pub mod serial;
pub mod setup;
pub mod verify;

pub use error::{CircuitError, ProofError, SerialError, SetupError, VerifyError};

#[cfg(test)]
mod tests {
    use ark_bn254::Bn254;
    use ark_ff::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use super::circuit::MulCircuit;
    use super::field::FrBn254;
    use super::prove::prove_mul;
    use super::serial::proof_to_bytes_compressed;
    use super::setup::trusted_setup;
    use super::verify::verify_mul;

    #[test]
    fn groth16_bn254_mul_roundtrip() {
        let mut rng = StdRng::from_seed([7u8; 32]);
        let (pk, vk) = trusted_setup::<Bn254, _>(&mut rng).unwrap();

        let a = FrBn254::rand(&mut rng);
        let b = FrBn254::rand(&mut rng);
        let mut c = a;
        c *= b;

        let proof = prove_mul(&pk, a, b, &mut rng).unwrap();
        assert!(verify_mul(&vk, c, &proof).unwrap());

        let bytes = proof_to_bytes_compressed(&proof).unwrap();
        assert!(!bytes.is_empty());

        let _sizing = MulCircuit::<FrBn254>::for_setup();
    }
}
