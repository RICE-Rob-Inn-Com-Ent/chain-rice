require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    // External networks - only configure if environment variables are set
    ...(process.env.PRIVATE_KEY &&
      process.env.ETH_RPC_URL && {
        ethereum: {
          url: process.env.ETH_RPC_URL,
          accounts: [process.env.PRIVATE_KEY],
        },
      }),
    ...(process.env.PRIVATE_KEY &&
      process.env.POLYGON_RPC_URL && {
        polygon: {
          url: process.env.POLYGON_RPC_URL,
          accounts: [process.env.PRIVATE_KEY],
        },
      }),
    ...(process.env.PRIVATE_KEY &&
      process.env.BSC_RPC_URL && {
        bsc: {
          url: process.env.BSC_RPC_URL,
          accounts: [process.env.PRIVATE_KEY],
        },
      }),
    ...(process.env.PRIVATE_KEY &&
      process.env.AVAX_RPC_URL && {
        avalanche: {
          url: process.env.AVAX_RPC_URL,
          accounts: [process.env.PRIVATE_KEY],
        },
      }),
    ...(process.env.PRIVATE_KEY &&
      process.env.ARB_RPC_URL && {
        arbitrum: {
          url: process.env.ARB_RPC_URL,
          accounts: [process.env.PRIVATE_KEY],
        },
      }),
    ...(process.env.PRIVATE_KEY &&
      process.env.OPT_RPC_URL && {
        optimism: {
          url: process.env.OPT_RPC_URL,
          accounts: [process.env.PRIVATE_KEY],
        },
      }),
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "demo",
  },
};
