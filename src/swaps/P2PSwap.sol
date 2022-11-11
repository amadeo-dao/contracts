// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract P2PSwap {
    using SafeERC20 for IERC20;

    address public buyer = address(0);
    address public seller = address(0);

    IERC20 public bidToken;

    IERC20 public sellToken;
    uint256 public sellAmount;
    
    enum SwapState {
        Uninitialized, Ask, Bid, Cancelled, Fulfilled
    }

    SwapState public swapState = SwapState.Uninitialized;

    modifier notCompleted() {
        require(swapState != SwapState.Fulfilled, "P2PSwap: swap already fulfilled");
        require(swapState != SwapState.Cancelled, "P2PSwap: swap already cancelled");
        _;
    }

    modifier uninitalized() {
        require(swapState == SwapState.Uninitialized, "P2P: swap already initialized");
        _;
    }

    modifier askModeOnly() {
        require(swapState == SwapState.Ask, "P2P: swap not in ask mode");
        _;
    }

    modifier bidModeOnly() {
        require(swapState == SwapState.Bid, "P2P: swap not in bid mode");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "P2PSwap: only allowed for buyer");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "P2PSwap: only allowed for seller");
        _;
    }

    event Ask(address indexed seller, address indexed buyer, address indexed sellToken, uint256 sellAmount);
    event Bid(address indexed buyer, address indexed bidToken, uint256 bidAmount);
    event Cancel(address indexed bidToken, uint256 bidAmount);
    event Swap(address indexed sellToken, address indexed bidToken, uint256 sellAmount, uint256 bidAmount);

    function ask(
        address buyer_,
        address sellToken_,
        uint256 sellAmount_
    ) external uninitalized {
        require(buyer_ != msg.sender, "P2PSwap: buyer cannot be seller");
        require(buyer_ != address(0), "P2PSwap: buyer cannot be null address");
        require(sellAmount_ > 0, "P2PSwap: ask amount cannot be null");
        require(sellToken_ != address(0), "P2PSwap: ask token cannot be null address");
        seller = msg.sender;
        buyer = buyer_;
        sellAmount = sellAmount_;
        sellToken = IERC20(sellToken_);        
        swapState = SwapState.Ask;
        emit Ask(buyer, seller, address(sellToken), sellAmount);
    }

    function bid(
        address bidToken_,
        uint256 bidAmount_
    ) external askModeOnly onlyBuyer  {
        require(bidAmount_ > 0, "P2PSwap: bid amount cannot be null");
        require(bidToken_ != address(0), "P2PSwap: bid token cannot be null address");
        require(bidToken_ != address(sellToken), "P2PSwap: bid token cannot be ask token");
        bidToken = IERC20(bidToken_);
        bidToken.safeTransferFrom(msg.sender, address(this), bidAmount_);
        swapState = SwapState.Bid;
        emit Bid(buyer, address(bidToken), bidAmount_);
    }

    function cancel() external bidModeOnly onlyBuyer {
        uint bidBalance = bidToken.balanceOf(address(this));
        bidToken.safeTransfer(buyer, bidBalance);
        swapState = SwapState.Cancelled;
        emit Cancel(address(bidToken), bidBalance);
    }

    function swap() external bidModeOnly onlySeller {
        sellToken.safeTransferFrom(seller, address(this), sellAmount);
        uint sellBalance = sellToken.balanceOf(address(this));
        uint bidBalance = bidToken.balanceOf(address(this));
        sellToken.safeTransfer(buyer, sellBalance);
        bidToken.safeTransfer(seller, bidBalance);
        swapState = SwapState.Fulfilled;
        emit Swap(address(sellToken), address(bidToken), sellBalance, bidBalance);
    }

}
