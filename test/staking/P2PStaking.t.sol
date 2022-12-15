// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/staking/P2PStaking.sol";

contract P2PStakingTest is Test {
    P2PStaking public staking;

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
        contractsAssetBalance = asset.balanceOf(address(staking));
        bobsShares = staking.sharesOf(bob);
        totalShares = staking.totalShares();

        bobsRewards1Balance = rewards1.balanceOf(bob);
        charlesRewards1Balance = rewards1.balanceOf(charles);
        contractRewards1Balance = rewards1.balanceOf(address(staking));
    }

    function setUp() public {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charles = makeAddr("charles");

        asset = new MockERC20("Staking Asset", "STAKED");
        rewards1 = new MockERC20("Rewards #1", "REWARDS1");

        vm.startPrank(deployer);
        staking = new P2PStaking();
        staking.initialize(alice, address(asset));
        vm.stopPrank();

        vm.startPrank(alice);
        staking.whitelistAddress(bob);
        staking.whitelistAddress(charles);
        vm.stopPrank();

        assertEq(staking.manager(), alice, "Alice is not manager");
        assertEq(staking.asset(), address(asset), "Staking Asset is not set");
        assertTrue(staking.isWhitelisted(bob), "Bob is not whitelisted");
        assertTrue(staking.isWhitelisted(charles), "Charles is not whitelisted");

        asset.mint(bob, 10000 ether);
        asset.mint(charles, 10000 ether);
        rewards1.mint(alice, 10000 ether);

        vm.prank(bob);
        asset.approve(address(staking), 10000 ether);
        vm.prank(charles);
        asset.approve(address(staking), 10000 ether);
        vm.prank(alice);
        rewards1.approve(address(staking), 10000 ether);
    }

    function test_FullLifecycle() public {
        save_state();

        vm.prank(bob);
        staking.stake(1000 ether);
        assertEq(asset.balanceOf(bob), bobsAssetBalance - 1000 ether, "Bob did not deposit 1000 tokens");
        assertEq(
            asset.balanceOf(address(staking)),
            contractsAssetBalance + 1000 ether,
            "Contract did not receive 1000 tokens"
        );
        assertEq(staking.sharesOf(bob), bobsShares + 1000 ether, "Bob did not receive enogh shares");
        assertEq(staking.totalShares(), totalShares + 1000 ether, "Total shares are incorrect");

        vm.prank(alice);
        staking.distribute(100 ether, address(rewards1));
        assertEq(rewards1.balanceOf(address(staking)), 100 ether, "Contract did not receive 100 rewards");

        save_state();

        vm.prank(bob);
        staking.claim(address(rewards1));
        assertEq(rewards1.balanceOf(bob), bobsRewards1Balance + 100 ether, "Bob did not receive any reward1 tokens");
        assertEq(
            rewards1.balanceOf(address(staking)),
            contractRewards1Balance - 100 ether,
            "Contract did not send correct number of reward1 tokens"
        );

        vm.prank(charles);
        staking.stake(200 ether);

        vm.prank(alice);
        staking.distribute(240 ether, address(rewards1));

        save_state();
        vm.prank(bob);
        staking.claim(address(rewards1));
        assertEq(
            rewards1.balanceOf(bob),
            bobsRewards1Balance + 200 ether,
            "Bob did not receive the correct share of rewards"
        );
        vm.prank(charles);
        staking.claim(address(rewards1));
        assertEq(
            rewards1.balanceOf(charles),
            charlesRewards1Balance + 40 ether,
            "Charles did not receive the correct share of rewards"
        );

        save_state();

        vm.prank(bob);
        staking.unstake(1000 ether);
        assertEq(
            asset.balanceOf(address(staking)),
            contractsAssetBalance - 1000 ether,
            "Contract did not pay back assets"
        );
        assertEq(asset.balanceOf(bob), bobsAssetBalance + 1000 ether, "Bob did not receive his assets back");
        assertEq(staking.totalShares(), totalShares - 1000 ether, "Contract did not reduce number of shares correctly");
        assertEq(staking.sharesOf(bob), 0, "Bob has still shares");
    }
}
