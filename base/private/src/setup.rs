//! Trusted setup — Groth16 CRS lifecycle with ceremony binding, environment guards, and efficient I/O.
//!
//! **Production:** `CLERK_ENV=production` (or `prod`) forces **load-only** from
//! [`ParameterStore::from_env`]. Inline generation returns [`PrivateError::SetupPolicy`]. Ceremony
//! bytes must match [`Circuit::ceremony_sha256`]; optional sidecar [`CEREMONY_FILE`] must agree.
//!
//! **Development:** With [`DEV_CEREMONY_SHA256_PLACEHOLDER`], [`get_or_generate_params`] may generate
//! once and cache under [`ParameterStore::from_env_or_dev_fallback`].
//!
//! **I/O:** Large proving keys use mmap-backed reads and buffered writes via [`crate::serial`].

use ark_crypto_primitives::snark::CircuitSpecificSetupSNARK;
use ark_bn254::Bn254;
use ark_ec::pairing::Pairing;
use ark_groth16::{Groth16, ProvingKey, VerifyingKey};
use ark_relations::r1cs::ConstraintSynthesizer;
use ark_std::rand::{CryptoRng, RngCore};
use util::bytes::{decode_hex, encode_hex_lower as hex_encode};
use sha2::{Digest, Sha256};
use std::fmt;
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};

use crate::circuit::{IdentityOpeningCircuit, MulCircuit, ShieldedTransferCircuit};
use crate::error::PrivateError;
use crate::identity::ParameterUpdateAuthorization;
use crate::serial::{
    proving_key_from_file_mmap, proving_key_to_bytes_compressed, proving_key_to_file_compressed,
    verifying_key_from_bytes_compressed, verifying_key_from_file_mmap,
    verifying_key_to_bytes_compressed, verifying_key_to_file_compressed,
};

/// Sidecar next to keys: hex-encoded SHA-256 of `vk_cmp || pk_cmp` (64 hex chars, ASCII).
pub const CEREMONY_FILE: &str = "ceremony.sha256";
pub const VK_FILE: &str = "verifying_key.cmp";
pub const PK_FILE: &str = "proving_key.cmp";

/// Sentinel [`Circuit::ceremony_sha256`]: non-production may generate/cache; **production forbids**.
pub const DEV_CEREMONY_SHA256_PLACEHOLDER: [u8; 32] = [0u8; 32];

/// Human-short verifying-key fingerprint for logs (first 4 bytes of SHA-256 over compressed VK).
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
pub struct VkId(pub [u8; 4]);

impl fmt::Display for VkId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", hex_encode(&self.0[..]))
    }
}

/// Compute [`VkId`] from a verifying key (canonical compressed encoding).
pub fn vk_id<E: Pairing>(vk: &VerifyingKey<E>) -> Result<VkId, PrivateError> {
    let b = verifying_key_to_bytes_compressed(vk)?;
    let h = Sha256::digest(b.as_ref());
    Ok(VkId(
        h[..4].try_into().expect("SHA-256 yields at least 4 bytes"),
    ))
}

/// Groth16 parameters with audit metadata.
pub struct Groth16Params<E: Pairing> {
    pub pk: ProvingKey<E>,
    pub vk: VerifyingKey<E>,
    pub verifying_key_id: VkId,
    /// SHA-256 of `verifying_key_compressed || proving_key_compressed`.
    pub ceremony_sha256: [u8; 32],
}

/// Circuits eligible for [`get_or_generate_params`] / [`ParameterStore`].
pub trait Circuit<E: Pairing> {
    type CS: ConstraintSynthesizer<E::ScalarField>;

    fn for_setup() -> Self::CS;

    /// Directory name under the parameter root (stable, versioned).
    fn circuit_id() -> &'static str;

    /// Expected SHA-256 of `sha256(verifying_key_compressed || proving_key_compressed)`.
    ///
    /// Use [`DEV_CEREMONY_SHA256_PLACEHOLDER`] for harness circuits in local dev only.
    fn ceremony_sha256() -> [u8; 32];
}

/// Harness for [`MulCircuit`] (teaching / integration).
#[derive(Clone, Copy, Debug, Default)]
pub struct MulSetup;

impl<E: Pairing> Circuit<E> for MulSetup {
    type CS = MulCircuit<E::ScalarField>;

    fn for_setup() -> Self::CS {
        MulCircuit::for_setup()
    }

    fn circuit_id() -> &'static str {
        "rice.zk.mul-harness.v1"
    }

    fn ceremony_sha256() -> [u8; 32] {
        DEV_CEREMONY_SHA256_PLACEHOLDER
    }
}

/// Registry entry for [`crate::circuit::IdentityOpeningCircuit`] (BN254).
#[derive(Clone, Copy, Debug, Default)]
pub struct IdentityOpeningSetup;

impl Circuit<Bn254> for IdentityOpeningSetup {
    type CS = IdentityOpeningCircuit;

    fn for_setup() -> Self::CS {
        IdentityOpeningCircuit::for_setup()
    }

    fn circuit_id() -> &'static str {
        "rice.zk.identity-opening.v1"
    }

    fn ceremony_sha256() -> [u8; 32] {
        DEV_CEREMONY_SHA256_PLACEHOLDER
    }
}

/// Registry entry for [`crate::circuit::ShieldedTransferCircuit`] (BN254).
#[derive(Clone, Copy, Debug, Default)]
pub struct ShieldedTransferSetup;

impl Circuit<Bn254> for ShieldedTransferSetup {
    type CS = ShieldedTransferCircuit;

    fn for_setup() -> Self::CS {
        ShieldedTransferCircuit::for_setup()
    }

    fn circuit_id() -> &'static str {
        "rice.zk.shielded-transfer.v1"
    }

    fn ceremony_sha256() -> [u8; 32] {
        DEV_CEREMONY_SHA256_PLACEHOLDER
    }
}

/// Root directory for ceremony or dev-cache material.
#[derive(Clone, Debug)]
pub struct ParameterStore {
    root: PathBuf,
}

impl ParameterStore {
    /// Construct a store with an explicit root (tests, custom layouts).
    #[inline]
    pub fn with_root(root: PathBuf) -> Self {
        Self { root }
    }

    /// Load store from `CLERK_ZK_TRUSTED_SETUP_PATH`.
    pub fn from_env() -> Result<Self, PrivateError> {
        let path = std::env::var("CLERK_ZK_TRUSTED_SETUP_PATH").map_err(|_| {
            PrivateError::SetupMissing(
                "CLERK_ZK_TRUSTED_SETUP_PATH is not set".into(),
            )
        })?;
        Ok(Self {
            root: PathBuf::from(path),
        })
    }

    /// Development default when env is unset: [`dev_fallback_cache_root`].
    #[inline]
    pub fn dev_fallback_cache_root() -> PathBuf {
        std::env::temp_dir().join("rice-zk-dev-cache")
    }

    /// Prefer `CLERK_ZK_TRUSTED_SETUP_PATH`; in non-production only, fall back to temp dev cache.
    pub fn from_env_or_dev_fallback() -> Result<Self, PrivateError> {
        match std::env::var("CLERK_ZK_TRUSTED_SETUP_PATH") {
            Ok(p) => Ok(Self { root: PathBuf::from(p) }),
            Err(_) => {
                if is_production_clerk_env() {
                    Err(PrivateError::SetupMissing(
                        "CLERK_ZK_TRUSTED_SETUP_PATH must be set when CLERK_ENV=production".into(),
                    ))
                } else {
                    Ok(Self {
                        root: Self::dev_fallback_cache_root(),
                    })
                }
            }
        }
    }

    #[inline]
    pub fn root(&self) -> &Path {
        &self.root
    }

    fn circuit_dir<C: Circuit<E>, E: Pairing>(&self) -> PathBuf {
        self.root.join(C::circuit_id())
    }

    /// Verifier-only: mmap the compressed verifying key for [`C::circuit_id`].
    ///
    /// Does **not** load the proving key or re-check [`CEREMONY_FILE`] against `vk||pk`; embed or
    /// pin [`VkId`] at policy boundaries when you need ceremony discipline without reading PK bytes.
    pub fn load_verifying_key<C, E>(&self) -> Result<(VerifyingKey<E>, VkId), PrivateError>
    where
        C: Circuit<E>,
        E: Pairing,
    {
        let vk_path = self.circuit_dir::<C, E>().join(VK_FILE);
        if !vk_path.is_file() {
            return Err(PrivateError::SetupMissing(format!(
                "missing verifying key under {:?} (expected {})",
                vk_path, VK_FILE
            )));
        }
        let vk = verifying_key_from_file_mmap::<E>(&vk_path)?;
        let id = vk_id(&vk)?;
        Ok((vk, id))
    }

    /// Load PK/VK from disk (mmap). Verifies ceremony binding.
    pub fn load_groth16_params<C, E>(&self) -> Result<Groth16Params<E>, PrivateError>
    where
        C: Circuit<E>,
        E: Pairing,
    {
        let dir = self.circuit_dir::<C, E>();
        let vk_path = dir.join(VK_FILE);
        let pk_path = dir.join(PK_FILE);
        if !vk_path.is_file() || !pk_path.is_file() {
            return Err(PrivateError::SetupMissing(format!(
                "missing Groth16 params under {:?} (expected {} and {})",
                dir, VK_FILE, PK_FILE
            )));
        }

        let vk = verifying_key_from_file_mmap::<E>(&vk_path)?;
        let pk = proving_key_from_file_mmap::<E>(&pk_path)?;

        let vk_cmp = verifying_key_to_bytes_compressed(&vk)?;
        let pk_cmp = proving_key_to_bytes_compressed(&pk)?;
        let computed = params_blob_sha256(vk_cmp.as_ref(), pk_cmp.as_ref());

        let ceremony_path = dir.join(CEREMONY_FILE);
        let on_disk = read_ceremony_hex_file(&ceremony_path)?;

        if is_production_clerk_env() {
            if C::ceremony_sha256() == DEV_CEREMONY_SHA256_PLACEHOLDER {
                return Err(PrivateError::SetupPolicy(
                    "production refuses DEV_CEREMONY_SHA256_PLACEHOLDER; pin Circuit::ceremony_sha256"
                        .into(),
                ));
            }
            if computed != C::ceremony_sha256() {
                return Err(PrivateError::SetupCorrupted(format!(
                    "ceremony SHA-256 mismatch for {}: expected {}, got {}",
                    C::circuit_id(),
                    hex_encode(C::ceremony_sha256().as_slice()),
                    hex_encode(computed.as_slice())
                )));
            }
            let sidecar = on_disk.ok_or_else(|| {
                PrivateError::SetupMissing(format!(
                    "production requires {} beside keys under {:?}",
                    CEREMONY_FILE, dir
                ))
            })?;
            if sidecar != computed {
                return Err(PrivateError::SetupCorrupted(format!(
                    "{CEREMONY_FILE} does not match recomputed key hash for {}",
                    C::circuit_id()
                )));
            }
        } else if C::ceremony_sha256() != DEV_CEREMONY_SHA256_PLACEHOLDER {
            if computed != C::ceremony_sha256() {
                return Err(PrivateError::SetupCorrupted(format!(
                    "ceremony hash mismatch for {} (dev pinned)",
                    C::circuit_id()
                )));
            }
            if let Some(sidecar) = on_disk {
                if sidecar != computed {
                    return Err(PrivateError::SetupCorrupted(format!(
                        "{CEREMONY_FILE} disagrees with keys for {}",
                        C::circuit_id()
                    )));
                }
            }
        } else if let Some(sidecar) = on_disk {
            if sidecar != computed {
                return Err(PrivateError::SetupCorrupted(format!(
                    "cached params corrupt for {}",
                    C::circuit_id()
                )));
            }
        }

        let verifying_key_id = vk_id(&vk)?;
        Ok(Groth16Params {
            pk,
            vk,
            verifying_key_id,
            ceremony_sha256: computed,
        })
    }

    /// Write PK/VK + [`CEREMONY_FILE`]. **Production** requires [`ParameterUpdateAuthorization`].
    pub fn persist_groth16_params<C, E>(
        &self,
        params: &Groth16Params<E>,
        auth: Option<&ParameterUpdateAuthorization>,
    ) -> Result<(), PrivateError>
    where
        C: Circuit<E>,
        E: Pairing,
    {
        if is_production_clerk_env() && auth.is_none() {
            return Err(PrivateError::SetupPolicy(
                "production persists Groth16 params only with ParameterUpdateAuthorization from .rice identity"
                    .into(),
            ));
        }
        if let Some(auth) = auth {
            auth.verify_identity_gate(self)?;
        }

        let dir = self.circuit_dir::<C, E>();
        fs::create_dir_all(&dir).map_err(PrivateError::StorageIo)?;

        verifying_key_to_file_compressed(&dir.join(VK_FILE), &params.vk)?;
        proving_key_to_file_compressed(&dir.join(PK_FILE), &params.pk)?;
        write_ceremony_hex_file(&dir.join(CEREMONY_FILE), &params.ceremony_sha256)?;
        Ok(())
    }

    /// Verifier-only: load VK from **embedded** bytes. `expected_sha256` is SHA-256 over `vk_bytes`.
    pub fn load_verifying_key_embedded<E: Pairing>(
        vk_bytes: &'static [u8],
        expected_sha256: [u8; 32],
    ) -> Result<(VerifyingKey<E>, VkId), PrivateError> {
        let digest: [u8; 32] = Sha256::digest(vk_bytes).into();
        if digest != expected_sha256 {
            return Err(PrivateError::SetupCorrupted(
                "embedded VK bytes do not match expected SHA-256 (ceremony / release binding)".into(),
            ));
        }
        let vk = verifying_key_from_bytes_compressed(vk_bytes)?;
        let id = vk_id(&vk)?;
        Ok((vk, id))
    }
}

#[inline]
fn params_blob_sha256(vk_cmp: &[u8], pk_cmp: &[u8]) -> [u8; 32] {
    let mut h = Sha256::new();
    h.update(vk_cmp);
    h.update(pk_cmp);
    h.finalize().into()
}

fn read_ceremony_hex_file(path: &Path) -> Result<Option<[u8; 32]>, PrivateError> {
    if !path.is_file() {
        return Ok(None);
    }
    let f = fs::File::open(path).map_err(PrivateError::StorageIo)?;
    let mut line = String::new();
    BufReader::new(f)
        .read_line(&mut line)
        .map_err(PrivateError::StorageIo)?;
    let line = line.trim();
    if line.len() != 64 {
        return Err(PrivateError::SetupCorrupted(format!(
            "{CEREMONY_FILE}: expected 64 hex chars, got length {}",
            line.len()
        )));
    }
    let decoded = decode_hex(line).map_err(|e| {
        PrivateError::SetupCorrupted(format!("{CEREMONY_FILE} invalid hex: {e}"))
    })?;
    if decoded.len() != 32 {
        return Err(PrivateError::SetupCorrupted(format!(
            "{CEREMONY_FILE}: expected 32 decoded bytes, got {}",
            decoded.len()
        )));
    }
    let mut out = [0u8; 32];
    out.copy_from_slice(&decoded);
    Ok(Some(out))
}

fn write_ceremony_hex_file(path: &Path, hash: &[u8; 32]) -> Result<(), PrivateError> {
    let mut f = fs::File::create(path).map_err(PrivateError::StorageIo)?;
    writeln!(f, "{}", hex_encode(hash.as_slice())).map_err(PrivateError::StorageIo)?;
    Ok(())
}

/// `true` when `CLERK_ENV` is `production` or `prod` (ASCII case-insensitive).
pub fn is_production_clerk_env() -> bool {
    matches!(
        std::env::var("CLERK_ENV")
            .map(|s| s.to_ascii_lowercase())
            .as_deref(),
        Ok("production" | "prod")
    )
}

/// Load from store, or generate + cache in **non-production** when [`Circuit::ceremony_sha256`]
/// is [`DEV_CEREMONY_SHA256_PLACEHOLDER`].
pub fn get_or_generate_params<C, E, R>(
    store: &ParameterStore,
    rng: &mut R,
) -> Result<Groth16Params<E>, PrivateError>
where
    C: Circuit<E>,
    E: Pairing,
    R: RngCore + CryptoRng,
{
    match store.load_groth16_params::<C, E>() {
        Ok(p) => return Ok(p),
        Err(PrivateError::SetupMissing(_)) => {}
        Err(e) => return Err(e),
    }

    if is_production_clerk_env() {
        return Err(PrivateError::SetupPolicy(
            "CLERK_ENV=production: refuse inline Groth16 generation; load ceremony from CLERK_ZK_TRUSTED_SETUP_PATH"
                .into(),
        ));
    }

    if C::ceremony_sha256() != DEV_CEREMONY_SHA256_PLACEHOLDER {
        return Err(PrivateError::SetupPolicy(
            "pinned ceremony hash requires an on-disk bundle; place keys under the parameter store root"
                .into(),
        ));
    }

    let (pk, vk) = Groth16::<E>::setup(C::for_setup(), rng)?;
    let vk_cmp = verifying_key_to_bytes_compressed(&vk)?;
    let pk_cmp = proving_key_to_bytes_compressed(&pk)?;
    let ceremony_sha256 = params_blob_sha256(vk_cmp.as_ref(), pk_cmp.as_ref());
    let verifying_key_id = vk_id(&vk)?;

    let params = Groth16Params {
        pk,
        vk,
        verifying_key_id,
        ceremony_sha256,
    };
    store.persist_groth16_params::<C, E>(&params, None)?;
    Ok(params)
}

/// One-shot setup for [`MulCircuit`] (backwards-compatible with early integration tests).
pub fn trusted_setup<E: Pairing, R: RngCore + CryptoRng>(
    rng: &mut R,
) -> Result<(ProvingKey<E>, VerifyingKey<E>), PrivateError> {
    let (pk, vk) = Groth16::<E>::setup(MulCircuit::<E::ScalarField>::for_setup(), rng)?;
    Ok((pk, vk))
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use super::*;
    use ark_bn254::Bn254;
    use ark_std::rand::SeedableRng;
    use rand::rngs::StdRng;

    static SETUP_ENV_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn dev_cache_roundtrip_mul_harness() {
        let _guard = SETUP_ENV_LOCK.lock().expect("setup test lock poisoned");
        unsafe {
            std::env::remove_var("CLERK_ENV");
        }
        let root = std::env::temp_dir().join(format!(
            "rice-zk-setup-test-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_nanos())
                .unwrap_or(0)
        ));
        let _ = fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root.clone());
        let mut rng = StdRng::from_seed([9u8; 32]);
        let p1 = get_or_generate_params::<MulSetup, Bn254, _>(&store, &mut rng).unwrap();
        let p2 = get_or_generate_params::<MulSetup, Bn254, _>(&store, &mut rng).unwrap();
        assert_eq!(p1.ceremony_sha256, p2.ceremony_sha256);
        assert_eq!(
            p1.verifying_key_id.to_string().len(),
            8,
            "VkId is 4 bytes hex = 8 chars"
        );
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn production_blocks_inline_generate() {
        let _guard = SETUP_ENV_LOCK.lock().expect("setup test lock poisoned");
        let root = std::env::temp_dir().join("rice-zk-prod-guard-test");
        let _ = fs::remove_dir_all(&root);
        let store = ParameterStore::with_root(root);
        let mut rng = StdRng::from_seed([1u8; 32]);
        // SAFETY: test is single-threaded; `set_var` is `unsafe` in Rust 2024 due to process-wide races.
        unsafe {
            std::env::set_var("CLERK_ENV", "production");
        }
        let out = get_or_generate_params::<MulSetup, Bn254, _>(&store, &mut rng);
        unsafe {
            std::env::remove_var("CLERK_ENV");
        }
        assert!(matches!(out, Err(PrivateError::SetupPolicy(_))));
    }
}
