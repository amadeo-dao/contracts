// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/swaps/P2PSwapFactory.sol";
import "../../src/swaps/P2PSwap.sol";


contract P2PSwapUtils is Test {

    P2PSwap public swap;

    MockERC20 public tokenA;
    MockERC20 public tokenB;
    
    address public deployer;
    address public alice;
    address public bob;

    constructor() {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        tokenA = new MockERC20("Token A", "TOKA");
        tokenA.mint(alice, 100000 ether);
        tokenA.mint(bob, 100000 ether);

        tokenB = new MockERC20("Token B", "TOKB");
        tokenB.mint(alice, 100000 ether);
        tokenB.mint(bob, 100000 ether);

    }

    function reset_Swap() public {
        vm.prank(deployer);
        swap = new P2PSwap();
        vm.prank(alice);
        tokenA.approve(address(swap), 10000 ether);
        vm.prank(bob);
        tokenB.approve(address(swap), 10000 ether);
    }

    function alice_offers_10_TokenA_to_Bob() public {
        vm.prank(alice);
        swap.ask(bob, address(tokenA), 10 ether);
    }

    function bob_bids_10_TokenB() public {
        vm.prank(bob);
        swap.bid(address(tokenB), 10 ether);
    }

    function bob_cancels_Swap() public {
        vm.prank(bob);
        swap.cancel();
    }

    function alice_fulfills_Swap() public {
        vm.prank(alice);
        swap.swap();
    }

}