// ============================================================================
// Tron Configuration
// ============================================================================

export interface TronConfig {
  rpcUrl: string;
  network: "mainnet" | "shasta" | "nile";
}

// ============================================================================
// Tron API Response Types
// ============================================================================

export interface TronAccountResponse {
  balance?: string;
}

/**
 * Tron Connector
 */
export class TronConnector {
  private readonly config: TronConfig;

  constructor(config: TronConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Tron address");
    }

    try {
      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = "https://api.trongrid.io";
      } else if (this.config.network === "shasta") {
        apiUrl = "https://api.shasta.trongrid.io";
      } else {
        apiUrl = this.config.rpcUrl;
      }

      const response = await fetch(`${apiUrl}/v1/accounts/${address}`, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Failed to fetch Tron balance");
      }

      const data = (await response.json()) as TronAccountResponse;
      // Return balance in sun (smallest unit, 1 TRX = 1,000,000 sun)
      return data.balance?.toString() || "0";
    } catch (error) {
      throw new Error(
        `Tron getBalance failed: ${
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
      throw new Error("Invalid Tron address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Tron transactions require:
      // 1. Creating transaction
      // 2. Signing with private key
      // 3. Broadcasting to network
      // This is simplified - in production use tronweb

      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = "https://api.trongrid.io";
      } else if (this.config.network === "shasta") {
        apiUrl = "https://api.shasta.trongrid.io";
      } else {
        apiUrl = this.config.rpcUrl;
      }

      // Create transaction
      const createResponse = await fetch(
        `${apiUrl}/wallet/createtransaction`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            to_address: toAddress,
            owner_address: fromAddress,
            amount: amountNum,
          }),
        }
      );

      if (!createResponse.ok) {
        throw new Error("Failed to create Tron transaction");
      }

      const transaction = await createResponse.json();

      // Sign and broadcast
      // Note: In production, sign with private key before broadcasting
      const broadcastResponse = await fetch(
        `${apiUrl}/wallet/broadcasttransaction`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(transaction),
        }
      );

      if (!broadcastResponse.ok) {
        throw new Error("Failed to broadcast Tron transaction");
      }

      const broadcastData = (await broadcastResponse.json()) as {
        txid?: string;
      };
      return (
        broadcastData.txid || (transaction as any).txID || "transaction_id"
      );
    } catch (error) {
      throw new Error(
        `Tron sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    return address.length === 34 && address.startsWith("T");
  }

  /**
   * Bridge tokens from Tron to another chain
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
    return "Tron";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["tron", "trx"];
  }
}

