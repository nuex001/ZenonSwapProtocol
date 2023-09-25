/**
 * @type import('hardhat/config').HardhatUserConfig
 */

import "hardhat-typechain";
import "@nomiclabs/hardhat-ethers";
import "hardhat-contract-sizer"
import "@nomicfoundation/hardhat-verify";
import "hardhat-deploy";

require("dotenv").config()
require("hardhat-storage-layout");
require('solidity-coverage')

module.exports = {
  solidity: {
    compilers: [{
      version: "0.8.19",
      settings: {
        optimizer: {
          enabled: true,
          runs: 1000000
        },
        outputSelection: {
          "*": {
            "*": ["storageLayout"],
          },
        },
      }
    }],
    overrides: {
    },

  },
  networks: {
    local: {
      url: 'http://127.0.0.1:8545',
      chainId: 31337,
      blockGasLimit: 100000000429720 // whatever you want here
    },
    // added extra layer for sepolia testnet
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/y44WXWFiaPe0HuMT_Z2he-xMzUgBmMWs",
      accounts: ["0x7c5e2cfbba7b00ba95e5ed7cd80566021da709442e147ad3e08f23f5044a3d5a"],
      chainId: 11155111,
    },
    ropsten: {
      url: 'https://ropsten.infura.io/v3/cf3bc905d88d4f248c6be347adc8a1d8',
      chainId: 3,
      accounts: ["0x7c5e2cfbba7b00ba95e5ed7cd80566021da709442e147ad3e08f23f5044a3d5a"]
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/cf3bc905d88d4f248c6be347adc8a1d8',
      chainId: 4,
      accounts: ["0x7c5e2cfbba7b00ba95e5ed7cd80566021da709442e147ad3e08f23f5044a3d5a"]
    },
    kovan: {
      url: 'https://kovan.infura.io/v3/cf3bc905d88d4f248c6be347adc8a1d8',
      chainId: 42,
      accounts: ["0x7c5e2cfbba7b00ba95e5ed7cd80566021da709442e147ad3e08f23f5044a3d5a"]
    },
    goerli: {
      url: 'https://goerli.infura.io/v3/cf3bc905d88d4f248c6be347adc8a1d8',
      chainId: 5,
      accounts: ["0x7c5e2cfbba7b00ba95e5ed7cd80566021da709442e147ad3e08f23f5044a3d5a"]
    },
    bsctestnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      chainId: 97,
      accounts: ["0x7c5e2cfbba7b00ba95e5ed7cd80566021da709442e147ad3e08f23f5044a3d5a"]
    },
    mainnet: {
      url: "https://bsc-dataseed.bnbchain.org/",
      chainId: 56,
      accounts: ["0x7c5e2cfbba7b00ba95e5ed7cd80566021da709442e147ad3e08f23f5044a3d5a"]
    },
    // mainnet: {
    //   url: 'https://mainnet.infura.io/v3/360ea5fda45b4a22883de8522ebd639e',
    //   chainId: 1
    // },

    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
    },

  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "",
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
  }
};

//had serious issues with @nomiclabs/hardhat-ethers": "npm:hardhat-deploy-ethers@^0.3.0-beta.13