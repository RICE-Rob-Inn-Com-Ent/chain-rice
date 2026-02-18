//! Stellar connector

use crate::{BridgeError, BridgeResult, StellarNetwork, http_get_json, http_post_json};
use serde::{Deserialize, Serialize};

/// Stellar connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StellarConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: StellarNetwork,
}

impl StellarConnector {
    pub fn new(rpc_url: &str, network: StellarNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<i64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Stellar Horizon API
        let url = format!("{}/accounts/{}", self.rpc_url.trim_end_matches('/'), address);
        let result = http_get_json(&url)?;

        let balance = result
            .get("balances")
            .and_then(|b| b.as_array())
            .and_then(|arr| {
                arr.iter()
                    .find(|bal| bal.get("asset_type").and_then(|at| at.as_str()) == Some("native"))
                    .and_then(|bal| bal.get("balance"))
                    .and_then(|b| b.as_str())
                    .and_then(|s| s.parse::<f64>().ok())
                    .map(|f| (f * 10_000_000.0) as i64) // Convert XLM to stroops
            })
            .unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: i64, // Stellar uses i64 for amounts
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Stellar address".to_string()));
        }
        if amount <= 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Stellar transactions require building and signing
        // This assumes the RPC endpoint can handle transaction submission
        let url = format!("{}/transactions", self.rpc_url.trim_end_matches('/'));
        let body = serde_json::json!({
            "from": from_address,
            "to": to_address,
            "amount": amount.to_string()
        });

        let result = http_post_json(&url, body)?;
        let hash = result
            .get("hash")
            .and_then(|h| h.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction hash".to_string()))?;
        Ok(hash)
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Stellar addresses are base32 encoded, 56 chars
        address.len() == 56
    }
}

