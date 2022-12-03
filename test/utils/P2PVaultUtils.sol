// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/vaults/P2PVault.sol";

contract P2PVaultUtils is Test {
    
    P2PVault public vault;

    MockERC20 public asset;
    
    address public deployer;
    address public alice;
    address public bob;
    address public charles;

    constructor() {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charles = makeAddr("charles");

        asset = new MockERC20("Asset Token", "ASS");
        asset.mint(alice, 100000 ether);
        asset.mint(bob, 100000 ether);
        asset.mint(charles, 100000 ether);
    }

  function reset_Vault() public {
        vm.startPrank(deployer);
        vault = new P2PVault();

        // Initializing
        vault.initialize(address(asset), "Test Vault", "VAULT");
        assertEq(vault.asset(), address(asset), "vault asset is not asset token");
        assertEq(vault.name(), "Test Vault");
        assertEq(vault.symbol(), "VAULT");

        // Set manager
        vault.setManager(alice);
        assertEq(vault.manager(), alice, "vault manager is mot alice");

        // Shares and asset balances are zero
        assertEq(asset.balanceOf(address(vault)), 0, "asset token balance of vault is not 0");
        assertEq(vault.totalSupply(), 0, "vault total supply is not 0");


        vm.stopPrank();
        vm.startPrank(alice);

        // Adding shareholders
        vault.whitelistShareholder(bob);
        asset.approve(address(vault), 10000 ether);
        assertTrue(vault.isShareholder(bob), "Bob is no shareholder");
        assertEq(vault.shareholders(), 1, "there is not only one shareholder");
        assertEq(vault.shareholder(0), bob, "First shareholder is not Bob");

        vault.whitelistShareholder(charles);
        asset.approve(address(vault), 10000 ether);
        assertTrue(vault.isShareholder(charles), "Charles is no shareholder");
        assertEq(vault.shareholders(), 2, "there is not only one shareholder");
        assertEq(vault.shareholder(1), charles, "Second shareholder is not Charles");

        vm.stopPrank();

        // Approve token allowance for bob's assets
        vm.prank(bob);
        asset.approve(address(vault), 10000 ether);
    }


}
