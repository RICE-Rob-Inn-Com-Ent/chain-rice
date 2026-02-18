//! Near Protocol connector

use crate::{BridgeError, BridgeResult, NearNetwork, http_post_json};
use serde::{Deserialize, Serialize};

/// Near Protocol connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NearConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: NearNetwork,
}

impl NearConnector {
    pub fn new(rpc_url: &str, network: NearNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, account_id: &str) -> BridgeResult<u128> {
        if !self.is_valid_account(account_id) {
            return Err(BridgeError::InvalidAddress(account_id.to_string()));
        }

        // Near RPC call
        let params = serde_json::json!({
            "jsonrpc": "2.0",
            "id": "dontcare",
            "method": "query",
            "params": {
                "request_type": "view_account",
                "finality": "final",
                "account_id": account_id
            }
        });

        let result = http_post_json(&self.rpc_url, params)?;
        let amount = result
            .get("result")
            .and_then(|r| r.get("amount"))
            .and_then(|a| a.as_str())
            .and_then(|s| s.parse::<u128>().ok())
            .unwrap_or(0);

        Ok(amount)
    }

    pub fn send_transaction(
        &self,
        from_account: &str,
        to_account: &str,
        amount: u128, // in yoctoNEAR
    ) -> BridgeResult<String> {
        if !self.is_valid_account(from_account) || !self.is_valid_account(to_account) {
            return Err(BridgeError::InvalidAddress("Invalid Near account".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Near transactions require signing. This assumes a signed transaction is provided
        // or the RPC endpoint has wallet access
        // For now, return error indicating signing is required
        Err(BridgeError::TransactionFailed(
            "Near transactions require signed transaction. Provide a signed transaction or use wallet-integrated RPC."
                .to_string(),
        ))
    }

    pub fn is_valid_account(&self, account_id: &str) -> bool {
        // Near account IDs: 2-64 chars, alphanumeric, dots, hyphens, underscores
        account_id.len() >= 2 && account_id.len() <= 64
    }
}

