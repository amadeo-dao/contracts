// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/staking/Dividends.sol";

contract DividendsTest is Test {
    Dividends public dividends;

    MockERC20 asset;
    MockERC20 rewards1;

    address public deployer;
    address public alice;
    address public bob;
    address public charles;

    uint256 bobsAssetBalance;
    uint256 contractsAssetBalance;

    uint256 bobsRewards1Balance;
    uint256 charlesRewards1Balance;
    uint256 contractRewards1Balance;

    uint256 bobsShares;
    uint256 totalShares;

    function save_state() public {
        bobsAssetBalance = asset.balanceOf(bob);
        contractsAssetBalance = asset.balanceOf(address(dividends));
        bobsShares = dividends.balanceOf(bob);
        totalShares = dividends.totalSupply();

        bobsRewards1Balance = rewards1.balanceOf(bob);
        charlesRewards1Balance = rewards1.balanceOf(bob);
        contractRewards1Balance = rewards1.balanceOf(address(dividends));
    }

    function setUp() public {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charles = makeAddr("charles");

        asset = new MockERC20("Staking Asset", "STAKED");
        rewards1 = new MockERC20("Rewards #1", "REWARDS1");

        vm.startPrank(deployer);
        dividends = new Dividends();
        dividends.initialize(alice, address(asset), "Staked Asset", "xSTAKED");
        vm.stopPrank();

        vm.startPrank(alice);
        dividends.whitelistAddress(bob);
        dividends.whitelistAddress(charles);
        vm.stopPrank();

        assertEq(dividends.manager(), alice, "Alice is not manager");
        assertEq(dividends.asset(), address(asset), "Staking Asset is not set");
        assertTrue(dividends.isWhitelisted(bob), "Bob is not whitelisted");
        assertTrue(dividends.isWhitelisted(charles), "Charles is not whitelisted");

        asset.mint(bob, 10000 ether);
        asset.mint(charles, 10000 ether);
        rewards1.mint(alice, 10000 ether);

        vm.prank(bob);
        asset.approve(address(dividends), 10000 ether);
        vm.prank(charles);
        asset.approve(address(dividends), 10000 ether);
        vm.prank(alice);
        rewards1.approve(address(dividends), 10000 ether);
    }

    function test_FullLifecycle() public {
        save_state();

        vm.prank(bob);
        dividends.deposit(bob, 1000 ether);
        assertEq(asset.balanceOf(bob), bobsAssetBalance - 1000 ether, "Bob did not deposit 1000 tokens");
        assertEq(
            asset.balanceOf(address(dividends)),
            contractsAssetBalance + 1000 ether,
            "Contract did not receive 1000 tokens"
        );
        assertEq(dividends.balanceOf(bob), bobsShares + 1000 ether, "Bob did not receive enogh shares");
        assertEq(dividends.totalSupply(), totalShares + 1000 ether, "Total shares are incorrect");

        vm.prank(alice);
        dividends.payout(100 ether, address(rewards1));
        assertEq(rewards1.balanceOf(address(dividends)), 100 ether, "Contract did not receive 100 rewards");

        save_state();

        vm.prank(bob);
        dividends.claim(bob, address(rewards1));
        assertEq(rewards1.balanceOf(bob), bobsRewards1Balance + 100 ether, "Bob did not receive any reward1 tokens");
        assertEq(
            rewards1.balanceOf(address(dividends)),
            contractRewards1Balance - 100 ether,
            "Contract did not send correct number of reward1 tokens"
        );

        vm.prank(charles);
        dividends.deposit(charles, 200 ether);

        vm.prank(alice);
        dividends.payout(240 ether, address(rewards1));

        save_state();
        vm.prank(bob);
        dividends.claim(bob, address(rewards1));
        assertEq(
            rewards1.balanceOf(bob),
            bobsRewards1Balance + 200 ether,
            "Bob did not receive the correct share of rewards"
        );
        vm.prank(charles);
        uint256 claimable = dividends.claimable(charles, address(rewards1));
        console.log(claimable);
        dividends.claim(charles, address(rewards1));
        assertEq(
            rewards1.balanceOf(charles),
            charlesRewards1Balance + 40 ether,
            "Charles did not receive the correct share of rewards"
        );
    }
}
