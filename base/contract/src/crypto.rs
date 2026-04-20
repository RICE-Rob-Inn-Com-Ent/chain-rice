//! Signing, hashing, symmetric crypto, and post-quantum verification hooks.
//!
//! Pure helpers only: no storage, no I/O. CosmWasm handlers may prefer `deps.api.verify_*` for
//! chain-native checks; these functions stay available for `.rice` agent logic and tests.

use aes_gcm::aead::{Aead, KeyInit, Payload};
use aes_gcm::{Aes256Gcm, Nonce};
use cosmwasm_std::Binary;
use ed25519_dalek::{Signature as Ed25519Signature, Verifier, VerifyingKey as Ed25519VerifyingKey};
use k256::ecdsa::{Signature as Secp256k1Signature, VerifyingKey as Secp256k1VerifyingKey};
use sha2::{Digest, Sha256};
use sha3::Sha3_256;

use crate::error::ContractError;

fn proof_invalid(detail: impl Into<String>) -> ContractError {
    ContractError::ProofInvalid { detail: detail.into() }
}

fn encryption_error(detail: impl Into<String>) -> ContractError {
    ContractError::EncryptionError { detail: detail.into() }
}

#[cfg(not(feature = "post-quantum"))]
fn capability_pq_disabled() -> ContractError {
    ContractError::CapabilityError {
        detail: "post-quantum crypto is not enabled; build with `--features post-quantum`".into(),
    }
}

/// Canonical 32-byte SHA-256 digest over arbitrary bytes.
pub fn sha256_digest(data: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize().into()
}

/// Wrap digest as `Binary` for attributes or stored proofs.
pub fn sha256_binary(data: &[u8]) -> Binary {
    Binary::from(sha256_digest(data).as_slice())
}

/// NIST SHA3-256 (Keccak family distinct from Ethereum’s Keccak-256).
pub fn sha3_256_digest(data: &[u8]) -> [u8; 32] {
    let mut hasher = Sha3_256::new();
    hasher.update(data);
    hasher.finalize().into()
}

pub fn sha3_256_binary(data: &[u8]) -> Binary {
    Binary::from(sha3_256_digest(data).as_slice())
}

/// Compact **intent proof** for `execute_intent`: **Ed25519** public key (32 bytes)
/// concatenated with signature (64 bytes) over `payload` — **96 bytes** total.
pub fn verify_intent_proof_ed25519(payload: &[u8], proof_bundle: &[u8]) -> Result<(), ContractError> {
    const ED25519_INTENT_PROOF_LEN: usize = 32 + 64;
    if proof_bundle.len() != ED25519_INTENT_PROOF_LEN {
        return Err(proof_invalid(format!(
            "intent proof must be {ED25519_INTENT_PROOF_LEN} bytes (ed25519 pubkey||sig), got {}",
            proof_bundle.len()
        )));
    }
    verify_ed25519(payload, &proof_bundle[32..], &proof_bundle[..32])?;
    Ok(())
}

/// Verify an Ed25519 signature (`sig` 64 bytes, `pubkey` 32 bytes). Any parse or verification
/// failure maps to [`ContractError::ProofInvalid`].
pub fn verify_ed25519(msg: &[u8], sig: &[u8], pubkey: &[u8]) -> Result<bool, ContractError> {
    let vk = Ed25519VerifyingKey::try_from(pubkey)
        .map_err(|_| proof_invalid("ed25519: public key must be a valid 32-byte encoding"))?;
    let signature = Ed25519Signature::try_from(sig)
        .map_err(|_| proof_invalid("ed25519: signature must be a valid 64-byte encoding"))?;
    vk.verify(msg, &signature)
        .map_err(|_| proof_invalid("ed25519: signature verification failed"))?;
    Ok(true)
}

/// ECDSA over secp256k1 with SHA-256 over `msg` (k256’s high-level [`Secp256k1VerifyingKey::verify`]).
///
/// `pubkey` is SEC1-encoded (33-byte compressed or 65-byte uncompressed). `sig` is DER or
/// fixed 64-byte (r‖s) as accepted by [`Secp256k1Signature::from_slice`].
pub fn verify_secp256k1(msg: &[u8], sig: &[u8], pubkey: &[u8]) -> Result<bool, ContractError> {
    let vk = Secp256k1VerifyingKey::from_sec1_bytes(pubkey)
        .map_err(|_| proof_invalid("secp256k1: invalid SEC1 public key"))?;
    let signature =
        Secp256k1Signature::from_slice(sig).map_err(|_| proof_invalid("secp256k1: invalid signature encoding"))?;
    vk.verify(msg, &signature)
        .map_err(|_| proof_invalid("secp256k1: signature verification failed"))?;
    Ok(true)
}

/// AES-256-GCM decrypt. `ciphertext` must include the 16-byte authentication tag (typical
/// `encrypt` output layout). `key` is 32 bytes, `nonce` 12 bytes. Decryption failures map to
/// [`ContractError::EncryptionError`].
pub fn decrypt_aes256_gcm(key: &[u8], nonce: &[u8], ciphertext: &[u8], aad: &[u8]) -> Result<Vec<u8>, ContractError> {
    if key.len() != 32 {
        return Err(encryption_error(format!("AES-GCM: key must be 32 bytes, got {}", key.len())));
    }
    if nonce.len() != 12 {
        return Err(encryption_error(format!(
            "AES-GCM: nonce must be 12 bytes, got {}",
            nonce.len()
        )));
    }
    let cipher =
        Aes256Gcm::new_from_slice(key).map_err(|e| encryption_error(format!("AES-GCM: invalid key material ({e})")))?;
    let mut nonce_bytes = [0u8; 12];
    nonce_bytes.copy_from_slice(nonce);
    let nonce = Nonce::from(nonce_bytes);
    cipher
        .decrypt(&nonce, Payload { msg: ciphertext, aad })
        .map_err(|e| encryption_error(format!("AES-GCM decrypt: {e}")))
}

#[cfg(feature = "post-quantum")]
pub fn verify_dilithium2_detached(msg: &[u8], sig: &[u8], pubkey: &[u8]) -> Result<bool, ContractError> {
    use pqcrypto::sign::dilithium2;
    use pqcrypto::traits::sign::{DetachedSignature, PublicKey};

    let pk = dilithium2::PublicKey::from_bytes(pubkey)
        .map_err(|_| proof_invalid("ML-DSA (Dilithium2): invalid public key encoding"))?;
    let detached = dilithium2::DetachedSignature::from_bytes(sig)
        .map_err(|_| proof_invalid("ML-DSA (Dilithium2): invalid detached signature encoding"))?;
    dilithium2::verify_detached_signature(&detached, msg, &pk)
        .map_err(|_| proof_invalid("ML-DSA (Dilithium2): signature verification failed"))?;
    Ok(true)
}

#[cfg(not(feature = "post-quantum"))]
pub fn verify_dilithium2_detached(_msg: &[u8], _sig: &[u8], _pubkey: &[u8]) -> Result<bool, ContractError> {
    Err(capability_pq_disabled())
}

#[cfg(feature = "post-quantum")]
pub fn verify_falcon512_detached(msg: &[u8], sig: &[u8], pubkey: &[u8]) -> Result<bool, ContractError> {
    use pqcrypto::sign::falcon512;
    use pqcrypto::traits::sign::{DetachedSignature, PublicKey};

    let pk = falcon512::PublicKey::from_bytes(pubkey)
        .map_err(|_| proof_invalid("Falcon-512: invalid public key encoding"))?;
    let detached = falcon512::DetachedSignature::from_bytes(sig)
        .map_err(|_| proof_invalid("Falcon-512: invalid detached signature encoding"))?;
    falcon512::verify_detached_signature(&detached, msg, &pk)
        .map_err(|_| proof_invalid("Falcon-512: signature verification failed"))?;
    Ok(true)
}

#[cfg(not(feature = "post-quantum"))]
pub fn verify_falcon512_detached(_msg: &[u8], _sig: &[u8], _pubkey: &[u8]) -> Result<bool, ContractError> {
    Err(capability_pq_disabled())
}
