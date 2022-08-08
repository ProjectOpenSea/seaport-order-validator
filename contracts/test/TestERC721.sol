// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract TestERC721 is ERC721, ERC2981 {
    bool royaltyFeeEnabled = false;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function burn(uint256 id) external {
        _burn(id);
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        if (!royaltyFeeEnabled) {
            revert("royalty fee disabled");
        }
        return (
            0x000000000000000000000000000000000000fEE2,
            (_salePrice * (royaltyFeeEnabled ? 250 : 0)) / 10000
        ); // 2.5% fee to 0xFEE2
    }

    function setRoyaltyFeeEnabled(bool enabled) public {
        royaltyFeeEnabled = enabled;
    }
}
