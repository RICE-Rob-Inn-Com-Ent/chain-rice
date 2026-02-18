//! Sui connector

use crate::{BridgeError, BridgeResult, SuiNetwork, solana_rpc_call};
use serde::{Deserialize, Serialize};

/// Sui connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SuiConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: SuiNetwork,
}

impl SuiConnector {
    pub fn new(rpc_url: &str, network: SuiNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Sui JSON-RPC call
        let params = serde_json::json!([address]);
        let result = solana_rpc_call(&self.rpc_url, "suix_getBalance", params)?;

        // Return balance in MIST (smallest unit, 1 SUI = 1,000,000,000 MIST)
        let balance = result
            .get("result")
            .and_then(|r| r.get("data"))
            .and_then(|d| d.get("totalBalance"))
            .and_then(|b| b.as_str())
            .and_then(|s| s.parse::<u64>().ok())
            .or_else(|| {
                result
                    .get("result")
                    .and_then(|r| r.get("data"))
                    .and_then(|d| d.get("totalBalance"))
                    .and_then(|b| b.as_u64())
            })
            .unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in MIST
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Sui address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Sui transactions require:
        // 1. Building transaction with proper Move call
        // 2. Signing with private key
        // 3. Submitting to network
        // This is simplified - in production use @mysten/sui.js
        let params = serde_json::json!([
            "base64_encoded_signed_transaction", // In production, this would be the signed transaction
            {
                "showEffects": true,
                "showEvents": true
            }
        ]);

        let result = solana_rpc_call(&self.rpc_url, "sui_executeTransactionBlock", params)?;
        result
            .get("result")
            .and_then(|r| r.get("digest"))
            .and_then(|d| d.as_str())
            .map(|s| s.to_string())
            .or_else(|| {
                result
                    .get("result")
                    .and_then(|r| r.get("transaction"))
                    .and_then(|t| t.get("data"))
                    .and_then(|d| d.get("transactionDigest"))
                    .and_then(|td| td.as_str())
                    .map(|s| s.to_string())
            })
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction digest".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Sui addresses are 0x followed by 64 hex characters
        address.starts_with("0x") && address.len() == 66 && address[2..].chars().all(|c| c.is_ascii_hexdigit())
    }
}

