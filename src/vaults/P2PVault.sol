// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract P2PVault is AccessControlEnumerableUpgradeable, ERC4626Upgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SHAREHOLDER_ROLE = keccak256("SHAREHOLDER_ROLE");


    uint256 public _assetsInUse;

    event WhitelistShareholder(address indexed newShareholder);
    event RevokeShareholder(address indexed newShareholder);

    event ChangeManager(address indexed newManager, address indexed oldManager);

    event UseAssets(uint256 amount);
    event ReturnAssets(uint256 amount);
    event Gains(uint256 amount);
    event Loss(uint256 amount);
    event Fees(uint256 amount);

    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        __AccessControl_init();
        __ERC20_init(name_, symbol_);
        __ERC4626_init(IERC20Upgradeable(asset_));
    }

    function manager() public view returns (address) {
        return getRoleMember(MANAGER_ROLE, 0);
    }

    function setManager(address newManager_) public onlyRole(MANAGER_ROLE) {
        require(newManager_ != address(0), "P2PVault: Manager cannot be null");
        require(!hasRole(SHAREHOLDER_ROLE, newManager_), "P2PVault: Shareholder cannot be manager");
        emit ChangeManager(newManager_, manager());
        _revokeRole(MANAGER_ROLE, manager());
        _grantRole(MANAGER_ROLE, newManager_);
    }

    function isShareholder(address address_) public view returns(bool) {
        return hasRole(SHAREHOLDER_ROLE, address_);
    }

    function shareholders() public view returns (uint256) {
        return getRoleMemberCount(SHAREHOLDER_ROLE);
    }

    function shareholder(uint256 index) public view returns (address) {
        return getRoleMember(SHAREHOLDER_ROLE, index);
    }

    function whitelistShareholder(address address_) public onlyRole(MANAGER_ROLE) {
        require(address_ != address(0), "P2PVault: Shareholder cannot be null");
        require(!hasRole(SHAREHOLDER_ROLE, _msgSender()), "P2PVault: Manager cannot be shareholder");
        _grantRole(SHAREHOLDER_ROLE, address_);
        emit WhitelistShareholder(address_);
    }

    function revokeShareholder(address address_) public onlyRole(MANAGER_ROLE) {
        emit RevokeShareholder(address_);
        _revokeRole(SHAREHOLDER_ROLE, address_);
    }

    function useAssets(uint256 amount_) public onlyRole(MANAGER_ROLE) {
        IERC20Upgradeable(asset()).safeTransfer(_msgSender(), amount_);
        _assetsInUse += amount_;
        emit UseAssets(amount_);
    }

    function returnAssets(uint256 amount_) public onlyRole(MANAGER_ROLE) {
        IERC20Upgradeable(asset()).safeTransferFrom(
            _msgSender(),
            address(this),
            amount_
        );
        _assetsInUse = amount_ > _assetsInUse ? 0 : (_assetsInUse - amount_);
        emit ReturnAssets(amount_);
    }

    function gains(uint256 amount_) public onlyRole(MANAGER_ROLE) {
        _assetsInUse += amount_;
        emit Gains(amount_);
    }

    function loss(uint256 amount_) public onlyRole(MANAGER_ROLE) {
        require(amount_<= _assetsInUse, "P2PVault: Loss cannot be higher than assets in use.");
        _assetsInUse -= amount_;
        emit Loss(amount_);
    }

    function fees(uint256 amount_) public onlyRole(MANAGER_ROLE) {
        require(amount_<= _assetsInUse, "P2PVault: Fees cannot be higher than assets in use.");
        _assetsInUse -= amount_;
        emit Fees(amount_);
    }

    function assetsInUse() public view virtual returns (uint256) {
        return _assetsInUse;
    }

    function totalAssets() public view virtual override returns (uint256) {
        return IERC20Upgradeable(asset()).balanceOf(address(this)) + _assetsInUse;
    }

    function maxWithdraw(
        address address_
    ) public view virtual override returns (uint256) {
        uint256 shares =  balanceOf(address_);
        uint256 assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);
        uint256 vaultBalance = IERC20Upgradeable(asset()).balanceOf(
            address(this)
        );
        return MathUpgradeable.min(assets, vaultBalance);
    }

    function maxRedeem(
        address owner_
    ) public view virtual override returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner_);
        return _convertToShares(maxAssets, MathUpgradeable.Rounding.Down);
    }

}
