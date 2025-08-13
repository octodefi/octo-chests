// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {CommunityChestRedeem} from "../contracts/CommunityChestRedeem.sol";
import {CommunityChest} from "../contracts/CommunityChest.sol";
import {ICommunityChestRedeem} from "../contracts/interfaces/ICommunityChestRedeem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract CommunityChestRedeemTest is Test {
    CommunityChestRedeem public redeem;
    CommunityChest public chest;
    MockUSDC public usdc;

    address public ADMIN = makeAddr("admin");
    address public MINTER = makeAddr("minter");
    address public USER = makeAddr("user");

    uint256 public constant LEVEL_1_PAYOUT = 10e6;
    uint256 public constant LEVEL_2_PAYOUT = 20e6;

    function setUp() public {
        usdc = new MockUSDC();
        chest = new CommunityChest(ADMIN, MINTER);

        vm.prank(ADMIN);
        redeem = new CommunityChestRedeem(
            address(usdc),
            address(chest),
            LEVEL_1_PAYOUT,
            LEVEL_2_PAYOUT
        );
    }

    function test_redeem_Success() external {
        vm.prank(MINTER);
        uint256 tokenId = chest.safeMintLevel1(USER);

        deal(address(usdc), address(redeem), LEVEL_1_PAYOUT);

        vm.startPrank(USER);
        chest.approve(address(redeem), tokenId);
        redeem.redeem(tokenId);
        vm.stopPrank();

        uint256 tokens = chest.balanceOf(USER);

        assertEq(tokens, 0);
        assertEq(usdc.balanceOf(USER), LEVEL_1_PAYOUT);
    }

    function test_redeem_Fail_NotApproved() external {
        vm.prank(MINTER);
        uint256 tokenId = chest.safeMintLevel1(USER);

        deal(address(usdc), address(redeem), LEVEL_1_PAYOUT);

        vm.startPrank(USER);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InsufficientApproval.selector,
                address(redeem),
                tokenId
            )
        );
        redeem.redeem(tokenId);
        vm.stopPrank();
    }

    function test_depositRedeemToken_Success(uint256 amount) external {
        deal(address(usdc), USER, amount);
        vm.startPrank(USER);
        usdc.approve(address(redeem), amount);
        redeem.depositRedeemToken(amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(redeem)), amount);
    }

    function test_withdrawRedeemToken(uint256 amount) external {
        deal(address(usdc), address(redeem), amount);

        vm.startPrank(ADMIN);
        redeem.withdrawRedeemToken(amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(redeem)), 0);
        assertEq(usdc.balanceOf(ADMIN), amount);
    }
}

/// @title MockUSDC
/// @notice A simple mock version of USDC for testing purposes
contract MockUSDC is ERC20 {
    uint8 private constant DECIMALS = 6;

    constructor() ERC20("USD Coin", "USDC") {
        // Optionally mint some tokens to the deployer for testing
        _mint(msg.sender, 1_000_000 * 10 ** DECIMALS); // 1,000,000 USDC
    }

    /// @notice Mint new tokens (for testing only)
    /// @param to The address to receive the tokens
    /// @param amount The amount to mint (in smallest unit, e.g. 1 USDC = 1e6)
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @inheritdoc ERC20
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
}
