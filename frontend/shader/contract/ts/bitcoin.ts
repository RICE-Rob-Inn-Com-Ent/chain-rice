import { JsonRpcResponse } from "../app/app";

// ============================================================================
// Bitcoin Configuration
// ============================================================================

export interface BitcoinConfig {
  rpcUrl: string;
  rpcUser: string;
  rpcPassword: string;
  network: "mainnet" | "testnet" | "regtest";
}

// ============================================================================
// Bitcoin API Response Types
// ============================================================================

export interface BlockstreamAddressResponse {
  chain_stats?: {
    funded_txo_sum?: number;
  };
  mempool_stats?: {
    funded_txo_sum?: number;
  };
}

/**
 * Bitcoin Connector
 * Connects to Bitcoin blockchain via RPC
 */
export class BitcoinConnector {
  private readonly config: BitcoinConfig;

  constructor(config: BitcoinConfig) {
    this.config = config;
  }

  /**
   * Get balance for a Bitcoin address
   * Uses Bitcoin RPC or public API
   */
  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Bitcoin address");
    }

    try {
      // Try RPC first if configured
      if (
        this.config.rpcUrl &&
        this.config.rpcUser &&
        this.config.rpcPassword
      ) {
        const response = await fetch(this.config.rpcUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Basic ${Buffer.from(
              `${this.config.rpcUser}:${this.config.rpcPassword}`
            ).toString("base64")}`,
          },
          body: JSON.stringify({
            jsonrpc: "2.0",
            id: 1,
            method: "getreceivedbyaddress",
            params: [address, 0],
          }),
        });

        if (response.ok) {
          const data = (await response.json()) as JsonRpcResponse;
          if (data.result !== undefined) {
            // Convert from BTC to satoshis, then back to string
            return (Number.parseFloat(data.result) * 100000000).toString();
          }
        }
      }

      // Fallback to public API (blockchain.info or blockstream.info)
      const apiUrl =
        this.config.network === "mainnet"
          ? `https://blockstream.info/api/address/${address}`
          : `https://blockstream.info/testnet/api/address/${address}`;

      const response = await fetch(apiUrl);
      if (response.ok) {
        const data = (await response.json()) as BlockstreamAddressResponse;
        // Return balance in satoshis
        return data.chain_stats?.funded_txo_sum?.toString() || "0";
      }

      throw new Error("Failed to fetch Bitcoin balance");
    } catch (error) {
      throw new Error(
        `Bitcoin getBalance failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  /**
   * Send Bitcoin transaction
   * Note: This requires proper wallet setup and signing
   */
  async sendTransaction(
    fromAddress: string,
    toAddress: string,
    amount: string // in satoshis
  ): Promise<string> {
    if (!this.isValidAddress(fromAddress)) {
      throw new Error("Invalid from address");
    }
    if (!this.isValidAddress(toAddress)) {
      throw new Error("Invalid to address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // This requires RPC access with wallet functionality
      if (
        !this.config.rpcUrl ||
        !this.config.rpcUser ||
        !this.config.rpcPassword
      ) {
        throw new Error(
          "Bitcoin RPC credentials required for sending transactions"
        );
      }

      // Get UTXOs for the from address
      const utxoResponse = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${Buffer.from(
            `${this.config.rpcUser}:${this.config.rpcPassword}`
          ).toString("base64")}`,
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 1,
          method: "listunspent",
          params: [0, 9999999, [fromAddress]],
        }),
      });

      if (!utxoResponse.ok) {
        throw new Error("Failed to fetch UTXOs");
      }

      const utxoData = (await utxoResponse.json()) as JsonRpcResponse;
      if (!utxoData.result || (utxoData.result as any[]).length === 0) {
        throw new Error("No UTXOs available for the from address");
      }

      // Create raw transaction
      // Note: This is a simplified version. In production, you'd need proper transaction building
      const createTxResponse = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${Buffer.from(
            `${this.config.rpcUser}:${this.config.rpcPassword}`
          ).toString("base64")}`,
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 2,
          method: "createrawtransaction",
          params: [
            (utxoData.result as any[]).map((utxo: any) => ({
              txid: utxo.txid,
              vout: utxo.vout,
            })),
            { [toAddress]: amountNum / 100000000 }, // Convert satoshis to BTC
          ],
        }),
      });

      if (!createTxResponse.ok) {
        throw new Error("Failed to create raw transaction");
      }

      const createTxData = (await createTxResponse.json()) as JsonRpcResponse;
      const rawTx = createTxData.result as string;

      // Sign transaction
      const signTxResponse = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${Buffer.from(
            `${this.config.rpcUser}:${this.config.rpcPassword}`
          ).toString("base64")}`,
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 3,
          method: "signrawtransactionwithwallet",
          params: [rawTx],
        }),
      });

      if (!signTxResponse.ok) {
        throw new Error("Failed to sign transaction");
      }

      const signTxData = (await signTxResponse.json()) as JsonRpcResponse;
      const signedTx = (signTxData.result as { hex: string }).hex;

      // Send transaction
      const sendTxResponse = await fetch(this.config.rpcUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${Buffer.from(
            `${this.config.rpcUser}:${this.config.rpcPassword}`
          ).toString("base64")}`,
        },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: 4,
          method: "sendrawtransaction",
          params: [signedTx],
        }),
      });

      if (!sendTxResponse.ok) {
        throw new Error("Failed to send transaction");
      }

      const sendTxData = (await sendTxResponse.json()) as JsonRpcResponse;
      return sendTxData.result as string;
    } catch (error) {
      throw new Error(
        `Bitcoin sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  /**
   * Validate Bitcoin address
   */
  isValidAddress(address: string): boolean {
    // Basic validation
    const mainnetPattern =
      /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$|^bc1[a-z0-9]{39,59}$/;
    const testnetPattern =
      /^[mn2][a-km-zA-HJ-NP-Z1-9]{25,34}$|^tb1[a-z0-9]{39,59}$/;

    if (this.config.network === "mainnet") {
      return mainnetPattern.test(address);
    } else {
      return testnetPattern.test(address) || mainnetPattern.test(address);
    }
  }

  /**
   * Bridge tokens from Bitcoin to another chain
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
    return "Bitcoin";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["bitcoin", "btc"];
  }
}

