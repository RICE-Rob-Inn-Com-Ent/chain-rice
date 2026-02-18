//! EVM connector for interacting with EVM-compatible blockchains
//! Supports Ethereum, Polygon, BSC, Avalanche, Arbitrum, Optimism, Base, zkSync, Linea, Scroll, Mantle

use crate::{BridgeError, BridgeResult, http_post_json};
use serde::{Deserialize, Serialize};

/// EVM network configuration
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum EVMNetwork {
    Ethereum,
    Polygon,
    BSC,
    Avalanche,
    Arbitrum,
    Optimism,
    Base,
    ZkSync,
    Linea,
    Scroll,
    Mantle,
}

/// EVM connector for interacting with EVM-compatible blockchains
pub struct EVMConnector {
    rpc_url: String,
    chain_id: u64,
    network: EVMNetwork,
}

impl EVMConnector {
    /// Create new EVM connector
    pub fn new(rpc_url: &str, chain_id: u64, network: EVMNetwork) -> BridgeResult<Self> {
        Ok(Self {
            rpc_url: rpc_url.to_string(),
            chain_id,
            network,
        })
    }

    /// Get balance for an EVM address
    pub fn get_balance(&self, address: &str) -> BridgeResult<String> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        let params = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "eth_getBalance",
            "params": [address, "latest"],
            "id": 1
        });

        let result = http_post_json(&self.rpc_url, params)?;
        let balance_hex = result
            .get("result")
            .and_then(|r| r.as_str())
            .ok_or_else(|| BridgeError::DeserializationError("Invalid balance response".to_string()))?;

        // Convert from hex to decimal string (wei to ether)
        let balance_wei = u128::from_str_radix(balance_hex.strip_prefix("0x").unwrap_or(balance_hex), 16)
            .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse balance: {}", e)))?;

        // Convert wei to ether (divide by 10^18)
        let balance_ether = balance_wei as f64 / 1_000_000_000_000_000_000.0;
        Ok(balance_ether.to_string())
    }

    /// Call a contract method (read-only)
    pub fn call_contract(
        &self,
        contract_address: &str,
        data: &str,
    ) -> BridgeResult<String> {
        if !self.is_valid_address(contract_address) {
            return Err(BridgeError::InvalidAddress(contract_address.to_string()));
        }

        let params = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [{
                "to": contract_address,
                "data": data
            }, "latest"],
            "id": 1
        });

        let result = http_post_json(&self.rpc_url, params)?;
        let result_hex = result
            .get("result")
            .and_then(|r| r.as_str())
            .ok_or_else(|| BridgeError::DeserializationError("Invalid call response".to_string()))?;

        Ok(result_hex.to_string())
    }

    /// Send transaction (requires private key signing - simplified for bridge)
    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in wei
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) {
            return Err(BridgeError::InvalidAddress(from_address.to_string()));
        }
        if !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress(to_address.to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Note: EVM transactions require signing with a private key.
        // This is a simplified implementation that assumes the RPC handles signing.
        // In production, you'd need to:
        // 1. Get transaction count (nonce)
        // 2. Get gas price
        // 3. Build transaction
        // 4. Sign with private key
        // 5. Send signed transaction

        Err(BridgeError::TransactionFailed(
            "EVM transactions require private key signing. Use a wallet-integrated RPC or provide a signed transaction.".to_string()
        ))
    }

    /// Validate EVM address (0x followed by 40 hex characters)
    pub fn is_valid_address(&self, address: &str) -> bool {
        address.starts_with("0x") && address.len() == 42 && address[2..].chars().all(|c| c.is_ascii_hexdigit())
    }

    /// Get transaction receipt
    pub fn get_transaction_receipt(&self, tx_hash: &str) -> BridgeResult<EVMTransactionReceipt> {
        let params = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "eth_getTransactionReceipt",
            "params": [tx_hash],
            "id": 1
        });

        let result = http_post_json(&self.rpc_url, params)?;
        let receipt = result
            .get("result")
            .ok_or_else(|| BridgeError::DeserializationError("Transaction receipt not found".to_string()))?;

        let status = receipt
            .get("status")
            .and_then(|s| s.as_str())
            .and_then(|s| u64::from_str_radix(s.strip_prefix("0x").unwrap_or(s), 16).ok())
            .unwrap_or(0);

        let block_number = receipt
            .get("blockNumber")
            .and_then(|bn| bn.as_str())
            .and_then(|s| u64::from_str_radix(s.strip_prefix("0x").unwrap_or(s), 16).ok())
            .unwrap_or(0);

        Ok(EVMTransactionReceipt {
            transaction_hash: tx_hash.to_string(),
            status,
            block_number,
        })
    }

    /// Get chain ID
    pub fn get_chain_id(&self) -> u64 {
        self.chain_id
    }

    /// Get network
    pub fn get_network(&self) -> EVMNetwork {
        self.network
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EVMTransactionReceipt {
    pub transaction_hash: String,
    pub status: u64,
    pub block_number: u64,
}

