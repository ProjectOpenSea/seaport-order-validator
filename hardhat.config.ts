import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: "0.8.14",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 1,
      forking: {
        enabled: true,
        url: process.env.ETH_RPC ?? "",
      },
    },
  },
};

export default config;
