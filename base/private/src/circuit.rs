//! R1CS circuits — constraint system wiring for Groth16 (witness + public inputs).

use ark_ff::Field;
use ark_relations::{
    lc,
    r1cs::{ConstraintSynthesizer, ConstraintSystemRef, SynthesisError},
};

// [ ] https://docs.rs/ark-groth16/ — ark-ff, ConstraintSynthesizer
// [ ] BalanceCircuit, IdentityCircuit, ComplianceCircuit, RangeProofCircuit; Poseidon RICE_ZK_POSEIDON_PARAMS

/// Multiplicative constraint: enforce `a * b = c` where `c` is a **public** input.
///
/// This is a minimal teaching / harness circuit; replace with domain-specific gadgets
/// (commitments, hashes, range checks) in `identity`, `balance`, and `compliance`.
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
