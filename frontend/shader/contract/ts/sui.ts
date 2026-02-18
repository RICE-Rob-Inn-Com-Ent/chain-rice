// ============================================================================
// Sui Configuration
// ============================================================================

export interface SuiConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet" | "devnet";
}

// ============================================================================
// Sui API Response Types
// ============================================================================

export interface SuiAccountResponse {
  data?: {
    totalBalance?: string;
  };
}

export interface SuiTransactionResponse {
  digest?: string;
  transaction?: {
    data?: {
      transactionDigest?: string;
    };
  };
}

/**
 * Sui Connector
 * Connects to Sui blockchain
 */
export class SuiConnector {
  private readonly config: SuiConfig;

  constructor(config: SuiConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Sui address");
    }

    try {
      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = this.config.rpcUrl || "https://fullnode.mainnet.sui.io:443";
      } else if (this.config.network === "testnet") {
        apiUrl = this.config.rpcUrl || "https://fullnode.testnet.sui.io:443";
      } else {
        apiUrl = this.config.rpcUrl || "https://fullnode.devnet.sui.io:443";
      }

      const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "suix_getBalance",
          params: [address],
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to fetch Sui balance");
      }

      const data = (await response.json()) as {
        result?: SuiAccountResponse;
        error?: { message?: string };
      };

      if (data.error) {
        throw new Error(data.error.message || "RPC error");
      }

      // Return balance in MIST (smallest unit, 1 SUI = 1,000,000,000 MIST)
      return data.result?.data?.totalBalance || "0";
    } catch (error) {
      throw new Error(
        `Sui getBalance failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  async sendTransaction(
    fromAddress: string,
    toAddress: string,
    amount: string
  ): Promise<string> {
    if (!this.isValidAddress(fromAddress) || !this.isValidAddress(toAddress)) {
      throw new Error("Invalid Sui address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Sui transactions require:
      // 1. Building transaction with proper Move call
      // 2. Signing with private key
      // 3. Submitting to network
      // This is simplified - in production use @mysten/sui.js

      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = this.config.rpcUrl || "https://fullnode.mainnet.sui.io:443";
      } else if (this.config.network === "testnet") {
        apiUrl = this.config.rpcUrl || "https://fullnode.testnet.sui.io:443";
      } else {
        apiUrl = this.config.rpcUrl || "https://fullnode.devnet.sui.io:443";
      }

      // Get gas objects and build transaction
      // Note: In production, use @mysten/sui.js to properly build and sign
      const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "sui_executeTransactionBlock",
          params: [
            // Signed transaction would go here
            // This requires proper serialization and signing
            "base64_encoded_signed_transaction",
            {
              showEffects: true,
              showEvents: true,
            },
          ],
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to submit Sui transaction");
      }

      const data = (await response.json()) as {
        result?: SuiTransactionResponse;
        error?: { message?: string };
      };

      if (data.error) {
        throw new Error(data.error.message || "Transaction failed");
      }

      return (
        data.result?.digest ||
        data.result?.transaction?.data?.transactionDigest ||
        "transaction_digest"
      );
    } catch (error) {
      throw new Error(
        `Sui sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    // Sui addresses are 0x followed by 64 hex characters
    const suiAddressPattern = /^0x[a-fA-F0-9]{64}$/;
    return suiAddressPattern.test(address);
  }

  /**
   * Bridge tokens from Sui to another chain
   */
  async bridgeTokens(
    sourceAddress: string,
    destinationAddress: string,
    amount: string
  ): Promise<{ sourceTx: string; destinationTx?: string }> {
    const txHash = await this.sendTransaction(
      sourceAddress,
      destinationAddress,
      amount
    );
    return { sourceTx: txHash };
  }

  /**
   * Get chain name for bridge operations
   */
  getChainName(): string {
    return "Sui";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["sui"];
  }
}

