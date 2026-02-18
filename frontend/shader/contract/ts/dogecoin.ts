import { JsonRpcResponse } from "../app/app";

// ============================================================================
// Dogecoin Configuration
// ============================================================================

export interface DogecoinConfig {
  rpcUrl: string;
  rpcUser: string;
  rpcPassword: string;
  network: "mainnet" | "testnet";
}

/**
 * Dogecoin Connector
 */
export class DogecoinConnector {
  private readonly config: DogecoinConfig;

  constructor(config: DogecoinConfig) {
    this.config = config;
  }

  async getBalance(address: string): Promise<string> {
    if (!this.isValidAddress(address)) {
      throw new Error("Invalid Dogecoin address");
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
            // Convert from DOGE to doges (smallest unit, 1 DOGE = 100,000,000 doges)
            return (
              Number.parseFloat(data.result as string) * 100000000
            ).toString();
          }
        }
      }

      // Fallback to public API
      const apiUrl = `https://dogechain.info/api/v1/address/balance/${address}`;
      const response = await fetch(apiUrl);

      if (response.ok) {
        const data = (await response.json()) as { balance?: string };
        // Return balance in doges
        return (Number.parseFloat(data.balance || "0") * 100000000).toString();
      }

      throw new Error("Failed to fetch Dogecoin balance");
    } catch (error) {
      throw new Error(
        `Dogecoin getBalance failed: ${
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
      throw new Error("Invalid Dogecoin address");
    }

    const amountNum = Number.parseInt(amount, 10);
    if (Number.isNaN(amountNum) || amountNum <= 0) {
      throw new Error("Invalid amount");
    }

    try {
      // Similar to Bitcoin/Litecoin - requires RPC with wallet
      if (
        !this.config.rpcUrl ||
        !this.config.rpcUser ||
        !this.config.rpcPassword
      ) {
        throw new Error(
          "Dogecoin RPC credentials required for sending transactions"
        );
      }

      // Get UTXOs
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
        throw new Error("No UTXOs available");
      }

      // Create, sign, and send transaction
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
            { [toAddress]: amountNum / 100000000 },
          ],
        }),
      });

      if (!createTxResponse.ok) {
        throw new Error("Failed to create transaction");
      }

      const createTxData = (await createTxResponse.json()) as JsonRpcResponse;
      const rawTx = createTxData.result as string;

      // Sign and send
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
        `Dogecoin sendTransaction failed: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  isValidAddress(address: string): boolean {
    return this.config.network === "mainnet"
      ? address.startsWith("D")
      : address.startsWith("n") || address.startsWith("m");
  }

  /**
   * Bridge tokens from Dogecoin to another chain
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
    return "Dogecoin";
  }

  /**
   * Get chain aliases for bridge operations
   */
  getChainAliases(): string[] {
    return ["dogecoin", "doge"];
  }
}

