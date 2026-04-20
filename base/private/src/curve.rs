//! Pairing-friendly curves as the **adaptive shield** for `.rice` private verification.
//!
//! # Quantum and hybrid context (operational, not a formal proof)
//!
//! - **BN254 — “daily speed.”** Optimized for fast Groth16 and L2-style throughput. The curve authors
//!   and community note it does **not** meet a 128-bit **classical** pairing security target today;
//!   treat it as a performance tier where latency matters more than decades-long binding strength.
//! - **BLS12-381 — “deep privacy.”** Wider margin for classical attacks on the pairing; better
//!   default when commitments and keys must age with policy-heavy or compliance-facing data.
//! - **Neither** curve is **post-quantum** for hidden-order / discrete-log assumptions: a
//!   cryptographically relevant quantum computer breaks the usual ECDLP / pairing hardness models
//!   underlying these SNARKs. The [`HybridPoint`] and [`HybridSecurityRequirement`] types document
//!   how CLERK will **layer** lattice / hash-based bindings (PQ signatures, commitments) **beside**
//!   curve proofs so policy can demand **both** where “high security” is triggered.
//!
//! Security **bit** figures in [`PairingSecurityBits`] are **rough engineering heuristics** for
//! capacity planning; rotate curves and PQ hybrids when standards move.

use ark_ec::pairing::{Pairing, PairingOutput};
use ark_ec::{AffineRepr, CurveGroup, Group, VariableBaseMSM};

pub use ark_bls12_381::Bls12_381;
pub use ark_bn254::Bn254;

use crate::error::PrivateError;

// ---------------------------------------------------------------------------
// Type aliases (wire / circuit ergonomics)
// ---------------------------------------------------------------------------

pub type G1AffineBn254 = <Bn254 as Pairing>::G1Affine;
pub type G2AffineBn254 = <Bn254 as Pairing>::G2Affine;
pub type G1AffineBls12 = <Bls12_381 as Pairing>::G1Affine;
pub type G2AffineBls12 = <Bls12_381 as Pairing>::G2Affine;

pub type GtBn254 = PairingOutput<Bn254>;
pub type GtBls12 = PairingOutput<Bls12_381>;

// ---------------------------------------------------------------------------
// Security taxonomy
// ---------------------------------------------------------------------------

/// How `.rice` classifies a curve for product and policy narration.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub enum CurveTier {
    /// BN254-class: prioritize prover/verifier latency and ecosystem compatibility.
    ///
    /// **Quantum / classical caveat:** pairing-friendly curves at this size trade long-horizon
    /// classical margin for speed; they are **not** a PQ shield on their own.
    DailySpeed,
    /// BLS12-381-class: higher classical pairing margin for long-lived private state.
    ///
    /// Still **not** post-quantum for underlying discrete-log assumptions; use with [`HybridPoint`]
    /// when PQ bindings are required.
    DeepPrivacy,
}

/// Estimated pairing-relevant strength (informative only).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct PairingSecurityBits {
    /// Approximate classical security for the pairing setting (see curve-specific docs).
    pub classical_pairing_bits: u32,
    /// Conservative **operational** target under quantum adversary models for the **same** curve
    /// (e.g. Grover-style square-root effects on symmetric analogies — **not** a theorem for pairings).
    pub quantum_estimate_bits: u32,
}

// ---------------------------------------------------------------------------
// RiceCurve
// ---------------------------------------------------------------------------

/// Unified pairing surface for BN254, BLS12-381, and future ark [`Pairing`] engines in CLERK.
///
/// **Why:** Verifiers should call one vocabulary for `e(G1, G2) → GT`, MSM, and security metadata
/// instead of scattering curve-specific helpers.
pub trait RiceCurve: Pairing + Sized + 'static {
    /// Human-readable curve id (logs, `CurveMismatch` strings).
    fn curve_name() -> &'static str;

    /// [`CurveTier`] for routing: hot path vs deep privacy.
    fn tier() -> CurveTier;

    /// Estimated classical vs quantum **heuristic** pairing strength.
    fn pairing_security_bits() -> PairingSecurityBits;

    /// Single pairing `e(g1, g2)` into the target group (Groth16 / KZG verification core).
    #[inline]
    fn pairing_gt(
        g1: impl Into<Self::G1Prepared>,
        g2: impl Into<Self::G2Prepared>,
    ) -> PairingOutput<Self> {
        Self::pairing(g1, g2)
    }

    /// Multi-scalar multiplication on **G1** (affine bases) — Pippenger-style internally when enabled.
    #[inline]
    fn msm_g1(
        bases: &[Self::G1Affine],
        scalars: &[Self::ScalarField],
    ) -> Result<Self::G1, usize> {
        Self::G1::msm(bases, scalars)
    }

    /// Multi-scalar multiplication on **G2** (affine bases).
    #[inline]
    fn msm_g2(
        bases: &[Self::G2Affine],
        scalars: &[Self::ScalarField],
    ) -> Result<Self::G2, usize> {
        Self::G2::msm(bases, scalars)
    }
}

impl RiceCurve for Bn254 {
    fn curve_name() -> &'static str {
        "BN254"
    }

    fn tier() -> CurveTier {
        CurveTier::DailySpeed
    }

    fn pairing_security_bits() -> PairingSecurityBits {
        // ark-bn254 documents that 128-bit classical pairing security is not met; ~100-bit class is a
        // common operational ballpark — round conservatively for planning.
        PairingSecurityBits {
            classical_pairing_bits: 100,
            quantum_estimate_bits: 60,
        }
    }
}

impl RiceCurve for Bls12_381 {
    fn curve_name() -> &'static str {
        "BLS12-381"
    }

    fn tier() -> CurveTier {
        CurveTier::DeepPrivacy
    }

    fn pairing_security_bits() -> PairingSecurityBits {
        PairingSecurityBits {
            classical_pairing_bits: 128,
            quantum_estimate_bits: 85,
        }
    }
}

// ---------------------------------------------------------------------------
// Pairing & MSM (free functions; mirror [`RiceCurve`] for turbofish ergonomics)
// ---------------------------------------------------------------------------

/// `e(g1, g2)` — pairing into `GT`.
#[inline]
pub fn pairing_e<E: Pairing>(
    g1: impl Into<E::G1Prepared>,
    g2: impl Into<E::G2Prepared>,
) -> PairingOutput<E> {
    E::pairing(g1, g2)
}

/// Variable-base MSM on G1 (ark’s optimized path; **requires** `bases.len() == scalars.len()`).
#[inline]
pub fn msm_g1_affine<E: Pairing>(
    bases: &[E::G1Affine],
    scalars: &[E::ScalarField],
) -> Result<E::G1, usize> {
    E::G1::msm(bases, scalars)
}

/// Variable-base MSM on G2.
#[inline]
pub fn msm_g2_affine<E: Pairing>(
    bases: &[E::G2Affine],
    scalars: &[E::ScalarField],
) -> Result<E::G2, usize> {
    E::G2::msm(bases, scalars)
}

// ---------------------------------------------------------------------------
// Dynamic hardening (“escape”): scalar salt blinding
// ---------------------------------------------------------------------------

/// Add `[salt]·G` to `p` in **G1** (affine in / affine out).
///
/// **Why:** Re-randomization-style entropy injection before publishing handles or transcript
/// binding. Pairings remain **well-defined** on the new point; **your verification equation must
/// account for the extra generator term** (same as standard blinding in Groth16-style proofs).
#[inline]
pub fn harden_g1<E: Pairing>(p: E::G1Affine, salt: E::ScalarField) -> E::G1Affine {
    let g = E::G1::generator();
    (g * salt + p.into_group()).into_affine()
}

/// Same pattern on **G2** (e.g. when blinding CRS / witness columns on the twist side).
#[inline]
pub fn harden_g2<E: Pairing>(p: E::G2Affine, salt: E::ScalarField) -> E::G2Affine {
    let g = E::G2::generator();
    (g * salt + p.into_group()).into_affine()
}

// ---------------------------------------------------------------------------
// Hybrid PQ layering (placeholders + policy gate)
// ---------------------------------------------------------------------------

/// Opaque bytes reserved for a **lattice / hash-based** binding (ML-DSA, SLH-DSA, Kyber-wrapped
/// symmetric keys, etc.) alongside an elliptic point.
///
/// **Why:** PQ primitives are not drop-in replacements for pairings; CLERK carries **both** lanes
/// until circuits absorb pure PQ statements.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct PqLatticeCommitmentPlaceholder {
    /// PQ signature, commitment opening, or serialized lattice vector — format TBD by SMITH/infra.
    pub opaque: Vec<u8>,
}

/// A **G1** handle plus optional PQ material for hybrid unlock flows.
#[derive(Clone, Debug)]
pub struct HybridPoint<E: Pairing> {
    /// Classical elliptic commitment / public input column.
    pub g1: E::G1Affine,
    /// PQ-side binding; [`None`] when the deployment is elliptic-only.
    pub pq_binding: Option<PqLatticeCommitmentPlaceholder>,
}

impl<E: Pairing> HybridPoint<E> {
    /// Elliptic-only shield (default SNARK path).
    #[inline]
    pub fn elliptic_only(g1: E::G1Affine) -> Self {
        Self {
            g1,
            pq_binding: None,
        }
    }

    /// Attach PQ placeholder bytes next to the curve point.
    #[inline]
    pub fn with_pq(g1: E::G1Affine, pq: PqLatticeCommitmentPlaceholder) -> Self {
        Self {
            g1,
            pq_binding: Some(pq),
        }
    }
}

/// Policy knob: when **high security** is on, verifiers require **both** SNARK validity and a PQ proof.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub enum HybridSecurityRequirement {
    /// Pairing / SNARK verification suffices.
    EllipticOnly,
    /// Require elliptic proof **and** a PQ signature / binding present on [`HybridPoint::pq_binding`].
    HybridEllipticAndPq,
}

/// Enforce that `point` satisfies `requirement` before accepting a private unlock (policy guard).
///
/// **Returns:** [`PrivateError::ComplianceVeto`] when high-security mode expects PQ material that is
/// missing or empty.
#[inline]
pub fn assert_hybrid_unlock_ready<E: Pairing>(
    point: &HybridPoint<E>,
    requirement: HybridSecurityRequirement,
) -> Result<(), PrivateError> {
    match requirement {
        HybridSecurityRequirement::EllipticOnly => Ok(()),
        HybridSecurityRequirement::HybridEllipticAndPq => {
            let Some(pq) = point.pq_binding.as_ref() else {
                return Err(PrivateError::ComplianceVeto(
                    "high-security hybrid mode requires PQ binding alongside the elliptic point"
                        .into(),
                ));
            };
            if pq.opaque.is_empty() {
                return Err(PrivateError::ComplianceVeto(
                    "high-security hybrid mode requires non-empty PQ commitment / signature bytes"
                        .into(),
                ));
            }
            Ok(())
        }
    }
}

/// Combine ZK verification outcome with PQ verification for hybrid unlock.
///
/// **Why:** Keeps “classical SNARK passed” separate from “PQ signature verified” so telemetry and
/// policy can branch without conflating failure modes.
#[inline]
pub fn hybrid_unlock_ok(
    requirement: HybridSecurityRequirement,
    zk_verified: bool,
    pq_verified: bool,
) -> Result<(), PrivateError> {
    match requirement {
        HybridSecurityRequirement::EllipticOnly => {
            if zk_verified {
                Ok(())
            } else {
                Err(PrivateError::ProofInvalid)
            }
        }
        HybridSecurityRequirement::HybridEllipticAndPq => {
            if zk_verified && pq_verified {
                Ok(())
            } else {
                Err(PrivateError::ComplianceVeto(
                    "hybrid unlock requires both valid ZK proof and valid PQ signature".into(),
                ))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ark_std::UniformRand;
    use ark_std::Zero;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    #[test]
    fn rice_curve_security_ordering() {
        let bn = Bn254::pairing_security_bits();
        let bls = Bls12_381::pairing_security_bits();
        assert!(bls.classical_pairing_bits >= bn.classical_pairing_bits);
        assert_eq!(Bn254::tier(), CurveTier::DailySpeed);
        assert_eq!(Bls12_381::tier(), CurveTier::DeepPrivacy);
    }

    #[test]
    fn pairing_non_trivial_bn254() {
        let mut rng = StdRng::from_seed([42u8; 32]);
        let g1 = <Bn254 as Pairing>::G1::rand(&mut rng);
        let g2 = <Bn254 as Pairing>::G2::rand(&mut rng);
        let e = pairing_e::<Bn254>(g1, g2);
        assert!(!e.is_zero());
    }

    #[test]
    fn msm_g1_matches_linear_combo_bn254() {
        let mut rng = StdRng::from_seed([5u8; 32]);
        let a = G1AffineBn254::rand(&mut rng);
        let b = G1AffineBn254::rand(&mut rng);
        let sa = <Bn254 as Pairing>::ScalarField::rand(&mut rng);
        let sb = <Bn254 as Pairing>::ScalarField::rand(&mut rng);
        let expected = a.into_group() * sa + b.into_group() * sb;
        let got = msm_g1_affine::<Bn254>(&[a, b], &[sa, sb]).unwrap();
        assert_eq!(got.into_affine(), expected.into_affine());
    }

    #[test]
    fn harden_g1_is_homomorphic_blind_bn254() {
        let mut rng = StdRng::from_seed([8u8; 32]);
        let p = G1AffineBn254::rand(&mut rng);
        let salt = <Bn254 as Pairing>::ScalarField::rand(&mut rng);
        let hardened = harden_g1::<Bn254>(p, salt);
        let g = <Bn254 as Pairing>::G1::generator();
        let expected = (g * salt + p.into_group()).into_affine();
        assert_eq!(hardened, expected);
    }

    #[test]
    fn hybrid_unlock_gates() {
        let p = HybridPoint::<Bn254>::elliptic_only(G1AffineBn254::generator());
        assert!(assert_hybrid_unlock_ready(&p, HybridSecurityRequirement::EllipticOnly).is_ok());
        assert!(assert_hybrid_unlock_ready(&p, HybridSecurityRequirement::HybridEllipticAndPq).is_err());

        let hp = HybridPoint::<Bn254>::with_pq(
            G1AffineBn254::generator(),
            PqLatticeCommitmentPlaceholder {
                opaque: vec![1, 2, 3],
            },
        );
        assert!(assert_hybrid_unlock_ready(&hp, HybridSecurityRequirement::HybridEllipticAndPq).is_ok());
        assert!(hybrid_unlock_ok(
            HybridSecurityRequirement::HybridEllipticAndPq,
            true,
            false
        )
        .is_err());
        assert!(hybrid_unlock_ok(
            HybridSecurityRequirement::HybridEllipticAndPq,
            true,
            true
        )
        .is_ok());
    }
}
