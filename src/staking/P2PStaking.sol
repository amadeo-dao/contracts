// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/math/DecimalMath.sol";

/**
 * @title ERC20MultiDividendable
 * @dev Implements an ERC20Mintable token with a dividend distribution procedure for dividendTokens received
 * @notice This contract was implemented from algorithms proposed by Nick Johnson here: https://medium.com/@weka/dividend-bearing-tokens-on-ethereum-42d01c710657
 */
contract P2PStaking is ERC20Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using DecimalMath for uint256;

    IERC20Upgradeable private _asset;

    mapping(address => uint256) public dividendsPerToken;
    mapping(address => mapping(address => uint256)) public lastDPT;
    mapping(uint256 => address) public dividendTokens;
    uint256 public tokenIndex;

    function initialize(address asset_, string memory name_, string memory symbol_) public initializer {
        __ERC20_init(name_, symbol_);
        _asset = IERC20Upgradeable(asset_);
    }

    /**
     * @notice Send dividendTokens to this function in order to increase the dividends pool
     * @dev Must have approved this contract to spend amount of dividendToken from msg.sender
     * @param amount The amount of dividendTokens to transfer from msg.sender to this contract
     * @param dividendToken The address of the token you wish to transfer to this contract
     */
    function releaseDividends(uint256 amount, address dividendToken) external virtual {
        resolveDividendToken(dividendToken);
        IERC20Upgradeable(dividendToken).transferFrom(msg.sender, address(this), amount);
        uint256 releasedDividends = amount.divd(this.totalSupply(), this.decimals());
        dividendsPerToken[dividendToken] = dividendsPerToken[dividendToken].add(releasedDividends);
    }

    /**
     * @dev Function to update an account
     * @param account The account to update
     * @param dividendToken The address of the token you wish to transfer to this contract
     * @notice Will revert if account need not be updated
     */
    function claimDividends(address payable account, address dividendToken) public virtual returns (uint256) {
        uint owing = dividendsOwing(account, dividendToken);
        if (owing == 0) return 0;
        lastDPT[account][dividendToken] = dividendsPerToken[dividendToken];
        IERC20Upgradeable(dividendToken).transfer(account, owing);
        return owing;
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

    /**
     * @dev Internal function to compute dividends owing to an account
     * @param account The account for which to compute the dividends
     * @param dividendToken The address of the token you wish to transfer to this contract
     */
    function dividendsOwing(address account, address dividendToken) internal view returns (uint256) {
        uint256 owedDividendsPerToken = dividendsPerToken[dividendToken].subd(lastDPT[account][dividendToken]);
        return this.balanceOf(account).muld(owedDividendsPerToken, this.decimals());
    }

    function deposit(address account_, uint256 amount_) public {
        _asset.safeTransferFrom(_msgSender(), address(this), amount_);
        _mint(account_, amount_);
    }

    function withdraw(address account_, uint256 amount_) public {
        // _asset.safeTransfer(account_, _msgSender(), amount_); // ???
    }

    function asset() public view returns (address) {
        return address(_asset);
    }
}
