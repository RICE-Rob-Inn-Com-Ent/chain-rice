const snarkjs = require("snarkjs");

async function runSetup() {
  console.log("Starting trusted setup for MyCircuit...");

  // Generate proving key and verification key
  await snarkjs.zKey.newZKey(
    "./mycircuit.r1cs",
    "./mycircuit_js/mycircuit.wasm",
    "./mycircuit_pk.zkey"
  );

  const vkey = await snarkjs.zKey.exportVerificationKey("./mycircuit_pk.zkey");
  require("fs").writeFileSync(
    "./mycircuit_vk.json",
    JSON.stringify(vkey, null, 2)
  );

  console.log("Setup completed successfully!");
  console.log("Proving key saved to: ./mycircuit_pk.zkey");
  console.log("Verification key saved to: ./mycircuit_vk.json");
}

async function generateProof() {
  console.log("Generating proof...");

  // Example inputs
  const input = {
    a: 3,
    b: 4,
  };

  // Generate proof
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    input,
    "./mycircuit_js/mycircuit.wasm",
    "./mycircuit_pk.zkey"
  );

  console.log("Proof generated successfully!");
  console.log("Proof:", JSON.stringify(proof, null, 2));
  console.log("Public signals:", publicSignals);

  return { proof, publicSignals };
}

async function verifyProof(proof, publicSignals) {
  console.log("Verifying proof...");

  const vkey = JSON.parse(
    require("fs").readFileSync("./mycircuit_vk.json", "utf8")
  );
  const res = await snarkjs.groth16.verify(vkey, publicSignals, proof);

  if (res === true) {
    console.log("✅ Proof is valid!");
  } else {
    console.log("❌ Proof is invalid!");
  }

  return res;
}

async function main() {
  try {
    // Run trusted setup
    await runSetup();

    // Generate and verify proof
    const { proof, publicSignals } = await generateProof();
    await verifyProof(proof, publicSignals);
  } catch (error) {
    console.error("Error:", error);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = {
  runSetup,
  generateProof,
  verifyProof,
};
