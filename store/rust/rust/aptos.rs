//! Aptos connector

use crate::{http_get_json, http_post_json, AptosNetwork, BridgeError, BridgeResult};
use serde::{Deserialize, Serialize};

/// Aptos connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AptosConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: AptosNetwork,
}

impl AptosConnector {
    pub fn new(rpc_url: &str, network: AptosNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Aptos uses REST API, not JSON-RPC
        let url = format!(
            "{}/v1/accounts/{}/resource/0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>",
            self.rpc_url.trim_end_matches('/'),
            address
        );

        match http_get_json(&url) {
            Ok(result) => {
                // Return balance in Octas (smallest unit, 1 APT = 100,000,000 Octas)
                let balance = result
                    .get("data")
                    .and_then(|d| d.get("coin"))
                    .and_then(|c| c.get("value"))
                    .and_then(|v| v.as_str())
                    .and_then(|s| s.parse::<u64>().ok())
                    .unwrap_or(0);
                Ok(balance)
            },
            Err(BridgeError::NetworkError(_)) => {
                // If account doesn't exist or has no balance, return 0
                Ok(0)
            },
            Err(e) => Err(e),
        }
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in Octas
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Aptos address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Aptos transactions require:
        // 1. Building transaction with proper Move function call
        // 2. Signing with private key
        // 3. Submitting to network
        // This is simplified - in production use aptos SDK
        let url = format!("{}/v1/transactions", self.rpc_url.trim_end_matches('/'));
        let body = serde_json::json!({
            "sender": from_address,
            "sequence_number": "0", // Would be fetched from account
            "max_gas_amount": "1000",
            "gas_unit_price": "100",
            "expiration_timestamp_secs": "0", // Would be calculated
            "payload": {
                "type": "entry_function_payload",
                "function": "0x1::coin::transfer",
                "type_arguments": ["0x1::aptos_coin::AptosCoin"],
                "arguments": [to_address, amount.to_string()],
            },
            "signature": {
                "type": "ed25519_signature",
                "public_key": "0x...",
                "signature": "0x...",
            },
        });

        let result = http_post_json(&url, body)?;
        result
            .get("hash")
            .or_else(|| result.get("transaction").and_then(|t| t.get("hash")))
            .and_then(|h| h.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction hash".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Aptos addresses are 0x followed by 64 hex characters
        address.starts_with("0x") && address.len() == 66 && address[2..].chars().all(|c| c.is_ascii_hexdigit())
    }
}
