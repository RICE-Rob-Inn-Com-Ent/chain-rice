const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HelloWorld", function () {
  let helloWorld;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    const HelloWorld = await ethers.getContractFactory("HelloWorld");
    helloWorld = await HelloWorld.deploy();
    await helloWorld.waitForDeployment();
  });

  it("Should return the initial message", async function () {
    const message = await helloWorld.getMessage();
    expect(message).to.equal("Hello, Rice Dev!");
  });

  it("Should set a new message", async function () {
    const newMessage = "Test message from Rice Dev!";
    await helloWorld.setMessage(newMessage);

    const message = await helloWorld.getMessage();
    expect(message).to.equal(newMessage);
  });

  it("Should emit an event when message is set", async function () {
    const newMessage = "Event test message";

    await expect(helloWorld.setMessage(newMessage))
      .to.emit(helloWorld, "MessageSet")
      .withArgs(newMessage);
  });
});
