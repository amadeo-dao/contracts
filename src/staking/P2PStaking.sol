// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import "../utils/math/DecimalMath.sol";

import "../utils/access/Whitelistable.sol";

contract P2PStaking is Whitelistable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using MathUpgradeable for uint256;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using DecimalMath for uint256;

    IERC20Upgradeable private _asset;

    uint256 private _totalShares;
    EnumerableMapUpgradeable.AddressToUintMap private _shares;

    mapping(address /* account */ => mapping(address /* reward token */ => uint256)) _accountRewards;

    event Claim(address indexed account, address indexed rewardToken, uint256 amount);
    event Distribute(address indexed distributor, address indexed rewardToken, uint256 amount);
    event Stake(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);

    function initialize(address manager_, address asset_) public initializer {
        __Whitelistable_init(manager_);
        _asset = IERC20Upgradeable(asset_);
    }

    function distribute(uint256 amount_, address rewardToken_) external virtual onlyManager {
        address distributor = _msgSender();
        IERC20Upgradeable(rewardToken_).safeTransferFrom(distributor, address(this), amount_);
        for (uint256 i = 0; i < _shares.length(); i++) {
            (address account, uint256 sharesAmount) = _shares.at(i);
            uint256 rewards = amount_.mulDiv(sharesAmount, _totalShares);
            _accountRewards[account][rewardToken_] += rewards;
        }
        emit Distribute(distributor, rewardToken_, amount_);
    }

    function claimable(address account_, address rewardToken_) public view returns (uint256) {
        return _accountRewards[account_][rewardToken_];
    }

    function claim(address rewardToken_) public virtual returns (uint256) {
        address account = _msgSender();
        uint256 amount = _accountRewards[account][rewardToken_];
        if (amount > 0) {
            IERC20Upgradeable(rewardToken_).safeTransfer(account, amount);
            _accountRewards[account][rewardToken_] = 0;
        }
        emit Claim(account, rewardToken_, amount);
        return amount;
    }

    function claimAll(address account_) public virtual {}

    function stake(uint256 amount_) public onlyWhitelisted {
        address account = _msgSender();
        _asset.safeTransferFrom(account, address(this), amount_);
        (, uint256 shares) = _shares.tryGet(account);
        _shares.set(account, shares + amount_);
        _totalShares += amount_;
        emit Stake(account, amount_);
    }

    function unstake(uint256 amount_) public {
        address account = _msgSender();
        (, uint256 shares) = _shares.tryGet(account);
        require(amount_ <= shares, "P2PStaking: Insufficient staking balance");
        if (shares == amount_) _shares.remove(account);
        else _shares.set(account, shares - amount_);
        _asset.safeTransfer(account, amount_);
        _totalShares -= amount_;
        emit Unstake(account, amount_);
    }

    function asset() public view returns (address) {
        return address(_asset);
    }

    function sharesOf(address account_) public view returns (uint256 shares) {
        (, shares) = _shares.tryGet(account_);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }
}
