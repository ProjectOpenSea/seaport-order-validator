// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface RoyaltyEngineInterface {
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}
