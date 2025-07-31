// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {CommunityChest} from "contracts/CommunityChest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CommunityChestTest is Test {
    address public ADMIN = makeAddr("admin");
    address public MINTER = makeAddr("minter");

    CommunityChest nft;

    function setUp() external {
        nft = new CommunityChest(ADMIN, MINTER);
    }

    ////////////////
    /// safeMint ///
    ////////////////

    function test_safeMintLevel1_Success() external {
        address receiver = makeAddr("reveiver");

        vm.prank(MINTER);
        uint256 tokenId = nft.safeMintLevel1(receiver);

        // Act
        string memory tokenUri = nft.tokenURI(tokenId);

        // Assert
        uint8 imageNumber = nft.imageNumberOf(tokenId); // you may need to expose this if private
        string memory expectedUri = string(
            abi.encodePacked(
                "ipfs://QmdscVX4s73EqpxWUwa1g445CGizwV5EWHf1eCmiJm1zF1/",
                Strings.toString(imageNumber),
                ".json"
            )
        );
        assertEq(tokenUri, expectedUri);
    }
}
