import { JsonRpcResponse } from "../app/app";

// ============================================================================
// Near Configuration
// ============================================================================

export interface NearConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet" | "betanet";
}

/**
 * Near Protocol Connector
 */
export class NearConnector {
  private readonly config: NearConfig;

  constructor(config: NearConfig) {
    this.config = config;
  }

  async getBalance(accountId: string): Promise<string> {
    if (!this.isValidAccount(accountId)) {
      throw new Error("Invalid Near account");
    }

    try {
      const response = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "query",
          params: {
            request_type: "view_account",
            finality: "final",
            account_id: accountId,
          },
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to fetch Near balance");
      }

      const data = (await response.json()) as JsonRpcResponse & {
        result?: { amount?: string };
      };
      if (data.error) {
        throw new Error(data.error.message || "RPC error");
      }

      // Return balance in yoctoNEAR (smallest unit)
      return data.result?.amount || "0";
    } catch (error) {
      throw new Error(
        `Near getBalance failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  async sendTransaction(
    fromAccount: string,
    toAccount: string,
    amount: string
  ): Promise<string> {
    if (!this.isValidAccount(fromAccount) || !this.isValidAccount(toAccount)) {
      throw new Error("Invalid Near account");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Near transactions require:
      // 1. Creating transaction with actions
      // 2. Signing with access key
      // 3. Submitting to network
      // This is simplified - in production use near-api-js

      const response = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "broadcast_tx_commit",
          params: [
            // Signed transaction would go here
            // This requires proper serialization and signing
            "base64_encoded_signed_tx",
          ],
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to submit Near transaction");
      }

      const data = (await response.json()) as JsonRpcResponse & {
        result?: { transaction?: { hash?: string } };
      };
      if (data.error) {
        throw new Error(data.error.message || "Transaction failed");
      }

      return data.result?.transaction?.hash || "transaction_hash";
    } catch (error) {
      throw new Error(
        `Near sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAccount(accountId: string): boolean {
    return accountId.length >= 2 && accountId.length <= 64;
  }

  /**
   * Bridge tokens from Near to another chain
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
    return "Near";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["near"];
  }
}

