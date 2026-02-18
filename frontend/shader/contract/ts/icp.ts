// ============================================================================
// Internet Computer (ICP) Configuration
// ============================================================================

export interface ICPConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet";
}

// ============================================================================
// ICP API Response Types
// ============================================================================

export interface ICPAccountResponse {
  account_balance?: {
    e8s?: string;
  };
  balance?: string;
}

export interface ICPTransactionResponse {
  block_height?: string;
  transaction_hash?: string;
}

/**
 * Internet Computer (ICP) Connector
 * Connects to Internet Computer blockchain
 */
export class ICPConnector {
  private readonly config: ICPConfig;

  constructor(config: ICPConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid ICP address");
    }

    try {
      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl =
          this.config.rpcUrl ||
          "https://ledger.public.internetcomputer.org";
      } else {
        apiUrl =
          this.config.rpcUrl ||
          "https://ledger.testnet.internetcomputer.org";
      }

      // ICP uses canister calls for account balance
      // For simplicity, using ledger API endpoint
      const response = await fetch(
        `${apiUrl}/api/v2/account/${address}/balance`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        // If account doesn't exist, return 0
        if (response.status === 404) {
          return "0";
        }
        throw new Error("Failed to fetch ICP balance");
      }

      const data = (await response.json()) as ICPAccountResponse;

      // Return balance in e8s (smallest unit, 1 ICP = 100,000,000 e8s)
      return (
        data.account_balance?.e8s ||
        data.balance ||
        "0"
      );
    } catch (error) {
      throw new Error(
        `ICP getBalance failed: ${
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
      throw new Error("Invalid ICP address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // ICP transactions require:
      // 1. Creating transfer request with proper canister call
      // 2. Signing with identity (using Internet Identity or private key)
      // 3. Submitting to network via canister
      // This is simplified - in production use @dfinity/agent

      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl =
          this.config.rpcUrl ||
          "https://ledger.public.internetcomputer.org";
      } else {
        apiUrl =
          this.config.rpcUrl ||
          "https://ledger.testnet.internetcomputer.org";
      }

      // Submit transaction
      // Note: In production, use @dfinity/agent to properly build and sign
      const response = await fetch(`${apiUrl}/api/v2/transfer`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          // Transfer request would go here
          // This requires proper serialization and signing
          to: toAddress,
          amount: {
            e8s: amountNum.toString(),
          },
          fee: {
            e8s: "10000", // Standard fee
          },
          memo: 0,
          created_at_time: {
            timestamp_nanos: Date.now() * 1000000,
          },
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to submit ICP transaction");
      }

      const data = (await response.json()) as ICPTransactionResponse & {
        error?: { message?: string };
      };

      if (data.error) {
        throw new Error(data.error.message || "Transaction failed");
      }

      return (
        data.transaction_hash ||
        data.block_height ||
        "transaction_hash"
      );
    } catch (error) {
      throw new Error(
        `ICP sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    // ICP addresses (Principal IDs) can be in different formats:
    // - Text format: base32 encoded with CRC32 checksum
    // - Hex format: 0x followed by hex
    // - Raw format: base64 encoded
    // Basic validation - check for common patterns
    const principalPattern = /^[a-z0-9-]{27,}$/i; // Text format (simplified)
    const hexPattern = /^0x[a-fA-F0-9]+$/; // Hex format
    const base64Pattern = /^[A-Za-z0-9+/=]+$/; // Base64 format

    return (
      principalPattern.test(address) ||
      hexPattern.test(address) ||
      (base64Pattern.test(address) && address.length >= 20)
    );
  }

  /**
   * Bridge tokens from ICP to another chain
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
    return "Internet Computer";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["icp", "internet-computer", "dfinity"];
  }
}

