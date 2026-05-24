//! Shielded ledger on **BN254** — multi-asset **policy** tags, Pedersen amount commitments, and
//! [`ShieldedTransferCircuit`] integration (64-bit range + value conservation + identity binding).
//!
//! **One proof = one asset type.** The Groth16 circuit enforces `v_in1 + v_in2 = v_out1 + v_out2 + fee`
//! on field witnesses with [`crate::circuit::gadgets::range_proof_u64`] on each leg. [`AssetType`] is
//! enforced **off-circuit** before proving so “Gold in → Gold out” is a ledger rule; extending the
//! R1CS with per-leg asset tags would be a future circuit revision.

pub use ark_bn254::Bn254;
pub use ark_groth16::{Proof, ProvingKey, VerifyingKey};

use ark_ec::{AffineRepr, CurveGroup};
use ark_std::rand::{CryptoRng, RngCore};
use num_bigint::BigUint;
use num_traits::ToPrimitive;
use sha2::{Digest, Sha256};

use crate::commitment::{CommitmentOpening, PedersenCommitment, PedersenGenerators};
use crate::error::PrivateError;
use crate::field::{FrBn254, Scalar, prime_field_from_be_bytes_strict};
use crate::identity::{IdentityAttestationPayload, PublicIdentityCommitment, SovereignIdentity};
use crate::prove::{ShieldedTransferWitness, prove_shielded_transfer};
use crate::setup::{ParameterStore, ShieldedTransferSetup};
use crate::verify;

pub type BalanceProof = Proof<Bn254>;

/// Domain separation for [`AssetType`] labels (UTF-8 commodity / ticker / SKU).
pub const CLERK_ASSET_LABEL_DOMAIN: &[u8] = b"rice.asset_type.v1";

// ---------------------------------------------------------------------------
// Asset tag (multi-asset)
// ---------------------------------------------------------------------------

/// ZK-friendly asset identifier: **Fr** derived from a canonical label hash (commodity, fiat code, …).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct AssetType(pub FrBn254);

impl AssetType {
    /// Hash a human-readable label into a field element (SHA-256 → strict canonical Fr).
    pub fn from_label(label: &str) -> Result<Self, PrivateError> {
        Ok(Self(hash_label_to_fr(label)?))
    }

    #[inline]
    pub fn as_field(&self) -> FrBn254 {
        self.0
    }

    /// Every [`ShieldedNote`] in a transfer must carry this tag (banker’s rule: no cross-asset mixing).
    #[inline]
    pub fn assert_note_matches(&self, note: &ShieldedNote) -> Result<(), PrivateError> {
        if note.asset_type != *self {
            return Err(PrivateError::CircuitConstraint(
                "shielded transfer mixes asset types (ledger rejected)".into(),
            ));
        }
        Ok(())
    }
}

fn hash_label_to_fr(label: &str) -> Result<FrBn254, PrivateError> {
    for attempt in 0u64..256 {
        let mut h = Sha256::new();
        h.update(CLERK_ASSET_LABEL_DOMAIN);
        h.update(label.as_bytes());
        h.update(attempt.to_le_bytes());
        let out = h.finalize();
        if let Ok(fr) = prime_field_from_be_bytes_strict::<FrBn254>(&out) {
            return Ok(fr);
        }
    }
    Err(PrivateError::FieldInvalid("failed to derive asset type Fr from label".into()))
}

// ---------------------------------------------------------------------------
// Shielded note (Pedersen amount + owner + asset)
// ---------------------------------------------------------------------------

/// A spendable cell: **asset**, Pedersen opening to **amount** (u64-sized in honest notes), and
/// **owner** identity commitment (Poseidon digest, same space as [`SovereignIdentity::public_commitment`]).
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ShieldedNote {
    pub asset_type: AssetType,
    /// Pedersen opening: `secret` should be `Fr::from(amount_u64)` for protocol-compliant notes.
    pub value: CommitmentOpening<FrBn254>,
    pub owner_commitment: FrBn254,
}

impl ShieldedNote {
    /// Construct a note whose amount fits the **64-bit** shielded range (enforced in-circuit on transfer).
    #[inline]
    pub fn new_bounded(
        asset_type: AssetType,
        amount: u64,
        value_blinding: FrBn254,
        owner: PublicIdentityCommitment,
    ) -> Self {
        Self {
            asset_type,
            value: CommitmentOpening {
                secret: FrBn254::from(amount),
                blinding: value_blinding,
            },
            owner_commitment: owner.0,
        }
    }

    #[inline]
    pub fn amount_pedersen(&self, gens: &PedersenGenerators<Bn254>) -> PedersenCommitment<Bn254> {
        PedersenCommitment::commit(gens, self.value.secret, self.value.blinding)
    }

    /// Homomorphic sum of amount commitments (same generators): commits to `v_a+v_b` with `r_a+r_b`.
    #[inline]
    pub fn combine_amount_commitments(
        a: &PedersenCommitment<Bn254>,
        b: &PedersenCommitment<Bn254>,
    ) -> PedersenCommitment<Bn254> {
        let p = a.point.into_group() + b.point.into_group();
        PedersenCommitment { point: p.into_affine() }
    }
}

// ---------------------------------------------------------------------------
// Banker’s rule (off-circuit, u128)
// ---------------------------------------------------------------------------

/// `in1 + in2 = out1 + out2 + fee` with no `u64` wrap in the accounting path.
#[inline]
pub fn assert_value_conservation_u64(in1: u64, in2: u64, out1: u64, out2: u64, fee: u64) -> Result<(), PrivateError> {
    let sum_in = (in1 as u128) + (in2 as u128);
    let sum_out = (out1 as u128) + (out2 as u128) + (fee as u128);
    if sum_in != sum_out {
        return Err(PrivateError::CircuitConstraint(format!(
            "value conservation violated: inputs {sum_in} != outputs+fee {sum_out}"
        )));
    }
    Ok(())
}

/// If `fr` encodes a small integral amount, recover it; otherwise reject (notes must use bounded amounts).
#[inline]
pub fn fr_as_u64_amount(fr: FrBn254) -> Result<u64, PrivateError> {
    let n = BigUint::from_bytes_be(&fr.to_be_bytes_fixed());
    let max = BigUint::from(u64::MAX);
    if n > max {
        return Err(PrivateError::FieldInvalid("field element does not fit u64 amount".into()));
    }
    let v = n
        .to_u64()
        .ok_or_else(|| PrivateError::FieldInvalid("u64 conversion failed".into()))?;
    if FrBn254::from(v) != fr {
        return Err(PrivateError::FieldInvalid("field element is not canonical u64 encoding".into()));
    }
    Ok(v)
}

// ---------------------------------------------------------------------------
// End-to-end transfer bundle
// ---------------------------------------------------------------------------

/// Fully specified **single-asset** shielded transfer: two inputs, two outputs, public fee, spender identity.
#[derive(Clone, Debug)]
pub struct ShieldedLedgerTransfer {
    pub asset: AssetType,
    pub input_left: ShieldedNote,
    pub input_right: ShieldedNote,
    pub output_left_amount: u64,
    pub output_right_amount: u64,
    pub fee: u64,
    pub spender: SovereignIdentity,
}

impl ShieldedLedgerTransfer {
    /// Enforce: matching asset tags, owner of both inputs is spender, u64 conservation, amounts in range.
    pub fn validate(&self) -> Result<(), PrivateError> {
        self.asset.assert_note_matches(&self.input_left)?;
        self.asset.assert_note_matches(&self.input_right)?;
        let oc = self.spender.public_commitment().0;
        if self.input_left.owner_commitment != oc || self.input_right.owner_commitment != oc {
            return Err(PrivateError::CircuitConstraint(
                "shielded inputs not owned by spender identity".into(),
            ));
        }
        let a = fr_as_u64_amount(self.input_left.value.secret)?;
        let b = fr_as_u64_amount(self.input_right.value.secret)?;
        assert_value_conservation_u64(a, b, self.output_left_amount, self.output_right_amount, self.fee)?;
        Ok(())
    }

    /// Build the Groth16 witness (range + conservation checked in-circuit; this must match [`validate`](Self::validate)).
    pub fn to_witness(&self) -> ShieldedTransferWitness {
        ShieldedTransferWitness {
            secret: self.spender.secret,
            blinding: self.spender.blinding,
            nullifier_key: self.spender.nullifier_key,
            v_in1: self.input_left.value.secret,
            v_in2: self.input_right.value.secret,
            v_out1: FrBn254::from(self.output_left_amount),
            v_out2: FrBn254::from(self.output_right_amount),
            fee: FrBn254::from(self.fee),
        }
    }
}

/// Prove after **off-circuit** ledger checks ([`ShieldedLedgerTransfer::validate`]).
#[inline]
pub fn prove_shielded_ledger_transfer<R: RngCore + CryptoRng>(
    store: &ParameterStore,
    xfer: &ShieldedLedgerTransfer,
    rng: &mut R,
) -> Result<Proof<Bn254>, PrivateError> {
    xfer.validate()?;
    prove_shielded_transfer(store, xfer.to_witness(), rng)
}

/// Verify shielded transfer proof against store VK (public inputs: commitment, nullifier, fee).
#[inline]
pub fn verify_shielded_ledger_transfer(
    store: &ParameterStore,
    identity_commitment: FrBn254,
    identity_nullifier: FrBn254,
    public_fee: FrBn254,
    proof: &Proof<Bn254>,
) -> Result<(), PrivateError> {
    verify::verify_with_store::<ShieldedTransferSetup, Bn254>(
        store,
        &[identity_commitment, identity_nullifier, public_fee],
        proof,
    )
}

// ---------------------------------------------------------------------------
// Mint authorization (real-world backing via identity attestation)
// ---------------------------------------------------------------------------

/// Declares mint of **`mint_amount`** units of **`asset`**, backed by an [`IdentityAttestationPayload`]
/// whose `binding_commitment` matches **`minter_identity`** (policy layer may require additional proofs).
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MintAuthorization {
    pub asset_type: AssetType,
    pub mint_amount: u64,
    pub minter_identity: PublicIdentityCommitment,
    pub backing_attestation: IdentityAttestationPayload,
}

impl MintAuthorization {
    pub fn new(
        asset_type: AssetType,
        mint_amount: u64,
        minter_identity: PublicIdentityCommitment,
        backing_attestation: IdentityAttestationPayload,
    ) -> Self {
        Self {
            asset_type,
            mint_amount,
            minter_identity,
            backing_attestation,
        }
    }

    /// Ensure the attestation plaintext binds to the claimed minter commitment (no crypto proof here — vault/policy may).
    pub fn verify_backing_binding(&self) -> Result<(), PrivateError> {
        if self.backing_attestation.binding_commitment != self.minter_identity.0 {
            return Err(PrivateError::ComplianceVeto(
                "mint attestation binding_commitment does not match minter_identity".into(),
            ));
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::sync::Mutex;

    use ark_std::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use super::*;
    use crate::setup::ParameterStore;

    static BAL_ENV_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn asset_label_hash_stable() {
        let g1 = AssetType::from_label("Gold").unwrap();
        let g2 = AssetType::from_label("Gold").unwrap();
        let usd = AssetType::from_label("USD").unwrap();
        assert_eq!(g1, g2);
        assert_ne!(g1, usd);
    }

    #[test]
    fn conservation_rejects_infinite_mint() {
        let e = assert_value_conservation_u64(10, 10, 100, 0, 0);
        assert!(matches!(e, Err(PrivateError::CircuitConstraint(_))));
    }

    #[test]
    fn pedersen_homomorphic_adds_amounts() {
        let gens = PedersenGenerators::<Bn254>::derived_second_generator();
        let a = CommitmentOpening::new(FrBn254::from(30u64), FrBn254::from(7u64));
        let b = CommitmentOpening::new(FrBn254::from(40u64), FrBn254::from(11u64));
        let ca = PedersenCommitment::commit(&gens, a.secret, a.blinding);
        let cb = PedersenCommitment::commit(&gens, b.secret, b.blinding);
        let csum = ShieldedNote::combine_amount_commitments(&ca, &cb);
        let expected = PedersenCommitment::commit(&gens, a.secret + b.secret, a.blinding + b.blinding);
        assert_eq!(csum.point, expected.point);
    }

    #[test]
    fn mint_binding_enforced() {
        let id = SovereignIdentity {
            secret: FrBn254::from(1u64),
            blinding: FrBn254::from(2u64),
            nullifier_key: FrBn254::from(3u64),
        };
        let pc = id.public_commitment();
        let good = MintAuthorization::new(
            AssetType::from_label("Corn_Seeds").unwrap(),
            1_000,
            pc,
            IdentityAttestationPayload::new(b"tokenize:warehouse_receipt_42".as_slice(), pc.0),
        );
        good.verify_backing_binding().unwrap();
        let bad = MintAuthorization::new(
            AssetType::from_label("Corn_Seeds").unwrap(),
            1_000,
            pc,
            IdentityAttestationPayload::new(b"other".as_slice(), FrBn254::from(999u64)),
        );
        assert!(bad.verify_backing_binding().is_err());
    }

    #[test]
    fn ledger_transfer_proves_and_verifies() {
        let _g = BAL_ENV_LOCK.lock().expect("lock");
        unsafe {
            std::env::remove_var("CLERK_ENV");
        }
        let mut rng = StdRng::from_seed([18u8; 32]);
        let root = std::env::temp_dir().join(format!("rice-balance-{}", line!()));
        let _ = fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root.clone());

        let gold = AssetType::from_label("Gold").unwrap();
        let spender = SovereignIdentity {
            secret: FrBn254::rand(&mut rng),
            blinding: FrBn254::rand(&mut rng),
            nullifier_key: FrBn254::rand(&mut rng),
        };
        let owner = spender.public_commitment();
        let in_l = ShieldedNote::new_bounded(gold, 50, FrBn254::rand(&mut rng), owner);
        let in_r = ShieldedNote::new_bounded(gold, 30, FrBn254::rand(&mut rng), owner);
        let xfer = ShieldedLedgerTransfer {
            asset: gold,
            input_left: in_l,
            input_right: in_r,
            output_left_amount: 60,
            output_right_amount: 15,
            fee: 5,
            spender,
        };
        xfer.validate().unwrap();
        let proof = prove_shielded_ledger_transfer(&store, &xfer, &mut rng).unwrap();
        let (c, n) = xfer.spender.public_statement_opening();
        verify_shielded_ledger_transfer(&store, c, n, FrBn254::from(5u64), &proof).unwrap();
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn cross_asset_transfer_rejected_before_prove() {
        let mut rng = StdRng::from_seed([19u8; 32]);
        let gold = AssetType::from_label("Gold").unwrap();
        let usd = AssetType::from_label("USD").unwrap();
        let spender = SovereignIdentity {
            secret: FrBn254::rand(&mut rng),
            blinding: FrBn254::rand(&mut rng),
            nullifier_key: FrBn254::rand(&mut rng),
        };
        let owner = spender.public_commitment();
        let in_l = ShieldedNote::new_bounded(gold, 10, FrBn254::rand(&mut rng), owner);
        let in_r = ShieldedNote::new_bounded(usd, 10, FrBn254::rand(&mut rng), owner);
        let xfer = ShieldedLedgerTransfer {
            asset: gold,
            input_left: in_l,
            input_right: in_r,
            output_left_amount: 10,
            output_right_amount: 10,
            fee: 0,
            spender,
        };
        assert!(xfer.validate().is_err());
    }
}
