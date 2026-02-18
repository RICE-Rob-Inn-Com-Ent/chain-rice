import * as fs from "node:fs";
import * as path from "node:path";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import { compileGnarkCircuit, compileCircomCircuit, type CompileGnarkOptions, type CompileCircomOptions, type CompileGnarkResult, type CompileCircomResult } from "../../app/app";

const execAsync = promisify(exec);

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

export interface RequirementsCheck {
  gnarkInstalled: boolean;
  circomInstalled: boolean;
  goInstalled: boolean;
  nodeInstalled: boolean;
  errors: string[];
}

export async function compileGnarkCircuitSafe(options: CompileGnarkOptions): Promise<CompileGnarkResult> {
  const validation = validateCircuitInputs(options.circuitPath, "gnark");
  if (!validation.valid) {
    throw new Error(`Input validation failed: ${validation.errors.join(", ")}`);
  }
  const requirements = await checkCircuitRequirements();
  if (!requirements.gnarkInstalled) {
    throw new Error("gnark CLI not installed. Install with: go install github.com/consensys/gnark/cmd/gnark@latest");
  }
  try {
    return await compileGnarkCircuit(options);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown compilation error";
    throw new Error(`Gnark compilation failed: ${message}`);
  }
}

export async function compileCircomCircuitSafe(options: CompileCircomOptions): Promise<CompileCircomResult> {
  const validation = validateCircuitInputs(options.circuitPath, "circom");
  if (!validation.valid) {
    throw new Error(`Input validation failed: ${validation.errors.join(", ")}`);
  }
  const requirements = await checkCircuitRequirements();
  if (!requirements.circomInstalled) {
    throw new Error("circom CLI not installed. Install with: npm install -g circom");
  }
  try {
    return await compileCircomCircuit(options);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown compilation error";
    throw new Error(`Circom compilation failed: ${message}`);
  }
}

export function validateCircuitInputs(circuitPath: string, circuitType: "gnark" | "circom"): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  if (!fs.existsSync(circuitPath)) {
    errors.push(`Circuit file not found: ${circuitPath}`);
    return { valid: false, errors, warnings };
  }
  const ext = path.extname(circuitPath);
  if (circuitType === "gnark" && ext !== ".go") {
    errors.push(`Gnark circuit must have .go extension, got: ${ext}`);
  }
  if (circuitType === "circom" && ext !== ".circom") {
    errors.push(`Circom circuit must have .circom extension, got: ${ext}`);
  }
  try {
    fs.accessSync(circuitPath, fs.constants.R_OK);
  } catch {
    errors.push(`Circuit file is not readable: ${circuitPath}`);
  }
  const stats = fs.statSync(circuitPath);
  const MAX_FILE_SIZE = 10 * 1024 * 1024;
  if (stats.size > MAX_FILE_SIZE) {
    warnings.push(`Circuit file is large (${(stats.size / 1024 / 1024).toFixed(2)}MB), compilation may be slow`);
  }
  if (stats.size === 0) {
    errors.push(`Circuit file is empty: ${circuitPath}`);
  }
  return { valid: errors.length === 0, errors, warnings };
}

export async function checkCircuitRequirements(): Promise<RequirementsCheck> {
  const errors: string[] = [];
  let gnarkInstalled = false;
  let circomInstalled = false;
  let goInstalled = false;
  let nodeInstalled = false;
  try {
    await execAsync("node --version");
    nodeInstalled = true;
  } catch {
    errors.push("Node.js is not installed or not in PATH");
  }
  try {
    await execAsync("go version");
    goInstalled = true;
  } catch {
    errors.push("Go is not installed or not in PATH (required for gnark)");
  }
  try {
    await execAsync("gnark version");
    gnarkInstalled = true;
  } catch {
    if (goInstalled) {
      errors.push("gnark CLI not found. Install with: go install github.com/consensys/gnark/cmd/gnark@latest");
    }
  }
  try {
    await execAsync("circom --version");
    circomInstalled = true;
  } catch {
    if (nodeInstalled) {
      errors.push("circom CLI not found. Install with: npm install -g circom");
    }
  }
  return { gnarkInstalled, circomInstalled, goInstalled, nodeInstalled, errors };
}
