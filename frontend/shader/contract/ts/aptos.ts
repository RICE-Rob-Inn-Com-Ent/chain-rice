// ============================================================================
// Aptos Configuration
// ============================================================================

export interface AptosConfig {
  rpcUrl: string;
  network: "mainnet" | "testnet";
}

// ============================================================================
// Aptos API Response Types
// ============================================================================

export interface AptosAccountResponse {
  data?: {
    coin?: {
      value?: string;
    };
  };
}

export interface AptosTransactionResponse {
  hash?: string;
  transaction?: {
    hash?: string;
  };
}

/**
 * Aptos Connector
 * Connects to Aptos blockchain
 */
export class AptosConnector {
  private readonly config: AptosConfig;

  constructor(config: AptosConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Aptos address");
    }

    try {
      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = this.config.rpcUrl || "https://fullnode.mainnet.aptoslabs.com";
      } else {
        apiUrl = this.config.rpcUrl || "https://fullnode.testnet.aptoslabs.com";
      }

      // Aptos uses REST API, not JSON-RPC
      const response = await fetch(
        `${apiUrl}/v1/accounts/${address}/resource/0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>`,
        {
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        // If account doesn't exist or has no balance, return 0
        if (response.status === 404) {
          return "0";
        }
        throw new Error("Failed to fetch Aptos balance");
      }

      const data = (await response.json()) as AptosAccountResponse;

      // Return balance in Octas (smallest unit, 1 APT = 100,000,000 Octas)
      return data.data?.coin?.value || "0";
    } catch (error) {
      throw new Error(
        `Aptos getBalance failed: ${
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
      throw new Error("Invalid Aptos address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Aptos transactions require:
      // 1. Building transaction with proper Move function call
      // 2. Signing with private key
      // 3. Submitting to network
      // This is simplified - in production use aptos SDK

      let apiUrl: string;
      if (this.config.network === "mainnet") {
        apiUrl = this.config.rpcUrl || "https://fullnode.mainnet.aptoslabs.com";
      } else {
        apiUrl = this.config.rpcUrl || "https://fullnode.testnet.aptoslabs.com";
      }

      // Get account sequence number
      const accountResponse = await fetch(`${apiUrl}/v1/accounts/${fromAddress}`, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!accountResponse.ok) {
        throw new Error("Failed to get account information");
      }

      // Submit transaction
      // Note: In production, use aptos SDK to properly build and sign
      const response = await fetch(`${apiUrl}/v1/transactions`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          // Signed transaction would go here
          // This requires proper serialization and signing
          sender: fromAddress,
          sequence_number: "0", // Would be fetched from account
          max_gas_amount: "1000",
          gas_unit_price: "100",
          expiration_timestamp_secs: "0", // Would be calculated
          payload: {
            type: "entry_function_payload",
            function: "0x1::coin::transfer",
            type_arguments: ["0x1::aptos_coin::AptosCoin"],
            arguments: [toAddress, amountNum.toString()],
          },
          signature: {
            type: "ed25519_signature",
            public_key: "0x...",
            signature: "0x...",
          },
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to submit Aptos transaction");
      }

      const data = (await response.json()) as AptosTransactionResponse & {
        message?: string;
      };

      if (data.message) {
        throw new Error(data.message);
      }

      return data.hash || data.transaction?.hash || "transaction_hash";
    } catch (error) {
      throw new Error(
        `Aptos sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    // Aptos addresses are 0x followed by 64 hex characters
    const aptosAddressPattern = /^0x[a-fA-F0-9]{64}$/;
    return aptosAddressPattern.test(address);
  }

  /**
   * Bridge tokens from Aptos to another chain
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
    return "Aptos";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["aptos", "apt"];
  }
}

