//! Tezos connector

use crate::{BridgeError, BridgeResult, TezosNetwork, http_get_json};
use serde::{Deserialize, Serialize};

/// Tezos connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TezosConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: TezosNetwork,
}

impl TezosConnector {
    pub fn new(rpc_url: &str, network: TezosNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Tezos RPC call
        let url = format!(
            "{}/chains/main/blocks/head/context/contracts/{}/balance",
            self.rpc_url.trim_end_matches('/'),
            address
        );
        let result = http_get_json(&url)?;

        let balance = result.as_str().and_then(|s| s.parse::<u64>().ok()).unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in mutez
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Tezos address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Tezos transactions require signing and injection
        // This assumes the RPC endpoint can handle signed operations
        // For now, return error indicating signing is required
        Err(BridgeError::TransactionFailed(
            "Tezos transactions require signed operations. Provide a signed operation or use wallet-integrated RPC."
                .to_string(),
        ))
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Tezos addresses start with 'tz1', 'tz2', 'tz3', or 'KT1' (contracts)
        address.starts_with("tz1")
            || address.starts_with("tz2")
            || address.starts_with("tz3")
            || address.starts_with("KT1")
    }
}

