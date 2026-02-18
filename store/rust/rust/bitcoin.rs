//! Bitcoin connector for interacting with Bitcoin blockchain

use crate::{bitcoin_rpc_call, BitcoinNetwork, BridgeError, BridgeResult};
use serde::{Deserialize, Serialize};

/// Bitcoin connector for interacting with Bitcoin blockchain
pub struct BitcoinConnector {
    rpc_url: String,
    rpc_user: String,
    rpc_password: String,
    network: BitcoinNetwork,
}

impl BitcoinConnector {
    /// Create new Bitcoin connector
    pub fn new(rpc_url: &str, rpc_user: &str, rpc_password: &str, network: BitcoinNetwork) -> BridgeResult<Self> {
        Ok(Self {
            rpc_url: rpc_url.to_string(),
            rpc_user: rpc_user.to_string(),
            rpc_password: rpc_password.to_string(),
            network,
        })
    }

    /// Get balance for a Bitcoin address
    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        // Validate Bitcoin address
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Get unspent outputs for the address
        let params = serde_json::json!([address]);
        let result = bitcoin_rpc_call(&self.rpc_url, &self.rpc_user, &self.rpc_password, "listunspent", params)?;

        // Sum all unspent outputs
        let utxos: Vec<serde_json::Value> = serde_json::from_value(result)
            .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse UTXOs: {}", e)))?;

        let balance: u64 = utxos
            .iter()
            .filter_map(|utxo| {
                utxo.get("amount")
                    .and_then(|a| a.as_f64())
                    .map(|amt| (amt * 100_000_000.0) as u64) // Convert BTC to satoshis
            })
            .sum();

        Ok(balance)
    }

    /// Send Bitcoin transaction
    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in satoshis
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

        // Get UTXOs for from_address
        let params = serde_json::json!([0, 9999999, [from_address]]);
        let result = bitcoin_rpc_call(&self.rpc_url, &self.rpc_user, &self.rpc_password, "listunspent", params)?;
        let utxos: Vec<serde_json::Value> = serde_json::from_value(result)
            .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse UTXOs: {}", e)))?;

        // Calculate total available
        let total_available: u64 = utxos
            .iter()
            .filter_map(|utxo| {
                utxo.get("amount")
                    .and_then(|a| a.as_f64())
                    .map(|amt| (amt * 100_000_000.0) as u64)
            })
            .sum();

        if total_available < amount {
            return Err(BridgeError::InsufficientBalance);
        }

        // Create raw transaction
        // Note: This is a simplified version. In production, you'd need to:
        // 1. Select appropriate UTXOs
        // 2. Calculate fees
        // 3. Create proper transaction structure
        // 4. Sign with private key
        // For now, we'll use sendtoaddress which handles all of this
        let amount_btc = amount as f64 / 100_000_000.0;
        let params = serde_json::json!([to_address, amount_btc]);
        let result = bitcoin_rpc_call(&self.rpc_url, &self.rpc_user, &self.rpc_password, "sendtoaddress", params)?;

        let tx_hash = result
            .as_str()
            .ok_or_else(|| BridgeError::DeserializationError("Invalid transaction hash format".to_string()))?
            .to_string();

        Ok(tx_hash)
    }

    /// Validate Bitcoin address
    pub fn is_valid_address(&self, address: &str) -> bool {
        // Basic validation - in production use proper Bitcoin address validation
        match self.network {
            BitcoinNetwork::Mainnet => {
                address.starts_with('1') || address.starts_with('3') || address.starts_with("bc1")
            },
            BitcoinNetwork::Testnet => {
                address.starts_with('m')
                    || address.starts_with('n')
                    || address.starts_with('2')
                    || address.starts_with("tb1")
            },
            BitcoinNetwork::Regtest => true, // More lenient for regtest
        }
    }

    /// Get transaction info
    pub fn get_transaction(&self, tx_hash: &str) -> BridgeResult<BitcoinTransaction> {
        let params = serde_json::json!([tx_hash, true]);
        let result = bitcoin_rpc_call(&self.rpc_url, &self.rpc_user, &self.rpc_password, "gettransaction", params)?;

        let confirmations = result.get("confirmations").and_then(|c| c.as_u64()).unwrap_or(0) as u32;

        let amount = result
            .get("amount")
            .and_then(|a| a.as_f64())
            .map(|amt| (amt * 100_000_000.0) as i64)
            .unwrap_or(0);

        let fee = result
            .get("fee")
            .and_then(|f| f.as_f64())
            .map(|f| (f.abs() * 100_000_000.0) as u64);

        Ok(BitcoinTransaction {
            txid: tx_hash.to_string(),
            confirmations,
            amount,
            fee,
        })
    }

    /// Get network
    pub fn get_network(&self) -> BitcoinNetwork {
        self.network
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BitcoinTransaction {
    pub txid: String,
    pub confirmations: u32,
    pub amount: i64, // Can be negative for sent transactions
    pub fee: Option<u64>,
}
