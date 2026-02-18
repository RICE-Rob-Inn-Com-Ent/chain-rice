import * as fs from "node:fs";
import * as path from "node:path";
import { runSetup, type VerificationKey } from "../../app/app";
import * as snarkjs from "snarkjs";

export interface TrustedSetupOptions {
  r1csPath: string;
  wasmPath: string;
  outputDir: string;
  circuitName: string;
  circuitType: "gnark" | "circom";
}

export interface TrustedSetupResult {
  provingKey: string;
  verificationKey: string;
  circuitType: "gnark" | "circom";
  setupTime: number;
}

export interface KeyValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

export async function runTrustedSetup(options: TrustedSetupOptions): Promise<TrustedSetupResult> {
  const startTime = Date.now();
  if (!fs.existsSync(options.r1csPath)) {
    throw new Error(`R1CS file not found: ${options.r1csPath}`);
  }
  if (!fs.existsSync(options.wasmPath)) {
    throw new Error(`WASM file not found: ${options.wasmPath}`);
  }
  if (!fs.existsSync(options.outputDir)) {
    fs.mkdirSync(options.outputDir, { recursive: true });
  }
  if (options.circuitType === "circom") {
    return await runCircomSetup(options, startTime);
  } else {
    throw new Error("Gnark setup requires manual implementation");
  }
}

async function runCircomSetup(options: TrustedSetupOptions, startTime: number): Promise<TrustedSetupResult> {
  const keysDir = path.join(options.outputDir, "keys");
  if (!fs.existsSync(keysDir)) {
    fs.mkdirSync(keysDir, { recursive: true });
  }
  const provingKeyPath = path.join(keysDir, `${options.circuitName}_pk.zkey`);
  const verificationKeyPath = path.join(keysDir, `${options.circuitName}_vk.json`);
  try {
    console.log(`Generating proving key for ${options.circuitName}...`);
    await snarkjs.zKey.newZKey(options.r1csPath, options.wasmPath, provingKeyPath);
    console.log(`Exporting verification key...`);
    const vkey = await snarkjs.zKey.exportVerificationKey(provingKeyPath);
    fs.writeFileSync(verificationKeyPath, JSON.stringify(vkey, null, 2));
    const setupTime = Date.now() - startTime;
    console.log(`✅ Trusted setup completed in ${setupTime}ms`);
    return { provingKey: provingKeyPath, verificationKey: verificationKeyPath, circuitType: "circom", setupTime };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown setup error";
    throw new Error(`Circom trusted setup failed: ${message}`);
  }
}

export function validateKeys(verificationKeyPath: string): KeyValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (!fs.existsSync(verificationKeyPath)) {
    errors.push(`Verification key file not found: ${verificationKeyPath}`);
    return { valid: false, errors, warnings };
  }
  try {
    const vkeyContent = fs.readFileSync(verificationKeyPath, "utf8");
    const vkey: VerificationKey = JSON.parse(vkeyContent);
    if (!vkey.protocol) {
      errors.push("Verification key missing protocol field");
    } else if (vkey.protocol !== "groth16") {
      warnings.push(`Unexpected protocol: ${vkey.protocol} (expected groth16)`);
    }
    if (!vkey.curve) {
      errors.push("Verification key missing curve field");
    }
    if (vkey.n_public === undefined || vkey.n_public === null) {
      errors.push("Verification key missing nPublic field");
    }
    if (!vkey.vk_alpha_1 || vkey.vk_alpha_1.length !== 2) {
      errors.push("Verification key vk_alpha_1 is invalid");
    }
    if (!vkey.ic || vkey.ic.length === 0) {
      errors.push("Verification key IC (Input Commitment) is empty");
    }
    return { valid: errors.length === 0, errors, warnings };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown validation error";
    errors.push(`Failed to parse verification key: ${message}`);
    return { valid: false, errors, warnings };
  }
}

export function validateProvingKey(provingKeyPath: string): KeyValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (!fs.existsSync(provingKeyPath)) {
    errors.push(`Proving key file not found: ${provingKeyPath}`);
    return { valid: false, errors, warnings };
  }
  const stats = fs.statSync(provingKeyPath);
  if (stats.size === 0) {
    errors.push("Proving key file is empty");
  } else if (stats.size < 1000) {
    warnings.push(`Proving key file is unusually small (${stats.size} bytes), may be corrupted`);
  }
  const ext = path.extname(provingKeyPath);
  if (ext !== ".zkey") {
    warnings.push(`Proving key file has unexpected extension: ${ext} (expected .zkey)`);
  }
  return { valid: errors.length === 0, errors, warnings };
}
