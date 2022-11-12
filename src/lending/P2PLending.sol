// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract P2PLending {

    using SafeERC20 for IERC20;

    address public borrower;
    address public lender;

    IERC20 public collateralToken;
    IERC20 public borrowToken;

    uint256 public collateralAmount;
    uint256 public borrowAmount;

    uint256 public maxLtvBps;
    uint256 public interestPerBlock;
    uint256 public maturityBlock;

    enum LendingState {
        Uninitialized, OfferLoan, PayCollateral, Lending, Cancelled, Fulfilled
    }

    LendingState public lendingState;

    uint256 private lastBorrowBlock;


    function offerLoan(address borrower_, address borrowToken_, uint256 borrowAmount_, 
        uint256 maxLtvBps_, 
        uint256 interestPerBlock_, 
        uint256 maturityBlock_) external {
        lender = msg.sender;
        borrower = borrower_;
        borrowToken = IERC20(borrowToken_);
        borrowAmount = borrowAmount_;
        maxLtvBps = maxLtvBps_;
        interestPerBlock = interestPerBlock_;
        maturityBlock = maturityBlock_;
        lendingState = LendingState.OfferLoan;

    }

    function payCollateral(address collateralToken_, uint256 collateralAmount_) external {
        collateralToken = IERC20(collateralToken_);
        collateralAmount = collateralAmount_;
        lendingState = LendingState.PayCollateral;
        collateralToken.safeTransferFrom(borrower, address(this), collateralAmount);
    }

    function cancel() external {

    }

    function accept() external {

    }


}