import { JsonRpcResponse } from "../app/app";

// ============================================================================
// Solana Configuration
// ============================================================================

export interface SolanaConfig {
  rpcUrl: string;
  network: "mainnet" | "devnet" | "testnet" | "localnet";
}

// ============================================================================
// Solana API Response Types
// ============================================================================

export interface SolanaBalanceResponse {
  result?: {
    value?: number;
  };
}

/**
 * Solana Connector
 * Connects to Solana blockchain
 */
export class SolanaConnector {
  private readonly config: SolanaConfig;

  constructor(config: SolanaConfig) {
    this.config = config;
  }

  /**
   * Get balance for a Solana address
   * Uses Solana RPC API
   */
  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Solana address");
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
          method: "getBalance",
          params: [address],
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to fetch Solana balance");
      }

      const data = (await response.json()) as SolanaBalanceResponse & {
        error?: { message?: string };
      };
      if (data.error) {
        throw new Error(data.error.message || "RPC error");
      }

      // Return balance in lamports
      return data.result?.value?.toString() || "0";
    } catch (error) {
      throw new Error(
        `Solana getBalance failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  /**
   * Send SOL transaction
   * Note: This requires proper keypair signing
   */
  async sendTransaction(
    fromAddress: string,
    toAddress: string,
    amount: string // in lamports
  ): Promise<string> {
    if (!this.isValidAddress(fromAddress) || !this.isValidAddress(toAddress)) {
      throw new Error("Invalid Solana address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Get recent blockhash
      const blockhashResponse = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "getLatestBlockhash",
          params: [{ commitment: "finalized" }],
        }),
      });

      if (!blockhashResponse.ok) {
        throw new Error("Failed to get recent blockhash");
      }

      const blockhashData =
        (await blockhashResponse.json()) as JsonRpcResponse & {
          result?: { value?: { blockhash?: string } };
        };
      if (blockhashData.error) {
        throw new Error(blockhashData.error.message || "RPC error");
      }

      // Note: In production, you would need to:
      // 1. Load the keypair from fromAddress
      // 2. Create and sign the transaction
      // 3. Send the signed transaction
      // This is a simplified version that shows the structure
      const transaction = {
        message: {
          accountKeys: [fromAddress, toAddress],
          instructions: [
            {
              programId: "11111111111111111111111111111111", // System Program
              accounts: [
                { pubkey: fromAddress, writable: true, signer: true },
                { pubkey: toAddress, writable: true, signer: false },
              ],
              data: Buffer.from([
                2,
                0,
                0,
                0, // Transfer instruction
                ...Buffer.from(
                  amountNum.toString(16).padStart(16, "0"),
                  "hex"
                ),
              ]).toString("base64"),
            },
          ],
          recentBlockhash: blockhashData.result?.value?.blockhash || "",
        },
      };

      // Send transaction (requires signing in production)
      const sendResponse = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 2,
          method: "sendTransaction",
          params: [
            // In production, this would be a signed transaction
            JSON.stringify(transaction),
            { encoding: "base64", skipPreflight: false },
          ],
        }),
      });

      if (!sendResponse.ok) {
        throw new Error("Failed to send Solana transaction");
      }

      const sendData = (await sendResponse.json()) as JsonRpcResponse;
      if (sendData.error) {
        throw new Error(sendData.error.message || "Transaction failed");
      }

      return sendData.result as string;
    } catch (error) {
      throw new Error(
        `Solana sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  /**
   * Validate Solana address (base58, 32-44 chars)
   */
  isValidAddress(address: string): boolean {
    // Basic validation - Solana addresses are base58 encoded
    return address.length >= 32 && address.length <= 44;
  }

  /**
   * Bridge tokens from Solana to another chain
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
    return "Solana";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["solana", "sol"];
  }
}

