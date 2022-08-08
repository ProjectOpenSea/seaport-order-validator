// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @notice TestERC721Funky is an ERC721 that implements ERC2981 with an incorrect return type.
 */
contract TestERC721Funky is ERC721 {
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function burn(uint256 id) external {
        _burn(id);
    }

    function royaltyInfo(uint256, uint256) public pure returns (address) {
        return (0x000000000000000000000000000000000000fEE2); // 2.5% fee to 0xFEE2
    }
}
