//! Prime field arithmetic — scalars for BN254 and BLS12-381 (and helpers over generic fields).

use ark_ff::{BigInteger, Field, PrimeField};

pub use ark_bls12_381::Fr as FrBls12;
pub use ark_bn254::Fr as FrBn254;

// [ ] https://docs.rs/ark-groth16/ — ark-ff, ark-serialize
// [ ] Fr/Fq ops; Poseidon RICE_ZK_POSEIDON_PARAMS; UniformRand OsRng

/// Multiply two field elements (R1CS gadgets will inline equivalent constraints in circuits).
#[inline]
pub fn mul<F: Field>(a: F, b: F) -> F {
    a * b
}

/// Invert when non-zero; maps 0 → None (caller must enforce in-circuit semantics separately).
#[inline]
pub fn inv<F: Field>(x: F) -> Option<F> {
    x.inverse()
}

/// Convert a prime-field element to a fixed-width big-endian byte representation (canonical).
pub fn fr_to_be_bytes<F: PrimeField>(x: F) -> Vec<u8> {
    x.into_bigint().to_bytes_be()
}
