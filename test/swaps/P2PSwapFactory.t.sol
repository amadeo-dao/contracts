// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/swaps/P2PSwapFactory.sol";
import "../../src/swaps/P2PSwap.sol";

contract P2PSwapFactoryTest is Test {
    P2PSwap swapImpl;
    P2PSwapFactory factory;

    MockERC20 tokenA;
    MockERC20 tokenB;
    MockERC20 feeToken;

    address deployer;
    address alice;
    address bob;

    function setUp() public {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        tokenA = new MockERC20("Token A", "TOKA");
        feeToken = new MockERC20("Fee Token", "FEE");

        vm.startPrank(deployer);
        swapImpl = new P2PSwap();
        factory = new P2PSwapFactory(address(swapImpl));
        vm.stopPrank();
    }

    function testCreate_createsNewSwapProxy() public {
        vm.startPrank(alice);
        P2PSwap swap = P2PSwap(factory.create());
        P2PSwap.SwapState state = swap.swapState();
        assertTrue(state == P2PSwap.SwapState.Uninitialized);
        swap.ask(bob, address(tokenA), 100 ether);

        assertTrue(swap.swapState() == P2PSwap.SwapState.Ask, "swap state should be 'ask'");
        assertEq(swap.buyer(), bob, "buyer should be Bob");
        assertEq(address(swap.sellToken()), address(tokenA), "sell token should be token A");
        assertEq(swap.sellAmount(), 100 ether, "sell amount should be 100");
        vm.stopPrank();
    }

    function testCreate_createDifferentSwapContracts() public {
        vm.startPrank(alice);
        P2PSwap swapAlice = P2PSwap(factory.create());
        P2PSwap.SwapState state = swapAlice.swapState();
        assertTrue(state == P2PSwap.SwapState.Uninitialized);
        swapAlice.ask(bob, address(tokenA), 100 ether);
        vm.stopPrank();
        assertTrue(swapAlice.swapState() == P2PSwap.SwapState.Ask, "swap state should be 'ask'");

        vm.startPrank(bob);
        P2PSwap swapBob = P2PSwap(factory.create());
        state = swapBob.swapState();
        assertTrue(state == P2PSwap.SwapState.Uninitialized, "swap state should be 'uninitialized'");
        vm.stopPrank();
    }

    function testCreate_feePayment() public {
        vm.prank(deployer);
        factory.updateFees(address(feeToken), 10 ether);

        vm.startPrank(alice);
        feeToken.mint(alice, 10 ether);
        feeToken.approve(address(factory), 10 ether);
        P2PSwap swapAlice = P2PSwap(factory.create());
        P2PSwap.SwapState state = swapAlice.swapState();
        assertTrue(state == P2PSwap.SwapState.Uninitialized);
        assertEq(feeToken.balanceOf(alice), 0);
        assertEq(feeToken.balanceOf(address(factory)), 10 ether);
        vm.stopPrank();
    }

    function testUpdateFees_ownerOnly() public {
        vm.startPrank(alice);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        factory.updateFees(address(feeToken), 10 ether);
    }

    function testCollectFees_transfersFeesToRecipient() public {
        vm.prank(deployer);
        factory.updateFees(address(feeToken), 10 ether);

        vm.startPrank(alice);
        feeToken.mint(alice, 10 ether);
        feeToken.approve(address(factory), 10 ether);
        P2PSwap(factory.create());
        vm.stopPrank();

        vm.prank(deployer);
        factory.collectFees(deployer, address(feeToken));
        assertEq(feeToken.balanceOf(deployer), 10 ether);
    }

    function testCollectFees_ownerOnly() public {
        vm.startPrank(alice);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        factory.collectFees(alice, address(feeToken));
    }
}
