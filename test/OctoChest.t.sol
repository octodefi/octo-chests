// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {OctoChest} from "contracts/OctoChest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract OctoChestTest is Test {
    address public ADMIN = makeAddr("admin");
    address public MINTER = makeAddr("minter");

    OctoChest nft;

    function setUp() external {
        nft = new OctoChest(ADMIN, MINTER);
    }

    ////////////////
    /// safeMint ///
    ////////////////
    function testSafeMintLevel1() external {
        address receiver = makeAddr("reveiver");

        vm.prank(MINTER);
        uint256 tokenId = nft.safeMintLevel1(receiver);

        // Act
        string memory tokenUri = nft.tokenURI(tokenId);

        // Assert
        uint8 imageNumber = nft.imageNumberOf(tokenId); // you may need to expose this if private
        string memory expectedUri = string(
            abi.encodePacked(
                "ipfs://QmZS34ktG626a3Gqu7CC3QiHeRtVWQzDSt7LsDGHuZoJzw/",
                Strings.toString(imageNumber),
                ".json"
            )
        );
        assertEq(tokenUri, expectedUri);
    }
}
