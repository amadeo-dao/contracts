// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/math/DecimalMath.sol";

import "../utils/access/Whitelistable.sol";

contract Dividends is ERC20Upgradeable, Whitelistable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using DecimalMath for uint256;

    IERC20Upgradeable private _asset;

    mapping(address => uint256) public dividendsPerToken;
    mapping(address => mapping(address => uint256)) public lastDPT;
    mapping(uint256 => address) public dividendTokens;
    uint256 public tokenIndex;

    function initialize(
        address manager_,
        address asset_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Whitelistable_init(manager_);
        _asset = IERC20Upgradeable(asset_);
    }

    function payout(uint256 amount, address dividendToken) external virtual onlyManager {
        resolveDividendToken(dividendToken);
        IERC20Upgradeable(dividendToken).transferFrom(msg.sender, address(this), amount);
        uint256 releasedDividends = amount.divd(this.totalSupply(), this.decimals());
        dividendsPerToken[dividendToken] = dividendsPerToken[dividendToken].add(releasedDividends);
    }

    function claim(address account, address dividendToken) public virtual returns (uint256) {
        uint owing = claimable(account, dividendToken);
        if (owing == 0) return 0;
        lastDPT[account][dividendToken] = dividendsPerToken[dividendToken];
        IERC20Upgradeable(dividendToken).transfer(account, owing);
        return owing;
    }

    function claimAll(address account_) public virtual {
        for (uint256 i = 0; i < tokenIndex; i++) {
            claim(account_, dividendTokens[i]);
        }
    }

    function resolveDividendToken(address dividendToken) internal {
        for (uint256 i = 0; i < tokenIndex; i++) {
            if (dividendTokens[i] == dividendToken) {
                return;
            }
        }
        dividendTokens[tokenIndex] = dividendToken;
        tokenIndex = tokenIndex + 1;
    }

    function claimable(address account, address dividendToken) public view returns (uint256) {
        uint256 owedDividendsPerToken = dividendsPerToken[dividendToken].subd(lastDPT[account][dividendToken]);
        return this.balanceOf(account).muld(owedDividendsPerToken, this.decimals());
    }

    function deposit(address account_, uint256 amount_) public onlyWhitelisted {
        _asset.safeTransferFrom(_msgSender(), address(this), amount_);
        _mint(account_, amount_);
        claimAll(account_);
    }

    function withdraw(address recipient_, uint256 amount_) public {
        require(balanceOf(_msgSender()) >= amount_, "P2PStaking: Insufficient staking balance");
        _asset.safeTransfer(recipient_, amount_); // ???
        _burn(_msgSender(), amount_);
    }

    function asset() public view returns (address) {
        return address(_asset);
    }
}
