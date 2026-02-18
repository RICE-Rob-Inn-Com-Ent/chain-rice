//! TON (The Open Network) connector

use crate::{BridgeError, BridgeResult, TONNetwork, http_get_json, http_post_json};
use serde::{Deserialize, Serialize};

/// TON connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TONConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: TONNetwork,
}

impl TONConnector {
    pub fn new(rpc_url: &str, network: TONNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // TON addresses need to be converted to raw format for API calls
        // For simplicity, we'll use the address directly (in production, use @ton/core to convert)
        // URL encode the address manually
        let encoded_address: String = address
            .chars()
            .map(|c| {
                if c.is_ascii_alphanumeric() || c == '-' || c == '_' || c == '.' || c == '~' {
                    c.to_string()
                } else {
                    format!("%{:02X}", c as u8)
                }
            })
            .collect();
        let url = format!(
            "{}/getAddressInformation?address={}",
            self.rpc_url.trim_end_matches('/'),
            encoded_address
        );

        let result = http_get_json(&url)?;

        // Check if response is ok
        if let Some(ok) = result.get("ok").and_then(|o| o.as_bool()) {
            if !ok {
                return Err(BridgeError::NetworkError("Failed to fetch TON account information".to_string()));
            }
        }

        // Return balance in nanograms (smallest unit, 1 TON = 1,000,000,000 nanograms)
        let balance = result
            .get("result")
            .and_then(|r| r.get("balance"))
            .and_then(|b| b.as_str())
            .and_then(|s| s.parse::<u64>().ok())
            .unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in nanograms
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid TON address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // TON transactions require:
        // 1. Creating transaction with proper message structure
        // 2. Signing with private key using TVM (TON Virtual Machine)
        // 3. Submitting to network
        // This is simplified - in production use @ton/core or tonweb
        let url = format!("{}/sendBoc", self.rpc_url.trim_end_matches('/'));
        let body = serde_json::json!({
            "boc": "base64_encoded_signed_transaction" // In production, this would be the signed transaction BOC
        });

        let result = http_post_json(&url, body)?;

        // Check if response is ok
        if let Some(ok) = result.get("ok").and_then(|o| o.as_bool()) {
            if !ok {
                return Err(BridgeError::TransactionFailed("Transaction submission failed".to_string()));
            }
        }

        result
            .get("result")
            .and_then(|r| r.get("transaction_id"))
            .and_then(|ti| ti.get("hash"))
            .and_then(|h| h.as_str())
            .map(|s| s.to_string())
            .or_else(|| {
                result
                    .get("result")
                    .and_then(|r| r.get("hash"))
                    .and_then(|h| h.as_str())
                    .map(|s| s.to_string())
            })
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction hash".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // TON addresses can be in different formats:
        // - Raw format: base64 encoded (48 chars)
        // - User-friendly format: starts with 0: or -1: followed by hex
        // - Bounceable/non-bounceable formats
        // Basic validation - check for common TON address patterns
        let raw_pattern = |s: &str| {
            s.len() == 48
                && s.chars()
                    .all(|c| c.is_ascii_alphanumeric() || c == '+' || c == '/' || c == '=')
        };
        let friendly_pattern = |s: &str| {
            (s.starts_with("0:") || s.starts_with("-1:"))
                && s.len() == 66
                && s[2..].chars().all(|c| c.is_ascii_hexdigit())
        };
        let bounceable_pattern = |s: &str| {
            s.len() == 48
                && s.chars()
                    .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
        };

        raw_pattern(address) || friendly_pattern(address) || bounceable_pattern(address) || address.len() == 48
    }
}

