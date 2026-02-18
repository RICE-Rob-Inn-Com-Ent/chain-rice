//! Ripple (XRP) connector

use crate::{BridgeError, BridgeResult, RippleNetwork, JsonRpcRequest, JsonRpcResponse};
use serde::{Deserialize, Serialize};

/// Ripple connector
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RippleConnector {
    rpc_url: String,
    #[allow(dead_code)]
    network: RippleNetwork,
}

impl RippleConnector {
    pub fn new(rpc_url: &str, network: RippleNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        // Ripple JSON-RPC
        let params = serde_json::json!({
            "account": address,
            "strict": true,
            "ledger_index": "validated"
        });

        let request = JsonRpcRequest {
            jsonrpc: "2.0".to_string(),
            method: "account_info".to_string(),
            params: serde_json::to_value(params)
                .map_err(|e| BridgeError::SerializationError(format!("Failed to serialize params: {}", e)))?,
            id: 1,
        };

        let client = reqwest::blocking::Client::new();
        let response = client
            .post(&self.rpc_url)
            .json(&request)
            .send()
            .map_err(|e| BridgeError::NetworkError(format!("RPC request failed: {}", e)))?;

        let json_response: JsonRpcResponse = response
            .json()
            .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse response: {}", e)))?;

        if let Some(error) = json_response.error {
            return Err(BridgeError::NetworkError(format!(
                "RPC error {}: {}",
                error.code, error.message
            )));
        }

        let balance = json_response
            .result
            .as_ref()
            .and_then(|r| r.get("account_data"))
            .and_then(|ad| ad.get("Balance"))
            .and_then(|b| b.as_str())
            .and_then(|s| s.parse::<u64>().ok())
            .unwrap_or(0);

        Ok(balance)
    }

    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in drops (1 XRP = 1,000,000 drops)
    ) -> BridgeResult<String> {
        if !self.is_valid_address(from_address) || !self.is_valid_address(to_address) {
            return Err(BridgeError::InvalidAddress("Invalid Ripple address".to_string()));
        }
        if amount == 0 {
            return Err(BridgeError::InvalidAmount("Amount must be greater than 0".to_string()));
        }

        // Ripple transactions require signing
        // This assumes the RPC endpoint can handle signed transaction submission
        let params = serde_json::json!({
            "TransactionType": "Payment",
            "Account": from_address,
            "Destination": to_address,
            "Amount": amount.to_string()
        });

        let request = JsonRpcRequest {
            jsonrpc: "2.0".to_string(),
            method: "submit".to_string(),
            params: serde_json::to_value(params)
                .map_err(|e| BridgeError::SerializationError(format!("Failed to serialize params: {}", e)))?,
            id: 1,
        };

        let client = reqwest::blocking::Client::new();
        let response = client
            .post(&self.rpc_url)
            .json(&request)
            .send()
            .map_err(|e| BridgeError::NetworkError(format!("RPC request failed: {}", e)))?;

        let json_response: JsonRpcResponse = response
            .json()
            .map_err(|e| BridgeError::DeserializationError(format!("Failed to parse response: {}", e)))?;

        if let Some(error) = json_response.error {
            return Err(BridgeError::NetworkError(format!(
                "RPC error {}: {}",
                error.code, error.message
            )));
        }

        let hash = json_response
            .result
            .as_ref()
            .and_then(|r| r.get("tx_json"))
            .and_then(|tx| tx.get("hash"))
            .and_then(|h| h.as_str())
            .map(|s| s.to_string())
            .or_else(|| {
                json_response
                    .result
                    .as_ref()
                    .and_then(|r| r.get("hash"))
                    .and_then(|h| h.as_str())
                    .map(|s| s.to_string())
            })
            .ok_or_else(|| BridgeError::TransactionFailed("Failed to get transaction hash".to_string()))?;
        Ok(hash)
    }

    pub fn is_valid_address(&self, address: &str) -> bool {
        // Ripple addresses are base58 encoded, start with 'r'
        address.len() >= 25 && address.len() <= 35 && address.starts_with('r')
    }
}

