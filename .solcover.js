module.exports = {
  skipFiles: [
    "test/TestERC721.sol",
    "test/TestERC1155.sol",
    "test/TestERC20.sol",
    "test/TestZone.sol",
    "test/TestERC1271.sol",
    "lib/ConsiderationTypeHashes.sol",
    "lib/ConsiderationStructs.sol",
    "lib/ConsiderationEnums.sol",
    "lib/Murky.sol",
    "lib/SignatureVerification.sol",
  ],
  configureYulOptimizer: true,
  solcOptimizerDetails: {
    yul: true,
    yulDetails: {
      stackAllocation: true,
    },
  },
};
