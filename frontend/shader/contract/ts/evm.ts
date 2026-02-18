import { ethers } from "ethers";
import { generateBridgeProof } from "../app/app";
import { CosmWasmConnector, CosmWasmToEVMBridge } from "./cosmwasm";

// ============================================================================
// EVM Chain Configuration
// ============================================================================

export interface EVMChainConfig {
  name: string;
  chainId: number;
  rpcUrl: string;
  explorerUrl?: string;
}

// ============================================================================
// EVM Network Configuration
// ============================================================================

export const NetworkConfig: Record<string, EVMChainConfig> = {
  ethereum: {
    name: "Ethereum Mainnet",
    chainId: Number.parseInt(process.env.ETH_CHAIN_ID || "1", 10),
    rpcUrl: process.env.ETH_RPC_URL || "https://eth.llamarpc.com",
    explorerUrl: process.env.ETH_EXPLORER_URL || "https://etherscan.io",
  },
  polygon: {
    name: "Polygon",
    chainId: Number.parseInt(process.env.POLYGON_CHAIN_ID || "137", 10),
    rpcUrl: process.env.POLYGON_RPC_URL || "https://polygon.llamarpc.com",
    explorerUrl: process.env.POLYGON_EXPLORER_URL || "https://polygonscan.com",
  },
  bsc: {
    name: "BNB Smart Chain",
    chainId: Number.parseInt(process.env.BSC_CHAIN_ID || "56", 10),
    rpcUrl: process.env.BSC_RPC_URL || "https://bsc-dataseed.binance.org",
    explorerUrl: process.env.BSC_EXPLORER_URL || "https://bscscan.com",
  },
  avalanche: {
    name: "Avalanche",
    chainId: Number.parseInt(process.env.AVAX_CHAIN_ID || "43114", 10),
    rpcUrl:
      process.env.AVAX_RPC_URL || "https://api.avax.network/ext/bc/C/rpc",
    explorerUrl: process.env.AVAX_EXPLORER_URL || "https://snowtrace.io",
  },
  arbitrum: {
    name: "Arbitrum One",
    chainId: Number.parseInt(process.env.ARB_CHAIN_ID || "42161", 10),
    rpcUrl: process.env.ARB_RPC_URL || "https://arb1.arbitrum.io/rpc",
    explorerUrl: process.env.ARB_EXPLORER_URL || "https://arbiscan.io",
  },
  optimism: {
    name: "Optimism",
    chainId: Number.parseInt(process.env.OPT_CHAIN_ID || "10", 10),
    rpcUrl: process.env.OPT_RPC_URL || "https://mainnet.optimism.io",
    explorerUrl:
      process.env.OPT_EXPLORER_URL || "https://optimistic.etherscan.io",
  },
  base: {
    name: "Base",
    chainId: Number.parseInt(process.env.BASE_CHAIN_ID || "8453", 10),
    rpcUrl: process.env.BASE_RPC_URL || "https://mainnet.base.org",
    explorerUrl: process.env.BASE_EXPLORER_URL || "https://basescan.org",
  },
  zksync: {
    name: "zkSync Era",
    chainId: Number.parseInt(process.env.ZKSYNC_CHAIN_ID || "324", 10),
    rpcUrl: process.env.ZKSYNC_RPC_URL || "https://mainnet.era.zksync.io",
    explorerUrl:
      process.env.ZKSYNC_EXPLORER_URL || "https://explorer.zksync.io",
  },
  linea: {
    name: "Linea",
    chainId: Number.parseInt(process.env.LINEA_CHAIN_ID || "59144", 10),
    rpcUrl: process.env.LINEA_RPC_URL || "https://rpc.linea.build",
    explorerUrl: process.env.LINEA_EXPLORER_URL || "https://lineascan.build",
  },
  scroll: {
    name: "Scroll",
    chainId: Number.parseInt(process.env.SCROLL_CHAIN_ID || "534352", 10),
    rpcUrl: process.env.SCROLL_RPC_URL || "https://rpc.scroll.io",
    explorerUrl: process.env.SCROLL_EXPLORER_URL || "https://scrollscan.com",
  },
  mantle: {
    name: "Mantle",
    chainId: Number.parseInt(process.env.MANTLE_CHAIN_ID || "5000", 10),
    rpcUrl: process.env.MANTLE_RPC_URL || "https://rpc.mantle.xyz",
    explorerUrl: process.env.MANTLE_EXPLORER_URL || "https://explorer.mantle.xyz",
  },
};

// ============================================================================
// EVM Connector
// ============================================================================

export class EVMConnector {
  private readonly provider: ethers.JsonRpcProvider;
  private readonly signer?: ethers.Wallet;
  private readonly config: EVMChainConfig;

  constructor(config: EVMChainConfig, privateKey?: string) {
    this.config = config;
    this.provider = new ethers.JsonRpcProvider(config.rpcUrl);

    if (privateKey) {
      this.signer = new ethers.Wallet(privateKey, this.provider);
    }
  }

  async getBalance(address: string): Promise<string> {
    const balance = await this.provider.getBalance(address);
    return ethers.formatEther(balance);
  }

  async deployContract(
    abi: any[],
    bytecode: string,
    ...args: any[]
  ): Promise<string> {
    if (!this.signer) {
      throw new Error("Signer not initialized. Provide private key.");
    }

    const factory = new ethers.ContractFactory(abi, bytecode, this.signer);
    const contract = await factory.deploy(...args);
    await contract.waitForDeployment();

    return await contract.getAddress();
  }

  async callContract(
    contractAddress: string,
    abi: any[],
    method: string,
    ...args: any[]
  ): Promise<any> {
    const contract = new ethers.Contract(contractAddress, abi, this.provider);
    return await contract[method](...args);
  }

  async sendTransaction(
    contractAddress: string,
    abi: any[],
    method: string,
    ...args: any[]
  ): Promise<string> {
    if (!this.signer) {
      throw new Error("Signer not initialized. Provide private key.");
    }

    const contract = new ethers.Contract(contractAddress, abi, this.signer);
    const tx = await contract[method](...args);
    const receipt = await tx.wait();
    return receipt.hash;
  }

  getProvider(): ethers.JsonRpcProvider {
    return this.provider;
  }

  getSigner(): ethers.Wallet | undefined {
    return this.signer;
  }

  getConfig(): EVMChainConfig {
    return this.config;
  }
}

/**
 * Create EVM connector for a specific network
 */
export const createEVMConnector = (
  chain: keyof typeof NetworkConfig,
  privateKey?: string
): EVMConnector => {
  const config = NetworkConfig[chain];
  if (!config) {
    throw new Error(`Unknown chain: ${chain}`);
  }
  return new EVMConnector(config, privateKey);
};

// ============================================================================
// EVM to CosmWasm Bridge
// ============================================================================

export interface EVMToCosmWasmBridgeConfig {
  evmChain: EVMConnector;
  cosmwasmChain: CosmWasmConnector;
  lockContractAddress: string;
  mintContractAddress: string;
}

export class EVMToCosmWasmBridge {
  private readonly config: EVMToCosmWasmBridgeConfig;

  constructor(config: EVMToCosmWasmBridgeConfig) {
    this.config = config;
  }

  async lockTokens(
    tokenAddress: string,
    amount: string,
    recipientCosmWasmAddress: string
  ): Promise<string> {
    const lockContractABI = [
      "function lock(address token, uint256 amount, string memory recipient) external",
      "event TokensLocked(address indexed token, uint256 amount, string recipient, uint256 nonce)",
    ];

    const lockContract = new ethers.Contract(
      this.config.lockContractAddress,
      lockContractABI,
      this.config.evmChain.getSigner()
    );

    const tx = await lockContract.lock(
      tokenAddress,
      amount,
      recipientCosmWasmAddress
    );
    const receipt = await tx.wait();

    const event = receipt.logs.find(
      (log: any) =>
        log.topics[0] ===
        ethers.id("TokensLocked(address,uint256,string,uint256)")
    );

    if (!event) {
      throw new Error("TokensLocked event not found");
    }

    return receipt.hash;
  }

  async mintOnCosmWasm(
    proof: string,
    amount: string,
    recipient: string
  ): Promise<string> {
    const mintMsg = {
      mint_from_bridge: {
        proof,
        amount,
        recipient,
      },
    };

    return await this.config.cosmwasmChain.executeContract(
      this.config.mintContractAddress,
      mintMsg
    );
  }

  async getLockedAmount(
    tokenAddress: string,
    recipient: string
  ): Promise<string> {
    const lockContractABI = [
      "function getLockedAmount(address token, string memory recipient) external view returns (uint256)",
    ];

    return await this.config.evmChain.callContract(
      this.config.lockContractAddress,
      lockContractABI,
      "getLockedAmount",
      tokenAddress,
      recipient
    );
  }
}

// ============================================================================
// Bridge Relay
// ============================================================================

export class BridgeRelay {
  private readonly evmToCosmWasm: EVMToCosmWasmBridge;
  private readonly cosmWasmToEVM: CosmWasmToEVMBridge;
  private readonly evmConnector: EVMConnector;
  private readonly cosmWasmConnector: CosmWasmConnector;

  constructor(
    evmConnector: EVMConnector,
    cosmWasmConnector: CosmWasmConnector,
    lockContractAddress: string,
    mintContractAddress: string,
    burnContractAddress: string,
    unlockContractAddress: string
  ) {
    this.evmConnector = evmConnector;
    this.cosmWasmConnector = cosmWasmConnector;

    this.evmToCosmWasm = new EVMToCosmWasmBridge({
      evmChain: evmConnector,
      cosmwasmChain: cosmWasmConnector,
      lockContractAddress,
      mintContractAddress,
    });

    this.cosmWasmToEVM = new CosmWasmToEVMBridge({
      cosmwasmChain: cosmWasmConnector,
      evmChain: evmConnector,
      burnContractAddress,
      unlockContractAddress,
    });
  }

  async monitorEVMEvents(
    lockContractAddress: string,
    callback: (event: any) => Promise<void>
  ): Promise<void> {
    const lockContractABI = [
      "event TokensLocked(address indexed token, uint256 amount, string recipient, uint256 nonce)",
    ];

    const contract = new ethers.Contract(
      lockContractAddress,
      lockContractABI,
      this.evmConnector.getProvider()
    );

    contract.on(
      "TokensLocked",
      async (
        token: string,
        amount: bigint,
        recipient: string,
        nonce: bigint,
        event: ethers.Log
      ) => {
        await callback({
          token,
          amount: amount.toString(),
          recipient,
          nonce: nonce.toString(),
          txHash: event.transactionHash,
          blockNumber: event.blockNumber,
        });
      }
    );
  }

  async relayEVMToCosmWasm(
    tokenAddress: string,
    amount: string,
    recipient: string
  ): Promise<{ lockTx: string; mintTx: string }> {
    const lockTx = await this.evmToCosmWasm.lockTokens(
      tokenAddress,
      amount,
      recipient
    );

    const proof = await this.generateProof(lockTx);
    const mintTx = await this.evmToCosmWasm.mintOnCosmWasm(
      proof,
      amount,
      recipient
    );

    return { lockTx, mintTx };
  }

  async relayCosmWasmToEVM(
    amount: string,
    recipient: string,
    tokenAddress: string
  ): Promise<{ burnTx: string; unlockTx: string }> {
    const burnTx = await this.cosmWasmToEVM.burnTokens(amount, recipient);

    const proof = await this.generateProof(burnTx);
    const unlockTx = await this.cosmWasmToEVM.unlockOnEVM(
      proof,
      amount,
      recipient,
      tokenAddress
    );

    return { burnTx, unlockTx };
  }

  private async generateProof(txHash: string): Promise<string> {
    try {
      const proof = await generateBridgeProof({
        txHash: txHash,
      } as any);
      return proof;
    } catch (error) {
      console.warn("zk-proof generation failed, using hash fallback:", error);
      return ethers.keccak256(ethers.toUtf8Bytes(txHash));
    }
  }
}
