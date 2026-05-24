//! **Cryptographic notary** on **BLS12-381** — Merkle **membership**, policy **binding**, **threshold**
//! quorum math, and hooks for **constant-size** accumulator witnesses (pairing / KZG path reserved).
//!
//! **Inclusion:** prove a private leaf digest sits under a published [`ComplianceMerkleTree`] root.
//! **Exclusion (sanctions):** operational pattern is either a **deny-list Merkle** (show leaf absent via
//! sparse Merkle — not fully implemented here) or an **allow-list** membership proof; document your
//! deployment choice at the policy layer.
//!
//! **BN254 elsewhere:** identity/shielded transfers stay on BN254; compliance artifacts here live in
//! `Fr`(**BLS12-381**) for signature / accumulator interoperability.

pub use ark_bls12_381::Bls12_381;
pub use ark_groth16::{Proof, ProvingKey, VerifyingKey};

use std::fs;
use std::path::{Path, PathBuf};

use ark_bls12_381::G1Affine;
use ark_crypto_primitives::sponge::poseidon::PoseidonSponge;
use ark_crypto_primitives::sponge::{CryptographicSponge, FieldBasedCryptographicSponge};
use ark_ff::Field;
use sha2::{Digest, Sha256};

use crate::commitment::poseidon_config_bls12_fr_rate2;
use crate::error::PrivateError;
use crate::field::prime_field_from_be_bytes_strict;

pub type ComplianceProof = Proof<Bls12_381>;
pub type FrBls12 = ark_bls12_381::Fr;

/// Maximum Merkle depth supported by `.rice` compliance trees (`2^depth` leaves after padding).
pub const CLERK_ZK_TREE_DEPTH: usize = 20;

/// Env: `m/n` quorum (e.g. `3/5` guardians).
pub const CLERK_ZK_THRESHOLD_ENV: &str = "CLERK_ZK_THRESHOLD";

/// Optional filesystem root for policy blobs (e.g. checkout of `base/policies`).
pub const CLERK_ZK_POLICY_ROOT_ENV: &str = "CLERK_ZK_POLICY_ROOT";

/// Poseidon domain tag for internal Merkle compression (distinct from leaf hashing).
pub const CLERK_ZK_MERKLE_COMPRESS_DOMAIN: u64 = 0x4D524B4C_4D45524Au64; // "MRK" "MERA" — numeric tag only

// ---------------------------------------------------------------------------
// Poseidon compress + leaf hashing (BLS12-381 Fr)
// ---------------------------------------------------------------------------

#[inline]
pub fn compress_merkle_pair(left: FrBls12, right: FrBls12) -> FrBls12 {
    let params = poseidon_config_bls12_fr_rate2();
    let mut sponge = PoseidonSponge::new(params);
    sponge.absorb(&vec![FrBls12::from(CLERK_ZK_MERKLE_COMPRESS_DOMAIN), left, right]);
    sponge.squeeze_native_field_elements(1)[0]
}

/// Hash opaque **secret** leaf material to a Merkle leaf (never publish `secret` itself).
pub fn leaf_digest_from_secret(secret: &[u8]) -> Result<FrBls12, PrivateError> {
    hash_to_fr_with_domain(b"rice.compliance.merkle.leaf.v1", secret)
}

fn hash_to_fr_with_domain(domain: &[u8], payload: &[u8]) -> Result<FrBls12, PrivateError> {
    for attempt in 0u64..256 {
        let mut h = Sha256::new();
        h.update(domain);
        h.update(payload);
        h.update(attempt.to_le_bytes());
        let out = h.finalize();
        if let Ok(fr) = prime_field_from_be_bytes_strict::<FrBls12>(&out) {
            return Ok(fr);
        }
    }
    Err(PrivateError::FieldInvalid("failed to map hash to BLS12-381 Fr".into()))
}

// ---------------------------------------------------------------------------
// Merkle tree (fixed depth, zero-padded)
// ---------------------------------------------------------------------------

/// Full Merkle structure: `layers[0]` are leaves (`2^depth` elements), last layer is `[root]`.
#[derive(Clone, Debug)]
pub struct ComplianceMerkleTree {
    depth: usize,
    layers: Vec<Vec<FrBls12>>,
}

impl ComplianceMerkleTree {
    /// Build with [`CLERK_ZK_TREE_DEPTH`] (production layout).
    #[inline]
    pub fn new(leaves: &[FrBls12]) -> Result<Self, PrivateError> {
        Self::with_depth(leaves, CLERK_ZK_TREE_DEPTH)
    }

    /// `depth` ≤ [`CLERK_ZK_TREE_DEPTH`]; pads with `Fr::ZERO` to `2^depth` leaves.
    pub fn with_depth(leaves: &[FrBls12], depth: usize) -> Result<Self, PrivateError> {
        if depth == 0 || depth > CLERK_ZK_TREE_DEPTH {
            return Err(PrivateError::CircuitConstraint(format!(
                "Merkle depth must be in 1..={CLERK_ZK_TREE_DEPTH} (got {depth})"
            )));
        }
        let cap = 1usize << depth;
        if leaves.len() > cap {
            return Err(PrivateError::CircuitConstraint(format!(
                "too many leaves {} for depth {} (max {})",
                leaves.len(),
                depth,
                cap
            )));
        }
        let mut level = leaves.to_vec();
        level.resize(cap, FrBls12::ZERO);

        let mut layers = vec![level.clone()];
        while level.len() > 1 {
            let mut next = Vec::with_capacity(level.len() / 2);
            for i in (0..level.len()).step_by(2) {
                next.push(compress_merkle_pair(level[i], level[i + 1]));
            }
            level = next;
            layers.push(level.clone());
        }
        Ok(Self { depth, layers })
    }

    #[inline]
    pub fn root(&self) -> FrBls12 {
        self.layers.last().and_then(|l| l.first()).copied().unwrap_or(FrBls12::ZERO)
    }

    #[inline]
    pub fn depth(&self) -> usize {
        self.depth
    }

    /// Membership path for `leaf_index` ∈ `[0, 2^depth)`.
    pub fn prove(&self, leaf_index: usize) -> Result<ComplianceMerklePath, PrivateError> {
        let cap = 1usize << self.depth;
        if leaf_index >= cap {
            return Err(PrivateError::CircuitConstraint(format!(
                "leaf_index {leaf_index} out of range for depth {}",
                self.depth
            )));
        }
        let mut siblings = Vec::with_capacity(self.depth);
        for k in 0..self.depth {
            let pos = leaf_index >> k;
            let sib_idx = pos ^ 1;
            siblings.push(
                self.layers[k]
                    .get(sib_idx)
                    .copied()
                    .ok_or_else(|| PrivateError::SecretLeak("merkle layer index corrupt".into()))?,
            );
        }
        Ok(ComplianceMerklePath { leaf_index, siblings })
    }

    /// Check inclusion of `leaf` under `root` using a [`ComplianceMerklePath`].
    pub fn verify_path(root: &FrBls12, leaf: &FrBls12, path: &ComplianceMerklePath) -> Result<bool, PrivateError> {
        let mut cur = *leaf;
        let mut idx = path.leaf_index;
        for sib in &path.siblings {
            let (left, right) = if idx & 1 == 0 { (cur, *sib) } else { (*sib, cur) };
            cur = compress_merkle_pair(left, right);
            idx >>= 1;
        }
        Ok(&cur == root)
    }
}

/// Authentication path for [`ComplianceMerkleTree`].
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ComplianceMerklePath {
    pub leaf_index: usize,
    pub siblings: Vec<FrBls12>,
}

impl ComplianceMerklePath {
    #[inline]
    pub fn expected_depth(&self) -> usize {
        self.siblings.len()
    }
}

// ---------------------------------------------------------------------------
// Policy commitment (bridge to `base/policies` or any blob)
// ---------------------------------------------------------------------------

/// Canonical commitment to a **policy document** (file bytes, CEL bundle, etc.).
#[inline]
pub fn policy_commitment_bytes(policy_blob: &[u8]) -> Result<FrBls12, PrivateError> {
    hash_to_fr_with_domain(b"rice.compliance.policy.v1", policy_blob)
}

/// Read a file under optional [`CLERK_ZK_POLICY_ROOT_ENV`] + `relative` and hash it.
pub fn policy_commitment_from_relative_path(relative: impl AsRef<Path>) -> Result<FrBls12, PrivateError> {
    let root = std::env::var(CLERK_ZK_POLICY_ROOT_ENV).map_err(|_| {
        PrivateError::SetupMissing(format!("{CLERK_ZK_POLICY_ROOT_ENV} is not set (cannot load policy file)"))
    })?;
    let path: PathBuf = Path::new(&root).join(relative.as_ref());
    let bytes = fs::read(&path).map_err(PrivateError::StorageIo)?;
    policy_commitment_bytes(&bytes)
}

/// Public statement: Groth16 / ledger can bind proofs to `expected_policy_digest`.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PolicyBinding {
    pub expected_policy_digest: FrBls12,
}

impl PolicyBinding {
    #[inline]
    pub fn from_blob(policy_blob: &[u8]) -> Result<Self, PrivateError> {
        Ok(Self {
            expected_policy_digest: policy_commitment_bytes(policy_blob)?,
        })
    }

    #[inline]
    pub fn assert_matches(&self, digest: &FrBls12) -> Result<(), PrivateError> {
        if *digest != self.expected_policy_digest {
            return Err(PrivateError::ComplianceVeto(
                "policy digest does not match bound expectation".into(),
            ));
        }
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// M-of-N threshold (guardians / approvers)
// ---------------------------------------------------------------------------

/// Quorum gate: **M** successful checks out of **N** possible (off-chain counters; crypto is per-check).
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ThresholdCompliance {
    pub required: u32,
    pub total: u32,
}

impl ThresholdCompliance {
    /// Parse `m/n` from env [`CLERK_ZK_THRESHOLD_ENV`].
    pub fn from_env() -> Result<Option<Self>, PrivateError> {
        let Ok(raw) = std::env::var(CLERK_ZK_THRESHOLD_ENV) else {
            return Ok(None);
        };
        Self::parse(&raw).map(Some)
    }

    pub fn parse(raw: &str) -> Result<Self, PrivateError> {
        let parts: Vec<&str> = raw.split('/').map(str::trim).collect();
        if parts.len() != 2 {
            return Err(PrivateError::ComplianceVeto(format!(
                "{CLERK_ZK_THRESHOLD_ENV} must look like m/n (got {raw:?})"
            )));
        }
        let m: u32 = parts[0]
            .parse()
            .map_err(|_| PrivateError::ComplianceVeto("invalid m in m/n".into()))?;
        let n: u32 = parts[1]
            .parse()
            .map_err(|_| PrivateError::ComplianceVeto("invalid n in m/n".into()))?;
        if m == 0 || n == 0 || m > n {
            return Err(PrivateError::ComplianceVeto(format!("invalid quorum {m}/{n}")));
        }
        Ok(Self { required: m, total: n })
    }

    /// `verified_ok` is how many independent compliance checks (KYC, AML, membership, …) succeeded.
    pub fn require(&self, verified_ok: u32) -> Result<(), PrivateError> {
        if verified_ok < self.required {
            return Err(PrivateError::ComplianceVeto(format!(
                "threshold not met: need {} of {}, got {}",
                self.required, self.total, verified_ok
            )));
        }
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Aggregate compliance digest (multi-check → one Fr)
// ---------------------------------------------------------------------------

/// Compress ordered component digests (KYC ∧ AML ∧ group …) for a single public **statement** field.
pub fn aggregate_compliance_digests(components: &[FrBls12]) -> FrBls12 {
    let mut acc = FrBls12::from(CLERK_ZK_MERKLE_COMPRESS_DOMAIN);
    for c in components {
        acc = compress_merkle_pair(acc, *c);
    }
    acc
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AggregatedComplianceStatement {
    pub combined_digest: FrBls12,
    pub component_count: usize,
}

impl AggregatedComplianceStatement {
    pub fn from_components(components: &[FrBls12]) -> Self {
        let combined_digest = aggregate_compliance_digests(components);
        Self {
            combined_digest,
            component_count: components.len(),
        }
    }
}

// ---------------------------------------------------------------------------
// Constant-size accumulator hook (BLS12-381 G1)
// ---------------------------------------------------------------------------

/// Placeholder **VIP / accumulator** witness: constant-size `G1` + epoch, for future KZG/IPA/RSA wiring.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PairingAccumulatorWitness {
    pub state_g1: G1Affine,
    pub epoch: u64,
}

impl PairingAccumulatorWitness {
    /// When implemented: verify opening proof against `state_g1` and digest.
    pub fn verify_membership_placeholder(&self) -> Result<(), PrivateError> {
        Err(PrivateError::SetupMissing(
            "BLS12-381 accumulator membership (constant-size) not implemented — use Merkle today".into(),
        ))
    }
}

/// Bind a **public** accumulator state to a Merkle root operators already publish (migration bridge).
#[inline]
pub fn accumulator_state_digest_from_merkle_root(root: FrBls12) -> FrBls12 {
    compress_merkle_pair(FrBls12::from(0x4143_4355u64), root) // "ACCU" tag
}

// ---------------------------------------------------------------------------
// Inclusion / exclusion claims (documentation + helpers)
// ---------------------------------------------------------------------------

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ComplianceListKind {
    /// Whitelist: prove **membership** with [`ComplianceMerkleTree::verify_path`].
    Allow,
    /// Deny-list: prefer **sparse Merkle non-membership** or prove membership in hashed empty subtree — full gadget TBD.
    Deny,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MembershipClaim {
    pub list_kind: ComplianceListKind,
    pub root: FrBls12,
    pub leaf: FrBls12,
    pub path: ComplianceMerklePath,
}

impl MembershipClaim {
    pub fn verify_inclusion(&self) -> Result<(), PrivateError> {
        if !ComplianceMerkleTree::verify_path(&self.root, &self.leaf, &self.path)? {
            return Err(PrivateError::ComplianceVeto("Merkle membership proof failed".into()));
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use ark_std::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    use super::*;

    #[test]
    fn merkle_prove_verify_small_depth() {
        let mut rng = StdRng::from_seed([21u8; 32]);
        let leaves: Vec<FrBls12> = (0..8).map(|_| FrBls12::rand(&mut rng)).collect();
        let tree = ComplianceMerkleTree::with_depth(&leaves, 3).unwrap();
        let root = tree.root();
        let path = tree.prove(5).unwrap();
        assert!(ComplianceMerkleTree::verify_path(&root, &leaves[5], &path).unwrap());
        assert!(!ComplianceMerkleTree::verify_path(&root, &FrBls12::rand(&mut rng), &path).unwrap());
    }

    #[test]
    fn policy_digest_stable() {
        let p = b"rule: no infinite mint";
        let a = policy_commitment_bytes(p).unwrap();
        let b = policy_commitment_bytes(p).unwrap();
        assert_eq!(a, b);
    }

    #[test]
    fn threshold_parse() {
        let t = ThresholdCompliance::parse("3/5").unwrap();
        t.require(3).unwrap();
        assert!(t.require(2).is_err());
    }

    #[test]
    fn aggregate_non_trivial() {
        let a = FrBls12::from(3u64);
        let b = FrBls12::from(7u64);
        let agg = AggregatedComplianceStatement::from_components(&[a, b]);
        assert_ne!(agg.combined_digest, FrBls12::ZERO);
    }

    #[test]
    fn membership_claim_ok() {
        let leaves = vec![FrBls12::from(1u64), FrBls12::from(2u64)];
        let tree = ComplianceMerkleTree::with_depth(&leaves, 2).unwrap();
        let root = tree.root();
        let path = tree.prove(0).unwrap();
        let claim = MembershipClaim {
            list_kind: ComplianceListKind::Allow,
            root,
            leaf: leaves[0],
            path,
        };
        claim.verify_inclusion().unwrap();
    }
}
