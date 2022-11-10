// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/swaps/P2PSwapFactory.sol";
import "../../src/swaps/P2PSwap.sol";


contract P2PSwapTest is Test {

    P2PSwap swap;

    address deployer;
    address alice;
    address bob;

    MockERC20 tokenA;
    MockERC20 tokenB;

    function setUp() public {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        tokenA = new MockERC20("Token A", "TOKA");
        tokenB = new MockERC20("Token B", "TOKB");

        swap = new P2PSwap();
    }

    function test_fullSwap() public {
        assertTrue(swap.swapState() == P2PSwap.SwapState.Uninitialized);
        vm.startPrank(alice);
        tokenA.mint(alice, 100 ether);
        swap.ask(bob, address(tokenA), 100 ether);
        vm.stopPrank();

        assertTrue(swap.swapState() == P2PSwap.SwapState.Ask);
        assertEq(swap.seller(), alice);
        assertEq(address(swap.sellToken()), address(tokenA));
        assertEq(swap.sellAmount(), 100 ether);

        vm.startPrank(bob);
        tokenB.mint(bob, 0.5 ether);
        tokenB.approve(address(swap), 0.5 ether);
        swap.bid(address(tokenB), 0.5 ether);
        vm.stopPrank();

        assertTrue(swap.swapState() == P2PSwap.SwapState.Bid);
        assertEq(swap.buyer(), bob);
        assertEq(address(swap.bidToken()), address(tokenB));
        assertEq(tokenB.balanceOf(address(bob)), 0);
        assertEq(tokenB.balanceOf(address(swap)), 0.5 ether);

        vm.startPrank(alice);
        tokenA.approve(address(swap), 100 ether);
        swap.swap();
        vm.stopPrank();

        assertEq(tokenA.balanceOf(address(alice)), 0);
        assertEq(tokenA.balanceOf(address(bob)), 100 ether);
        assertEq(tokenA.balanceOf(address(swap)), 0);

        assertEq(tokenB.balanceOf(address(alice)), 0.5 ether);
        assertEq(tokenB.balanceOf(address(bob)), 0);
        assertEq(tokenB.balanceOf(address(swap)), 0);

        assertTrue(swap.swapState() == P2PSwap.SwapState.Fulfilled);
    }

}