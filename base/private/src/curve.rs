//! Pairing-friendly curves — BN254 (identity/balance templates) and BLS12-381 (compliance templates).

use ark_ec::pairing::Pairing;

// [ ] https://docs.rs/ark-groth16/ — ark-ec
// [ ] RICE_ZK_CURVE selector; MSM; pairing ops constant-time

pub use ark_bls12_381::Bls12_381;
pub use ark_bn254::Bn254;

pub type G1AffineBn254 = <Bn254 as Pairing>::G1Affine;
pub type G2AffineBn254 = <Bn254 as Pairing>::G2Affine;
pub type G1AffineBls12 = <Bls12_381 as Pairing>::G1Affine;
pub type G2AffineBls12 = <Bls12_381 as Pairing>::G2Affine;
