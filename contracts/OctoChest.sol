// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title OctoChest NFT Contract
/// @author 3Blocks
/// @notice ERC721 NFT contract with enumerable and burnable functionality. Each NFT is randomly assigned one of 20 images stored on IPFS.
/// @dev Uses OpenZeppelin Contracts v5.0 with AccessControl, ERC721Enumerable, and ERC721Burnable.
contract OctoChest is ERC721, ERC721Burnable, AccessControl, ERC721Enumerable {
    /// @notice Base URI for all token metadata, pointing to IPFS
    string private constant BASE_URI =
        "ipfs://QmZS34ktG626a3Gqu7CC3QiHeRtVWQzDSt7LsDGHuZoJzw/";

    // ┏━━━━━━━━━━━━━━━━━━━━┓
    // ┃       Errors       ┃
    // ┗━━━━━━━━━━━━━━━━━━━━┛

    /// @notice Error thrown when querying a nonexistent token
    error OctoChestDontExist();

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃       StateVariable       ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @notice Role identifier for accounts that can mint new tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Tracks the next token ID to be minted
    uint256 private _nextTokenId;

    /// @dev Maps each token ID to its randomly assigned image number (1–20)
    mapping(uint256 tokenId => uint8 imageNumber) private _imageNumbers;

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃       Constructor       ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @notice Initializes the contract with admin and minter roles
    /// @param defaultAdmin The address that will be granted the DEFAULT_ADMIN_ROLE
    /// @param minter The address that will be granted the MINTER_ROLE
    constructor(
        address defaultAdmin,
        address minter
    ) ERC721("OctoChest", "OC") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃       Mint Functions: Level 1 & 2     ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @notice Mints a new Level 1 NFT to the specified address
    /// @dev Level 1 NFTs use images 1 through 5
    /// @param to The address that will receive the newly minted NFT
    /// @return tokenId The ID of the newly minted token
    function safeMintLevel1(
        address to
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        return _mintWithRange(to, 1, 5); // Images 1–5
    }

    /// @notice Mints a new Level 2 NFT to the specified address
    /// @dev Level 2 NFTs use images 6 through 20
    /// @param to The address that will receive the newly minted NFT
    /// @return tokenId The ID of the newly minted token
    function safeMintLevel2(
        address to
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        return _mintWithRange(to, 6, 20); // Images 6–20
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃     Private Functions     ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @inheritdoc ERC721Enumerable
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    /// @inheritdoc ERC721Enumerable
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _mintWithRange(
        address to,
        uint8 min,
        uint8 max
    ) internal returns (uint256) {
        require(min < max && max <= 20, "Invalid image range");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        uint8 imageNumber = uint8(
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, to, tokenId))
            ) % (max - min + 1)) + min
        );
        _imageNumbers[tokenId] = imageNumber;

        return tokenId;
    }

    function _tokenExist(uint256 tokenId) internal view {
        if (_ownerOf(tokenId) == address(0)) {
            revert OctoChestDontExist();
        }
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃     View / Pure Functions     ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    /// @notice Returns the base URI used to construct `tokenURI`
    /// @return The base IPFS URI
    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    /// @notice Returns the token URI for a given token ID
    /// @dev Reverts if the token does not exist
    /// @param tokenId The ID of the token
    /// @return The full IPFS URI pointing to the token's metadata JSON
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _tokenExist(tokenId);

        uint8 imageNumber = _imageNumbers[tokenId];

        string memory stringNumber = Strings.toString(imageNumber);

        return string(abi.encodePacked(_baseURI(), stringNumber, ".json"));
    }

    /// @notice Indicates which interfaces are supported by this contract
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the interface is supported
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function imageNumberOf(uint256 tokenId) external view returns (uint8) {
        _tokenExist(tokenId);

        return _imageNumbers[tokenId];
    }
}
