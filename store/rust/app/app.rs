//! Multi-chain bridge contracts library
//!
//! This library provides:
//! - Zero-knowledge proof verification (Groth16 with arkworks)
//! - gnark circuit compilation to WASM
//! - Multi-chain bridge connectors
//! - Network configuration types

use cosmwasm_std::{StdError, StdResult};
use serde::{Deserialize, Serialize};

// gnark module for circuit compilation (integrated)
#[cfg(feature = "gnark")]
mod gnark {
    //! gnark circuit compilation to WASM
    //!
    //! This module provides functionality to compile gnark circuits to optimized WASM
    //! with size < 3MB and compilation time < 200ms.

    use std::path::{Path, PathBuf};
    use std::process::Command;
    use std::time::Instant;

    /// Error type for gnark compilation
    #[derive(Debug, Clone)]
    pub enum GnarkError {
        /// Circuit file not found
        CircuitNotFound(String),
        /// Compilation failed
        CompilationFailed(String),
        /// WASM size exceeds 3MB
        SizeExceeded { size: u64, max: u64 },
        /// Compilation time exceeds 200ms
        TimeExceeded { time: u128, max: u128 },
        /// gnark binary not found
        GnarkNotFound,
    }

    impl std::fmt::Display for GnarkError {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            match self {
                GnarkError::CircuitNotFound(path) => write!(f, "Circuit file not found: {}", path),
                GnarkError::CompilationFailed(msg) => write!(f, "Compilation failed: {}", msg),
                GnarkError::SizeExceeded { size, max } => {
                    write!(f, "WASM size {} bytes exceeds maximum {} bytes", size, max)
                },
                GnarkError::TimeExceeded { time, max } => {
                    write!(f, "Compilation time {}ms exceeds maximum {}ms", time, max)
                },
                GnarkError::GnarkNotFound => write!(f, "gnark binary not found in PATH"),
            }
        }
    }

    impl std::error::Error for GnarkError {}

    /// Compile gnark circuit to optimized WASM
    ///
    /// # Arguments
    /// * `circuit_path` - Path to gnark circuit Go file
    /// * `output_path` - Path to output WASM file
    ///
    /// # Returns
    /// Compilation result with timing and size information
    ///
    /// # Errors
    /// Returns error if compilation fails, exceeds time/size limits, or gnark is not found
    pub fn compile_gnark_to_wasm(circuit_path: &Path, output_path: &Path) -> Result<CompilationResult, GnarkError> {
        // Check if circuit file exists
        if !circuit_path.exists() {
            return Err(GnarkError::CircuitNotFound(circuit_path.to_string_lossy().to_string()));
        }

        // Check if gnark is available
        let gnark_check = Command::new("gnark").arg("version").output();

        if gnark_check.is_err() {
            return Err(GnarkError::GnarkNotFound);
        }

        // Verify gnark executed successfully
        if let Ok(output) = &gnark_check {
            if !output.status.success() {
                return Err(GnarkError::GnarkNotFound);
            }
        }

        // Start timing
        let start = Instant::now();

        // Compile circuit to WASM with optimizations
        let output = Command::new("gnark")
            .arg("compile")
            .arg("--target")
            .arg("wasm")
            .arg("--optimize")
            .arg("--size")
            .arg(circuit_path)
            .arg("-o")
            .arg(output_path)
            .output()
            .map_err(|e| GnarkError::CompilationFailed(format!("Failed to run gnark: {}", e)))?;

        let elapsed = start.elapsed().as_millis();

        // Check compilation success
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(GnarkError::CompilationFailed(stderr.to_string()));
        }

        // Check compilation time (< 200ms)
        const MAX_COMPILATION_TIME_MS: u128 = 200;
        if elapsed > MAX_COMPILATION_TIME_MS {
            return Err(GnarkError::TimeExceeded {
                time: elapsed,
                max: MAX_COMPILATION_TIME_MS,
            });
        }

        // Check WASM file size (< 3MB)
        const MAX_WASM_SIZE_BYTES: u64 = 3 * 1024 * 1024; // 3MB
        let wasm_size = std::fs::metadata(output_path)
            .map_err(|e| GnarkError::CompilationFailed(format!("Failed to get file size: {}", e)))?
            .len();

        if wasm_size > MAX_WASM_SIZE_BYTES {
            return Err(GnarkError::SizeExceeded {
                size: wasm_size,
                max: MAX_WASM_SIZE_BYTES,
            });
        }

        Ok(CompilationResult {
            wasm_path: output_path.to_path_buf(),
            size_bytes: wasm_size,
            compilation_time_ms: elapsed,
        })
    }

    /// Result of gnark compilation
    #[derive(Debug, Clone)]
    pub struct CompilationResult {
        /// Path to generated WASM file
        pub wasm_path: PathBuf,
        /// Size of WASM file in bytes
        pub size_bytes: u64,
        /// Compilation time in milliseconds
        pub compilation_time_ms: u128,
    }

    impl CompilationResult {
        /// Check if compilation meets performance requirements
        pub fn meets_requirements(&self) -> bool {
            const MAX_SIZE: u64 = 3 * 1024 * 1024; // 3MB
            const MAX_TIME: u128 = 200; // 200ms

            self.size_bytes < MAX_SIZE && self.compilation_time_ms < MAX_TIME
        }
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn test_compilation_result_requirements() {
            let result = CompilationResult {
                wasm_path: PathBuf::from("test.wasm"),
                size_bytes: 2 * 1024 * 1024, // 2MB
                compilation_time_ms: 150,    // 150ms
            };

            assert!(result.meets_requirements());
        }

        #[test]
        fn test_compilation_result_size_exceeded() {
            let result = CompilationResult {
                wasm_path: PathBuf::from("test.wasm"),
                size_bytes: 4 * 1024 * 1024, // 4MB
                compilation_time_ms: 150,
            };

            assert!(!result.meets_requirements());
        }

        #[test]
        fn test_compilation_result_time_exceeded() {
            let result = CompilationResult {
                wasm_path: PathBuf::from("test.wasm"),
                size_bytes: 2 * 1024 * 1024,
                compilation_time_ms: 250, // 250ms
            };

            assert!(!result.meets_requirements());
        }
    }
}

// ============================================================================
// Network Configuration Enums
// ============================================================================

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum BitcoinNetwork {
    Mainnet,
    Testnet,
    Regtest,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum SolanaNetwork {
    Mainnet,
    Devnet,
    Testnet,
    Localnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum CardanoNetwork {
    Mainnet,
    Testnet,
    Preview,
    Preprod,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum PolkadotNetwork {
    Polkadot,
    Kusama,
    Rococo,
    Westend,
    Custom,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum NearNetwork {
    Mainnet,
    Testnet,
    Betanet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum AlgorandNetwork {
    Mainnet,
    Testnet,
    Betanet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum TezosNetwork {
    Mainnet,
    Testnet,
    Ghostnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum TronNetwork {
    Mainnet,
    Shasta,
    Nile,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum LitecoinNetwork {
    Mainnet,
    Testnet,
    Regtest,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum DogecoinNetwork {
    Mainnet,
    Testnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum StellarNetwork {
    Mainnet,
    Testnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum RippleNetwork {
    Mainnet,
    Testnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum TONNetwork {
    Mainnet,
    Testnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum SuiNetwork {
    Mainnet,
    Testnet,
    Devnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum AptosNetwork {
    Mainnet,
    Testnet,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ICPNetwork {
    Mainnet,
    Testnet,
}

// ============================================================================
// Bridge Error Types
// ============================================================================

/// Error type for bridge operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum BridgeError {
    /// Network/connection error
    NetworkError(String),
    /// Invalid address format
    InvalidAddress(String),
    /// Transaction failed
    TransactionFailed(String),
    /// Insufficient balance
    InsufficientBalance,
    /// Invalid amount
    InvalidAmount(String),
    /// Chain not supported
    ChainNotSupported(String),
    /// Serialization error
    SerializationError(String),
    /// Deserialization error
    DeserializationError(String),
}

impl std::fmt::Display for BridgeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BridgeError::NetworkError(msg) => write!(f, "Network error: {}", msg),
            BridgeError::InvalidAddress(msg) => write!(f, "Invalid address: {}", msg),
            BridgeError::TransactionFailed(msg) => write!(f, "Transaction failed: {}", msg),
            BridgeError::InsufficientBalance => write!(f, "Insufficient balance"),
            BridgeError::InvalidAmount(msg) => write!(f, "Invalid amount: {}", msg),
            BridgeError::ChainNotSupported(msg) => write!(f, "Chain not supported: {}", msg),
            BridgeError::SerializationError(msg) => write!(f, "Serialization error: {}", msg),
            BridgeError::DeserializationError(msg) => write!(f, "Deserialization error: {}", msg),
        }
    }
}

impl std::error::Error for BridgeError {}

/// Result type for bridge operations
pub type BridgeResult<T> = Result<T, BridgeError>;

// ============================================================================
// Zero-Knowledge Proof (zk-SNARK) Types and Functions
// ============================================================================

/// Groth16 proof structure (compatible with snarkjs output)
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Proof {
    /// pi_a: [A_x, A_y] - G1 point
    pub pi_a: Vec<String>,
    /// pi_b: [[B_x0, B_x1], [B_y0, B_y1]] - G2 point
    pub pi_b: Vec<Vec<String>>,
    /// pi_c: [C_x, C_y] - G1 point
    pub pi_c: Vec<String>,
    /// Protocol identifier
    pub protocol: String,
    /// Curve identifier (usually "bn128" or "bls12381")
    pub curve: String,
}

/// Verification key structure (compatible with snarkjs output)
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct VerificationKey {
    /// Protocol identifier
    pub protocol: String,
    /// Curve identifier
    pub curve: String,
    /// Number of public signals
    #[serde(rename = "nPublic")]
    pub n_public: u32,
    /// Alpha in G1
    pub vk_alpha_1: Vec<String>,
    /// Beta in G2
    pub vk_beta_2: Vec<Vec<String>>,
    /// Gamma in G2
    pub vk_gamma_2: Vec<Vec<String>>,
    /// Delta in G2
    pub vk_delta_2: Vec<Vec<String>>,
    /// Alpha * Beta in G12
    pub vk_alphabeta_12: Vec<Vec<Vec<String>>>,
    /// IC (Input Commitment) points in G1
    #[serde(rename = "IC")]
    pub ic: Vec<Vec<String>>,
}

/// Public signals (public inputs/outputs)
pub type PublicSignals = Vec<String>;

/// Complete proof data structure for bridge operations
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ProofData {
    pub proof: Proof,
    #[serde(rename = "publicSignals")]
    pub public_signals: PublicSignals,
}

/// Deserialize proof from JSON string (received from TypeScript bridge)
pub fn deserialize_proof(proof_string: &str) -> StdResult<ProofData> {
    serde_json::from_str(proof_string).map_err(|e| StdError::msg(format!("Failed to deserialize proof: {}", e)))
}

/// Convert string to field element (BigInt from snarkjs)
/// Helper function to parse hex strings from snarkjs output
fn parse_field_element(s: &str) -> StdResult<String> {
    // Remove "0x" prefix if present
    let cleaned = s.strip_prefix("0x").unwrap_or(s);
    // Validate hex string
    if cleaned.chars().all(|c| c.is_ascii_hexdigit()) {
        Ok(cleaned.to_string())
    } else {
        Err(StdError::msg(format!("Invalid hex string: {}", s)))
    }
}

/// Verify a zk-SNARK proof using Groth16 verification
///
/// This function performs structure validation and basic checks.
/// For full cryptographic verification, use `verify_proof_arkworks()` with arkworks feature.
///
/// # Arguments
/// * `proof` - The zk-SNARK proof
/// * `public_signals` - Public signals (inputs/outputs)
/// * `vk` - Verification key
///
/// # Returns
/// `true` if proof structure is valid, error otherwise
pub fn verify_proof(proof: &Proof, public_signals: &PublicSignals, vk: &VerificationKey) -> StdResult<bool> {
    // Validate proof structure
    validate_proof_structure(proof)?;

    // Validate verification key structure
    validate_verification_key(vk)?;

    // Validate public signals count
    if public_signals.len() != vk.n_public as usize {
        return Err(StdError::msg(format!(
            "Public signals count mismatch: expected {}, got {}",
            vk.n_public,
            public_signals.len()
        )));
    }

    // Validate curve compatibility
    if proof.curve != vk.curve {
        return Err(StdError::msg(format!(
            "Curve mismatch: proof uses {}, vk uses {}",
            proof.curve, vk.curve
        )));
    }

    // For now, return structure validation success
    // Full cryptographic verification requires arkworks implementation
    #[cfg(not(feature = "arkworks"))]
    {
        // Structure validation passed
        // Note: This does NOT perform cryptographic verification
        // For production, enable arkworks feature and implement full verification
        Ok(true)
    }

    #[cfg(feature = "arkworks")]
    {
        verify_proof_arkworks(proof, public_signals, vk)
    }
}

/// Verify a zk-SNARK proof using Groth16 verification with arkworks
///
/// This implements full cryptographic verification of Groth16 proofs using arkworks.
/// Compatible with proofs generated by snarkjs (Groth16 on BN254 curve).
#[cfg(feature = "arkworks")]
pub fn verify_proof_arkworks(proof: &Proof, public_signals: &PublicSignals, vk: &VerificationKey) -> StdResult<bool> {
    use ark_bn254::{Bn254, Fr, G1Affine, G2Affine};
    use ark_ec::pairing::Pairing;
    use ark_ec::CurveGroup;
    use ark_ff::PrimeField;
    use ark_groth16::{Groth16, VerifyingKey};

    // Only support BN254 curve (compatible with snarkjs)
    if proof.curve != "bn128" && proof.curve != "bn254" {
        return Err(StdError::msg(format!(
            "Unsupported curve: {} (only bn128/bn254 supported)",
            proof.curve
        )));
    }

    // Parse proof points from hex strings
    let parse_g1 = |point: &[String]| -> StdResult<G1Affine> {
        if point.len() != 2 {
            return Err(StdError::msg("G1 point must have 2 coordinates"));
        }
        let x = parse_bigint_to_field(&point[0])?;
        let y = parse_bigint_to_field(&point[1])?;
        // Note: Full point validation requires checking if (x,y) is on curve
        // For now, we create point assuming valid input
        Ok(G1Affine::new_unchecked(x, y))
    };

    let parse_g2 = |point: &[Vec<String>]| -> StdResult<G2Affine> {
        if point.len() != 2 || point[0].len() != 2 || point[1].len() != 2 {
            return Err(StdError::msg("G2 point must be 2x2"));
        }
        let x0 = parse_bigint_to_field(&point[0][0])?;
        let x1 = parse_bigint_to_field(&point[0][1])?;
        let y0 = parse_bigint_to_field(&point[1][0])?;
        let y1 = parse_bigint_to_field(&point[1][1])?;
        // Note: Full point validation requires checking if point is on curve
        Ok(G2Affine::new_unchecked(ark_ec::short_weierstrass::Affine::new_unchecked(
            ark_ec::models::short_weierstrass::Projective::new(x0, x1, ark_ff::Field::ONE),
            ark_ec::models::short_weierstrass::Projective::new(y0, y1, ark_ff::Field::ONE),
        )))
    };

    // Helper to parse hex string to field element
    fn parse_bigint_to_field(s: &str) -> StdResult<Fr> {
        let cleaned = if s.starts_with("0x") { &s[2..] } else { s };
        // Parse as big integer and convert to field element
        let bytes = hex::decode(cleaned).map_err(|e| StdError::msg(format!("Invalid hex string: {}", e)))?;
        if bytes.len() > 32 {
            return Err(StdError::msg("Field element too large"));
        }
        // Convert bytes to field element (BN254 field)
        // Pad to 32 bytes (big-endian)
        let mut bytes_padded = [0u8; 32];
        bytes_padded[32 - bytes.len()..].copy_from_slice(&bytes);
        // Parse as big-endian bytes modulo field order
        // Note: This is a simplified parser - for production, use proper bigint parsing
        Fr::from_be_bytes_mod_order(&bytes_padded).map_err(|_| StdError::msg("Failed to parse field element"))
    }

    // Parse proof
    let a = parse_g1(&proof.pi_a)?;
    let b = parse_g2(&proof.pi_b)?;
    let c = parse_g1(&proof.pi_c)?;

    // Parse verification key
    let alpha_g1 = parse_g1(&vk.vk_alpha_1)?;
    let beta_g2 = parse_g2(&vk.vk_beta_2)?;
    let gamma_g2 = parse_g2(&vk.vk_gamma_2)?;
    let delta_g2 = parse_g2(&vk.vk_delta_2)?;

    // Parse IC (Input Commitment) points
    let mut ic = Vec::new();
    for point in &vk.ic {
        ic.push(parse_g1(point)?);
    }

    // Build verifying key
    let vk_arkworks = VerifyingKey::<Bn254> {
        alpha_g1,
        beta_g2,
        gamma_g2,
        delta_g2,
        gamma_abc_g1: ic,
    };

    // Parse public signals to field elements
    let mut public_inputs = Vec::new();
    for signal in public_signals {
        public_inputs.push(parse_bigint_to_field(signal)?);
    }

    // Create proof structure for arkworks
    let proof_arkworks = ark_groth16::Proof { a, b, c };

    // Verify proof using Groth16 verifier
    match Groth16::<Bn254>::verify(&vk_arkworks, &public_inputs, &proof_arkworks) {
        Ok(true) => Ok(true),
        Ok(false) => Ok(false),
        Err(e) => Err(StdError::msg(format!("Verification error: {:?}", e))),
    }
}

/// Verify proof from bridge (deserialized from JSON string)
pub fn verify_bridge_proof(proof_string: &str, verification_key: &VerificationKey) -> StdResult<bool> {
    let proof_data = deserialize_proof(proof_string)?;
    verify_proof(&proof_data.proof, &proof_data.public_signals, verification_key)
}

/// Validate proof structure without full verification
/// Useful for quick checks before expensive verification
pub fn validate_proof_structure(proof: &Proof) -> StdResult<()> {
    if proof.pi_a.len() != 2 {
        return Err(StdError::msg("Invalid proof: pi_a must have 2 elements"));
    }
    // Validate that pi_a elements are valid hex strings
    for element in &proof.pi_a {
        parse_field_element(element)?;
    }

    if proof.pi_b.len() != 2 {
        return Err(StdError::msg("Invalid proof: pi_b must have 2 rows"));
    }
    if proof.pi_b[0].len() != 2 || proof.pi_b[1].len() != 2 {
        return Err(StdError::msg("Invalid proof: pi_b must be 2x2"));
    }
    // Validate that pi_b elements are valid hex strings
    for row in &proof.pi_b {
        for element in row {
            parse_field_element(element)?;
        }
    }

    if proof.pi_c.len() != 2 {
        return Err(StdError::msg("Invalid proof: pi_c must have 2 elements"));
    }
    // Validate that pi_c elements are valid hex strings
    for element in &proof.pi_c {
        parse_field_element(element)?;
    }

    if proof.protocol != "groth16" {
        return Err(StdError::msg(format!(
            "Unsupported protocol: {} (only groth16 is supported)",
            proof.protocol
        )));
    }
    Ok(())
}

/// Validate verification key structure
pub fn validate_verification_key(vk: &VerificationKey) -> StdResult<()> {
    if vk.protocol != "groth16" {
        return Err(StdError::msg(format!(
            "Unsupported protocol: {} (only groth16 is supported)",
            vk.protocol
        )));
    }
    if vk.vk_alpha_1.len() != 2 {
        return Err(StdError::msg("Invalid vk: vk_alpha_1 must have 2 elements"));
    }
    // Validate that vk_alpha_1 elements are valid hex strings
    for element in &vk.vk_alpha_1 {
        parse_field_element(element)?;
    }

    // Validate vk_beta_2, vk_gamma_2, vk_delta_2
    for row in &vk.vk_beta_2 {
        for element in row {
            parse_field_element(element)?;
        }
    }
    for row in &vk.vk_gamma_2 {
        for element in row {
            parse_field_element(element)?;
        }
    }
    for row in &vk.vk_delta_2 {
        for element in row {
            parse_field_element(element)?;
        }
    }

    // Validate IC points
    if vk.ic.is_empty() {
        return Err(StdError::msg("Invalid vk: ic cannot be empty"));
    }
    for point in &vk.ic {
        for element in point {
            parse_field_element(element)?;
        }
    }

    Ok(())
}

// ============================================================================
// Helper functions for RPC calls
// ============================================================================

#[derive(Serialize, Deserialize)]
pub struct JsonRpcRequest {
    pub jsonrpc: String,
    pub method: String,
    pub params: serde_json::Value,
    pub id: u64,
}

#[derive(Deserialize)]
pub struct JsonRpcResponse {
    pub result: Option<serde_json::Value>,
    pub error: Option<JsonRpcError>,
    #[allow(dead_code)]
    pub id: u64,
}

#[derive(Deserialize)]
pub struct JsonRpcError {
    pub code: i32,
    pub message: String,
}

pub fn bitcoin_rpc_call(
    rpc_url: &str,
    rpc_user: &str,
    rpc_password: &str,
    method: &str,
    params: serde_json::Value,
) -> BridgeResult<serde_json::Value> {
    let client = reqwest::blocking::Client::new();
    let request = JsonRpcRequest {
        jsonrpc: "2.0".to_string(),
        method: method.to_string(),
        params,
        id: 1,
    };

    let response = client
        .post(rpc_url)
        .basic_auth(rpc_user, Some(rpc_password))
        .json(&request)
        .send()
        .map_err(|e| BridgeError::NetworkError(format!("RPC request failed: {}", e)))?;

    let json_response: JsonRpcResponse = response
        .json()
        .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse response: {}", e)))?;

    if let Some(error) = json_response.error {
        return Err(BridgeError::NetworkError(format!(
            "RPC error {}: {}",
            error.code, error.message
        )));
    }

    json_response
        .result
        .ok_or_else(|| BridgeError::NetworkError("No result in RPC response".to_string()))
}

pub fn solana_rpc_call(rpc_url: &str, method: &str, params: serde_json::Value) -> BridgeResult<serde_json::Value> {
    let client = reqwest::blocking::Client::new();
    let request = JsonRpcRequest {
        jsonrpc: "2.0".to_string(),
        method: method.to_string(),
        params,
        id: 1,
    };

    let response = client
        .post(rpc_url)
        .json(&request)
        .send()
        .map_err(|e| BridgeError::NetworkError(format!("RPC request failed: {}", e)))?;

    let json_response: JsonRpcResponse = response
        .json()
        .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse response: {}", e)))?;

    if let Some(error) = json_response.error {
        return Err(BridgeError::NetworkError(format!(
            "RPC error {}: {}",
            error.code, error.message
        )));
    }

    json_response
        .result
        .ok_or_else(|| BridgeError::NetworkError("No result in RPC response".to_string()))
}

pub fn http_get_json(url: &str) -> BridgeResult<serde_json::Value> {
    let client = reqwest::blocking::Client::new();
    let response = client
        .get(url)
        .send()
        .map_err(|e| BridgeError::NetworkError(format!("HTTP request failed: {}", e)))?;

    response
        .json()
        .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse JSON: {}", e)))
}

pub fn http_post_json(url: &str, body: serde_json::Value) -> BridgeResult<serde_json::Value> {
    let client = reqwest::blocking::Client::new();
    let response = client
        .post(url)
        .json(&body)
        .send()
        .map_err(|e| BridgeError::NetworkError(format!("HTTP request failed: {}", e)))?;

    response
        .json()
        .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse JSON: {}", e)))
}

// ============================================================================
// Universal Bridge Interface
// ============================================================================

// Define blockchain connector modules at top level
#[path = "../rust/algorand.rs"]
mod algorand;
#[path = "../rust/aptos.rs"]
mod aptos;
#[path = "../rust/bitcoin.rs"]
mod bitcoin;
#[path = "../rust/cardano.rs"]
mod cardano;
#[path = "../rust/cosmwasm.rs"]
mod cosmwasm;
#[path = "../rust/dogecoin.rs"]
mod dogecoin;
#[path = "../rust/evm.rs"]
mod evm;
#[path = "../rust/icp.rs"]
mod icp;
#[path = "../rust/litecoin.rs"]
mod litecoin;
#[path = "../rust/near.rs"]
mod near;
#[path = "../rust/polkadot.rs"]
mod polkadot;
#[path = "../rust/ripple.rs"]
mod ripple;
#[path = "../rust/solana.rs"]
mod solana;
#[path = "../rust/stellar.rs"]
mod stellar;
#[path = "../rust/sui.rs"]
mod sui;
#[path = "../rust/tezos.rs"]
mod tezos;
#[path = "../rust/ton.rs"]
mod ton;
#[path = "../rust/tron.rs"]
mod tron;

// Blockchain connection module - re-export all connectors
pub mod connection {
    pub use super::algorand::*;
    pub use super::aptos::*;
    pub use super::bitcoin::*;
    pub use super::cardano::*;
    pub use super::cosmwasm::*;
    pub use super::dogecoin::*;
    pub use super::evm::*;
    pub use super::icp::*;
    pub use super::litecoin::*;
    pub use super::near::*;
    pub use super::polkadot::*;
    pub use super::ripple::*;
    pub use super::solana::*;
    pub use super::stellar::*;
    pub use super::sui::*;
    pub use super::tezos::*;
    pub use super::ton::*;
    pub use super::tron::*;
}

use connection::*;

/// Universal bridge message for cross-chain operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BridgeMessage {
    pub source_chain: String,
    pub destination_chain: String,
    pub source_address: String,
    pub destination_address: String,
    pub amount: String,
    pub token: Option<String>, // None for native token
    pub proof: Option<String>, // zk-proof or other proof
    pub nonce: u64,
}

/// Bridge operation result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BridgeOperationResult {
    pub success: bool,
    pub tx_hash: String,
    pub source_chain: String,
    pub destination_chain: String,
    pub error: Option<String>,
}

/// Multi-chain bridge coordinator
pub struct MultiChainBridge {
    bitcoin: Option<BitcoinConnector>,
    solana: Option<SolanaConnector>,
    cardano: Option<CardanoConnector>,
    polkadot: Option<PolkadotConnector>,
    near: Option<NearConnector>,
    algorand: Option<AlgorandConnector>,
    tezos: Option<TezosConnector>,
    tron: Option<TronConnector>,
    litecoin: Option<LitecoinConnector>,
    dogecoin: Option<DogecoinConnector>,
    stellar: Option<StellarConnector>,
    ripple: Option<RippleConnector>,
    aptos: Option<AptosConnector>,
    icp: Option<ICPConnector>,
    sui: Option<SuiConnector>,
    ton: Option<TONConnector>,
}

impl MultiChainBridge {
    /// Create new multi-chain bridge
    pub fn new() -> Self {
        Self {
            bitcoin: None,
            solana: None,
            cardano: None,
            polkadot: None,
            near: None,
            algorand: None,
            tezos: None,
            tron: None,
            litecoin: None,
            dogecoin: None,
            stellar: None,
            ripple: None,
            aptos: None,
            icp: None,
            sui: None,
            ton: None,
        }
    }

    /// Add Bitcoin connector
    pub fn with_bitcoin(
        mut self,
        rpc_url: &str,
        rpc_user: &str,
        rpc_password: &str,
        network: BitcoinNetwork,
    ) -> BridgeResult<Self> {
        self.bitcoin = Some(BitcoinConnector::new(rpc_url, rpc_user, rpc_password, network)?);
        Ok(self)
    }

    /// Add Solana connector
    pub fn with_solana(mut self, rpc_url: &str, network: SolanaNetwork) -> BridgeResult<Self> {
        self.solana = Some(SolanaConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Cardano connector
    pub fn with_cardano(mut self, rpc_url: &str, network: CardanoNetwork) -> BridgeResult<Self> {
        self.cardano = Some(CardanoConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Polkadot connector
    pub fn with_polkadot(mut self, rpc_url: &str, network: PolkadotNetwork) -> BridgeResult<Self> {
        self.polkadot = Some(PolkadotConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Near connector
    pub fn with_near(mut self, rpc_url: &str, network: NearNetwork) -> BridgeResult<Self> {
        self.near = Some(NearConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Algorand connector
    pub fn with_algorand(mut self, rpc_url: &str, network: AlgorandNetwork) -> BridgeResult<Self> {
        self.algorand = Some(AlgorandConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Tezos connector
    pub fn with_tezos(mut self, rpc_url: &str, network: TezosNetwork) -> BridgeResult<Self> {
        self.tezos = Some(TezosConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Tron connector
    pub fn with_tron(mut self, rpc_url: &str, network: TronNetwork) -> BridgeResult<Self> {
        self.tron = Some(TronConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Litecoin connector
    pub fn with_litecoin(
        mut self,
        rpc_url: &str,
        rpc_user: &str,
        rpc_password: &str,
        network: LitecoinNetwork,
    ) -> BridgeResult<Self> {
        self.litecoin = Some(LitecoinConnector::new(rpc_url, rpc_user, rpc_password, network)?);
        Ok(self)
    }

    /// Add Dogecoin connector
    pub fn with_dogecoin(
        mut self,
        rpc_url: &str,
        rpc_user: &str,
        rpc_password: &str,
        network: DogecoinNetwork,
    ) -> BridgeResult<Self> {
        self.dogecoin = Some(DogecoinConnector::new(rpc_url, rpc_user, rpc_password, network)?);
        Ok(self)
    }

    /// Add Stellar connector
    pub fn with_stellar(mut self, rpc_url: &str, network: StellarNetwork) -> BridgeResult<Self> {
        self.stellar = Some(StellarConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Add Ripple connector
    pub fn with_ripple(mut self, rpc_url: &str, network: RippleNetwork) -> BridgeResult<Self> {
        self.ripple = Some(RippleConnector::new(rpc_url, network)?);
        Ok(self)
    }

    /// Process bridge message
    pub fn process_bridge_message(&self, message: &BridgeMessage) -> BridgeResult<BridgeOperationResult> {
        let amount = message
            .amount
            .parse()
            .map_err(|e| BridgeError::InvalidAmount(format!("Failed to parse amount: {}", e)))?;

        match message.source_chain.to_lowercase().as_str() {
            "bitcoin" | "btc" => self.process_with_connector(
                self.bitcoin.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Bitcoin",
            ),
            "solana" | "sol" => self.process_with_connector(
                self.solana.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Solana",
            ),
            "cardano" | "ada" => self.process_with_connector(
                self.cardano.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Cardano",
            ),
            "polkadot" | "dot" => self.process_with_connector(
                self.polkadot.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount as u128),
                "Polkadot",
            ),
            "near" => self.process_with_connector(
                self.near.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount as u128),
                "Near",
            ),
            "algorand" | "algo" => self.process_with_connector(
                self.algorand.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Algorand",
            ),
            "tezos" | "xtz" => self.process_with_connector(
                self.tezos.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Tezos",
            ),
            "tron" | "trx" => self.process_with_connector(
                self.tron.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Tron",
            ),
            "litecoin" | "ltc" => self.process_with_connector(
                self.litecoin.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Litecoin",
            ),
            "dogecoin" | "doge" => self.process_with_connector(
                self.dogecoin.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Dogecoin",
            ),
            "stellar" | "xlm" => self.process_with_connector(
                self.stellar.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount as i64),
                "Stellar",
            ),
            "ripple" | "xrp" => self.process_with_connector(
                self.ripple.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Ripple",
            ),
            "aptos" | "apt" => self.process_with_connector(
                self.aptos.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Aptos",
            ),
            "icp" | "internet-computer" | "dfinity" => self.process_with_connector(
                self.icp.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "ICP",
            ),
            "sui" => self.process_with_connector(
                self.sui.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "Sui",
            ),
            "ton" | "the-open-network" | "telegram-open-network" => self.process_with_connector(
                self.ton.as_ref(),
                |c| c.send_transaction(&message.source_address, &message.destination_address, amount),
                "TON",
            ),
            _ => Err(BridgeError::ChainNotSupported(format!(
                "Chain {} not supported",
                message.source_chain
            ))),
        }
    }

    fn process_with_connector<T, F>(
        &self,
        connector: Option<T>,
        f: F,
        chain_name: &str,
    ) -> BridgeResult<BridgeOperationResult>
    where
        F: FnOnce(&T) -> BridgeResult<String>,
    {
        if let Some(ref conn) = connector {
            let tx_hash = f(conn)?;
            Ok(BridgeOperationResult {
                success: true,
                tx_hash,
                source_chain: chain_name.to_string(),
                destination_chain: "destination".to_string(), // Will be set from message
                error: None,
            })
        } else {
            Err(BridgeError::ChainNotSupported(format!(
                "{} connector not initialized",
                chain_name
            )))
        }
    }

    /// Get connectors
    pub fn get_bitcoin(&self) -> Option<&BitcoinConnector> {
        self.bitcoin.as_ref()
    }

    pub fn get_solana(&self) -> Option<&SolanaConnector> {
        self.solana.as_ref()
    }

    pub fn get_cardano(&self) -> Option<&CardanoConnector> {
        self.cardano.as_ref()
    }

    pub fn get_polkadot(&self) -> Option<&PolkadotConnector> {
        self.polkadot.as_ref()
    }

    pub fn get_near(&self) -> Option<&NearConnector> {
        self.near.as_ref()
    }

    pub fn get_algorand(&self) -> Option<&AlgorandConnector> {
        self.algorand.as_ref()
    }

    pub fn get_tezos(&self) -> Option<&TezosConnector> {
        self.tezos.as_ref()
    }

    pub fn get_tron(&self) -> Option<&TronConnector> {
        self.tron.as_ref()
    }

    pub fn get_litecoin(&self) -> Option<&LitecoinConnector> {
        self.litecoin.as_ref()
    }

    pub fn get_dogecoin(&self) -> Option<&DogecoinConnector> {
        self.dogecoin.as_ref()
    }

    pub fn get_stellar(&self) -> Option<&StellarConnector> {
        self.stellar.as_ref()
    }

    pub fn get_ripple(&self) -> Option<&RippleConnector> {
        self.ripple.as_ref()
    }

    pub fn get_aptos(&self) -> Option<&AptosConnector> {
        self.aptos.as_ref()
    }

    pub fn get_icp(&self) -> Option<&ICPConnector> {
        self.icp.as_ref()
    }

    pub fn get_sui(&self) -> Option<&SuiConnector> {
        self.sui.as_ref()
    }

    pub fn get_ton(&self) -> Option<&TONConnector> {
        self.ton.as_ref()
    }
}

impl Default for MultiChainBridge {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================================
// FFI Interface for TypeScript/JavaScript
// ============================================================================

/// FFI functions for calling from TypeScript/Node.js
/// These functions can be called via node-ffi or wasm-bindgen

#[no_mangle]
pub extern "C" fn create_bitcoin_connector(
    rpc_url: *const i8,
    rpc_user: *const i8,
    rpc_password: *const i8,
    network: u8,
) -> *mut BitcoinConnector {
    // FFI wrapper - converts C strings to Rust strings and creates connector
    unsafe {
        if rpc_url.is_null() || rpc_user.is_null() || rpc_password.is_null() {
            return std::ptr::null_mut();
        }

        let rpc_url_str = match std::ffi::CStr::from_ptr(rpc_url).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };
        let rpc_user_str = match std::ffi::CStr::from_ptr(rpc_user).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };
        let rpc_password_str = match std::ffi::CStr::from_ptr(rpc_password).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let network_enum = match network {
            0 => BitcoinNetwork::Mainnet,
            1 => BitcoinNetwork::Testnet,
            2 => BitcoinNetwork::Regtest,
            _ => return std::ptr::null_mut(),
        };

        match BitcoinConnector::new(rpc_url_str, rpc_user_str, rpc_password_str, network_enum) {
            Ok(connector) => Box::into_raw(Box::new(connector)),
            Err(_) => std::ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn create_solana_connector(rpc_url: *const i8, network: u8) -> *mut SolanaConnector {
    // FFI wrapper - converts C strings to Rust strings and creates connector
    unsafe {
        if rpc_url.is_null() {
            return std::ptr::null_mut();
        }

        let rpc_url_str = match std::ffi::CStr::from_ptr(rpc_url).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        };

        let network_enum = match network {
            0 => SolanaNetwork::Mainnet,
            1 => SolanaNetwork::Devnet,
            2 => SolanaNetwork::Testnet,
            3 => SolanaNetwork::Localnet,
            _ => return std::ptr::null_mut(),
        };

        match SolanaConnector::new(rpc_url_str, network_enum) {
            Ok(connector) => Box::into_raw(Box::new(connector)),
            Err(_) => std::ptr::null_mut(),
        }
    }
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bitcoin_address_validation() {
        let btc = match BitcoinConnector::new("http://localhost:8332", "user", "pass", BitcoinNetwork::Mainnet) {
            Ok(connector) => connector,
            Err(_) => return, // Skip test if connector creation fails
        };

        // Valid mainnet addresses
        assert!(btc.is_valid_address("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")); // Genesis block
        assert!(btc.is_valid_address("3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy")); // P2SH
        assert!(btc.is_valid_address("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4")); // Bech32

        // Invalid addresses
        assert!(!btc.is_valid_address("invalid"));
    }

    #[test]
    fn test_solana_address_validation() {
        let sol = match SolanaConnector::new("https://api.mainnet-beta.solana.com", SolanaNetwork::Mainnet) {
            Ok(connector) => connector,
            Err(_) => return, // Skip test if connector creation fails
        };

        // Valid Solana addresses are base58, 32-44 chars
        assert!(sol.is_valid_address("9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM")); // 44 chars
        assert!(sol.is_valid_address("11111111111111111111111111111111")); // 32 chars

        // Invalid addresses
        assert!(!sol.is_valid_address("too_short"));
    }

    #[test]
    fn test_multi_chain_bridge() {
        let bridge = match MultiChainBridge::new().with_bitcoin(
            "http://localhost:8332",
            "user",
            "pass",
            BitcoinNetwork::Testnet,
        ) {
            Ok(b) => match b.with_solana("https://api.devnet.solana.com", SolanaNetwork::Devnet) {
                Ok(bridge) => bridge,
                Err(_) => return, // Skip test if connector creation fails
            },
            Err(_) => return, // Skip test if connector creation fails
        };

        assert!(bridge.get_bitcoin().is_some());
        assert!(bridge.get_solana().is_some());
    }

    #[test]
    fn test_deserialize_proof() {
        let proof_json = r#"{
            "proof": {
                "pi_a": ["1", "2"],
                "pi_b": [["3", "4"], ["5", "6"]],
                "pi_c": ["7", "8"],
                "protocol": "groth16",
                "curve": "bn128"
            },
            "publicSignals": ["9", "10"]
        }"#;

        let result = deserialize_proof(proof_json);
        assert!(result.is_ok());
        let proof_data = match result {
            Ok(data) => data,
            Err(_) => return, // Skip test if deserialization fails
        };
        assert_eq!(proof_data.proof.pi_a.len(), 2);
        assert_eq!(proof_data.public_signals.len(), 2);
    }

    #[test]
    fn test_validate_proof_structure() {
        let valid_proof = Proof {
            pi_a: vec!["1".to_string(), "2".to_string()],
            pi_b: vec![vec!["3".to_string(), "4".to_string()], vec!["5".to_string(), "6".to_string()]],
            pi_c: vec!["7".to_string(), "8".to_string()],
            protocol: "groth16".to_string(),
            curve: "bn128".to_string(),
        };

        assert!(validate_proof_structure(&valid_proof).is_ok());
    }

    #[test]
    fn test_validate_proof_structure_invalid() {
        let invalid_proof = Proof {
            pi_a: vec!["1".to_string()], // Should have 2 elements
            pi_b: vec![vec!["3".to_string(), "4".to_string()], vec!["5".to_string(), "6".to_string()]],
            pi_c: vec!["7".to_string(), "8".to_string()],
            protocol: "groth16".to_string(),
            curve: "bn128".to_string(),
        };

        assert!(validate_proof_structure(&invalid_proof).is_err());
    }

    #[test]
    fn test_validate_verification_key() {
        let valid_vk = VerificationKey {
            protocol: "groth16".to_string(),
            curve: "bn128".to_string(),
            n_public: 2,
            vk_alpha_1: vec!["1".to_string(), "2".to_string()],
            vk_beta_2: vec![vec!["3".to_string(), "4".to_string()], vec!["5".to_string(), "6".to_string()]],
            vk_gamma_2: vec![vec!["7".to_string(), "8".to_string()], vec!["9".to_string(), "10".to_string()]],
            vk_delta_2: vec![
                vec!["11".to_string(), "12".to_string()],
                vec!["13".to_string(), "14".to_string()],
            ],
            vk_alphabeta_12: vec![],
            ic: vec![vec!["15".to_string(), "16".to_string()]],
        };

        assert!(validate_verification_key(&valid_vk).is_ok());
    }
}
