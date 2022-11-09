// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ITokenSwap.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract P2PSwap is ITokenSwap {
    uint256 public swapLength;

    mapping(uint256 => ITokenSwap.Swap) swaps;

    function createAsk(
        address seller,
        address buyer,
        address askToken,
        uint256 askAmount,
        uint256 askExpires
    ) external returns (uint256) {
        require(buyer != seller, "P2PSwap: same buyer and seller");
        require(buyer != address(0), "P2PSwap: buyer is null");
        require(seller != address(0), "P2PSwap: seller is null");
        Swap storage swap = swaps[swapLength];
        swap.seller = seller;
        swap.buyer = buyer;
        swap.ask.token = askToken;
        swap.ask.amount = askAmount;
        swap.ask.expires = askExpires;
        return swapLength++;
    }

    function addBid(uint256 swapId, 
        address bidToken, uint256 bidAmount, uint256 bidExpires) 
        external 
    {
        require(swapId < swapLength, "P2PSwap: swap id does not exist");
        Swap storage swap = swaps[swapLength];
        require(swap.isComplete, "P2PSwap: swap already completed");
        require(block.timestamp < swap.ask.expires, "P2PSwap: ask expired");
        swap.bid.amount = bidAmount;
        swap.bid.expires = bidExpires;
        swap.bid.token = bidToken;
    }

    function swapInfo(uint256 swapId) public view returns (Swap memory) {
        return swaps[swapId];
    }
}
