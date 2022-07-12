import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.14",
  networks: {
    hardhat: {
      chainId: 1,
      forking: {
        enabled: true,
        url: process.env.ETH_RPC ?? "",
      },
    },
  },
};

export default config;
