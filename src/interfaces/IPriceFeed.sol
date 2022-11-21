// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {

  function token() 
    external 
    view 
    returns (address);

  function latestPrice()
    external
    view
    returns (
      uint256 price,
      uint256 updatedAt,
      int8 decimals
    );

}