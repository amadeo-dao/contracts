// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IPriceFeed.sol";

contract ChainlinkFeed is IPriceFeed {

    address public immutable token;
    AggregatorV3Interface public immutable aggregator;

    constructor(address token_, address aggregator) {
        token = token_;
        aggregator = AggregatorV3Interface(aggregator_);
    }

    




}