import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.14",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },

  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 42161,
      forking: {
        enabled: true,
        url:
          "https://arbitrum-mainnet.infura.io/v3/" +
          (process.env.INFURA_KEY ?? ""),
      },
    },
  },
};

export default config;
