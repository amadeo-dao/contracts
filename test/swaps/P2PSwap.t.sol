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

    function test_swapModes() public {
        // Setup token balances and allowances
        tokenA.mint(alice, 100000 ether);
        vm.prank(alice);
        tokenA.approve(address(swap), 100000 ether);
        tokenB.mint(bob, 100000 ether);
        vm.prank(bob);
        tokenB.approve(address(swap), 100000 ether);
        assertTrue(swap.swapState() == P2PSwap.SwapState.Uninitialized);
        
        // Swap.State === Uninitialized
        vm.startPrank(bob);
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        swap.bid(address(tokenB), 10000 ether);
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap.cancel();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap.swap();
        vm.stopPrank();


        // Swap.State === Ask
        vm.startPrank(alice);
        tokenA.mint(alice, 100 ether);
        swap.ask(bob, address(tokenA), 100 ether);
        vm.stopPrank();
        vm.startPrank(alice);
        vm.expectRevert(bytes("P2P: swap already initialized"));
        swap.ask(bob, address(tokenB), 10000 ether);
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap.cancel();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap.swap();
        vm.stopPrank();

        // Swap.State === Bid
        vm.startPrank(bob);
        swap.bid(address(tokenB), 10000 ether);
        vm.stopPrank();
        vm.startPrank(alice);
        vm.expectRevert(bytes("P2P: swap already initialized"));
        swap.ask(bob, address(tokenB), 10000 ether);
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        swap.bid(address(tokenB), 10000 ether);
        vm.stopPrank();

        // Swap.State === Cancelled
        vm.prank(bob);
        swap.cancel();
        vm.startPrank(alice);
        vm.expectRevert(bytes("P2P: swap already initialized"));
        swap.ask(bob, address(tokenB), 10000 ether);
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap.swap();
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        swap.bid(address(tokenB), 10000 ether);
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap.cancel();
        vm.stopPrank();

        // Swap.State === Fulfilled
        P2PSwap swap2 = new P2PSwap();
        vm.prank(alice);
        tokenA.approve(address(swap2), 100000 ether);

        vm.prank(bob);
        tokenB.approve(address(swap2), 100000 ether);

        vm.prank(alice);
        swap2.ask(bob, address(tokenA), 10 ether);
        vm.prank(bob);
        swap2.bid(address(tokenB), 10 ether);
        vm.prank(alice);
        swap2.swap();
        assertTrue(swap2.swapState() == P2PSwap.SwapState.Fulfilled);
        vm.startPrank(alice);
        vm.expectRevert(bytes("P2P: swap already initialized"));
        swap2.ask(bob, address(tokenB), 10000 ether);
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap2.swap();
        vm.stopPrank();
        
        vm.startPrank(bob);
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        swap2.bid(address(tokenB), 10000 ether);
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        swap2.cancel();
        vm.stopPrank();

    }
}
