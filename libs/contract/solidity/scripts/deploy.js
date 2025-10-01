const hre = require("hardhat");

async function main() {
  console.log("Deploying HelloWorld contract...");

  const HelloWorld = await hre.ethers.getContractFactory("HelloWorld");
  const helloWorld = await HelloWorld.deploy();

  await helloWorld.waitForDeployment();

  const address = await helloWorld.getAddress();
  console.log("HelloWorld deployed to:", address);

  // Test the contract
  const message = await helloWorld.getMessage();
  console.log("Initial message:", message);

  // Set a new message
  await helloWorld.setMessage("Hello from Rice Dev!");
  const newMessage = await helloWorld.getMessage();
  console.log("New message:", newMessage);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
