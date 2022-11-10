// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract P2PSwapFactory is Ownable {

    using Clones for address;
    using SafeERC20 for IERC20;

    address public implementation;

    IERC20 public feeToken = IERC20(address(0));
    uint256 public feeAmount = 0;

    event UpdateFees(address indexed token, uint256 amount);

    event CollectFees(address indexed recipient, address indexed token, uint256 amount);

    event UpdateImplementation(address indexed newImplementation, address indexed oldImplementation);

    event CreateP2PSwap(address indexed);

    constructor(address impl_) Ownable() {
        _updateImpl(impl_);
    }

    function create() external returns (address contractAddress) {
        if (feeToken != IERC20(address(0)) && feeAmount > 0) {
            feeToken.safeTransferFrom(msg.sender, address(this), feeAmount);
        }
        contractAddress =implementation.clone();
        emit CreateP2PSwap(contractAddress);
    }

    function updateImplementation(address impl_) external onlyOwner {
        address prevImpl_ = implementation;
        _updateImpl(impl_);
        emit UpdateImplementation(impl_, prevImpl_);
    }

    function _updateImpl(address impl_) private {
        implementation = impl_;
    }


    function updateFees(address token, uint256 amount) external onlyOwner {
        feeToken = IERC20(token);
        feeAmount = amount;
        emit UpdateFees(token, amount);
    }

    function _updatePrice(address token_, uint256 amount_) private {
        feeToken = IERC20(token_);
        feeAmount = amount_;
    }

    function collectFees(address recipient, address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount > 0) IERC20(token).safeTransfer(recipient, amount);
        emit CollectFees(recipient, token, amount);
    }


}