import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";


const config: HardhatUserConfig = {
  solidity: "0.8.28", // You can change this to the version your contract uses
};

export default config;
