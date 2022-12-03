// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";



import "../interfaces/IPriceFeed.sol";

contract ChainlinkFeed is IPriceFeed {

    using SafeCast for int256;

    address public immutable token;
    uint256 public immutable tokenDecimals;
    AggregatorV3Interface public immutable aggregator;

    constructor(address token_, uint8 tokenDecimals_, address aggregator_) {
        token = token_;
        tokenDecimals = tokenDecimals_;
        aggregator = AggregatorV3Interface(aggregator_);
    }

    function latestPrice()
        external
        view
        returns (
            uint256 price
        )
    {
        uint8 clDecimals = aggregator.decimals();
        (,int256 clAnswer, uint256 clStartedAt, uint256 clUpdatedAt,) = aggregator.latestRoundData();
        require(clStartedAt > block.timestamp - 1 hours, "ChainLinkFeed: oracle data too old");
        require(price >= 0, "ChainlinkFeed: negative price not supported");
        price = clAnswer.toUint256() * 10 ^ tokenDecimals / 10 ^ clDecimals;
        return uint256(clAnswer);
    }
    
}
