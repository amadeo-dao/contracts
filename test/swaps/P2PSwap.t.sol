// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../utils/P2PSwapUtils.sol";
import "../../src/swaps/P2PSwap.sol";

contract P2PSwapTest is P2PSwapUtils {

    function setUp() public {
        reset_Swap();
        assertTrue(swap.swapState() == P2PSwap.SwapState.Uninitialized, "swap is in unitialized state before ask");
    }

    function test_Alice_fulffils_Swap() public {
        
        alice_offers_10_TokenA_to_Bob();
        assertTrue(swap.swapState() == P2PSwap.SwapState.Ask, "swap is in ask state after alice offers 10 TOKA to bob");
        assertEq(swap.seller(), alice, "seller is alice after alice offers 10 TOKA to bob");
        assertEq(address(swap.sellToken()), address(tokenA), "sell token is TOKA  after alice offers 10 TOKA to bob");
        assertEq(swap.sellAmount(), 10 ether, "sell amount is 10 TOKA  after alice offers 10 TOKA to bob");

        uint256 alicesBalanceA = tokenA.balanceOf(alice);
        uint256 bobsBalanceA = tokenA.balanceOf(bob);
        uint256 alicesBalanceB = tokenB.balanceOf(alice);
        uint256 bobsBalanceB = tokenB.balanceOf(bob);
        bob_bids_10_TokenB();
        assertTrue(swap.swapState() == P2PSwap.SwapState.Bid, "swap is in bid state after bob bids 10 TOKB");
        assertEq(swap.buyer(), bob, "buyer is bob after bob bids 10 TOKB");
        assertEq(address(swap.bidToken()), address(tokenB), "bid token is TOKB after bob bids 10 TOKB");
        assertEq(tokenB.balanceOf(bob), bobsBalanceB - 10 ether, "bobs balance TOKB is down 10 TOKB after bob bids 10 TOKB");
        assertEq(tokenB.balanceOf(address(swap)), 10 ether, "swap contract owns 10 TOKB after bob bids 10 TOKB");
        assertEq(tokenA.balanceOf(alice), alicesBalanceA, "alices balance TOKA is uneffected after bob bids 10 TOKB");
        assertEq(tokenA.balanceOf(bob), bobsBalanceA, "bobs balance TOKA is uneffected after bob bids 10 TOKB");

        alicesBalanceA = tokenA.balanceOf(alice);
        bobsBalanceA = tokenA.balanceOf(bob);
        alicesBalanceB = tokenB.balanceOf(alice);
        bobsBalanceB = tokenB.balanceOf(bob);
        alice_fulfills_Swap();

        assertTrue(swap.swapState() == P2PSwap.SwapState.Fulfilled, "swap is in fulfilled state after alice fulfills the swap");
        assertEq(tokenA.balanceOf(alice), alicesBalanceA - 10 ether, "alice is down 10 TOKA after alice fulfills the swap");
        assertEq(tokenA.balanceOf(bob), bobsBalanceA + 10 ether, "bob is up 10 TOKA after alice fulfills the swap");
        assertEq(tokenA.balanceOf(address(swap)), 0, "swap contract has no more TOKA after alice fulfills the swap");

        assertEq(tokenB.balanceOf(address(alice)), alicesBalanceB + 10 ether, "alice is up 10 TOKB after alice fulfills the swap");
        assertEq(tokenB.balanceOf(address(bob)), bobsBalanceB, "bobs balance of TOKB is uneffected after alice fulfills the swap");
        assertEq(tokenB.balanceOf(address(swap)), 0, "swap contract has no more TOKB after alice fulfills the swap");
    }

    function test_Bob_Cancels_Swap() public {
        alice_offers_10_TokenA_to_Bob();
        bob_bids_10_TokenB();
        
        uint256 bobsBalanceB = tokenB.balanceOf(bob);
        bob_cancels_Swap();
        assertTrue(swap.swapState() == P2PSwap.SwapState.Cancelled, "swap state is cancelled after bob cancels swap");
        assertEq(tokenB.balanceOf(bob), bobsBalanceB + 10 ether, "bob gets his funds back after bob cancels swap");
    }

    function test_Swap_State_Failures() public {


        // Swap.State === Uninitialized
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        bob_bids_10_TokenB();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        bob_cancels_Swap();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        alice_fulfills_Swap();


        // Swap.State === Ask
        alice_offers_10_TokenA_to_Bob();
        
        vm.expectRevert(bytes("P2P: swap already initialized"));
        alice_offers_10_TokenA_to_Bob();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        bob_cancels_Swap();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        alice_fulfills_Swap();


        // Swap.State === Bid
        bob_bids_10_TokenB();

        vm.expectRevert(bytes("P2P: swap already initialized"));
        alice_offers_10_TokenA_to_Bob();
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        bob_bids_10_TokenB();

        // Swap.State === Cancelled
        bob_cancels_Swap();

        vm.expectRevert(bytes("P2P: swap already initialized"));
        alice_offers_10_TokenA_to_Bob();
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        bob_bids_10_TokenB();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        bob_cancels_Swap();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        alice_fulfills_Swap();

        // Swap.State === Fulfilled
        reset_Swap();
        alice_offers_10_TokenA_to_Bob();
        bob_bids_10_TokenB();
        alice_fulfills_Swap();

        vm.expectRevert(bytes("P2P: swap already initialized"));
        alice_offers_10_TokenA_to_Bob();
        vm.expectRevert(bytes("P2P: swap not in ask mode"));
        bob_bids_10_TokenB();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        bob_cancels_Swap();
        vm.expectRevert(bytes("P2P: swap not in bid mode"));
        alice_fulfills_Swap();
    }

    function test_Swap_Permissions_Failure() public {
        alice_offers_10_TokenA_to_Bob();
        
        vm.prank(alice);
        vm.expectRevert(bytes("P2PSwap: only allowed for buyer"));
        swap.bid(address(tokenB), 10 ether);

        bob_bids_10_TokenB();
        vm.prank(alice);
        vm.expectRevert(bytes("P2PSwap: only allowed for buyer"));
        swap.cancel();

        vm.prank(bob);
        vm.expectRevert(bytes("P2PSwap: only allowed for seller"));
        swap.swap();
    }

}
