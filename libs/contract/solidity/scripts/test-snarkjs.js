const snarkjs = require("snarkjs");

async function main() {
  console.log("Testing snarkjs functionality...");

  try {
    // Test basic functionality
    console.log("snarkjs version:", snarkjs.version || "unknown");
    console.log("Available methods:", Object.keys(snarkjs));

    // Test if we can read the R1CS file
    const fs = require("fs");
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
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();
