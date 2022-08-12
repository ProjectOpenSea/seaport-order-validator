module.exports = {
  skipFiles: [
    "test/TestERC721.sol",
    "test/TestERC1155.sol",
    "test/TestERC20.sol",
    "test/TestZone.sol",
    "test/TestERC1271.sol",
    "test/TestERC721Funky.sol",
    "test/contracts/test/TestEW.sol",
    "lib/ConsiderationTypeHashes.sol",
    "lib/ConsiderationStructs.sol",
    "lib/ConsiderationEnums.sol",
    "lib/SignatureVerification.sol",
  ],
  configureYulOptimizer: true,
  solcOptimizerDetails: {
    yul: true,
    yulDetails: {
      stackAllocation: true,
    },
  },
  istanbulReporter: ["lcov"],
  istanbulFolder: "./coverage-arbitrum",
};
