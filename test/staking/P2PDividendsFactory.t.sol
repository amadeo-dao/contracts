// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "../../src/staking/P2PDividendsFactory.sol";
import "../../src/staking/P2PDividends.sol";

contract P2PDividendsFactoryTest is Test {
    P2PDividends vault;
    P2PDividendsFactory factory;

    MockERC20 asset;

    address deployer;
    address alice;

    function setUp() public {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");

        asset = new MockERC20("Token A", "TOKA");

        vm.startPrank(deployer);
        vault = new P2PDividends();
        factory = new P2PDividendsFactory(address(vault));
    }

    function test_Create_P2PDividends() public {
        address proxy = factory.create(alice, address(asset));
        vm.stopPrank();
        assertTrue(proxy != address(0));
        assertEq(P2PDividends(proxy).manager(), alice, "Contract manager is not Alice");
        assertEq(P2PDividends(proxy).asset(), address(asset), "Contract asset is not correct");
    }
}
