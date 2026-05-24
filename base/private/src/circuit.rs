//! R1CS circuits — constraint “factory” for `.rice` privacy: gadgets, identity, shielded balance, range.
//!
//! **BN254 focus:** Production identity pins [`crate::field::FrBn254`]. Poseidon parameters come from
//! [`crate::field::poseidon_config_bn254_rate2`] so native hooks ([`crate::field::poseidon_commit_digest_bn254`],
//! [`crate::field::poseidon_nullifier_digest_bn254`]) match in-circuit absorbs byte-for-byte.
//!
//! **Gadgets** live in [`gadgets`] — small reusable pieces composed by [`IdentityOpeningCircuit`] and
//! [`ShieldedTransferCircuit`] (shielded transfer = balance conservation + range + identity binding).

use ark_crypto_primitives::sponge::constraints::CryptographicSpongeVar;
use ark_crypto_primitives::sponge::poseidon::PoseidonConfig;
use ark_crypto_primitives::sponge::poseidon::constraints::PoseidonSpongeVar;
use ark_ff::Field;
use ark_r1cs_std::fields::fp::FpVar;
use ark_r1cs_std::prelude::*;
use ark_relations::r1cs::{ConstraintSynthesizer, ConstraintSystemRef, SynthesisError};
use ark_relations::{lc, ns};

use crate::field::{FrBn254, poseidon_config_bn254_rate2};

// ---------------------------------------------------------------------------
// Domains (must match native [`crate::field`] / prover witness generation)
// ---------------------------------------------------------------------------

/// Domain tag for Poseidon **identity commitment** (`secret`, `blinding`); keep in sync with provers.
pub const CLERK_IDENTITY_POSEIDON_DOMAIN: u64 = 7;

// ---------------------------------------------------------------------------
// Gadgets
// ---------------------------------------------------------------------------

pub mod gadgets {
    use super::*;

    /// Poseidon absorb order: `domain || secret || blinding` → one field (matches [`crate::field::poseidon_commit_digest_bn254`]).
    pub fn poseidon_commitment_digest_var(
        cs: ConstraintSystemRef<FrBn254>,
        params: &PoseidonConfig<FrBn254>,
        domain: u64,
        secret: &FpVar<FrBn254>,
        blinding: &FpVar<FrBn254>,
    ) -> Result<FpVar<FrBn254>, SynthesisError> {
        let mut sponge = PoseidonSpongeVar::new(cs.clone(), params);
        let d = FpVar::constant(FrBn254::from(domain));
        sponge.absorb(&d)?;
        sponge.absorb(secret)?;
        sponge.absorb(blinding)?;
        let out = sponge.squeeze_field_elements(1)?;
        Ok(out[0].clone())
    }

    /// Nullifier arm: `0x4E4C || secret || external || nullifier_key` (matches [`crate::field::poseidon_nullifier_digest_bn254`]).
    pub fn poseidon_nullifier_digest_var(
        cs: ConstraintSystemRef<FrBn254>,
        params: &PoseidonConfig<FrBn254>,
        secret: &FpVar<FrBn254>,
        external: &FpVar<FrBn254>,
        nullifier_key: &FpVar<FrBn254>,
    ) -> Result<FpVar<FrBn254>, SynthesisError> {
        let mut sponge = PoseidonSpongeVar::new(cs.clone(), params);
        let tag = FpVar::constant(FrBn254::from(0x4E4Cu64));
        sponge.absorb(&tag)?;
        sponge.absorb(secret)?;
        sponge.absorb(external)?;
        sponge.absorb(nullifier_key)?;
        let out = sponge.squeeze_field_elements(1)?;
        Ok(out[0].clone())
    }

    /// Enforce `sum(in) = sum(out) + fee` on shielded amounts (all witnesses except `fee` public input).
    pub fn shielded_balance_equation(
        v_in1: &FpVar<FrBn254>,
        v_in2: &FpVar<FrBn254>,
        v_out1: &FpVar<FrBn254>,
        v_out2: &FpVar<FrBn254>,
        fee: &FpVar<FrBn254>,
    ) -> Result<(), SynthesisError> {
        let lhs = v_in1 + v_in2;
        let rhs = v_out1 + v_out2 + fee;
        lhs.enforce_equal(&rhs)?;
        Ok(())
    }

    /// Range proof: hidden value fits in **64 bits** (no negative / overflow-to-negative in u64 semantics).
    pub fn range_proof_u64(cs: ConstraintSystemRef<FrBn254>, x: &FpVar<FrBn254>) -> Result<(), SynthesisError> {
        let _ = ns!(cs, "range_u64");
        let bits = x.to_bits_le()?;
        for bit in bits.iter().skip(64) {
            bit.enforce_equal(&Boolean::FALSE)?;
        }
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Identity: opening → public commitment + nullifier
// ---------------------------------------------------------------------------

/// Proves knowledge of a Poseidon commitment opening whose nullifier (with `external = 0`) is published.
#[derive(Clone, Debug)]
pub struct IdentityOpeningCircuit {
    pub public_commitment_digest: Option<FrBn254>,
    pub public_nullifier: Option<FrBn254>,
    pub secret: Option<FrBn254>,
    pub blinding: Option<FrBn254>,
    pub nullifier_key: Option<FrBn254>,
}

impl IdentityOpeningCircuit {
    pub fn for_setup() -> Self {
        Self {
            public_commitment_digest: None,
            public_nullifier: None,
            secret: None,
            blinding: None,
            nullifier_key: None,
        }
    }
}

impl ConstraintSynthesizer<FrBn254> for IdentityOpeningCircuit {
    fn generate_constraints(self, cs: ConstraintSystemRef<FrBn254>) -> Result<(), SynthesisError> {
        let params = poseidon_config_bn254_rate2().clone();

        let secret = FpVar::new_witness(cs.clone(), || self.secret.ok_or(SynthesisError::AssignmentMissing))?;
        let blinding = FpVar::new_witness(cs.clone(), || self.blinding.ok_or(SynthesisError::AssignmentMissing))?;
        let nullifier_key =
            FpVar::new_witness(cs.clone(), || self.nullifier_key.ok_or(SynthesisError::AssignmentMissing))?;

        let pub_commit = FpVar::new_input(cs.clone(), || {
            self.public_commitment_digest.ok_or(SynthesisError::AssignmentMissing)
        })?;
        let pub_null = FpVar::new_input(cs.clone(), || self.public_nullifier.ok_or(SynthesisError::AssignmentMissing))?;

        let c = gadgets::poseidon_commitment_digest_var(
            cs.clone(),
            &params,
            CLERK_IDENTITY_POSEIDON_DOMAIN,
            &secret,
            &blinding,
        )?;
        c.enforce_equal(&pub_commit)?;

        let ext_zero = FpVar::constant(FrBn254::ZERO);
        let nf = gadgets::poseidon_nullifier_digest_var(cs.clone(), &params, &secret, &ext_zero, &nullifier_key)?;
        nf.enforce_equal(&pub_null)?;

        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Shielded transfer: balance + u64 range + identity binding
// ---------------------------------------------------------------------------

/// Shielded transfer “brain”: conservation of value across two inputs / two outputs, **public fee**,
/// 64-bit range on each amount, and identity commitment + nullifier (same statement as [`IdentityOpeningCircuit`]).
#[derive(Clone, Debug)]
pub struct ShieldedTransferCircuit {
    pub public_commitment_digest: Option<FrBn254>,
    pub public_nullifier: Option<FrBn254>,
    pub public_fee: Option<FrBn254>,
    pub secret: Option<FrBn254>,
    pub blinding: Option<FrBn254>,
    pub nullifier_key: Option<FrBn254>,
    pub v_in1: Option<FrBn254>,
    pub v_in2: Option<FrBn254>,
    pub v_out1: Option<FrBn254>,
    pub v_out2: Option<FrBn254>,
}

impl ShieldedTransferCircuit {
    pub fn for_setup() -> Self {
        Self {
            public_commitment_digest: None,
            public_nullifier: None,
            public_fee: None,
            secret: None,
            blinding: None,
            nullifier_key: None,
            v_in1: None,
            v_in2: None,
            v_out1: None,
            v_out2: None,
        }
    }
}

impl ConstraintSynthesizer<FrBn254> for ShieldedTransferCircuit {
    fn generate_constraints(self, cs: ConstraintSystemRef<FrBn254>) -> Result<(), SynthesisError> {
        let params = poseidon_config_bn254_rate2().clone();

        let secret = FpVar::new_witness(cs.clone(), || self.secret.ok_or(SynthesisError::AssignmentMissing))?;
        let blinding = FpVar::new_witness(cs.clone(), || self.blinding.ok_or(SynthesisError::AssignmentMissing))?;
        let nullifier_key =
            FpVar::new_witness(cs.clone(), || self.nullifier_key.ok_or(SynthesisError::AssignmentMissing))?;

        let v_in1 = FpVar::new_witness(cs.clone(), || self.v_in1.ok_or(SynthesisError::AssignmentMissing))?;
        let v_in2 = FpVar::new_witness(cs.clone(), || self.v_in2.ok_or(SynthesisError::AssignmentMissing))?;
        let v_out1 = FpVar::new_witness(cs.clone(), || self.v_out1.ok_or(SynthesisError::AssignmentMissing))?;
        let v_out2 = FpVar::new_witness(cs.clone(), || self.v_out2.ok_or(SynthesisError::AssignmentMissing))?;

        let pub_commit = FpVar::new_input(cs.clone(), || {
            self.public_commitment_digest.ok_or(SynthesisError::AssignmentMissing)
        })?;
        let pub_null = FpVar::new_input(cs.clone(), || self.public_nullifier.ok_or(SynthesisError::AssignmentMissing))?;
        let fee = FpVar::new_input(cs.clone(), || self.public_fee.ok_or(SynthesisError::AssignmentMissing))?;

        gadgets::range_proof_u64(cs.clone(), &v_in1)?;
        gadgets::range_proof_u64(cs.clone(), &v_in2)?;
        gadgets::range_proof_u64(cs.clone(), &v_out1)?;
        gadgets::range_proof_u64(cs.clone(), &v_out2)?;

        gadgets::shielded_balance_equation(&v_in1, &v_in2, &v_out1, &v_out2, &fee)?;

        let c = gadgets::poseidon_commitment_digest_var(
            cs.clone(),
            &params,
            CLERK_IDENTITY_POSEIDON_DOMAIN,
            &secret,
            &blinding,
        )?;
        c.enforce_equal(&pub_commit)?;

        let ext_zero = FpVar::constant(FrBn254::ZERO);
        let nf = gadgets::poseidon_nullifier_digest_var(cs.clone(), &params, &secret, &ext_zero, &nullifier_key)?;
        nf.enforce_equal(&pub_null)?;

        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Harness (toy)
// ---------------------------------------------------------------------------

/// Multiplicative constraint: enforce `a * b = c` where `c` is a **public** input.
#[derive(Clone, Debug)]
pub struct MulCircuit<F: Field> {
    pub a: Option<F>,
    pub b: Option<F>,
}

impl<F: Field> MulCircuit<F> {
    /// Circuit with unknown witness — used only for **trusted setup** sizing.
    pub fn for_setup() -> Self {
        Self { a: None, b: None }
    }
}

impl<F: Field> ConstraintSynthesizer<F> for MulCircuit<F> {
    fn generate_constraints(self, cs: ConstraintSystemRef<F>) -> Result<(), SynthesisError> {
        let a = cs.new_witness_variable(|| self.a.ok_or(SynthesisError::AssignmentMissing))?;
        let b = cs.new_witness_variable(|| self.b.ok_or(SynthesisError::AssignmentMissing))?;
        let c = cs.new_input_variable(|| {
            let mut a = self.a.ok_or(SynthesisError::AssignmentMissing)?;
            let b = self.b.ok_or(SynthesisError::AssignmentMissing)?;
            a *= &b;
            Ok(a)
        })?;

        cs.enforce_constraint(lc!() + a, lc!() + b, lc!() + c)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ark_relations::r1cs::ConstraintSystem;
    use ark_std::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use crate::field::{poseidon_commit_digest_bn254, poseidon_nullifier_digest_bn254};

    #[test]
    fn identity_opening_satisfied_matches_native_poseidon() {
        let mut rng = StdRng::from_seed([42u8; 32]);
        let secret = FrBn254::rand(&mut rng);
        let blinding = FrBn254::rand(&mut rng);
        let nullifier_key = FrBn254::rand(&mut rng);

        let c = poseidon_commit_digest_bn254(CLERK_IDENTITY_POSEIDON_DOMAIN, secret, blinding);
        let nf = poseidon_nullifier_digest_bn254(secret, FrBn254::ZERO, nullifier_key);

        let cs = ConstraintSystem::<FrBn254>::new_ref();
        let circuit = IdentityOpeningCircuit {
            public_commitment_digest: Some(c),
            public_nullifier: Some(nf),
            secret: Some(secret),
            blinding: Some(blinding),
            nullifier_key: Some(nullifier_key),
        };
        circuit.generate_constraints(cs.clone()).unwrap();
        assert!(cs.is_satisfied().unwrap());
    }

    #[test]
    fn shielded_transfer_satisfied() {
        let mut rng = StdRng::from_seed([43u8; 32]);
        let secret = FrBn254::rand(&mut rng);
        let blinding = FrBn254::rand(&mut rng);
        let nullifier_key = FrBn254::rand(&mut rng);

        let v_in1 = FrBn254::from(50u64);
        let v_in2 = FrBn254::from(30u64);
        let v_out1 = FrBn254::from(60u64);
        let v_out2 = FrBn254::from(15u64);
        let fee = FrBn254::from(5u64);

        let c = poseidon_commit_digest_bn254(CLERK_IDENTITY_POSEIDON_DOMAIN, secret, blinding);
        let nf = poseidon_nullifier_digest_bn254(secret, FrBn254::ZERO, nullifier_key);

        let cs = ConstraintSystem::<FrBn254>::new_ref();
        let circuit = ShieldedTransferCircuit {
            public_commitment_digest: Some(c),
            public_nullifier: Some(nf),
            public_fee: Some(fee),
            secret: Some(secret),
            blinding: Some(blinding),
            nullifier_key: Some(nullifier_key),
            v_in1: Some(v_in1),
            v_in2: Some(v_in2),
            v_out1: Some(v_out1),
            v_out2: Some(v_out2),
        };
        circuit.generate_constraints(cs.clone()).unwrap();
        assert!(cs.is_satisfied().unwrap());
    }
}
