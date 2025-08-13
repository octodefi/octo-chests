// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CommunityChest} from "./CommunityChest.sol";
import {ICommunityChestRedeem} from "./interfaces/ICommunityChestRedeem.sol";

/// @title CommunityChestRedeem
/// @notice Allows NFT owners to burn their CommunityChest NFTs in exchange for USDC payouts
contract CommunityChestRedeem is Ownable, ICommunityChestRedeem {
    IERC20 public immutable redeemToken;
    CommunityChest public immutable communityChest;

    uint256 public level1Payout;
    uint256 public level2Payout;

    /// @param _redeemToken Address of the redeem token contract
    /// @param _communityChest Address of the CommunityChest NFT contract
    /// @param _level1Payout Payout for image numbers 1–5 (in smallest redeem token unit)
    /// @param _level2Payout Payout for image numbers 6–20 (in smallest redeem token unit)
    constructor(
        address _redeemToken,
        address _communityChest,
        uint256 _level1Payout,
        uint256 _level2Payout
    ) Ownable(msg.sender) {
        redeemToken = IERC20(_redeemToken);
        communityChest = CommunityChest(_communityChest);
        _setPayouts(_level1Payout, _level2Payout);
    }

    /// @inheritdoc ICommunityChestRedeem
    function redeem(uint256 tokenId) external override {
        if (communityChest.ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }

        uint8 imageNum = communityChest.imageNumberOf(tokenId);
        uint256 payout = (imageNum >= 1 && imageNum <= 5)
            ? level1Payout
            : level2Payout;

        if (redeemToken.balanceOf(address(this)) < payout) {
            revert InsufficientBalance();
        }

        communityChest.burn(tokenId);

        if (!redeemToken.transfer(msg.sender, payout)) {
            revert TokenTransferFailed();
        }

        emit Redeemed(msg.sender, tokenId, payout);
    }

    /// @inheritdoc ICommunityChestRedeem
    function depositRedeemToken(uint256 amount) external override {
        if (!redeemToken.transferFrom(msg.sender, address(this), amount)) {
            revert TokenTransferFailed();
        }
        emit Deposit(msg.sender, amount);
    }

    /// @inheritdoc ICommunityChestRedeem
    function withdrawRedeemToken(uint256 amount) external override onlyOwner {
        if (!redeemToken.transfer(msg.sender, amount)) {
            revert TokenTransferFailed();
        }
        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc ICommunityChestRedeem
    function setPayouts(
        uint256 _level1Payout,
        uint256 _level2Payout
    ) external override onlyOwner {
        _setPayouts(_level1Payout, _level2Payout);
    }

    function _setPayouts(
        uint256 _level1Payout,
        uint256 _level2Payout
    ) internal {
        level1Payout = _level1Payout;
        level2Payout = _level2Payout;
        emit PayoutsUpdated(_level1Payout, _level2Payout);
    }
}
