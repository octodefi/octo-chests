// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ICommunityChestRedeem {
    /// @notice Emitted when a token is redeemed
    event Redeemed(
        address indexed user,
        uint256 indexed tokenId,
        uint256 payout
    );

    /// @notice Emitted when redeem tokens are deposited
    event Deposit(address indexed from, uint256 amount);

    /// @notice Emitted when redeem tokens are withdrawn
    event Withdraw(address indexed to, uint256 amount);

    /// @notice Emitted when payouts are updated
    event PayoutsUpdated(uint256 level1Payout, uint256 level2Payout);

    /// @notice Error when caller is not the NFT owner
    error NotTokenOwner();

    /// @notice Error when contract balance is insufficient
    error InsufficientBalance();

    /// @notice Error when token transfer fails
    error TokenTransferFailed();

    function redeem(uint256 tokenId) external;

    function depositRedeemToken(uint256 amount) external;

    function withdrawRedeemToken(uint256 amount) external;

    function setPayouts(uint256 _level1Payout, uint256 _level2Payout) external;
}
