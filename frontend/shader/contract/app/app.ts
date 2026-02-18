// ============================================================================
// Main Application File
// Contains zk-SNARK functions, configuration types, and HTTP server
// ============================================================================

import * as snarkjs from "snarkjs";
import * as fs from "node:fs";
import * as http from "node:http";
import * as path from "node:path";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

// ============================================================================
// Blockchain Connector Imports
// ============================================================================

import { EVMConnector, createEVMConnector, NetworkConfig } from "../ts/evm";
import { BitcoinConnector, BitcoinConfig } from "../ts/bitcoin";
import { SolanaConnector, SolanaConfig } from "../ts/solana";
import { CardanoConnector, CardanoConfig } from "../ts/cardano";
import { PolkadotConnector, PolkadotConfig } from "../ts/polkadot";
import { NearConnector, NearConfig } from "../ts/near";
import { AlgorandConnector, AlgorandConfig } from "../ts/algorand";
import { TezosConnector, TezosConfig } from "../ts/tezos";
import { TronConnector, TronConfig } from "../ts/tron";
import { LitecoinConnector, LitecoinConfig } from "../ts/litecoin";
import { DogecoinConnector, DogecoinConfig } from "../ts/dogecoin";
import { StellarConnector, StellarConfig } from "../ts/stellar";
import { RippleConnector, RippleConfig } from "../ts/ripple";
import { TONConnector, TONConfig } from "../ts/ton";
import { SuiConnector, SuiConfig } from "../ts/sui";
import { AptosConnector, AptosConfig } from "../ts/aptos";
import { ICPConnector, ICPConfig } from "../ts/icp";

// ============================================================================
// zk-SNARK Types
// ============================================================================

/**
 * Interface for circuit input
 */
export interface CircuitInput {
  a: number;
  b: number;
  [key: string]: number | string | boolean;
}

/**
 * Interface for zk-SNARK proof
 */
export interface Proof {
  pi_a: string[];
  pi_b: string[][];
  pi_c: string[];
  protocol: string;
  curve: string;
}

/**
 * Interface for verification key
 */
export interface VerificationKey {
  protocol: string;
  curve: string;
  nPublic: number;
  vk_alpha_1: string[];
  vk_beta_2: string[][];
  vk_gamma_2: string[][];
  vk_delta_2: string[][];
  vk_alphabeta_12: string[][][];
  IC: string[][];
}

// ============================================================================
// API Response Types
// ============================================================================

/**
 * Generic JSON-RPC response interface
 * Used by multiple blockchain connectors
 */
export interface JsonRpcResponse {
  jsonrpc: string;
  id: number;
  result?: any;
  error?: {
    code: number;
    message: string;
  };
}

// ============================================================================
// Circuit Compilation Types
// ============================================================================

export interface CompileCircomResult {
  r1cs: string;
  wasm: string;
  sym?: string;
}

export interface CompileCircomOptions {
  circuitPath: string;
  outputDir: string;
  circuitName: string;
}

export interface CompileGnarkResult {
  wasm: string;
  size: number;
  compilationTime: number;
}

export interface CompileGnarkOptions {
  circuitPath: string;
  outputPath: string;
}

// ============================================================================
// Circuit Compilation Functions
// ============================================================================

/**
 * Compile Circom circuit to R1CS and WASM
 * Generic function - reusable for all projects - no hardcoded paths
 */
export async function compileCircomCircuit(
  options: CompileCircomOptions
): Promise<CompileCircomResult> {
  const { circuitPath, outputDir, circuitName } = options;

  // Validate inputs
  if (!fs.existsSync(circuitPath)) {
    throw new Error(`Circuit file not found: ${circuitPath}`);
  }

  // Create output directory if it doesn't exist
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Create subdirectories
  const r1csDir = path.join(outputDir, "r1cs");
  const wasmDir = path.join(outputDir, "wasm");
  const symDir = path.join(outputDir, "sym");

  [r1csDir, wasmDir, symDir].forEach((dir) => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });

  // Output file paths
  const r1csPath = path.join(r1csDir, `${circuitName}.r1cs`);
  const wasmDirPath = path.join(wasmDir, `${circuitName}_js`);
  const actualWasmPath = path.join(wasmDirPath, `${circuitName}.wasm`);
  const symPath = path.join(symDir, `${circuitName}.sym`);

  try {
    // Check if circom is available
    try {
      await execAsync("circom --version");
    } catch (error) {
      throw new Error(
        "circom CLI not found. Install with: npm install -g circom"
      );
    }

    // Compile circuit
    const command = `circom ${circuitPath} --r1cs --wasm --sym -o ${outputDir}`;

    console.log(`Compiling Circom circuit: ${circuitPath}`);
    console.log(`Command: ${command}`);

    const { stdout, stderr } = await execAsync(command);

    if (stderr && !stderr.includes("warning")) {
      console.warn("Compilation warnings:", stderr);
    }

    console.log("Compilation output:", stdout);

    // Verify output files exist
    if (!fs.existsSync(r1csPath)) {
      throw new Error(`R1CS file not generated: ${r1csPath}`);
    }

    if (!fs.existsSync(actualWasmPath)) {
      throw new Error(`WASM file not generated: ${actualWasmPath}`);
    }

    console.log(`✅ Circuit compiled successfully`);
    console.log(`   R1CS: ${r1csPath}`);
    console.log(`   WASM: ${actualWasmPath}`);

    return {
      r1cs: r1csPath,
      wasm: actualWasmPath,
      sym: fs.existsSync(symPath) ? symPath : undefined,
    };
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown compilation error";
    throw new Error(`Failed to compile Circom circuit: ${message}`);
  }
}

/**
 * Compile Gnark circuit to optimized WASM
 * Generic function - reusable for all projects - no hardcoded paths
 * Target: < 3MB size, < 200ms compilation time
 */
export async function compileGnarkCircuit(
  options: CompileGnarkOptions
): Promise<CompileGnarkResult> {
  const { circuitPath, outputPath } = options;

  // Validate inputs
  if (!fs.existsSync(circuitPath)) {
    throw new Error(`Circuit file not found: ${circuitPath}`);
  }

  // Create output directory if it doesn't exist
  const outputDir = path.dirname(outputPath);
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  try {
    // Check if gnark CLI is available
    try {
      await execAsync("gnark version");
    } catch (error) {
      throw new Error(
        "gnark CLI not found. Install with: go install github.com/consensys/gnark/cmd/gnark@latest"
      );
    }

    // Start timing
    const startTime = Date.now();

    // Compile circuit to WASM with optimizations
    const command = `gnark compile --target wasm --optimize --size ${circuitPath} -o ${outputPath}`;

    console.log(`Compiling Gnark circuit: ${circuitPath}`);
    console.log(`Command: ${command}`);

    const { stdout, stderr } = await execAsync(command);

    const compilationTime = Date.now() - startTime;

    if (stderr && !stderr.includes("warning")) {
      console.warn("Compilation warnings:", stderr);
    }

    console.log("Compilation output:", stdout);

    // Verify output file exists
    if (!fs.existsSync(outputPath)) {
      throw new Error(`WASM file not generated: ${outputPath}`);
    }

    // Get file size
    const stats = fs.statSync(outputPath);
    const size = stats.size;

    // Check size limit (3MB)
    const MAX_SIZE = 3 * 1024 * 1024; // 3MB
    if (size > MAX_SIZE) {
      throw new Error(
        `WASM size ${size} bytes exceeds maximum ${MAX_SIZE} bytes (3MB)`
      );
    }

    // Check compilation time limit (200ms)
    const MAX_TIME = 200; // 200ms
    if (compilationTime > MAX_TIME) {
      console.warn(
        `⚠️  Compilation time ${compilationTime}ms exceeds recommended ${MAX_TIME}ms`
      );
    }

    console.log(`✅ Circuit compiled successfully`);
    console.log(`   WASM: ${outputPath}`);
    console.log(
      `   Size: ${size} bytes (${(size / 1024 / 1024).toFixed(2)}MB)`
    );
    console.log(`   Time: ${compilationTime}ms`);

    return {
      wasm: outputPath,
      size,
      compilationTime,
    };
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown compilation error";
    throw new Error(`Failed to compile Gnark circuit: ${message}`);
  }
}

// ============================================================================
// zk-SNARK Functions
// ============================================================================

/**
 * Test basic snarkjs functionality and check if required files exist
 */
export async function testSnarkjs(): Promise<boolean> {
  console.log("Testing snarkjs functionality...");

  try {
    // Test basic functionality
    console.log("snarkjs version:", (snarkjs as any).version || "unknown");
    console.log("Available methods:", Object.keys(snarkjs));

    // Test if we can read the R1CS file
    if (fs.existsSync("./mycircuit.r1cs")) {
      console.log("✅ R1CS file exists");
    } else {
      console.log("❌ R1CS file not found");
    }

    if (fs.existsSync("./mycircuit_js/mycircuit.wasm")) {
      console.log("✅ WASM file exists");
    } else {
      console.log("❌ WASM file not found");
    }

    console.log("Basic snarkjs test completed successfully!");
    return true;
  } catch (error) {
    const err = error as Error;
    console.error("Error:", err.message);
    return false;
  }
}

/**
 * Run trusted setup to generate proving key and verification key
 *
 * @param r1csPath - Path to R1CS file
 * @param wasmPath - Path to WASM file
 * @param outputDir - Output directory for keys
 * @param circuitName - Name of the circuit (for output files)
 * @returns Paths to generated proving key and verification key
 */
export async function runSetup(
  r1csPath: string,
  wasmPath: string,
  outputDir: string,
  circuitName: string
): Promise<{ provingKey: string; verificationKey: string }> {
  console.log(`Starting trusted setup for ${circuitName}...`);

  // Validate input files
  if (!fs.existsSync(r1csPath)) {
    throw new Error(`R1CS file not found: ${r1csPath}`);
  }
  if (!fs.existsSync(wasmPath)) {
    throw new Error(`WASM file not found: ${wasmPath}`);
  }

  // Create output directory if it doesn't exist
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Create keys subdirectory
  const keysDir = path.join(outputDir, "keys");
  if (!fs.existsSync(keysDir)) {
    fs.mkdirSync(keysDir, { recursive: true });
  }

  // Output file paths
  const provingKeyPath = path.join(keysDir, `${circuitName}_pk.zkey`);
  const verificationKeyPath = path.join(keysDir, `${circuitName}_vk.json`);

  try {
    // Generate proving key and verification key
    console.log(`Generating proving key: ${provingKeyPath}`);
    await snarkjs.zKey.newZKey(r1csPath, wasmPath, provingKeyPath);

    console.log(`Exporting verification key: ${verificationKeyPath}`);
    const vkey = await snarkjs.zKey.exportVerificationKey(provingKeyPath);
    fs.writeFileSync(verificationKeyPath, JSON.stringify(vkey, null, 2));

    console.log("✅ Setup completed successfully!");
    console.log(`   Proving key: ${provingKeyPath}`);
    console.log(`   Verification key: ${verificationKeyPath}`);

    return {
      provingKey: provingKeyPath,
      verificationKey: verificationKeyPath,
    };
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown setup error";
    throw new Error(`Failed to run trusted setup: ${message}`);
  }
}

/**
 * Generate a zk-SNARK proof
 */
export async function generateProof(
  input?: CircuitInput
): Promise<{ proof: Proof; publicSignals: string[] }> {
  const circuitInput: CircuitInput = input ?? { a: 3, b: 4 };
  console.log("Generating proof...");

  // Generate proof
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    circuitInput,
    "./mycircuit_js/mycircuit.wasm",
    "./mycircuit_pk.zkey"
  );

  console.log("Proof generated successfully!");
  console.log("Proof:", JSON.stringify(proof, null, 2));
  console.log("Public signals:", publicSignals);

  return { proof: proof as Proof, publicSignals: publicSignals as string[] };
}

/**
 * Verify a zk-SNARK proof
 */
export async function verifyProof(
  proof: Proof,
  publicSignals: string[]
): Promise<boolean> {
  console.log("Verifying proof...");

  const vkey: VerificationKey = JSON.parse(
    fs.readFileSync("./mycircuit_vk.json", "utf8")
  );
  const res = await snarkjs.groth16.verify(vkey, publicSignals, proof);

  if (res === true) {
    console.log("✅ Proof is valid!");
  } else {
    console.log("❌ Proof is invalid!");
  }

  return res;
}

/**
 * Serialize proof to JSON string for bridge transmission
 * Used when sending proof from EVM to CosmWasm
 */
export function serializeProof(proof: Proof, publicSignals: string[]): string {
  return JSON.stringify({
    proof,
    publicSignals,
  });
}

/**
 * Deserialize proof from JSON string
 * Used when receiving proof in CosmWasm contracts
 */
export function deserializeProof(proofString: string): {
  proof: Proof;
  publicSignals: string[];
} {
  const parsed = JSON.parse(proofString);
  return {
    proof: parsed.proof as Proof,
    publicSignals: parsed.publicSignals as string[],
  };
}

/**
 * Generate proof for bridge operations
 * Creates proof for cross-chain token transfers
 */
export async function generateBridgeProof(
  input: CircuitInput,
  circuitPath: string = "./mycircuit_js/mycircuit.wasm",
  provingKeyPath: string = "./mycircuit_pk.zkey"
): Promise<string> {
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    input,
    circuitPath,
    provingKeyPath
  );

  return serializeProof(proof as Proof, publicSignals as string[]);
}

/**
 * Verify proof from bridge (deserialized)
 */
export async function verifyBridgeProof(
  proofString: string,
  verificationKeyPath: string = "./mycircuit_vk.json"
): Promise<boolean> {
  const { proof, publicSignals } = deserializeProof(proofString);
  const vkey: VerificationKey = JSON.parse(
    fs.readFileSync(verificationKeyPath, "utf8")
  );

  return await snarkjs.groth16.verify(vkey, publicSignals, proof);
}

/**
 * Main function - runs full workflow: test -> setup -> generate proof -> verify
 * Note: This is a legacy function. Use API endpoints for production.
 */
export async function main(): Promise<void> {
  try {
    // Test snarkjs first
    await testSnarkjs();
    console.log("\n");

    // Note: runSetup() now requires parameters
    // This function is kept for backward compatibility but may not work
    // without proper circuit files. Use API endpoints instead.
    console.log("Note: Use API endpoints for circuit compilation and setup");
  } catch (error) {
    console.error("Error:", error);
    if (typeof process !== "undefined") {
      process.exit(1);
    }
    throw error;
  }
}

// ============================================================================
// Multi-Chain Bridge
// ============================================================================

/**
 * Multi-Chain Bridge
 * Coordinates cross-chain token transfers across multiple blockchain networks
 */
export class MultiChainBridge {
  private readonly evmConnectors: Map<string, EVMConnector> = new Map();
  private bitcoinConnector?: BitcoinConnector;
  private solanaConnector?: SolanaConnector;
  private cardanoConnector?: CardanoConnector;
  private polkadotConnector?: PolkadotConnector;
  private nearConnector?: NearConnector;
  private algorandConnector?: AlgorandConnector;
  private tezosConnector?: TezosConnector;
  private tronConnector?: TronConnector;
  private litecoinConnector?: LitecoinConnector;
  private dogecoinConnector?: DogecoinConnector;
  private stellarConnector?: StellarConnector;
  private rippleConnector?: RippleConnector;
  private tonConnector?: TONConnector;
  private suiConnector?: SuiConnector;
  private aptosConnector?: AptosConnector;
  private icpConnector?: ICPConnector;

  addEVMChain(chain: keyof typeof NetworkConfig, privateKey?: string): void {
    const connector = createEVMConnector(chain, privateKey);
    this.evmConnectors.set(chain, connector);
  }

  addBitcoin(config: BitcoinConfig): void {
    this.bitcoinConnector = new BitcoinConnector(config);
  }

  addSolana(config: SolanaConfig): void {
    this.solanaConnector = new SolanaConnector(config);
  }

  addCardano(config: CardanoConfig): void {
    this.cardanoConnector = new CardanoConnector(config);
  }

  addPolkadot(config: PolkadotConfig): void {
    this.polkadotConnector = new PolkadotConnector(config);
  }

  addNear(config: NearConfig): void {
    this.nearConnector = new NearConnector(config);
  }

  addAlgorand(config: AlgorandConfig): void {
    this.algorandConnector = new AlgorandConnector(config);
  }

  addTezos(config: TezosConfig): void {
    this.tezosConnector = new TezosConnector(config);
  }

  addTron(config: TronConfig): void {
    this.tronConnector = new TronConnector(config);
  }

  addLitecoin(config: LitecoinConfig): void {
    this.litecoinConnector = new LitecoinConnector(config);
  }

  addDogecoin(config: DogecoinConfig): void {
    this.dogecoinConnector = new DogecoinConnector(config);
  }

  addStellar(config: StellarConfig): void {
    this.stellarConnector = new StellarConnector(config);
  }

  addRipple(config: RippleConfig): void {
    this.rippleConnector = new RippleConnector(config);
  }

  addTON(config: TONConfig): void {
    this.tonConnector = new TONConnector(config);
  }

  addSui(config: SuiConfig): void {
    this.suiConnector = new SuiConnector(config);
  }

  addAptos(config: AptosConfig): void {
    this.aptosConnector = new AptosConnector(config);
  }

  addICP(config: ICPConfig): void {
    this.icpConnector = new ICPConnector(config);
  }

  getEVMConnector(chain: string): EVMConnector | undefined {
    return this.evmConnectors.get(chain);
  }

  getBitcoinConnector(): BitcoinConnector | undefined {
    return this.bitcoinConnector;
  }

  getSolanaConnector(): SolanaConnector | undefined {
    return this.solanaConnector;
  }

  getCardanoConnector(): CardanoConnector | undefined {
    return this.cardanoConnector;
  }

  getPolkadotConnector(): PolkadotConnector | undefined {
    return this.polkadotConnector;
  }

  getNearConnector(): NearConnector | undefined {
    return this.nearConnector;
  }

  getAlgorandConnector(): AlgorandConnector | undefined {
    return this.algorandConnector;
  }

  getTezosConnector(): TezosConnector | undefined {
    return this.tezosConnector;
  }

  getTronConnector(): TronConnector | undefined {
    return this.tronConnector;
  }

  getLitecoinConnector(): LitecoinConnector | undefined {
    return this.litecoinConnector;
  }

  getDogecoinConnector(): DogecoinConnector | undefined {
    return this.dogecoinConnector;
  }

  getStellarConnector(): StellarConnector | undefined {
    return this.stellarConnector;
  }

  getRippleConnector(): RippleConnector | undefined {
    return this.rippleConnector;
  }

  getTONConnector(): TONConnector | undefined {
    return this.tonConnector;
  }

  getSuiConnector(): SuiConnector | undefined {
    return this.suiConnector;
  }

  getAptosConnector(): AptosConnector | undefined {
    return this.aptosConnector;
  }

  getICPConnector(): ICPConnector | undefined {
    return this.icpConnector;
  }

  async bridgeTokens(
    sourceChain: string,
    destinationChain: string,
    sourceAddress: string,
    destinationAddress: string,
    amount: string,
    tokenAddress?: string
  ): Promise<{ sourceTx: string; destinationTx?: string }> {
    if (this.evmConnectors.has(sourceChain)) {
      throw new Error(
        "EVM bridge operations should use EVMToCosmWasmBridge or CosmWasmToEVMBridge"
      );
    }

    const connector = this.getConnectorByChainInternal(sourceChain);
    if (!connector) {
      throw new Error(`Unsupported source chain: ${sourceChain}`);
    }

    return await connector.bridgeTokens(
      sourceAddress,
      destinationAddress,
      amount
    );
  }

  /**
   * Unified method to get connector by chain name
   * Returns connector with unified interface for easy use in projects
   */
  getConnectorByChain(chain: string): {
    getBalance(address: string): Promise<string>;
    sendTransaction(from: string, to: string, amount: string): Promise<string>;
    getChainAliases(): string[];
    bridgeTokens?(
      sourceAddress: string,
      destinationAddress: string,
      amount: string
    ): Promise<{ sourceTx: string; destinationTx?: string }>;
  } | null {
    const chainLower = chain.toLowerCase();

    // Check EVM chains first
    const evmConnector = this.evmConnectors.get(chainLower);
    if (evmConnector) {
      return {
        getBalance: (address: string) => evmConnector.getBalance(address),
        sendTransaction: async () => {
          throw new Error(
            "EVM sendTransaction requires contract address and ABI. Use EVMConnector directly."
          );
        },
        getChainAliases: () => [chainLower],
      };
    }

    // Check non-EVM connectors
    const connector = this.getConnectorByChainInternal(chainLower);
    if (!connector) {
      return null;
    }

    const result: {
      getBalance: (address: string) => Promise<string>;
      sendTransaction: (
        from: string,
        to: string,
        amount: string
      ) => Promise<string>;
      getChainAliases: () => string[];
      bridgeTokens?: (
        sourceAddress: string,
        destinationAddress: string,
        amount: string
      ) => Promise<{ sourceTx: string; destinationTx?: string }>;
    } = {
      getBalance: (address: string) => connector.getBalance(address),
      sendTransaction: (from: string, to: string, amount: string) =>
        connector.sendTransaction(from, to, amount),
      getChainAliases: () => connector.getChainAliases(),
    };

    if (connector.bridgeTokens) {
      result.bridgeTokens = (
        sourceAddress: string,
        destinationAddress: string,
        amount: string
      ) => connector.bridgeTokens(sourceAddress, destinationAddress, amount);
    }

    return result;
  }

  private getConnectorByChainInternal(
    chain: string
  ):
    | BitcoinConnector
    | SolanaConnector
    | CardanoConnector
    | PolkadotConnector
    | NearConnector
    | AlgorandConnector
    | TezosConnector
    | TronConnector
    | LitecoinConnector
    | DogecoinConnector
    | StellarConnector
    | RippleConnector
    | TONConnector
    | SuiConnector
    | AptosConnector
    | ICPConnector
    | null {
    const chainLower = chain.toLowerCase();

    // Check each connector's aliases using optional chaining
    const connectors = [
      this.bitcoinConnector,
      this.solanaConnector,
      this.cardanoConnector,
      this.polkadotConnector,
      this.nearConnector,
      this.algorandConnector,
      this.tezosConnector,
      this.tronConnector,
      this.litecoinConnector,
      this.dogecoinConnector,
      this.stellarConnector,
      this.rippleConnector,
      this.tonConnector,
      this.suiConnector,
      this.aptosConnector,
      this.icpConnector,
    ];

    for (const connector of connectors) {
      if (connector?.getChainAliases().includes(chainLower)) {
        return connector;
      }
    }

    return null;
  }
}

// ============================================================================
// HTTP Server for Network Connections
// ============================================================================

const PORT = Number.parseInt(process.env.PORT || "8080", 10);

// Global bridge instance for API
let globalBridge: MultiChainBridge | null = null;

/**
 * Initialize global bridge instance
 */
export function initializeBridge(): MultiChainBridge {
  if (!globalBridge) {
    globalBridge = new MultiChainBridge();
  }
  return globalBridge;
}

/**
 * Get global bridge instance
 */
export function getBridge(): MultiChainBridge | null {
  return globalBridge;
}

/**
 * Helper function to easily get balance from any chain
 * Usage in projects: import { getBalance } from "@rice-mono/contract/app/app"
 */
export async function getBalance(
  chain: string,
  address: string
): Promise<string> {
  const bridge = getBridge() || initializeBridge();
  const connector = bridge.getConnectorByChain(chain);
  if (!connector) {
    throw new Error(`Chain ${chain} not configured. Call addChain first.`);
  }
  return await connector.getBalance(address);
}

/**
 * Helper function to easily send transaction on any chain
 * Usage in projects: import { sendTransaction } from "@rice-mono/contract/app/app"
 */
export async function sendTransaction(
  chain: string,
  from: string,
  to: string,
  amount: string
): Promise<string> {
  const bridge = getBridge() || initializeBridge();
  const connector = bridge.getConnectorByChain(chain);
  if (!connector) {
    throw new Error(`Chain ${chain} not configured. Call addChain first.`);
  }
  return await connector.sendTransaction(from, to, amount);
}

/**
 * Helper function to easily bridge tokens between chains
 * Usage in projects: import { bridgeTokens } from "@rice-mono/contract/app/app"
 */
export async function bridgeTokens(
  sourceChain: string,
  destinationChain: string,
  sourceAddress: string,
  destinationAddress: string,
  amount: string,
  tokenAddress?: string
): Promise<{ sourceTx: string; destinationTx?: string }> {
  const bridge = getBridge() || initializeBridge();
  return await bridge.bridgeTokens(
    sourceChain,
    destinationChain,
    sourceAddress,
    destinationAddress,
    amount,
    tokenAddress
  );
}

/**
 * Chain configuration mapping for simplified chain addition
 */
const CHAIN_CONFIG_MAP: Record<
  string,
  (bridge: MultiChainBridge, config?: any, privateKey?: string) => void
> = {
  // EVM chains
  ethereum: (b, _, pk) => b.addEVMChain("ethereum", pk),
  polygon: (b, _, pk) => b.addEVMChain("polygon", pk),
  bsc: (b, _, pk) => b.addEVMChain("bsc", pk),
  avalanche: (b, _, pk) => b.addEVMChain("avalanche", pk),
  arbitrum: (b, _, pk) => b.addEVMChain("arbitrum", pk),
  optimism: (b, _, pk) => b.addEVMChain("optimism", pk),
  base: (b, _, pk) => b.addEVMChain("base", pk),
  zksync: (b, _, pk) => b.addEVMChain("zksync", pk),
  linea: (b, _, pk) => b.addEVMChain("linea", pk),
  scroll: (b, _, pk) => b.addEVMChain("scroll", pk),
  mantle: (b, _, pk) => b.addEVMChain("mantle", pk),
  // Non-EVM chains
  bitcoin: (b, c) => b.addBitcoin(c),
  btc: (b, c) => b.addBitcoin(c),
  solana: (b, c) => b.addSolana(c),
  sol: (b, c) => b.addSolana(c),
  cardano: (b, c) => b.addCardano(c),
  ada: (b, c) => b.addCardano(c),
  polkadot: (b, c) => b.addPolkadot(c),
  dot: (b, c) => b.addPolkadot(c),
  near: (b, c) => b.addNear(c),
  algorand: (b, c) => b.addAlgorand(c),
  algo: (b, c) => b.addAlgorand(c),
  tezos: (b, c) => b.addTezos(c),
  xtz: (b, c) => b.addTezos(c),
  tron: (b, c) => b.addTron(c),
  trx: (b, c) => b.addTron(c),
  litecoin: (b, c) => b.addLitecoin(c),
  ltc: (b, c) => b.addLitecoin(c),
  dogecoin: (b, c) => b.addDogecoin(c),
  doge: (b, c) => b.addDogecoin(c),
  stellar: (b, c) => b.addStellar(c),
  xlm: (b, c) => b.addStellar(c),
  ripple: (b, c) => b.addRipple(c),
  xrp: (b, c) => b.addRipple(c),
  ton: (b, c) => b.addTON(c),
  "the-open-network": (b, c) => b.addTON(c),
  sui: (b, c) => b.addSui(c),
  aptos: (b, c) => b.addAptos(c),
  apt: (b, c) => b.addAptos(c),
  icp: (b, c) => b.addICP(c),
  "internet-computer": (b, c) => b.addICP(c),
};

/**
 * Helper function to add a chain to the bridge
 * Usage in projects: import { addChain } from "@rice-mono/contract/app/app"
 */
export function addChain(
  chain: string,
  config?: any,
  privateKey?: string
): void {
  const bridge = getBridge() || initializeBridge();
  const chainLower = chain.toLowerCase();

  const chainHandler = CHAIN_CONFIG_MAP[chainLower];
  if (!chainHandler) {
    throw new Error(`Unsupported chain: ${chain}`);
  }

  chainHandler(bridge, config, privateKey);
}

/**
 * Parse request body
 */
async function parseBody(req: http.IncomingMessage): Promise<any> {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk.toString();
    });
    req.on("end", () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (error: unknown) {
        const message =
          error instanceof Error ? error.message : "Invalid JSON";
        reject(new Error(message));
      }
    });
    req.on("error", reject);
  });
}

/**
 * Send JSON response
 */
function sendJson(res: http.ServerResponse, status: number, data: any): void {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(data));
}

/**
 * Set CORS headers
 */
function setCorsHeaders(res: http.ServerResponse): void {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, DELETE, OPTIONS"
  );
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
}

/**
 * Handle add chain endpoint
 */
async function handleAddChain(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { chain, config, privateKey } = body;

  if (!chain) {
    sendJson(res, 400, { error: "Chain is required" });
    return;
  }

  try {
    addChain(chain, config, privateKey);
    sendJson(res, 200, {
      success: true,
      message: `Chain ${chain} added successfully`,
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to add chain";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle get balance endpoint
 */
async function handleGetBalance(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { chain, address } = body;

  if (!chain || !address) {
    sendJson(res, 400, { error: "Chain and address are required" });
    return;
  }

  try {
    const balance = await getBalance(chain, address);
    sendJson(res, 200, { chain, address, balance });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to get balance";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle send transaction endpoint
 */
async function handleSendTransaction(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { chain, from, to, amount } = body;

  if (!chain || !from || !to || !amount) {
    sendJson(res, 400, {
      error: "Chain, from, to, and amount are required",
    });
    return;
  }

  try {
    const txHash = await sendTransaction(chain, from, to, amount);
    sendJson(res, 200, { chain, txHash, from, to, amount });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to send transaction";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle bridge tokens endpoint
 */
async function handleBridgeTokens(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const {
    sourceChain,
    destinationChain,
    sourceAddress,
    destinationAddress,
    amount,
    tokenAddress,
  } = body;

  if (
    !sourceChain ||
    !destinationChain ||
    !sourceAddress ||
    !destinationAddress ||
    !amount
  ) {
    sendJson(res, 400, {
      error: "All bridge parameters are required",
    });
    return;
  }

  try {
    const result = await bridgeTokens(
      sourceChain,
      destinationChain,
      sourceAddress,
      destinationAddress,
      amount,
      tokenAddress
    );
    sendJson(res, 200, { success: true, ...result });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to bridge tokens";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle ZK proof generation endpoint
 */
async function handleGenerateProof(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { input } = body;

  if (!input) {
    sendJson(res, 400, { error: "Input is required" });
    return;
  }

  try {
    const proofString = await generateBridgeProof(input);
    sendJson(res, 200, { success: true, proof: proofString });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to generate proof";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle ZK proof verification endpoint
 */
async function handleVerifyProof(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { proof } = body;

  if (!proof) {
    sendJson(res, 400, { error: "Proof is required" });
    return;
  }

  try {
    const isValid = await verifyBridgeProof(proof);
    sendJson(res, 200, { success: true, valid: isValid });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to verify proof";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle Circom circuit compilation endpoint
 */
async function handleCompileCircom(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { circuitPath, outputDir, circuitName } = body;

  if (!circuitPath || !outputDir || !circuitName) {
    sendJson(res, 400, {
      error: "circuitPath, outputDir, and circuitName are required",
    });
    return;
  }

  try {
    const result = await compileCircomCircuit({
      circuitPath,
      outputDir,
      circuitName,
    });
    sendJson(res, 200, { success: true, ...result });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to compile circuit";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle Gnark circuit compilation endpoint
 */
async function handleCompileGnark(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { circuitPath, outputPath } = body;

  if (!circuitPath || !outputPath) {
    sendJson(res, 400, {
      error: "circuitPath and outputPath are required",
    });
    return;
  }

  try {
    const result = await compileGnarkCircuit({
      circuitPath,
      outputPath,
    });
    sendJson(res, 200, { success: true, ...result });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to compile circuit";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Handle trusted setup endpoint
 */
async function handleSetup(
  req: http.IncomingMessage,
  res: http.ServerResponse
): Promise<void> {
  const body = await parseBody(req);
  const { r1csPath, wasmPath, outputDir, circuitName } = body;

  if (!r1csPath || !wasmPath || !outputDir || !circuitName) {
    sendJson(res, 400, {
      error: "r1csPath, wasmPath, outputDir, and circuitName are required",
    });
    return;
  }

  try {
    const result = await runSetup(r1csPath, wasmPath, outputDir, circuitName);
    sendJson(res, 200, { success: true, ...result });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Failed to run setup";
    sendJson(res, 500, { error: message });
  }
}

/**
 * Route API requests to appropriate handlers
 */
async function handleApiRequest(
  req: http.IncomingMessage,
  res: http.ServerResponse,
  url: URL
): Promise<void> {
  // Initialize bridge if not exists
  if (!globalBridge) {
    globalBridge = initializeBridge();
  }

  const pathname = url.pathname;
  const method = req.method;

  // Route to appropriate handler
  if (pathname === "/api/bridge/add-chain" && method === "POST") {
    await handleAddChain(req, res);
    return;
  }

  if (pathname === "/api/bridge/balance" && method === "POST") {
    await handleGetBalance(req, res);
    return;
  }

  if (pathname === "/api/bridge/send" && method === "POST") {
    await handleSendTransaction(req, res);
    return;
  }

  if (pathname === "/api/bridge/bridge" && method === "POST") {
    await handleBridgeTokens(req, res);
    return;
  }

  if (pathname === "/api/zk/generate" && method === "POST") {
    await handleGenerateProof(req, res);
    return;
  }

  if (pathname === "/api/zk/verify" && method === "POST") {
    await handleVerifyProof(req, res);
    return;
  }

  if (pathname === "/api/zk/circuit/compile-circom" && method === "POST") {
    await handleCompileCircom(req, res);
    return;
  }

  if (pathname === "/api/zk/circuit/compile-gnark" && method === "POST") {
    await handleCompileGnark(req, res);
    return;
  }

  if (pathname === "/api/zk/circuit/setup" && method === "POST") {
    await handleSetup(req, res);
    return;
  }

  sendJson(res, 404, { error: "Endpoint not found" });
}

const server = http.createServer(
  async (req: http.IncomingMessage, res: http.ServerResponse) => {
    setCorsHeaders(res);

    if (req.method === "OPTIONS") {
      res.writeHead(200);
      res.end();
      return;
    }

    const url = new URL(req.url || "/", `http://${req.headers.host}`);

    // Health check
    if (url.pathname === "/health" && req.method === "GET") {
      sendJson(res, 200, { status: "ok", service: "contract-bridges" });
      return;
    }

    // Root endpoint
    if (url.pathname === "/" && req.method === "GET") {
      sendJson(res, 200, {
        service: "contract-bridges",
        status: "running",
        version: "1.0.0",
        endpoints: {
          health: "/health",
          bridge: {
            addChain: "POST /api/bridge/add-chain",
            getBalance: "POST /api/bridge/balance",
            sendTransaction: "POST /api/bridge/send",
            bridgeTokens: "POST /api/bridge/bridge",
          },
          zkProof: {
            generate: "POST /api/zk/generate",
            verify: "POST /api/zk/verify",
            compileCircom: "POST /api/zk/circuit/compile-circom",
            compileGnark: "POST /api/zk/circuit/compile-gnark",
            setup: "POST /api/zk/circuit/setup",
          },
        },
      });
      return;
    }

    // API endpoints
    if (url.pathname.startsWith("/api/")) {
      try {
        await handleApiRequest(req, res, url);
      } catch (error: unknown) {
        const message =
          error instanceof Error ? error.message : "Internal server error";
        sendJson(res, 500, { error: message });
      }
      return;
    }

    sendJson(res, 404, { error: "Not found" });
  }
);

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully...");
  server.close(() => {
    console.log("Server closed");
    process.exit(0);
  });
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down gracefully...");
  server.close(() => {
    console.log("Server closed");
    process.exit(0);
  });
});

// ============================================================================
// Re-exports - All blockchain connectors and types
// ============================================================================
export * from "../ts/evm";
export * from "../ts/bitcoin";
export * from "../ts/solana";
export * from "../ts/cardano";
export * from "../ts/polkadot";
export * from "../ts/near";
export * from "../ts/algorand";
export * from "../ts/tezos";
export * from "../ts/tron";
export * from "../ts/litecoin";
export * from "../ts/dogecoin";
export * from "../ts/stellar";
export * from "../ts/ripple";
export * from "../ts/ton";
export * from "../ts/sui";
export * from "../ts/aptos";
export * from "../ts/icp";
export * from "../ts/cosmwasm";

// Start server and run zk-SNARK main if this file is run directly
if (typeof require !== "undefined" && require.main === module) {
  // Start HTTP server
  server.listen(PORT, "0.0.0.0", () => {
    console.log(`✅ Contract Bridges service listening on port ${PORT}`);
  });

  // Run zk-SNARK main (for testing)
  // Top-level await is not available in CommonJS modules (module: "commonjs" in tsconfig.json)
  // SonarLint rule S7785 disabled: top-level await requires ES modules, but we use CommonJS
  // eslint-disable-next-line sonarjs/prefer-top-level-await
  main().catch((error) => {
    console.error("Fatal error:", error);
    if (typeof process !== "undefined") {
      process.exit(1);
    }
  });
}
