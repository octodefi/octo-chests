// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IMarketPlace {
    struct Listing {
        uint256 price;
        address seller;
        address paymentToken;
    }

    /* ====== Events ====== */

    event ListingCreated(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price,
        address paymentToken
    );

    event ListingCancelled(address indexed seller, uint256 indexed tokenId);

    event ListingUpdated(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    event ListingPurchased(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        address paymentToken
    );

    event FeeSet(uint256 newFee);

    event NewPaymentToken(address token);

    event Withdrawal(address indexed by, uint256 amount);

    /* ====== Errors ====== */

    error NotTheOwner(uint256 tokenId, address sender);
    error ZeroPriceNotAllowed();
    error ListingAlreadyExist();
    error ListingDoesNotExist();
    error TokenNotApproved(uint256 tokenId);
    error NoValidPaymentToken();
    error PaymentTokenAlreadyExist();
    error NotEnoughFundsSupplied();
    error FailedToSendCoins();
    error FailedToSendTokens();
    error PaymentTokenTransferFailed();
    error NoValidFee();

    /* ====== External Functions ====== */

    function createListing(uint256 tokenId, uint256 price) external;

    function createListingWithToken(
        uint256 tokenId,
        uint256 price,
        address paymentToken
    ) external;

    function cancelListing(uint256 tokenId) external;

    function updateListing(uint256 tokenId, uint256 newPrice) external;

    function purchaseListing(uint256 tokenId) external payable;

    function purchaseListingWithToken(uint256 tokenId) external;

    function setFee(uint256 newFee) external;

    function withdraw(address _token) external;

    function addPaymentToken(address _token) external;

    /* ====== View Functions ====== */

    function getFee() external view returns (uint256);

    function getNFTAddress() external view returns (address);

    function getListing(uint256 tokenId) external view returns (Listing memory);

    function isPaymentToken(address _token) external view returns (bool);
}
