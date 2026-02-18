//! Cardano connector for interacting with Cardano blockchain

use crate::{http_get_json, http_post_json, BridgeError, BridgeResult, CardanoNetwork};
use serde::{Deserialize, Serialize};

/// Cardano connector for interacting with Cardano blockchain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CardanoConnector {
    rpc_url: String,
    network: CardanoNetwork,
}

impl CardanoConnector {
    pub fn new(rpc_url: &str, network: CardanoNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Cardano uses Ogmios or Blockfrost API
        // Try Blockfrost-style API first
        let url = format!("{}/addresses/{}", self.rpc_url.trim_end_matches('/'), address);
        match http_get_json(&url) {
            Ok(result) => {
                // Blockfrost format: {"amount": [{"unit": "lovelace", "quantity": "..."}]}
                let amount = result
                    .get("amount")
                    .and_then(|a| a.as_array())
                    .and_then(|arr| {
                        arr.iter()
                            .find(|item| item.get("unit").and_then(|u| u.as_str()) == Some("lovelace"))
                            .and_then(|item| item.get("quantity"))
                            .and_then(|q| q.as_str())
                            .and_then(|s| s.parse::<u64>().ok())
                    })
                    .unwrap_or(0);
                Ok(amount)
            },
            Err(_) => {
                // Fallback: try Ogmios-style query
                let params = serde_json::json!({"address": address});
                let result = http_post_json(&self.rpc_url, params)?;
                result
                    .get("lovelace")
                    .and_then(|l| l.as_u64())
                    .ok_or_else(|| BridgeError::NetworkError("Failed to get Cardano balance".to_string()))
            },
        }
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in lovelace
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Cardano address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Cardano transactions require building, signing, and submitting
        // This is a simplified version that assumes the RPC endpoint handles transaction building
        let body = serde_json::json!({
            "from": from_address,
            "to": to_address,
            "amount": amount.to_string()
        });

        let result = http_post_json(&self.rpc_url, body)?;
        result
            .get("txHash")
            .or_else(|| result.get("tx_hash"))
            .and_then(|h| h.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction hash".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Cardano addresses start with 'addr' for mainnet or 'addr_test' for testnet
        match self.network {
            CardanoNetwork::Mainnet => address.starts_with("addr1"),
            CardanoNetwork::Testnet | CardanoNetwork::Preview | CardanoNetwork::Preprod => {
                address.starts_with("addr_test")
            },
        }
    }
}
