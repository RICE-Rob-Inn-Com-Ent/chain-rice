import {
  CosmWasmClient,
  SigningCosmWasmClient,
} from "@cosmjs/cosmwasm-stargate";
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";
import { GasPrice } from "@cosmjs/stargate";
import { EVMConnector } from "./evm";

// ============================================================================
// CosmWasm Configuration
// ============================================================================

export interface CosmWasmConfig {
  rpcUrl: string;
  prefix: string;
  gasPrice: string;
}

// ============================================================================
// CosmWasm Connector
// ============================================================================

export class CosmWasmConnector {
  private client?: CosmWasmClient;
  private signingClient?: SigningCosmWasmClient;
  private readonly config: CosmWasmConfig;

  constructor(config: CosmWasmConfig) {
    this.config = config;
  }

  async connect(): Promise<void> {
    this.client = await CosmWasmClient.connect(this.config.rpcUrl);
  }

  async connectWithSigner(mnemonic: string): Promise<void> {
    const wallet = await DirectSecp256k1HdWallet.fromMnemonic(mnemonic, {
      prefix: this.config.prefix,
    });

    this.signingClient = await SigningCosmWasmClient.connectWithSigner(
      this.config.rpcUrl,
      wallet,
      {
        gasPrice: GasPrice.fromString(this.config.gasPrice),
      }
    );
  }

  async queryContract(
    contractAddress: string,
    queryMsg: Record<string, any>
  ): Promise<any> {
    if (!this.client) {
      await this.connect();
    }
    return await this.client!.queryContractSmart(contractAddress, queryMsg);
  }

  async deployContract(
    wasmCode: Uint8Array,
    instantiateMsg: Record<string, any>,
    label: string
  ): Promise<string> {
    if (!this.signingClient) {
      throw new Error(
        "Signing client not initialized. Call connectWithSigner first."
      );
    }

    const [account] = await this.signingClient.getAccounts();
    const uploadResult = await this.signingClient.upload(
      account.address,
      wasmCode,
      "auto"
    );

    const instantiateResult = await this.signingClient.instantiate(
      account.address,
      uploadResult.codeId,
      instantiateMsg,
      label,
      "auto"
    );

    return instantiateResult.contractAddress;
  }

  async executeContract(
    contractAddress: string,
    executeMsg: Record<string, any>
  ): Promise<string> {
    if (!this.signingClient) {
      throw new Error(
        "Signing client not initialized. Call connectWithSigner first."
      );
    }

    const [account] = await this.signingClient.getAccounts();
    const result = await this.signingClient.execute(
      account.address,
      contractAddress,
      executeMsg,
      "auto"
    );

    return result.transactionHash;
  }

  getClient(): CosmWasmClient | undefined {
    return this.client;
  }

  getSigningClient(): SigningCosmWasmClient | undefined {
    return this.signingClient;
  }
}

export const createCosmWasmConnector = (
  rpcUrl: string = process.env.COSMOS_RPC_URL ||
    process.env.COSMWASM_RPC_URL ||
    "http://localhost:26657",
  prefix: string = process.env.COSMOS_PREFIX || "crice",
  gasPrice: string = process.env.COSMOS_GAS_PRICE || "0.025urice"
): CosmWasmConnector => {
  const config: CosmWasmConfig = { rpcUrl, prefix, gasPrice };
  return new CosmWasmConnector(config);
};

// ============================================================================
// CosmWasm to EVM Bridge
// ============================================================================

export interface CosmWasmToEVMBridgeConfig {
  cosmwasmChain: CosmWasmConnector;
  evmChain: EVMConnector;
  burnContractAddress: string;
  unlockContractAddress: string;
}

export class CosmWasmToEVMBridge {
  private readonly config: CosmWasmToEVMBridgeConfig;

  constructor(config: CosmWasmToEVMBridgeConfig) {
    this.config = config;
  }

  async burnTokens(
    amount: string,
    recipientEvmAddress: string
  ): Promise<string> {
    const burnMsg = {
      burn_for_bridge: {
        amount,
        recipient: recipientEvmAddress,
      },
    };

    return await this.config.cosmwasmChain.executeContract(
      this.config.burnContractAddress,
      burnMsg
    );
  }

  async unlockOnEVM(
    proof: string,
    amount: string,
    recipient: string,
    tokenAddress: string
  ): Promise<string> {
    const unlockContractABI = [
      "function unlock(address token, uint256 amount, address recipient, string memory proof) external",
    ];

    return await this.config.evmChain.sendTransaction(
      this.config.unlockContractAddress,
      unlockContractABI,
      "unlock",
      tokenAddress,
      amount,
      recipient,
      proof
    );
  }

  async getBurnedAmount(): Promise<string> {
    const queryMsg = {
      get_burned_amount: {},
    };

    return await this.config.cosmwasmChain.queryContract(
      this.config.burnContractAddress,
      queryMsg
    );
  }
}

