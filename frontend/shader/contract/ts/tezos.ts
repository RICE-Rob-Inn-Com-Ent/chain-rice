// ============================================================================
// Tezos Configuration
// ============================================================================

export interface TezosConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet" | "ghostnet";
}

/**
 * Tezos Connector
 */
export class TezosConnector {
  private readonly config: TezosConfig;

  constructor(config: TezosConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Tezos address");
    }

    try {
      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = "https://api.tzkt.io";
      } else if (this.config.network === "testnet") {
        apiUrl = "https://api.ghostnet.tzkt.io";
      } else {
        apiUrl = this.config.rpcUrl;
      }

      const response = await fetch(
        `${apiUrl}/v1/accounts/${address}/balance`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        throw new Error("Failed to fetch Tezos balance");
      }

      const balance = await response.text();
      // Return balance in mutez (smallest unit)
      return balance || "0";
    } catch (error) {
      throw new Error(
        `Tezos getBalance failed: ${
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
      throw new Error("Invalid Tezos address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Tezos transactions require:
      // 1. Creating operation
      // 2. Signing with private key
      // 3. Injecting to network
      // This is simplified - in production use @taquito/taquito

      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = "https://api.tzkt.io";
      } else if (this.config.network === "testnet") {
        apiUrl = "https://api.ghostnet.tzkt.io";
      } else {
        apiUrl = this.config.rpcUrl;
      }

      // Get account info
      const accountResponse = await fetch(
        `${apiUrl}/v1/accounts/${fromAddress}`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!accountResponse.ok) {
        throw new Error("Failed to get account info");
      }

      // Inject operation
      // Note: In production, use @taquito/taquito to properly build and sign
      // Account info would be retrieved here: await accountResponse.json()
      // Account sequence would be used from accountData.counter
      const injectResponse = await fetch(
        `${apiUrl}/v1/operations/transactions`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            // Signed operation would go here
            // This requires proper serialization and signing
          }),
        }
      );

      if (!injectResponse.ok) {
        throw new Error("Failed to inject Tezos transaction");
      }

      const injectData = (await injectResponse.json()) as { hash?: string };
      return injectData.hash || "operation_hash";
    } catch (error) {
      throw new Error(
        `Tezos sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    return (
      address.startsWith("tz1") ||
      address.startsWith("tz2") ||
      address.startsWith("tz3") ||
      address.startsWith("KT1")
    );
  }

  /**
   * Bridge tokens from Tezos to another chain
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
    return "Tezos";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["tezos", "xtz"];
  }
}

