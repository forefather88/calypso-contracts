require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");
const kovanApi = process.env.KOVANAPI;
const fs = require("fs");
const mnemonic = fs.readFileSync("metamask.txt").toString().trim();

module.exports = {
  networks: {
    kovan: {
      provider: function () {
        return new HDWalletProvider(
          mnemonic,
          "wss://kovan.infura.io/ws/v3/b280b8aa6cda4dba845afb03d46c2396"
        );
      },
      network_id: 42,
      gasPrice: 100000000000,
      skipDryRun: true,
    },
    rinkeby: {
      networkCheckTimeout: 10000,
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          "wss://rinkeby.infura.io/ws/v3/9b3be367fb174b298829d298f98cc103"
        ),
      network_id: 4,
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.3", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "byzantium",
      },
    },
  },

  db: {
    enabled: false,
  },

  plugins: ["truffle-plugin-verify"],

  api_keys: {
    etherscan: kovanApi,
  },
};
