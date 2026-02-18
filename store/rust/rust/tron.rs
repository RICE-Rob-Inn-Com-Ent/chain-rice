//! Tron connector

use crate::{BridgeError, BridgeResult, TronNetwork, http_post_json};
use serde::{Deserialize, Serialize};

/// Tron connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TronConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: TronNetwork,
}

impl TronConnector {
    pub fn new(rpc_url: &str, network: TronNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Tron API call
        let url = format!("{}/wallet/getaccount", self.rpc_url.trim_end_matches('/'));
        let body = serde_json::json!({
            "address": address,
            "visible": true
        });

        let result = http_post_json(&url, body)?;
        let balance = result
            .get("balance")
            .and_then(|b| b.as_u64())
            .or_else(|| {
                result
                    .get("balance")
                    .and_then(|b| b.as_str())
                    .and_then(|s| s.parse::<u64>().ok())
            })
            .unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in sun (1 TRX = 1,000,000 sun)
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Tron address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Tron transaction creation and broadcast
        let url = format!("{}/wallet/createtransaction", self.rpc_url.trim_end_matches('/'));
        let body = serde_json::json!({
            "to_address": to_address,
            "owner_address": from_address,
            "amount": amount
        });

        let result = http_post_json(&url, body)?;
        result
            .get("txID")
            .or_else(|| result.get("txid"))
            .and_then(|t| t.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to create Tron transaction".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Tron addresses are base58, 34 chars, start with 'T'
        address.len() == 34 && address.starts_with('T')
    }
}

