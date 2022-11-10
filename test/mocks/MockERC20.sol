// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(string memory name, string memory symbol) ERC20 (name, symbol) {

    }

    function mint(address recipient, uint256 amount) public {
        _mint(recipient, amount);
    }

    function burn(address owner, uint256 amount) public {
        _burn(owner, amount);
    }
}