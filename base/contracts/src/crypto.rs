//! Signing, hashing, symmetric crypto, and post-quantum helpers.
//!
//! `pqcrypto` is compiled only for non-WASM targets so the contract artifact stays portable;
//! PQ verification can run on relayers or off-chain clients using the same types.

use cosmwasm_std::Binary;
use sha2::{Digest, Sha256};

// [ ] https://docs.cosmwasm.com/ — ed25519-dalek, aes-gcm, pqcrypto feature-gated
// [ ] ed25519 verify — keys from state/config, not embedded literals
// [ ] SHA256 — merkle / state commitments for private/
// [ ] aes-gcm when RICE_ENCRYPT_STATE — key from SOPS / env path
// [ ] post-quantum — Kyber/Dilithium per RICE_PQ_ALGORITHM when feature enabled

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

/// Ed25519 verify — thin wrapper; use `deps.api.verify` in handlers when integrating with CosmWasm API.
pub mod ed25519 {
    pub use ed25519_dalek::{Signature, VerifyingKey};
}

/// AES-GCM primitives (nonce + key management stays in your protocol layer).
pub mod aes {
    pub use aes_gcm::{Aes256Gcm, Key};
}

/// Post-quantum primitives — enable with `--features post-quantum` on native targets (see `Cargo.toml`).
#[cfg(feature = "post-quantum")]
pub mod pq {
    pub use pqcrypto::traits as pq_traits;
}

#[cfg(not(feature = "post-quantum"))]
pub mod pq {
    //! Enable `post-quantum` Cargo feature to link `pqcrypto` (native / tests — not for default wasm).
}
