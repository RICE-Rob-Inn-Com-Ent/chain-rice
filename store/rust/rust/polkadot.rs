//! Polkadot connector for interacting with Polkadot/Substrate chains

use crate::{BridgeError, BridgeResult, PolkadotNetwork, http_post_json, solana_rpc_call};
use serde::{Deserialize, Serialize};

/// Polkadot connector for interacting with Polkadot/Substrate chains
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PolkadotConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: PolkadotNetwork,
}

impl PolkadotConnector {
    pub fn new(rpc_url: &str, network: PolkadotNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u128> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Substrate RPC call
        let params = serde_json::json!([address]);
        let result = solana_rpc_call(&self.rpc_url, "system_account", params)?;

        // Extract balance from account data
        let balance = result
            .get("data")
            .and_then(|d| d.get("free"))
            .and_then(|f| f.as_str())
            .and_then(|s| u128::from_str_radix(s.trim_start_matches("0x"), 16).ok())
            .or_else(|| {
                result
                    .get("data")
                    .and_then(|d| d.get("free"))
                    .and_then(|f| f.as_u64())
                    .map(|u| u as u128)
            })
            .unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u128, // in smallest unit
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Polkadot address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Substrate transactions require signing with private key
        // This assumes the RPC endpoint can handle signed transactions
        let params = serde_json::json!({
            "from": from_address,
            "to": to_address,
            "amount": format!("0x{:x}", amount)
        });

        let result = http_post_json(&self.rpc_url, params)?;
        result
            .get("txHash")
            .or_else(|| result.get("hash"))
            .and_then(|h| h.as_str())
            .map(|s| s.to_string())
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction hash".to_string()))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Polkadot uses SS58 encoding, addresses are typically 48-49 chars
        address.len() >= 32 && address.len() <= 50
    }
}

