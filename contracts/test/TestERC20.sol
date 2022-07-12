// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function burn(address from, uint256 id) external {
        _burn(from, id);
    }
}
