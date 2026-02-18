// ============================================================================
// Algorand Configuration
// ============================================================================

export interface AlgorandConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet" | "betanet";
}

// ============================================================================
// Algorand API Response Types
// ============================================================================

export interface AlgorandAccountResponse {
  amount?: number;
}

/**
 * Algorand Connector
 */
export class AlgorandConnector {
  private readonly config: AlgorandConfig;

  constructor(config: AlgorandConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Algorand address");
    }

    try {
      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = "https://mainnet-api.algonode.cloud";
      } else if (this.config.network === "testnet") {
        apiUrl = "https://testnet-api.algonode.cloud";
      } else {
        apiUrl = this.config.rpcUrl;
      }

      const response = await fetch(`${apiUrl}/v2/accounts/${address}`, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Failed to fetch Algorand balance");
      }

      const data = (await response.json()) as AlgorandAccountResponse;
      // Return balance in microAlgos (smallest unit)
      return data.amount?.toString() || "0";
    } catch (error) {
      throw new Error(
        `Algorand getBalance failed: ${
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
      throw new Error("Invalid Algorand address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Algorand transactions require:
      // 1. Creating payment transaction
      // 2. Signing with private key
      // 3. Submitting to network
      // This is simplified - in production use algosdk

      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = "https://mainnet-api.algonode.cloud";
      } else if (this.config.network === "testnet") {
        apiUrl = "https://testnet-api.algonode.cloud";
      } else {
        apiUrl = this.config.rpcUrl;
      }

      // Get suggested params
      const paramsResponse = await fetch(`${apiUrl}/v2/transactions/params`, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!paramsResponse.ok) {
        throw new Error("Failed to get transaction parameters");
      }

      // Build and submit transaction
      // Note: In production, use algosdk to properly build and sign
      const submitResponse = await fetch(`${apiUrl}/v2/transactions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-binary",
        },
        body: JSON.stringify({
          // Signed transaction would go here
          // This requires proper serialization and signing
        }),
      });

      if (!submitResponse.ok) {
        throw new Error("Failed to submit Algorand transaction");
      }

      const submitData = (await submitResponse.json()) as { txid?: string };
      return submitData.txid || "transaction_id";
    } catch (error) {
      throw new Error(
        `Algorand sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    return address.length === 58;
  }

  /**
   * Bridge tokens from Algorand to another chain
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
    return "Algorand";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["algorand", "algo"];
  }
}
