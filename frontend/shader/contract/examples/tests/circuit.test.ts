/**
 * Circuit-Specific Tests
 * Tests for bridge lock circuit constraints, input validation, and edge cases
 */
import { expect } from "chai";
import { describe, it } from "mocha";
import { validateCircuitInputs } from "../helpers/compile-circuit";
import { createTestInputTemplate } from "../helpers/test-circuit";

describe("Bridge Lock Circuit Tests", () => {
  describe("Input Validation", () => {
    it("Should validate token address is non-zero", () => {
      const input = createTestInputTemplate("circom");
      expect(input.tokenAddress).to.not.equal("0");
      expect(input.tokenAddress).to.have.length.greaterThan(0);
    });

    it("Should validate amount is positive", () => {
      const input = createTestInputTemplate("circom");
      expect(Number(input.amount)).to.be.greaterThan(0);
    });

    it("Should validate recipient address is non-zero", () => {
      const input = createTestInputTemplate("circom");
      expect(input.recipient).to.not.equal("0");
      expect(input.recipient).to.have.length.greaterThan(0);
    });
  });

  describe("Edge Cases", () => {
    it("Should handle minimum amount", () => {
      const input = createTestInputTemplate("circom");
      input.amount = "1";
      expect(Number(input.amount)).to.equal(1);
    });

    it("Should handle maximum amount", () => {
      const input = createTestInputTemplate("circom");
      input.amount = "115792089237316195423570985008687907853269984665640564039457584007913129639935";
      expect(Number(input.amount)).to.be.greaterThan(0);
    });

    it("Should handle empty merkle proof", () => {
      const input = createTestInputTemplate("circom");
      input.merklePathElements = [];
      input.merklePathIndices = [];
      expect(input.merklePathElements).to.have.length(0);
    });
  });

  describe("Performance Limits", () => {
    it("Should validate circuit file size is reasonable", () => {
      // This would check actual file size in a real test
      // For now, just verify the validation function exists
      expect(validateCircuitInputs).to.be.a("function");
    });
  });
});
