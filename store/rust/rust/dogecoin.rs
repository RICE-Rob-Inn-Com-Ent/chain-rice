//! Dogecoin connector (similar to Bitcoin)

use crate::{bitcoin_rpc_call, BridgeError, BridgeResult, DogecoinNetwork};
use serde::{Deserialize, Serialize};

/// Dogecoin connector (similar to Bitcoin)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DogecoinConnector {
    rpc_url: String,
    rpc_user: String,
    rpc_password: String,
    #[allow(dead_code)]
    network: DogecoinNetwork,
}

impl DogecoinConnector {
    pub fn new(rpc_url: &str, rpc_user: &str, rpc_password: &str, network: DogecoinNetwork) -> BridgeResult<Self> {
        Ok(Self {
            rpc_url: rpc_url.to_string(),
            rpc_user: rpc_user.to_string(),
            rpc_password: rpc_password.to_string(),
            network,
        })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Dogecoin uses same RPC as Bitcoin
        let params = serde_json::json!([address]);
        let result = bitcoin_rpc_call(&self.rpc_url, &self.rpc_user, &self.rpc_password, "listunspent", params)?;

        let utxos: Vec<serde_json::Value> = serde_json::from_value(result)
            .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse UTXOs: {}", e)))?;

        let balance: u64 = utxos
            .iter()
            .filter_map(|utxo| {
                utxo.get("amount")
                    .and_then(|a| a.as_f64())
                    .map(|amt| (amt * 100_000_000.0) as u64)
            })
            .sum();

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in smallest unit
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Dogecoin address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Dogecoin uses same RPC as Bitcoin
        let amount_doge = amount as f64 / 100_000_000.0;
        let params = serde_json::json!([to_address, amount_doge]);
        let result = bitcoin_rpc_call(&self.rpc_url, &self.rpc_user, &self.rpc_password, "sendtoaddress", params)?;

        let tx_hash = result
            .as_str()
            .ok_or_else(|| BridgeError::DeserializationError("Invalid transaction hash format".to_string()))?
            .to_string();

        Ok(tx_hash)
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Dogecoin addresses start with 'D' for mainnet
        match self.network {
            DogecoinNetwork::Mainnet => address.starts_with('D'),
            DogecoinNetwork::Testnet => address.starts_with('n') || address.starts_with('m'),
        }
    }
}
