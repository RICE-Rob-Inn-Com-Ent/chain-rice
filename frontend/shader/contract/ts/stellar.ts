// ============================================================================
// Stellar Configuration
// ============================================================================

export interface StellarConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet";
}

// ============================================================================
// Stellar API Response Types
// ============================================================================

export interface StellarAccountResponse {
  balances?: Array<{
    asset_type: string;
    balance: string;
  }>;
}

/**
 * Stellar Connector
 */
export class StellarConnector {
  private readonly config: StellarConfig;

  constructor(config: StellarConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Stellar address");
    }

    try {
      const apiUrl =
        this.config.network === "mainnet"
          ? "https://horizon.stellar.org"
          : "https://horizon-testnet.stellar.org";

      const response = await fetch(`${apiUrl}/accounts/${address}`, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Failed to fetch Stellar balance");
      }

      const data = (await response.json()) as StellarAccountResponse;
      // Find XLM balance (native asset)
      const xlmBalance = data.balances?.find(
        (bal: any) => bal.asset_type === "native"
      );
      // Return balance in stroops (smallest unit, 1 XLM = 10,000,000 stroops)
      return xlmBalance
        ? (Number.parseFloat(xlmBalance.balance) * 10000000).toString()
        : "0";
    } catch (error) {
      throw new Error(
        `Stellar getBalance failed: ${
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
      throw new Error("Invalid Stellar address");
    }

    const amountNum = Number.parseFloat(amount);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Stellar transactions require:
      // 1. Getting account sequence number
      // 2. Building transaction
      // 3. Signing with private key
      // 4. Submitting to network
      // This is simplified - in production use stellar-sdk

      const apiUrl =
        this.config.network === "mainnet"
          ? "https://horizon.stellar.org"
          : "https://horizon-testnet.stellar.org";

      // Get account info
      const accountResponse = await fetch(
        `${apiUrl}/accounts/${fromAddress}`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!accountResponse.ok) {
        throw new Error("Failed to get account info");
      }

      // Build payment operation
      // Note: In production, use stellar-sdk to properly build and sign
      // Account info would be retrieved here: await accountResponse.json()
      // Submit transaction
      // Note: Transaction must be signed before submission
      const submitResponse = await fetch(`${apiUrl}/transactions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          tx: "base64_encoded_signed_transaction", // In production, this would be the signed transaction
          // Transaction would include:
          // source: fromAddress,
          // sequence: (await accountResponse.json()).sequence,
          // operations: [{ type: "payment", destination: toAddress, asset: { type: "native" }, amount: (amountNum / 10000000).toFixed(7) }]
        }),
      });

      if (!submitResponse.ok) {
        throw new Error("Failed to submit Stellar transaction");
      }

      const submitData = (await submitResponse.json()) as { hash?: string };
      return submitData.hash || "transaction_hash";
    } catch (error) {
      throw new Error(
        `Stellar sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    return address.length === 56;
  }

  /**
   * Bridge tokens from Stellar to another chain
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
    return "Stellar";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["stellar", "xlm"];
  }
}

