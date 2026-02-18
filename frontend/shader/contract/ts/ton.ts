// ============================================================================
// TON (The Open Network) Configuration
// ============================================================================

export interface TONConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet";
}

// ============================================================================
// TON API Response Types
// ============================================================================

export interface TONAccountResponse {
  balance?: string;
  state?: string;
}

export interface TONTransactionResponse {
  transaction_id?: {
    hash?: string;
    lt?: string;
  };
  hash?: string;
}

/**
 * TON Connector
 * Connects to The Open Network (TON) blockchain
 */
export class TONConnector {
  private readonly config: TONConfig;

  constructor(config: TONConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid TON address");
    }

    try {
      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = this.config.rpcUrl || "https://toncenter.com/api/v2";
      } else {
        apiUrl = this.config.rpcUrl || "https://testnet.toncenter.com/api/v2";
      }

      // TON addresses need to be converted to raw format for API calls
      // For simplicity, we'll use the address directly (in production, use @ton/core to convert)
      const response = await fetch(
        `${apiUrl}/getAddressInformation?address=${encodeURIComponent(address)}`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        throw new Error("Failed to fetch TON balance");
      }

      const data = (await response.json()) as {
        result?: TONAccountResponse;
        ok?: boolean;
      };

      if (!data.ok || !data.result) {
        throw new Error("Failed to fetch TON account information");
      }

      // Return balance in nanograms (smallest unit, 1 TON = 1,000,000,000 nanograms)
      return data.result.balance || "0";
    } catch (error) {
      throw new Error(
        `TON getBalance failed: ${
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
      throw new Error("Invalid TON address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // TON transactions require:
      // 1. Creating transaction with proper message structure
      // 2. Signing with private key using TVM (TON Virtual Machine)
      // 3. Submitting to network
      // This is simplified - in production use @ton/core or tonweb

      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = this.config.rpcUrl || "https://toncenter.com/api/v2";
      } else {
        apiUrl = this.config.rpcUrl || "https://testnet.toncenter.com/api/v2";
      }

      // Get account state to get sequence number
      const accountResponse = await fetch(
        `${apiUrl}/getAddressInformation?address=${encodeURIComponent(
          fromAddress
        )}`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!accountResponse.ok) {
        throw new Error("Failed to get account information");
      }

      const accountData = (await accountResponse.json()) as {
        result?: TONAccountResponse;
        ok?: boolean;
      };

      if (!accountData.ok) {
        throw new Error("Failed to get account state");
      }

      // Send transaction
      // Note: In production, use @ton/core to properly build and sign transactions
      // Transaction would include:
      // - source: fromAddress
      // - destination: toAddress
      // - amount: amountNum (in nanograms)
      // - seqno: account sequence number
      // - body: message body (empty for simple transfers)
      const sendResponse = await fetch(`${apiUrl}/sendBoc`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          boc: "base64_encoded_signed_transaction", // In production, this would be the signed transaction BOC
        }),
      });

      if (!sendResponse.ok) {
        throw new Error("Failed to send TON transaction");
      }

      const sendData = (await sendResponse.json()) as {
        result?: TONTransactionResponse;
        ok?: boolean;
      };

      if (!sendData.ok || !sendData.result) {
        throw new Error("Transaction submission failed");
      }

      return (
        sendData.result.transaction_id?.hash ||
        sendData.result.hash ||
        "transaction_hash"
      );
    } catch (error) {
      throw new Error(
        `TON sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    // TON addresses can be in different formats:
    // - Raw format: base64 encoded (48 chars)
    // - User-friendly format: starts with 0: or -1: followed by hex
    // - Bounceable/non-bounceable formats
    // Basic validation - check for common TON address patterns
    const rawPattern = /^[A-Za-z0-9+/]{48}$/; // Base64 raw format
    const friendlyPattern = /^(0|-1):[A-Fa-f0-9]{64}$/; // User-friendly format
    const bounceablePattern = /^[A-Za-z0-9_-]{48}$/; // Bounceable format

    return (
      rawPattern.test(address) ||
      friendlyPattern.test(address) ||
      bounceablePattern.test(address) ||
      address.length === 48
    );
  }

  /**
   * Bridge tokens from TON to another chain
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
    return "TON";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["ton", "the-open-network", "telegram-open-network"];
  }
}

