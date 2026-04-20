//! **Secret-first** serialization — the vault interface for proofs, keys, and any witness material
//! that must leave the device only under policy.
//!
//! **Why:** Canonical ark compression handles mathematical encoding; [`VaultEnvelope`] adds
//! **AEAD**, **quantum salt** (per-message randomness that diversifies derived keys and ciphertexts),
//! and **jurisdiction policy tags** so compliance can reason about what left the black box. The
//! format is **deterministic** for a given plaintext, policy, AAD, and random salt/nonce draws —
//! re-sealing the same artifact yields different ciphertexts (fresh salt/nonce), but the **outer
//! layout** and field order are fixed for parsers.
//!
//! **Quantum note:** ChaCha20-Poly1305 is **not** post-quantum; the **salt + nonce** still defend
//! against offline pre-computation of rainbow tables over static identities. Long-term PQ hybrid
//! transport belongs beside this layer (see [`crate::curve::HybridPoint`]).

use core::marker::PhantomData;
use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::Path;

use ark_ec::pairing::Pairing;
use ark_groth16::{Proof, ProvingKey, VerifyingKey};
use ark_serialize::{CanonicalDeserialize, CanonicalSerialize, SerializationError};
use bytes::Bytes;
use chacha20poly1305::aead::{Aead, KeyInit, Payload};
use chacha20poly1305::{ChaCha20Poly1305, Key, Nonce};
use rand::RngCore;
use sha2::{Digest, Sha256};

use crate::error::PrivateError;

// ---------------------------------------------------------------------------
// Wire constants (canonical envelope)
// ---------------------------------------------------------------------------

/// Magic bytes identifying a `.rice` vault frame (`R`ice `V`au`LT`).
pub const VAULT_MAGIC: [u8; 4] = *b"RVLT";

/// Format version for [`VaultEnvelope::to_canonical_bytes`].
pub const VAULT_FORMAT_VERSION: u8 = 1;

const MAX_POLICY_TAG_LEN: usize = 512;
const MAX_CIPHERTEXT_LEN: usize = 64 * 1024 * 1024;

// ---------------------------------------------------------------------------
// Policy & compliance (global filter)
// ---------------------------------------------------------------------------

/// Jurisdiction / rules identifier carried in the clear (who may demand what view).
///
/// **Why:** Auditors and cross-border routing need a stable tag without decrypting the payload.
#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct PolicyTag(pub Bytes);

impl PolicyTag {
    /// Build from UTF-8 jurisdiction code (e.g. `b"EU-GDPR-DE"`).
    #[inline]
    pub fn from_static(bytes: &'static [u8]) -> Self {
        Self(Bytes::from_static(bytes))
    }

    /// Copy arbitrary bytes into a refcounted buffer ([`util::bytes`] ecosystem).
    #[inline]
    pub fn from_slice(slice: &[u8]) -> Self {
        Self(Bytes::copy_from_slice(slice))
    }

    #[inline]
    pub fn as_bytes(&self) -> &Bytes {
        &self.0
    }
}

/// Whether an operation may leave the user’s trust boundary.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub enum ComplianceOperation {
    /// Seal/open on-device or inside the same security enclave.
    LocalVault,
    /// Transmit over network / hand to third party — subject to [`ComplianceMask::paranoid`].
    ExternalTransmit,
}

/// Geographic / regulatory filter applied at seal time.
///
/// **Paranoid mode:** any [`ComplianceOperation::ExternalTransmit`] returns
/// [`PrivateError::ComplianceVeto`] — **fail closed** for “total blackout” deployments.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ComplianceMask {
    /// When `true`, [`ComplianceOperation::ExternalTransmit`] is always vetoed.
    pub paranoid: bool,
    /// Policy tag stored in the envelope header.
    pub policy_tag: PolicyTag,
    /// Optional **ZKP view key** material bound into AEAD associated data (lawful viewer hooks).
    /// Does **not** encrypt the payload by itself; it only authenticates alongside ciphertext.
    pub zkp_view_key: Option<Bytes>,
}

impl ComplianceMask {
    /// Default open policy: no paranoid flag, global tag, no view key.
    #[inline]
    pub fn global_default() -> Self {
        Self {
            paranoid: false,
            policy_tag: PolicyTag::from_static(b"GLOBAL-DEFAULT"),
            zkp_view_key: None,
        }
    }

    /// Enforce mask for a high-level operation (serializer “global filter”).
    #[inline]
    pub fn enforce_operation(&self, op: ComplianceOperation) -> Result<(), PrivateError> {
        if matches!(op, ComplianceOperation::ExternalTransmit) && self.paranoid {
            return Err(PrivateError::ComplianceVeto(
                "paranoid compliance mask: external vault serialization vetoed (total blackout)"
                    .into(),
            ));
        }
        Ok(())
    }

    /// Hook for jurisdiction-specific **plaintext** shaping before encryption.
    ///
    /// **Why:** Some regimes may require stripping optional witness fields or attaching hashed
    /// redactions. The default is a no-op; callers can wrap [`ComplianceMask`] and override
    /// behavior at integration time.
    #[inline]
    pub fn transform_plaintext(&self, _plaintext: &mut Vec<u8>) -> Result<(), PrivateError> {
        Ok(())
    }

    fn view_key_slice(&self) -> Option<&[u8]> {
        self.zkp_view_key.as_ref().map(|b| b.as_ref())
    }
}

// ---------------------------------------------------------------------------
// Master key hook (.rice identity root)
// ---------------------------------------------------------------------------

/// Derives per-envelope symmetric keys from a **32-byte identity root** (KDF + salt + policy).
///
/// **Why:** CLERK can back this with HSM unwrap, OS keystore, or session ECDH — the private crate
/// stays agnostic.
pub trait VaultMasterKeySource {
    /// Root symmetric material for the current `.rice` principal (never logged).
    fn master_symmetric_key(&self) -> Result<[u8; 32], PrivateError>;
}

/// Test / offline helper: static 32-byte root.
#[derive(Clone, Copy, Debug)]
pub struct StaticVaultKey(pub [u8; 32]);

impl VaultMasterKeySource for StaticVaultKey {
    #[inline]
    fn master_symmetric_key(&self) -> Result<[u8; 32], PrivateError> {
        Ok(self.0)
    }
}

#[inline]
fn derive_chacha_key(root: &[u8; 32], quantum_salt: &[u8; 32], policy: &[u8]) -> [u8; 32] {
    let mut h = Sha256::new();
    h.update(b"rice.vault.chacha20poly1305.v1");
    h.update(root);
    h.update(quantum_salt);
    h.update((policy.len() as u64).to_be_bytes());
    h.update(policy);
    h.finalize().into()
}

#[inline]
fn build_aad(
    format_version: u8,
    policy: &[u8],
    view_key: Option<&[u8]>,
    user_aad: &[u8],
) -> Vec<u8> {
    let mut out = Vec::with_capacity(32 + policy.len() + user_aad.len());
    out.push(format_version);
    out.extend_from_slice(&(policy.len() as u32).to_be_bytes());
    out.extend_from_slice(policy);
    match view_key {
        Some(vk) => {
            out.push(1);
            out.extend_from_slice(&(vk.len() as u32).to_be_bytes());
            out.extend_from_slice(vk);
        }
        None => out.push(0),
    }
    out.extend_from_slice(user_aad);
    out
}

#[inline]
fn chacha_encrypt(
    key: &[u8; 32],
    nonce: &[u8; 12],
    plaintext: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>, PrivateError> {
    let key = Key::from(*key);
    let cipher = ChaCha20Poly1305::new(&key);
    let nonce = Nonce::from(*nonce);
    cipher
        .encrypt(
            &nonce,
            Payload {
                msg: plaintext,
                aad,
            },
        )
        .map_err(|_| {
            PrivateError::SecretLeak(
                "vault AEAD encryption failed (internal invariant or RNG)".into(),
            )
        })
}

#[inline]
fn chacha_decrypt(
    key: &[u8; 32],
    nonce: &[u8; 12],
    ciphertext: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>, PrivateError> {
    let key = Key::from(*key);
    let cipher = ChaCha20Poly1305::new(&key);
    let nonce = Nonce::from(*nonce);
    cipher
        .decrypt(
            &nonce,
            Payload {
                msg: ciphertext,
                aad,
            },
        )
        .map_err(|_| {
            PrivateError::SecretLeak(
                "vault AEAD decrypt failed: wrong key, tampered ciphertext, or AAD mismatch"
                    .into(),
            )
        })
}

// ---------------------------------------------------------------------------
// VaultEnvelope<T>
// ---------------------------------------------------------------------------

/// Encrypted vault record wrapping a **canonical** ZK artifact of logical type `T`.
///
/// On the wire, `T` is not self-describing: callers must supply the expected type at open time.
#[derive(Clone, Debug)]
pub struct VaultEnvelope<T = ()> {
    /// Per-message random 256-bit domain separator for KDF inputs (mitigates multi-target
    /// pre-computation if identity roots ever leak across deployments).
    pub quantum_salt: [u8; 32],
    /// ChaCha20-Poly1305 nonce (unique per seal).
    pub nonce: [u8; 12],
    /// Jurisdiction / policy label (stored in clear).
    pub policy_tag: PolicyTag,
    /// Ciphertext including Poly1305 tag.
    pub ciphertext: Bytes,
    _artifact: PhantomData<fn() -> T>,
}

impl<T> VaultEnvelope<T> {
    #[inline]
    fn new(
        quantum_salt: [u8; 32],
        nonce: [u8; 12],
        policy_tag: PolicyTag,
        ciphertext: Bytes,
    ) -> Self {
        Self {
            quantum_salt,
            nonce,
            policy_tag,
            ciphertext,
            _artifact: PhantomData,
        }
    }

    /// Erase compile-time artifact marker after decoding off the wire.
    #[inline]
    pub fn erase_type(self) -> VaultEnvelope<()> {
        VaultEnvelope::new(
            self.quantum_salt,
            self.nonce,
            self.policy_tag,
            self.ciphertext,
        )
    }
}

impl VaultEnvelope<()> {
    /// Parse a canonical vault frame from `bytes` ([`util::Bytes`]).
    #[inline]
    pub fn decode_canonical(bytes: &Bytes) -> Result<Self, PrivateError> {
        decode_canonical_inner(bytes.as_ref()).map(|(salt, nonce, tag, ct)| {
            VaultEnvelope::new(salt, nonce, tag, Bytes::from(ct))
        })
    }
}

impl<T> VaultEnvelope<T> {
    /// Serialize this envelope to a **single** deterministic byte vector (same logical value →
    /// same layout; ciphertext already includes fresh randomness from seal).
    #[inline]
    pub fn to_canonical_bytes(&self) -> Bytes {
        encode_canonical(
            VAULT_FORMAT_VERSION,
            &self.quantum_salt,
            &self.nonce,
            self.policy_tag.as_bytes().as_ref(),
            self.ciphertext.as_ref(),
        )
    }

    /// Seal `artifact`: canonical compress → compliance transform → AEAD → envelope.
    pub fn seal_artifact(
        artifact: &T,
        key_src: &impl VaultMasterKeySource,
        mask: &ComplianceMask,
        op: ComplianceOperation,
        user_aad: &[u8],
        rng: &mut impl RngCore,
    ) -> Result<Self, PrivateError>
    where
        T: CanonicalSerialize,
    {
        mask.enforce_operation(op)?;
        let mut plaintext = Vec::new();
        artifact
            .serialize_compressed(&mut plaintext)
            .map_err(PrivateError::Serialization)?;
        mask.transform_plaintext(&mut plaintext)?;

        let mut quantum_salt = [0u8; 32];
        rng.fill_bytes(&mut quantum_salt);
        let mut nonce = [0u8; 12];
        rng.fill_bytes(&mut nonce);

        let root = key_src.master_symmetric_key()?;
        let policy_bytes = mask.policy_tag.as_bytes();
        let subkey = derive_chacha_key(&root, &quantum_salt, policy_bytes.as_ref());
        let aad = build_aad(
            VAULT_FORMAT_VERSION,
            policy_bytes.as_ref(),
            mask.view_key_slice(),
            user_aad,
        );
        let ct = chacha_encrypt(&subkey, &nonce, &plaintext, &aad)?;

        Ok(Self::new(
            quantum_salt,
            nonce,
            mask.policy_tag.clone(),
            Bytes::from(ct),
        ))
    }

    /// Decrypt and deserialize the inner artifact.
    pub fn open(
        &self,
        key_src: &impl VaultMasterKeySource,
        mask: &ComplianceMask,
        user_aad: &[u8],
    ) -> Result<T, PrivateError>
    where
        T: CanonicalDeserialize,
    {
        let root = key_src.master_symmetric_key()?;
        let policy_bytes = self.policy_tag.as_bytes();
        if policy_bytes.as_ref() != mask.policy_tag.as_bytes().as_ref() {
            return Err(PrivateError::SecretLeak(
                "vault policy tag mismatch between envelope and compliance mask".into(),
            ));
        }
        let subkey = derive_chacha_key(&root, &self.quantum_salt, policy_bytes.as_ref());
        let aad = build_aad(
            VAULT_FORMAT_VERSION,
            policy_bytes.as_ref(),
            mask.view_key_slice(),
            user_aad,
        );
        let pt = chacha_decrypt(
            &subkey,
            &self.nonce,
            self.ciphertext.as_ref(),
            &aad,
        )?;
        let out = T::deserialize_compressed(pt.as_slice()).map_err(PrivateError::Serialization)?;
        Ok(out)
    }
}

/// One-step: artifact → encrypted canonical [`Bytes`].
#[inline]
pub fn to_encrypted_bytes<T: CanonicalSerialize>(
    artifact: &T,
    key_src: &impl VaultMasterKeySource,
    mask: &ComplianceMask,
    op: ComplianceOperation,
    user_aad: &[u8],
    rng: &mut impl RngCore,
) -> Result<Bytes, PrivateError> {
    let env = VaultEnvelope::<T>::seal_artifact(artifact, key_src, mask, op, user_aad, rng)?;
    Ok(env.to_canonical_bytes())
}

/// One-step: wire bytes → artifact (typed).
#[inline]
pub fn from_encrypted_bytes<T: CanonicalDeserialize>(
    wire: &Bytes,
    key_src: &impl VaultMasterKeySource,
    mask: &ComplianceMask,
    user_aad: &[u8],
) -> Result<T, PrivateError> {
    let env: VaultEnvelope<T> = {
        let base = VaultEnvelope::decode_canonical(wire)?;
        VaultEnvelope::new(
            base.quantum_salt,
            base.nonce,
            base.policy_tag,
            base.ciphertext,
        )
    };
    env.open(key_src, mask, user_aad)
}

// ---------------------------------------------------------------------------
// Canonical encode / decode helpers
// ---------------------------------------------------------------------------

fn encode_canonical(
    version: u8,
    quantum_salt: &[u8; 32],
    nonce: &[u8; 12],
    policy: &[u8],
    ciphertext: &[u8],
) -> Bytes {
    let mut v = Vec::with_capacity(
        4 + 1 + 32 + 12 + 4 + policy.len() + 4 + ciphertext.len(),
    );
    v.extend_from_slice(&VAULT_MAGIC);
    v.push(version);
    v.extend_from_slice(quantum_salt);
    v.extend_from_slice(nonce);
    v.extend_from_slice(&(policy.len() as u32).to_be_bytes());
    v.extend_from_slice(policy);
    v.extend_from_slice(&(ciphertext.len() as u32).to_be_bytes());
    v.extend_from_slice(ciphertext);
    Bytes::from(v)
}

fn decode_canonical_inner(data: &[u8]) -> Result<([u8; 32], [u8; 12], PolicyTag, Vec<u8>), PrivateError> {
    let mut i = 0usize;
    if data.len() < 4 + 1 + 32 + 12 + 4 + 4 {
        return Err(PrivateError::SecretLeak(
            "vault envelope truncated (minimum header)".into(),
        ));
    }
    if data[i..i + 4] != VAULT_MAGIC {
        return Err(PrivateError::SecretLeak(
            "vault envelope magic mismatch (not a .rice RVLT frame)".into(),
        ));
    }
    i += 4;
    let version = data[i];
    i += 1;
    if version != VAULT_FORMAT_VERSION {
        return Err(PrivateError::Serialization(SerializationError::InvalidData));
    }
    let mut quantum_salt = [0u8; 32];
    quantum_salt.copy_from_slice(&data[i..i + 32]);
    i += 32;
    let mut nonce = [0u8; 12];
    nonce.copy_from_slice(&data[i..i + 12]);
    i += 12;
    let plen = read_u32_be(data, &mut i)? as usize;
    if plen > MAX_POLICY_TAG_LEN {
        return Err(PrivateError::SecretLeak("vault policy tag length absurd".into()));
    }
    if i + plen + 4 > data.len() {
        return Err(PrivateError::SecretLeak(
            "vault envelope truncated at policy tag".into(),
        ));
    }
    let policy = PolicyTag::from_slice(&data[i..i + plen]);
    i += plen;
    let clen = read_u32_be(data, &mut i)? as usize;
    if clen > MAX_CIPHERTEXT_LEN {
        return Err(PrivateError::SecretLeak(
            "vault ciphertext length over cap".into(),
        ));
    }
    if i + clen != data.len() {
        return Err(PrivateError::SecretLeak(
            "vault envelope trailing garbage or length mismatch".into(),
        ));
    }
    Ok((quantum_salt, nonce, policy, data[i..i + clen].to_vec()))
}

#[inline]
fn read_u32_be(buf: &[u8], i: &mut usize) -> Result<u32, PrivateError> {
    if *i + 4 > buf.len() {
        return Err(PrivateError::SecretLeak(
            "vault envelope truncated reading u32".into(),
        ));
    }
    let v = u32::from_be_bytes(buf[*i..*i + 4].try_into().expect("length checked"));
    *i += 4;
    Ok(v)
}

// ---------------------------------------------------------------------------
// Ark compressed serialization (canonical, plaintext)
// ---------------------------------------------------------------------------

#[inline]
pub fn proof_to_bytes_compressed<E: Pairing>(proof: &Proof<E>) -> Result<Bytes, PrivateError> {
    let mut buf = Vec::new();
    proof.serialize_compressed(&mut buf)?;
    Ok(Bytes::from(buf))
}

#[inline]
pub fn proof_from_bytes_compressed<E: Pairing>(bytes: &[u8]) -> Result<Proof<E>, PrivateError> {
    Ok(Proof::deserialize_compressed(bytes)?)
}

#[inline]
pub fn proving_key_to_bytes_compressed<E: Pairing>(pk: &ProvingKey<E>) -> Result<Bytes, PrivateError> {
    let mut buf = Vec::new();
    pk.serialize_compressed(&mut buf)?;
    Ok(Bytes::from(buf))
}

#[inline]
pub fn proving_key_from_bytes_compressed<E: Pairing>(bytes: &[u8]) -> Result<ProvingKey<E>, PrivateError> {
    Ok(ProvingKey::deserialize_compressed(bytes)?)
}

#[inline]
pub fn verifying_key_to_bytes_compressed<E: Pairing>(vk: &VerifyingKey<E>) -> Result<Bytes, PrivateError> {
    let mut buf = Vec::new();
    vk.serialize_compressed(&mut buf)?;
    Ok(Bytes::from(buf))
}

#[inline]
pub fn verifying_key_from_bytes_compressed<E: Pairing>(bytes: &[u8]) -> Result<VerifyingKey<E>, PrivateError> {
    Ok(VerifyingKey::deserialize_compressed(bytes)?)
}

/// Load a proving key via **mmap** (single OS-backed mapping; ark deserialization still builds the typed key).
#[inline]
pub fn proving_key_from_file_mmap<E: Pairing>(path: &Path) -> Result<ProvingKey<E>, PrivateError> {
    let file = File::open(path).map_err(PrivateError::StorageIo)?;
    let mmap = unsafe { memmap2::Mmap::map(&file).map_err(PrivateError::StorageIo)? };
    proving_key_from_bytes_compressed(&mmap)
}

/// Load a verifying key via **mmap** (VKs are small but path matches PK ergonomics).
#[inline]
pub fn verifying_key_from_file_mmap<E: Pairing>(path: &Path) -> Result<VerifyingKey<E>, PrivateError> {
    let file = File::open(path).map_err(PrivateError::StorageIo)?;
    let mmap = unsafe { memmap2::Mmap::map(&file).map_err(PrivateError::StorageIo)? };
    verifying_key_from_bytes_compressed(&mmap)
}

/// Write a proving key with a **buffered** writer (large SRS-friendly).
#[inline]
pub fn proving_key_to_file_compressed<E: Pairing>(
    path: &Path,
    pk: &ProvingKey<E>,
) -> Result<(), PrivateError> {
    let mut f = BufWriter::new(File::create(path).map_err(PrivateError::StorageIo)?);
    pk.serialize_compressed(&mut f).map_err(PrivateError::Serialization)?;
    f.flush().map_err(PrivateError::StorageIo)?;
    Ok(())
}

/// Write a verifying key with a **buffered** writer.
#[inline]
pub fn verifying_key_to_file_compressed<E: Pairing>(
    path: &Path,
    vk: &VerifyingKey<E>,
) -> Result<(), PrivateError> {
    let mut f = BufWriter::new(File::create(path).map_err(PrivateError::StorageIo)?);
    vk.serialize_compressed(&mut f).map_err(PrivateError::Serialization)?;
    f.flush().map_err(PrivateError::StorageIo)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use ark_bn254::Bn254;
    use ark_ff::UniformRand;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    #[test]
    fn vault_roundtrip_proof() {
        let mut rng = StdRng::from_seed([19u8; 32]);
        let key = StaticVaultKey([7u8; 32]);
        let mask = ComplianceMask::global_default();
        let proof = crate::prove::prove_mul(
            &crate::setup::trusted_setup::<Bn254, _>(&mut rng).unwrap().0,
            ark_bn254::Fr::rand(&mut rng),
            ark_bn254::Fr::rand(&mut rng),
            &mut rng,
        )
        .unwrap();

        let env = VaultEnvelope::seal_artifact(
            &proof,
            &key,
            &mask,
            ComplianceOperation::LocalVault,
            b"context",
            &mut rng,
        )
        .unwrap();
        let wire = env.to_canonical_bytes();
        let back: ark_groth16::Proof<Bn254> =
            from_encrypted_bytes(&wire, &key, &mask, b"context").unwrap();
        assert_eq!(
            proof_to_bytes_compressed(&proof).unwrap(),
            proof_to_bytes_compressed(&back).unwrap()
        );
    }

    #[test]
    fn paranoid_blocks_external_seal() {
        let mut rng = StdRng::from_seed([3u8; 32]);
        let key = StaticVaultKey([1u8; 32]);
        let mut mask = ComplianceMask::global_default();
        mask.paranoid = true;
        let proof = crate::prove::prove_mul(
            &crate::setup::trusted_setup::<Bn254, _>(&mut rng).unwrap().0,
            ark_bn254::Fr::from(2u64),
            ark_bn254::Fr::from(3u64),
            &mut rng,
        )
        .unwrap();
        let err = VaultEnvelope::seal_artifact(
            &proof,
            &key,
            &mask,
            ComplianceOperation::ExternalTransmit,
            b"",
            &mut rng,
        )
        .unwrap_err();
        assert!(matches!(err, PrivateError::ComplianceVeto(_)));
    }

    #[test]
    fn wrong_key_fails_closed() {
        let mut rng = StdRng::from_seed([44u8; 32]);
        let k1 = StaticVaultKey([9u8; 32]);
        let k2 = StaticVaultKey([8u8; 32]);
        let mask = ComplianceMask::global_default();
        let proof = crate::prove::prove_mul(
            &crate::setup::trusted_setup::<Bn254, _>(&mut rng).unwrap().0,
            ark_bn254::Fr::from(5u64),
            ark_bn254::Fr::from(7u64),
            &mut rng,
        )
        .unwrap();
        let wire = to_encrypted_bytes(
            &proof,
            &k1,
            &mask,
            ComplianceOperation::LocalVault,
            b"",
            &mut rng,
        )
        .unwrap();
        let err: Result<ark_groth16::Proof<Bn254>, _> =
            from_encrypted_bytes(&wire, &k2, &mask, b"");
        assert!(matches!(err, Err(PrivateError::SecretLeak(_))));
    }
}
