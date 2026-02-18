// Type declarations for external modules and global types
// These are stub declarations to prevent TypeScript errors when modules are not yet installed

/// <reference types="node" />

// ============================================================================
// Global type declarations for Node.js built-ins
// ============================================================================

declare global {
  // fetch is available globally in Node.js 18+
  var fetch: typeof globalThis.fetch;
  
  // Buffer is available globally in Node.js
  var Buffer: typeof import('buffer').Buffer;
  
  // process and console are available globally in Node.js
  var process: NodeJS.Process;
  var console: Console;
}

// ============================================================================
// External module declarations
// ============================================================================

declare module "ethers" {
  export class JsonRpcProvider {
    constructor(url: string);
    getBalance(address: string): Promise<bigint>;
  }
  export class Wallet {
    constructor(privateKey: string, provider: JsonRpcProvider);
  }
  export class Contract {
    constructor(address: string, abi: any[], providerOrSigner: any);
    on(event: string, callback: (...args: any[]) => void): void;
    [key: string]: any; // Allow dynamic method calls from ABI
  }
  export class ContractFactory {
    constructor(abi: any[], bytecode: string, signer: any);
    deploy(...args: any[]): Promise<ContractDeployment>;
  }
  export interface ContractDeployment {
    waitForDeployment(): Promise<Contract>;
    getAddress(): Promise<string>;
  }
  export function formatEther(value: bigint): string;
  export function id(text: string): string;
  export function keccak256(data: Uint8Array): string;
  export function toUtf8Bytes(text: string): Uint8Array;
  export interface Log {
    transactionHash: string;
    blockNumber: number;
  }

  namespace ethers {
    export {
      JsonRpcProvider,
      Wallet,
      Contract,
      ContractFactory,
      formatEther,
      id,
      keccak256,
      toUtf8Bytes,
    };
    export type { Log };
  }
}

declare module "@cosmjs/cosmwasm-stargate" {
  export class CosmWasmClient {
    static connect(rpcUrl: string): Promise<CosmWasmClient>;
    queryContractSmart(
      contractAddress: string,
      queryMsg: Record<string, any>
    ): Promise<any>;
    getAccounts(): Promise<any[]>;
  }
  export class SigningCosmWasmClient {
    static connectWithSigner(
      rpcUrl: string,
      wallet: any,
      options: any
    ): Promise<SigningCosmWasmClient>;
    upload(sender: string, wasmCode: Uint8Array, fee: string): Promise<any>;
    instantiate(
      sender: string,
      codeId: number,
      instantiateMsg: Record<string, any>,
      label: string,
      fee: string
    ): Promise<any>;
    execute(
      sender: string,
      contractAddress: string,
      executeMsg: Record<string, any>,
      fee: string
    ): Promise<any>;
    getAccounts(): Promise<any[]>;
  }
}

declare module "@cosmjs/proto-signing" {
  export class DirectSecp256k1HdWallet {
    static fromMnemonic(
      mnemonic: string,
      options: { prefix: string }
    ): Promise<DirectSecp256k1HdWallet>;
    getAccounts(): Promise<any[]>;
  }
}

declare module "@cosmjs/stargate" {
  export class GasPrice {
    static fromString(gasPrice: string): GasPrice;
  }
}

declare module "node:http" {
  export interface IncomingMessage {
    url?: string;
    method?: string;
  }
  export interface ServerResponse {
    writeHead(statusCode: number, headers?: Record<string, string>): void;
    end(chunk?: string): void;
  }
  export interface Server {
    listen(port: number, hostname: string, callback?: () => void): void;
    close(callback?: () => void): void;
  }
  export function createServer(
    requestListener?: (req: IncomingMessage, res: ServerResponse) => void
  ): Server;
}

declare module "node:fs" {
  export function existsSync(path: string): boolean;
  export function readFileSync(path: string, encoding: "utf8"): string;
  export function writeFileSync(
    path: string,
    data: string,
    options?: { encoding?: string }
  ): void;
}

declare module "snarkjs" {
  export interface Proof {
    pi_a: string[];
    pi_b: string[][];
    pi_c: string[];
    protocol: string;
    curve: string;
  }

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

  export namespace groth16 {
    export function fullProve(
      input: any,
      wasmPath: string,
      zkeyPath: string
    ): Promise<{ proof: Proof; publicSignals: string[] }>;
    export function verify(
      vkey: VerificationKey,
      publicSignals: string[],
      proof: Proof
    ): Promise<boolean>;
  }

  export namespace zKey {
    export function newZKey(
      r1csPath: string,
      wasmPath: string,
      zkeyPath: string
    ): Promise<void>;
    export function exportVerificationKey(
      zkeyPath: string
    ): Promise<VerificationKey>;
  }

  export var version: string | undefined;
}

export {};

