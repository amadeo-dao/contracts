// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../mocks/MockERC20.sol";
import "../utils/P2PVaultUtils.sol";

contract P2PVaultTest is P2PVaultUtils {

    using Math for uint256;

    function setUp() public {
        reset_Vault();
    }

    function test_Vault_Lifecycle() public {

        uint256 alicesAssetBalance = asset.balanceOf(alice);
        uint256 bobsAssetBalance = asset.balanceOf(bob);

        // Check deposit previews.
        assertEq(vault.previewDeposit(100 ether), 100 ether, "Depositing 100 tokens does not result in 100 shares");

        // Bob invests 100 asset tokens
        vm.prank(bob);
        vault.deposit(100 ether, bob);

        assertEq(asset.balanceOf(bob), bobsAssetBalance-100 ether, "Bob has not paid 100 asset tokens");
        assertEq(asset.balanceOf(address(vault)), 100 ether, "Vault has not received 100 asset tokens");

        // Alice uses the funds from the vault
        vm.prank(alice);
        vault.useAssets(55 ether);
        
        assertEq(asset.balanceOf(alice), alicesAssetBalance + 55 ether, "Alice has not received 100 asset tokens");
        assertEq(asset.balanceOf(address(vault)), 45 ether, "Vault has not spent 100 asset tokens");
        assertEq(vault.assetsInUse(), 55 ether, "Vault assets in use is not 55 asset tokens");
        assertEq(vault.totalAssets(), 100 ether, "Total assets in vault are not 100 ether");
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 100 ether, "Assets of Bob are not 100 asset tokens");
        
        // Alice takes a fee
        vm.prank(alice);
        vault.fees(5 ether);

        assertEq(vault.assetsInUse(), 50 ether, "Fee is not removed from assets in use");
        assertEq(vault.totalAssets(), 95 ether, "Fee is not removed from vault total assets");
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), 95 ether, "Fee is not removed from Bob's shares");
        assertEq(vault.maxWithdraw(bob), 45 ether, "Bob's withdrawable funds are not 45 ether");
        // 45 tokens * 100 shares / 95 tokens
        assertEq(vault.maxRedeem(bob), uint256(45 ether).mulDiv(100 ether, 95 ether), "Bob's redeemable shares are not 45 ether");
        
        // Bob withdraws 20 asset tokens
        uint256 sharesToBurn = uint256(20 ether).mulDiv(100 ether, 95 ether, Math.Rounding.Up);
        assertEq(vault.previewWithdraw(20 ether), sharesToBurn);
        vm.prank(bob);
        vault.withdraw(20 ether, bob, bob);
        assertEq(asset.balanceOf(bob), bobsAssetBalance - 100 ether + 20 ether, "Bob did not receive 20 ether");
        assertEq(vault.balanceOf(bob), 100 ether - sharesToBurn, "Bob did not burn the correct amount of shares");

        // Bob buys 60 more shares


    }

}