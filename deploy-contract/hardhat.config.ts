import "dotenv/config";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const RPC_URL = process.env.RPC_URL!;
const CHAIN_ID = Number(process.env.CHAIN_ID || "252501");
const PRIVKEY = process.env.PRIVKEY!;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
    evmVersion: "paris", 
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    didlab: {
      url: RPC_URL,
      chainId: CHAIN_ID,
      accounts: process.env.PRIVKEY ? [process.env.PRIVKEY] : [],
      gas: 6000000,
      gasPrice: 20000000000,
      type: "http", // Only allowed types are "http" and "edr-simulated"
    },
  },
};

export default config;
