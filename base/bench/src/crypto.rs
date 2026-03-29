//! Host crypto — Ed25519, AES-GCM, SHA-256 (PQ behind `--features bench-pq` when wired).
#![allow(deprecated)] // aes-gcm 0.10 / digest generic-array `from_slice` until stack upgrades

use aes_gcm::aead::{Aead, KeyInit};
use aes_gcm::{Aes256Gcm, Key, Nonce};
use criterion::{black_box, Criterion};
use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use rand::rngs::StdRng;
use rand::SeedableRng;
use sha2::{Digest, Sha256};

// [ ] https://docs.rs/criterion/
// [ ] ed25519 sign/verify, aes-gcm, sha256 sizes; bench-pq feature

pub fn register(c: &mut Criterion) {
    let mut rng = StdRng::from_seed([8u8; 32]);
    let signing_key = SigningKey::generate(&mut rng);
    let verifying_key = VerifyingKey::from(&signing_key);
    let message: &[u8] = b"rice-bench ed25519 message";
    let signature: Signature = signing_key.sign(message);

    let key = Key::<Aes256Gcm>::from_slice(&[0x5au8; 32]);
    let cipher = Aes256Gcm::new(key);
    let nonce = Nonce::from_slice(b"0123456789ab");
    let plaintext = b"rice-bench aes-gcm";
    let ciphertext = cipher
        .encrypt(nonce, plaintext.as_ref())
        .expect("encrypt once");

    let mut g = c.benchmark_group("crypto");
    g.bench_function("sha256_1kb", |b| {
        let buf = [0xabu8; 1024];
        b.iter(|| Sha256::digest(black_box(&buf)))
    });
    g.bench_function("ed25519_sign", |b| {
        b.iter(|| signing_key.sign(black_box(message)))
    });
    g.bench_function("ed25519_verify", |b| {
        b.iter(|| verifying_key.verify(black_box(message), black_box(&signature)))
    });
    g.bench_function("aes256gcm_encrypt", |b| {
        b.iter(|| {
            cipher
                .encrypt(black_box(nonce), black_box(plaintext.as_ref()))
                .unwrap()
        })
    });
    g.bench_function("aes256gcm_decrypt", |b| {
        b.iter(|| {
            cipher
                .decrypt(black_box(nonce), black_box(ciphertext.as_ref()))
                .unwrap()
        })
    });
    g.finish();
}
