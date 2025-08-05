// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Marketplace} from "../contracts/Marketplace.sol";
import {IMarketPlace} from "../contracts/interfaces/IMarketplace.sol";
import {CommunityChest} from "../contracts/CommunityChest.sol";

contract MarketplaceTest is Test {
    Marketplace marketplace;

    uint256 public constant FEE = 200;

    address public OWNER = makeAddr("owner");
    address public ADMIN = makeAddr("admin");
    address public MINTER = makeAddr("minter");

    function setUp() external {
        address[] memory paymentsToken = new address[](1);
        paymentsToken[0] = address(0);

        vm.prank(OWNER);
        marketplace = new Marketplace(FEE, paymentsToken);
    }

    /////////////////////
    /// createListing ///
    /////////////////////

    function test_createListing_Success(address token) external {
        address seller = makeAddr("seller");

        uint256 tokenId = 200;

        uint256 price = 2.5 ether;

        mockContracts(token, seller);

        vm.prank(seller);
        marketplace.createListing(token, tokenId, price);

        //Assert
        IMarketPlace.Listing memory listing = marketplace.getListing(
            token,
            tokenId
        );

        assertEq(seller, listing.seller);
        assertEq(address(0), listing.paymentToken);
        assertEq(price, listing.price);
    }

    function test_createListing_Fail_NotApproved(address token) external {}

    function test_purchaseListing_Success(address token) external {
        address seller = makeAddr("seller");
        address buyer = makeAddr("buyer");

        uint256 tokenId = 0;

        uint256 price = 2.5 ether;

        CommunityChest nft = new CommunityChest(ADMIN, MINTER);

        vm.prank(MINTER);
        nft.safeMintLevel1(seller);

        vm.startPrank(seller);

        nft.approve(address(marketplace), tokenId);

        marketplace.createListing(address(nft), tokenId, price);

        vm.stopPrank();
        deal(buyer, price);

        vm.prank(buyer);
        marketplace.purchaseListing{value: price}(address(nft), tokenId);
    }

    function mockContracts(address token, address owner) internal {
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC721.ownerOf.selector),
            abi.encode(owner)
        );

        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC721.isApprovedForAll.selector),
            abi.encode(true)
        );
    }
}
