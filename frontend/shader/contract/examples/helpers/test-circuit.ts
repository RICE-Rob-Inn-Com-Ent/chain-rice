import * as fs from "node:fs";
import * as path from "node:path";
import { type CircuitInput, type Proof } from "../../app/app";
import * as snarkjs from "snarkjs";

export interface TestProofOptions {
  wasmPath: string;
  provingKeyPath: string;
  input: CircuitInput;
  circuitType: "gnark" | "circom";
}

export interface TestProofResult {
  proof: Proof | string;
  publicSignals: string[];
  generationTime: number;
  proofSize: number;
}

export interface VerifyProofOptions {
  proof: Proof | string;
  publicSignals: string[];
  verificationKeyPath: string;
  circuitType: "gnark" | "circom";
}

export async function generateTestProof(options: TestProofOptions): Promise<TestProofResult> {
  const startTime = Date.now();
  if (!fs.existsSync(options.wasmPath)) {
    throw new Error(`WASM file not found: ${options.wasmPath}`);
  }
  if (!fs.existsSync(options.provingKeyPath)) {
    throw new Error(`Proving key not found: ${options.provingKeyPath}`);
  }
  try {
    if (options.circuitType === "circom") {
      const { proof, publicSignals } = await snarkjs.groth16.fullProve(options.input, options.wasmPath, options.provingKeyPath);
      const generationTime = Date.now() - startTime;
      const proofString = JSON.stringify({ proof, publicSignals });
      const proofSize = Buffer.from(proofString).length;
      return { proof: proof as Proof, publicSignals: publicSignals as string[], generationTime, proofSize };
    } else {
      throw new Error("Gnark proof generation requires manual implementation");
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown proof generation error";
    throw new Error(`Proof generation failed: ${message}`);
  }
}

export async function verifyTestProof(options: VerifyProofOptions): Promise<boolean> {
  try {
    if (options.circuitType === "circom") {
      const vkeyContent = fs.readFileSync(options.verificationKeyPath, "utf8");
      const vkey = JSON.parse(vkeyContent);
      let proof: Proof;
      if (typeof options.proof === "string") {
        const parsed = JSON.parse(options.proof);
        proof = parsed.proof as Proof;
      } else {
        proof = options.proof;
      }
      return await snarkjs.groth16.verify(vkey, options.publicSignals, proof);
    } else {
      throw new Error("Gnark proof verification requires manual implementation");
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown verification error";
    throw new Error(`Proof verification failed: ${message}`);
  }
}

export function createTestInputTemplate(circuitType: "gnark" | "circom"): CircuitInput {
  if (circuitType === "circom") {
    return {
      tokenAddress: "1234567890123456789012345678901234567890",
      amount: "1000000000000000000",
      recipient: "9876543210987654321098765432109876543210",
      lockTxHash: "1234567890123456789012345678901234567890123456789012345678901234",
      merkleRoot: "9876543210987654321098765432109876543210987654321098765432109876",
      merklePathElements: Array(32).fill("0"),
      merklePathIndices: Array(32).fill(0),
    };
  } else {
    return {
      TokenAddress: "1234567890123456789012345678901234567890",
      Amount: "1000000000000000000",
      Recipient: "9876543210987654321098765432109876543210",
      LockTxHash: "1234567890123456789012345678901234567890123456789012345678901234",
      MerkleProof: Array(32).fill("0"),
      MerkleRoot: "9876543210987654321098765432109876543210987654321098765432109876",
    };
  }
}
