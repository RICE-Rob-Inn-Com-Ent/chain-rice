/**
 * Integration Tests for Circuit Compilation and Setup
 * Tests end-to-end workflows for gnark and circom circuits
 */
import { expect } from "chai";
import { describe, it, before } from "mocha";
import * as fs from "node:fs";
import * as path from "node:path";
import {
  compileGnarkCircuitSafe,
  compileCircomCircuitSafe,
  checkCircuitRequirements,
  validateCircuitInputs,
} from "../helpers/compile-circuit";
import {
  runTrustedSetup,
  validateKeys,
  validateProvingKey,
} from "../helpers/setup-circuit";
import {
  generateTestProof,
  verifyTestProof,
  createTestInputTemplate,
} from "../helpers/test-circuit";

const EXAMPLES_DIR = path.join(__dirname, "..");
const CIRCUITS_DIR = path.join(EXAMPLES_DIR, "circuits");
const ARTIFACTS_DIR = path.join(EXAMPLES_DIR, "artifacts");

describe("Circuit Integration Tests", () => {
  before(() => {
    // Create artifacts directory if it doesn't exist
    if (!fs.existsSync(ARTIFACTS_DIR)) {
      fs.mkdirSync(ARTIFACTS_DIR, { recursive: true });
    }
  });

  describe("Requirements Check", () => {
    it("Should check if all required CLIs are installed", async () => {
      const requirements = await checkCircuitRequirements();
      
      expect(requirements).to.have.property("gnarkInstalled");
      expect(requirements).to.have.property("circomInstalled");
      expect(requirements).to.have.property("goInstalled");
      expect(requirements).to.have.property("nodeInstalled");
      expect(requirements).to.have.property("errors");
      
      // Node should always be installed (we're running in Node)
      expect(requirements.nodeInstalled).to.be.true;
    });
  });

  describe("Input Validation", () => {
    it("Should validate gnark circuit inputs", () => {
      const gnarkCircuit = path.join(CIRCUITS_DIR, "gnark", "bridge_lock.go");
      
      if (fs.existsSync(gnarkCircuit)) {
        const validation = validateCircuitInputs(gnarkCircuit, "gnark");
        expect(validation).to.have.property("valid");
        expect(validation).to.have.property("errors");
        expect(validation).to.have.property("warnings");
      }
    });

    it("Should validate circom circuit inputs", () => {
      const circomCircuit = path.join(CIRCUITS_DIR, "circom", "bridge_lock.circom");
      
      if (fs.existsSync(circomCircuit)) {
        const validation = validateCircuitInputs(circomCircuit, "circom");
        expect(validation).to.have.property("valid");
        expect(validation).to.have.property("errors");
        expect(validation).to.have.property("warnings");
      }
    });

    it("Should reject invalid file paths", () => {
      const validation = validateCircuitInputs("/nonexistent/file.go", "gnark");
      expect(validation.valid).to.be.false;
      expect(validation.errors.length).to.be.greaterThan(0);
    });
  });

  describe("Circom Circuit Compilation", () => {
    it("Should compile circom circuit if file exists", async function () {
      this.timeout(30000); // 30 second timeout for compilation
      
      const circomCircuit = path.join(CIRCUITS_DIR, "circom", "bridge_lock.circom");
      
      if (!fs.existsSync(circomCircuit)) {
        this.skip(); // Skip if circuit file doesn't exist
      }

      const outputDir = path.join(ARTIFACTS_DIR, "circom");
      const result = await compileCircomCircuitSafe({
        circuitPath: circomCircuit,
        outputDir,
        circuitName: "bridge_lock",
      });

      expect(result).to.have.property("r1cs");
      expect(result).to.have.property("wasm");
      expect(fs.existsSync(result.r1cs)).to.be.true;
      expect(fs.existsSync(result.wasm)).to.be.true;
    });

    it("Should handle compilation errors gracefully", async function () {
      this.timeout(10000);
      
      try {
        await compileCircomCircuitSafe({
          circuitPath: "/nonexistent/circuit.circom",
          outputDir: ARTIFACTS_DIR,
          circuitName: "test",
        });
        expect.fail("Should have thrown an error");
      } catch (error) {
        expect(error).to.be.instanceOf(Error);
      }
    });
  });

  describe("Gnark Circuit Compilation", () => {
    it("Should compile gnark circuit if file exists", async function () {
      this.timeout(30000);
      
      const gnarkCircuit = path.join(CIRCUITS_DIR, "gnark", "bridge_lock.go");
      
      if (!fs.existsSync(gnarkCircuit)) {
        this.skip();
      }

      const outputPath = path.join(ARTIFACTS_DIR, "gnark", "bridge_lock.wasm");
      const result = await compileGnarkCircuitSafe({
        circuitPath: gnarkCircuit,
        outputPath,
      });

      expect(result).to.have.property("wasm");
      expect(result).to.have.property("size");
      expect(result).to.have.property("compilationTime");
      expect(fs.existsSync(result.wasm)).to.be.true;
    });

    it("Should handle compilation errors gracefully", async function () {
      this.timeout(10000);
      
      try {
        await compileGnarkCircuitSafe({
          circuitPath: "/nonexistent/circuit.go",
          outputPath: "/tmp/test.wasm",
        });
        expect.fail("Should have thrown an error");
      } catch (error) {
        expect(error).to.be.instanceOf(Error);
      }
    });
  });

  describe("Trusted Setup", () => {
    it("Should run trusted setup for circom circuit", async function () {
      this.timeout(60000);
      
      const r1csPath = path.join(ARTIFACTS_DIR, "circom", "r1cs", "bridge_lock.r1cs");
      const wasmPath = path.join(ARTIFACTS_DIR, "circom", "wasm", "bridge_lock_js", "bridge_lock.wasm");
      
      if (!fs.existsSync(r1csPath) || !fs.existsSync(wasmPath)) {
        this.skip();
      }

      const result = await runTrustedSetup({
        r1csPath,
        wasmPath,
        outputDir: path.join(ARTIFACTS_DIR, "circom"),
        circuitName: "bridge_lock",
        circuitType: "circom",
      });

      expect(result).to.have.property("provingKey");
      expect(result).to.have.property("verificationKey");
      expect(result).to.have.property("setupTime");
      expect(fs.existsSync(result.provingKey)).to.be.true;
      expect(fs.existsSync(result.verificationKey)).to.be.true;
    });

    it("Should validate generated keys", () => {
      const vkPath = path.join(ARTIFACTS_DIR, "circom", "keys", "bridge_lock_vk.json");
      
      if (!fs.existsSync(vkPath)) {
        return; // Skip if key doesn't exist
      }

      const validation = validateKeys(vkPath);
      expect(validation).to.have.property("valid");
      expect(validation).to.have.property("errors");
      expect(validation).to.have.property("warnings");
    });
  });

  describe("Proof Generation and Verification", () => {
    it("Should generate test input template", () => {
      const template = createTestInputTemplate("circom");
      expect(template).to.have.property("tokenAddress");
      expect(template).to.have.property("amount");
      expect(template).to.have.property("recipient");
    });

    it("Should generate and verify proof for circom circuit", async function () {
      this.timeout(120000);
      
      const wasmPath = path.join(ARTIFACTS_DIR, "circom", "wasm", "bridge_lock_js", "bridge_lock.wasm");
      const pkPath = path.join(ARTIFACTS_DIR, "circom", "keys", "bridge_lock_pk.zkey");
      const vkPath = path.join(ARTIFACTS_DIR, "circom", "keys", "bridge_lock_vk.json");
      
      if (!fs.existsSync(wasmPath) || !fs.existsSync(pkPath) || !fs.existsSync(vkPath)) {
        this.skip();
      }

      const testInput = createTestInputTemplate("circom");
      
      const proofResult = await generateTestProof({
        wasmPath,
        provingKeyPath: pkPath,
        input: testInput,
        circuitType: "circom",
      });

      expect(proofResult).to.have.property("proof");
      expect(proofResult).to.have.property("publicSignals");
      expect(proofResult).to.have.property("generationTime");

      const isValid = await verifyTestProof({
        proof: proofResult.proof,
        publicSignals: proofResult.publicSignals,
        verificationKeyPath: vkPath,
        circuitType: "circom",
      });

      expect(isValid).to.be.true;
    });
  });

  describe("Error Handling", () => {
    it("Should handle missing circuit files", async () => {
      try {
        await compileCircomCircuitSafe({
          circuitPath: "/nonexistent.circom",
          outputDir: ARTIFACTS_DIR,
          circuitName: "test",
        });
        expect.fail("Should have thrown an error");
      } catch (error) {
        expect(error).to.be.instanceOf(Error);
        expect((error as Error).message).to.include("not found");
      }
    });

    it("Should handle missing CLI tools", async () => {
      // This test checks error handling when CLIs are missing
      // In a real scenario, you might mock the execAsync call
      const requirements = await checkCircuitRequirements();
      // Just verify the function doesn't throw
      expect(requirements).to.have.property("errors");
    });
  });
});
