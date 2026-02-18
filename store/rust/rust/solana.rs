//! Solana connector for interacting with Solana blockchain

use crate::{BridgeError, BridgeResult, SolanaNetwork, solana_rpc_call};
use serde::{Deserialize, Serialize};

/// Solana connector for interacting with Solana blockchain
pub struct SolanaConnector {
    rpc_url: String,
    network: SolanaNetwork,
}

impl SolanaConnector {
    /// Create new Solana connector
    pub fn new(rpc_url: &str, network: SolanaNetwork) -> BridgeResult<Self> {
        Ok(Self { rpc_url: rpc_url.to_string(), network })
    }

    /// Get balance for a Solana address
    pub fn get_balance(&self, address: &str) -> BridgeResult<u64> {
        // Validate Solana address (base58, 32-44 chars)
        if !self.is_valid_address(address) {
            return Err(BridgeError::InvalidAddress(address.to_string()));
        }

        let params = serde_json::json!([address, {"encoding": "jsonParsed"}]);
        let result = solana_rpc_call(&self.rpc_url, "getBalance", params)?;

        let balance = result
            .get("value")
            .and_then(|v| v.as_u64())
            .ok_or_else(|| BridgeError::DeserializationError("Invalid balance format".to_string()))?;

        Ok(balance)
    }

    /// Send SOL transaction
    pub fn send_transaction(
        &self,
        from_address: &str,
        to_address: &str,
        amount: u64, // in lamports
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

        // Note: Solana transactions require signing with a private key.
        // This implementation assumes the RPC endpoint has access to the wallet.
        // In production, you'd need to:
        // 1. Get recent blockhash
        // 2. Create transfer instruction
        // 3. Build and sign transaction
        // 4. Send transaction

        // For now, we'll use a simplified approach that requires the RPC to handle signing
        // This is typically done via wallet integration or by sending a pre-signed transaction
        // Here we return an error indicating that signing is required
        Err(BridgeError::TransactionFailed(
            "Solana transactions require private key signing. Use a wallet-integrated RPC or provide a signed transaction.".to_string()
        ))
    }

    /// Validate Solana address (base58)
    pub fn is_valid_address(&self, address: &str) -> bool {
        // Basic validation - Solana addresses are base58 encoded, 32-44 chars
        // In production, use proper base58 decoding
        address.len() >= 32 && address.len() <= 44
    }

    /// Get transaction info
    pub fn get_transaction(&self, signature: &str) -> BridgeResult<SolanaTransaction> {
        let params = serde_json::json!([signature, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}]);
        let result = solana_rpc_call(&self.rpc_url, "getTransaction", params)?;

        let slot = result.get("slot").and_then(|s| s.as_u64()).unwrap_or(0);

        let block_time = result.get("blockTime").and_then(|bt| bt.as_i64());

        // Extract amount and fee from transaction
        let amount = result
            .get("meta")
            .and_then(|m| m.get("preBalances"))
            .and_then(|pb| pb.as_array())
            .and_then(|arr| {
                if arr.len() >= 2 {
                    let pre = arr[0].as_u64()?;
                    let post = arr[1].as_u64()?;
                    Some(post.saturating_sub(pre))
                } else {
                    None
                }
            })
            .unwrap_or(0);

        let fee = result
            .get("meta")
            .and_then(|m| m.get("fee"))
            .and_then(|f| f.as_u64())
            .unwrap_or(0);

        Ok(SolanaTransaction {
            signature: signature.to_string(),
            slot,
            block_time,
            amount,
            fee,
        })
    }

    /// Get network
    pub fn get_network(&self) -> SolanaNetwork {
        self.network
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SolanaTransaction {
    pub signature: String,
    pub slot: u64,
    pub block_time: Option<i64>,
    pub amount: u64,
    pub fee: u64,
}

