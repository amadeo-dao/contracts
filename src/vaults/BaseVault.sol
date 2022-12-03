// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";


contract BaseVault is ERC4626 {

    constructor(string memory name_, string memory symbol_, address asset_) ERC20(name_, symbol_) ERC4626(IERC20(asset_)) {

    }



}