//! CosmWasm connector for interacting with CosmWasm-compatible blockchains
//! Supports ChainRice and other Cosmos SDK chains with CosmWasm

use crate::{BridgeError, BridgeResult, http_post_json, http_get_json};
use serde::{Deserialize, Serialize};

/// CosmWasm network configuration
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum CosmWasmNetwork {
    ChainRice,
    Osmosis,
    Juno,
    Secret,
    Terra,
    Custom,
}

/// CosmWasm connector for interacting with CosmWasm-compatible blockchains
pub struct CosmWasmConnector {
    rpc_url: String,
    prefix: String,
    network: CosmWasmNetwork,
}

impl CosmWasmConnector {
    /// Create new CosmWasm connector
    pub fn new(rpc_url: &str, prefix: &str, network: CosmWasmNetwork) -> BridgeResult<Self> {
        Ok(Self {
            rpc_url: rpc_url.to_string(),
            prefix: prefix.to_string(),
            network,
        })
    }

    /// Get balance for a CosmWasm address
    pub fn get_balance(&self, address: &str) -> BridgeResult<String> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Query balance via Cosmos SDK REST API
        let url = format!("{}/cosmos/bank/v1beta1/balances/{}", self.rpc_url, address);
        let result = http_get_json(&url)?;

        // Extract balance from response
        let balances = result
            .get("balances")
            .and_then(|b| b.as_array())
            .ok_or_else(|| BridgeError::DeserializationError("Invalid balance response".to_string()))?;

        if balances.is_empty() {
            return Ok("0".to_string());
        }

        // Get first balance amount
        let amount = balances[0]
            .get("amount")
            .and_then(|a| a.as_str())
            .ok_or_else(|| BridgeError::DeserializationError("Invalid amount format".to_string()))?;

        Ok(amount.to_string())
    }

    /// Query a CosmWasm contract
    pub fn query_contract(
        &self,
        contract_address: &str,
        query_msg: &str,
    ) -> BridgeResult<String> {
        if !self.is_valid_address(contract_address) {
            return Err(BridgeError::InvalidAddress(contract_address.to_string()));
        }

        // Query contract via CosmWasm query endpoint
        let url = format!("{}/cosmwasm/wasm/v1/contract/{}/smart", self.rpc_url, contract_address);
        let params = serde_json::json!({
            "query_msg": query_msg
        });

        let result = http_post_json(&url, params)?;
        let data = result
            .get("data")
            .and_then(|d| d.as_str())
            .ok_or_else(|| BridgeError::DeserializationError("Invalid query response".to_string()))?;

        Ok(data.to_string())
    }

    /// Execute a CosmWasm contract (requires signing - simplified for bridge)
    pub fn execute_contract(
        &self,
        contract_address: &str,
        _execute_msg: &str,
    ) -> BridgeResult<String> {
        if !self.is_valid_address(contract_address) {
            return Err(BridgeError::InvalidAddress(contract_address.to_string()));
        }

        // Note: CosmWasm contract execution requires signing with a private key.
        // This is a simplified implementation that assumes the RPC handles signing.
        // In production, you'd need to:
        // 1. Build execute message
        // 2. Sign with private key
        // 3. Broadcast transaction
        // 4. Wait for confirmation

        Err(BridgeError::TransactionFailed(
            "CosmWasm contract execution requires private key signing. Use a wallet-integrated RPC or provide a signed transaction.".to_string()
        ))
    }

    /// Validate CosmWasm address (bech32 encoded with prefix)
    pub fn is_valid_address(&self, address: &str) -> bool {
        // Basic validation - CosmWasm addresses are bech32 encoded
        // Should start with prefix (e.g., "crice1", "osmo1", "juno1")
        address.starts_with(&self.prefix) && address.len() > self.prefix.len() && address.len() <= 90
    }

    /// Get contract info
    pub fn get_contract_info(&self, contract_address: &str) -> BridgeResult<CosmWasmContractInfo> {
        if !self.is_valid_address(contract_address) {
            return Err(BridgeError::InvalidAddress(contract_address.to_string()));
        }

        let url = format!("{}/cosmwasm/wasm/v1/contract/{}", self.rpc_url, contract_address);
        let result = http_get_json(&url)?;

        let code_id = result
            .get("contract_info")
            .and_then(|ci| ci.get("code_id"))
            .and_then(|id| id.as_u64())
            .unwrap_or(0);

        let creator = result
            .get("contract_info")
            .and_then(|ci| ci.get("creator"))
            .and_then(|c| c.as_str())
            .map(|s| s.to_string())
            .unwrap_or_default();

        Ok(CosmWasmContractInfo {
            address: contract_address.to_string(),
            code_id,
            creator,
        })
    }

    /// Get network
    pub fn get_network(&self) -> CosmWasmNetwork {
        self.network
    }

    /// Get address prefix
    pub fn get_prefix(&self) -> &str {
        &self.prefix
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmWasmContractInfo {
    pub address: String,
    pub code_id: u64,
    pub creator: String,
}

