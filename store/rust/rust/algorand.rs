//! Algorand connector

use crate::{http_get_json, http_post_json, AlgorandNetwork, BridgeError, BridgeResult};
use serde::{Deserialize, Serialize};

/// Algorand connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlgorandConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: AlgorandNetwork,
}

impl AlgorandConnector {
    pub fn new(rpc_url: &str, network: AlgorandNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Algorand Algod API
        let url = format!("{}/v2/accounts/{}", self.rpc_url.trim_end_matches('/'), address);
        let result = http_get_json(&url)?;

        let balance = result.get("amount").and_then(|a| a.as_u64()).unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in microAlgos
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Algorand address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Algorand transactions require building and signing
        // This assumes the RPC endpoint can handle transaction submission
        let url = format!("{}/v2/transactions", self.rpc_url.trim_end_matches('/'));
        let body = serde_json::json!({
            "from": from_address,
            "to": to_address,
            "amount": amount
        });

        let result = http_post_json(&url, body)?;
        result
            .get("txid")
            .and_then(|t| t.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction ID".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Algorand addresses are base32 encoded, 58 chars
        address.len() == 58
    }
}
