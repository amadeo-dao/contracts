// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/vaults/P2PVaultFactory.sol";
import "../../src/vaults/P2PVault.sol";

contract P2PSwapFactoryTest is Test {
    P2PVault vault;
    P2PVaultFactory factory;

    MockERC20 asset;

    address deployer;
    address alice;

    function setUp() public {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");

        asset = new MockERC20("Token A", "TOKA");

        vm.startPrank(deployer);
        vault = new P2PVault();
        factory = new P2PVaultFactory(address(vault));
    }

    function test_Create_Vault() public {
        address proxy = factory.create(deployer, address(asset), "Test Vault", "VAULT");
        vm.stopPrank();
        assertTrue(proxy != address(0));
        assertEq(P2PVault(proxy).name(), "Test Vault", "Vault name does not match");
        assertEq(P2PVault(proxy).symbol(), "VAULT", "Vault symbol does not match");
        assertEq(P2PVault(proxy).asset(), address(asset), "Token address does not match");
    }
}
