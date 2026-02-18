//! Internet Computer (ICP) connector

use crate::{http_get_json, http_post_json, BridgeError, BridgeResult, ICPNetwork};
use serde::{Deserialize, Serialize};

/// Internet Computer (ICP) connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ICPConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: ICPNetwork,
}

impl ICPConnector {
    pub fn new(rpc_url: &str, network: ICPNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // ICP uses canister calls for account balance
        // For simplicity, using ledger API endpoint
        let url = format!("{}/api/v2/account/{}/balance", self.rpc_url.trim_end_matches('/'), address);

        match http_get_json(&url) {
            Ok(result) => {
                // Return balance in e8s (smallest unit, 1 ICP = 100,000,000 e8s)
                let balance = result
                    .get("account_balance")
                    .and_then(|ab| ab.get("e8s"))
                    .and_then(|e| e.as_str())
                    .and_then(|s| s.parse::<u64>().ok())
                    .or_else(|| {
                        result
                            .get("balance")
                            .and_then(|b| b.as_str())
                            .and_then(|s| s.parse::<u64>().ok())
                    })
                    .unwrap_or(0);
                Ok(balance)
            },
            Err(BridgeError::NetworkError(_)) => {
                // If account doesn't exist, return 0
                Ok(0)
            },
            Err(e) => Err(e),
        }
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in e8s
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid ICP address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // ICP transactions require:
        // 1. Creating transfer request with proper canister call
        // 2. Signing with identity (using Internet Identity or private key)
        // 3. Submitting to network via canister
        // This is simplified - in production use @dfinity/agent
        let url = format!("{}/api/v2/transfer", self.rpc_url.trim_end_matches('/'));
        let body = serde_json::json!({
            "to": to_address,
            "amount": {
                "e8s": amount.to_string()
            },
            "fee": {
                "e8s": "10000" // Standard fee
            },
            "memo": 0,
            "created_at_time": {
                "timestamp_nanos": match std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH) {
                    Ok(duration) => duration.as_nanos().to_string(),
                    Err(_) => "0".to_string(), // Fallback to 0 if time calculation fails
                }
            }
        });

        let result = http_post_json(&url, body)?;
        result
            .get("transaction_hash")
            .or_else(|| result.get("block_height"))
            .and_then(|h| h.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction hash".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // ICP addresses (Principal IDs) can be in different formats:
        // - Text format: base32 encoded with CRC32 checksum
        // - Hex format: 0x followed by hex
        // - Raw format: base64 encoded
        // Basic validation - check for common patterns
        let principal_pattern = |s: &str| s.len() >= 27 && s.chars().all(|c| c.is_ascii_alphanumeric() || c == '-');
        let hex_pattern = |s: &str| s.starts_with("0x") && s.len() > 2 && s[2..].chars().all(|c| c.is_ascii_hexdigit());
        let base64_pattern =
            |s: &str| s.len() >= 20 && s.chars().all(|c| c.is_ascii_alphanumeric() || c == '+' || c == '/' || c == '=');

        principal_pattern(address) || hex_pattern(address) || base64_pattern(address)
    }
}
