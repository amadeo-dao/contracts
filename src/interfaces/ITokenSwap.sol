// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenSwap {

    struct Offer {
        IERC20 token;
        uint256 amount;
        uint256 expires;
        bool isFulfilled;
    }

    struct Swap {
        address buyer;
        address seller;
        Offer ask;
        Offer bid;
        bool isComplete;
    }

    function createAsk(address seller, address buyer, 
        address askToken, uint256 askAmount, uint256 askExpires) external returns(uint256 swapId);

    function addBid(uint256 swapId, address bidToken, uint256 bidAmount, uint256 bidExpires) external;

    function fulfillAsk(uint256 swapId) external;

    function fulfillBid(uint256 swapId) external;

    function retractAsk(uint256 swapId) external;

    function retractBid(uint256 swapId) external;

    function cancel(uint256 swapId) external;

    function swap(uint256 swapId) external;

    function swapLength() external view returns (uint256);
    
    function swapInfo(uint256 swapId) external view returns (Swap memory);

}
