// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMarketPlace} from "./interfaces/IMarketplace.sol";

contract Marketplace is Ownable, IMarketPlace {
    /* ====== State Variables ====== */
    uint256 public constant MAX_FEE = 500;
    uint256 public constant FEE_MULTIPLIER = 10000;

    address private immutable token;
    uint256 private s_fee;

    mapping(address token => bool valid) private s_paymentTokens;
    mapping(uint256 tokenId => Listing info) private s_listings;

    /* ====== Modifiers ====== */

    modifier isOctoOwner(uint256 tokenId) {
        if (IERC721(token).ownerOf(tokenId) != msg.sender) {
            revert NotTheOwner(tokenId, msg.sender);
        }
        _;
    }

    modifier validPrice(uint256 price) {
        if (price == 0) {
            revert ZeroPriceNotAllowed();
        }
        _;
    }

    modifier isNotListed(uint256 tokenId) {
        if (s_listings[tokenId].price > 0) {
            revert ListingAlreadyExist();
        }
        _;
    }

    modifier isListed(uint256 tokenId) {
        if (s_listings[tokenId].price == 0) {
            revert ListingDoesNotExist();
        }
        _;
    }

    modifier isApproved(uint256 tokenId) {
        if (
            !IERC721(token).isApprovedForAll(msg.sender, address(this)) &&
            IERC721(token).getApproved(tokenId) != address(this)
        ) {
            revert TokenNotApproved(tokenId);
        }
        _;
    }

    modifier isValidPaymentToken(address _token) {
        if (!s_paymentTokens[_token]) {
            revert NoValidPaymentToken();
        }
        _;
    }

    modifier paymentTokenDoesNotExist(address _token) {
        if (s_paymentTokens[_token]) {
            revert PaymentTokenAlreadyExist();
        }
        _;
    }

    constructor(
        address _token,
        uint256 fee,
        address[] memory paymentTokens
    ) Ownable(msg.sender) {
        _isValidFee(fee);

        token = _token;
        s_fee = fee;
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            s_paymentTokens[paymentTokens[i]] = true;
        }

        emit FeeSet(fee);
    }

    function createListing(
        uint256 tokenId,
        uint256 price
    )
        external
        isOctoOwner(tokenId)
        validPrice(price)
        isNotListed(tokenId)
        isApproved(tokenId)
    {
        _createListing(tokenId, price, address(0));
    }

    function createListingWithToken(
        uint256 tokenId,
        uint256 price,
        address paymentToken
    )
        external
        isOctoOwner(tokenId)
        validPrice(price)
        isNotListed(tokenId)
        isApproved(tokenId)
        isValidPaymentToken(paymentToken)
    {
        _createListing(tokenId, price, paymentToken);
    }

    function cancelListing(
        uint256 tokenId
    ) external isOctoOwner(tokenId) isListed(tokenId) {
        delete s_listings[tokenId];

        emit ListingCancelled(msg.sender, tokenId);
    }

    function updateListing(
        uint256 tokenId,
        uint256 newPrice
    ) external isOctoOwner(tokenId) isListed(tokenId) validPrice(newPrice) {
        s_listings[tokenId].price = newPrice;

        emit ListingUpdated(msg.sender, tokenId, newPrice);
    }

    function purchaseListing(
        uint256 tokenId
    ) external payable isListed(tokenId) {
        uint256 amount = msg.value;

        Listing memory listing = s_listings[tokenId];

        if (listing.paymentToken != address(0)) {
            revert NoValidPaymentToken();
        }

        if (amount < listing.price) {
            revert NotEnoughFundsSupplied();
        }

        uint256 netAmount = _executePurchase(amount, tokenId, listing.seller);

        emit ListingPurchased(msg.sender, listing.seller, tokenId, address(0));

        (bool sent, ) = payable(listing.seller).call{value: netAmount}("");
        if (!sent) revert FailedToSendCoins();
    }

    function purchaseListingWithToken(
        uint256 tokenId
    ) external isListed(tokenId) {
        Listing memory listing = s_listings[tokenId];

        if (listing.paymentToken == address(0)) {
            revert NoValidPaymentToken();
        }

        bool success = IERC20(listing.paymentToken).transferFrom(
            msg.sender,
            address(this),
            listing.price
        );

        if (!success) {
            revert PaymentTokenTransferFailed();
        }

        uint256 netAmount = _executePurchase(
            listing.price,
            tokenId,
            listing.seller
        );
        emit ListingPurchased(
            msg.sender,
            listing.seller,
            tokenId,
            listing.paymentToken
        );

        bool sent = IERC20(listing.paymentToken).transfer(
            listing.seller,
            netAmount
        );
        if (!sent) revert FailedToSendTokens();
    }

    /* ====== Setup Functions ====== */

    function setFee(uint256 newFee) external onlyOwner {
        _isValidFee(newFee);
        s_fee = newFee;

        emit FeeSet(newFee);
    }

    function withdraw(address _token) external onlyOwner {
        uint256 balance = address(this).balance;

        emit Withdrawal(msg.sender, balance);

        if (_token == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: balance}("");
            if (!sent) revert FailedToSendCoins();
        } else {
            uint256 tokenBalance = IERC20(_token).balanceOf(address(this));

            bool sent = IERC20(_token).transfer(msg.sender, tokenBalance);

            if (!sent) revert FailedToSendTokens();
        }
    }

    function addPaymentToken(
        address _token
    ) external onlyOwner paymentTokenDoesNotExist(token) {
        s_paymentTokens[_token] = true;

        emit NewPaymentToken(_token);
    }

    /* ====== Internal Functions ====== */

    function _isValidFee(uint256 fee) internal pure {
        if (fee > MAX_FEE) {
            revert NoValidFee();
        }
    }

    function _createListing(
        uint256 tokenId,
        uint256 price,
        address paymentToken
    ) internal {
        s_listings[tokenId] = Listing({
            price: price,
            seller: msg.sender,
            paymentToken: paymentToken
        });

        emit ListingCreated(msg.sender, tokenId, price, paymentToken);
    }

    function _executePurchase(
        uint256 price,
        uint256 tokenId,
        address seller
    ) internal returns (uint256 netPrice) {
        delete s_listings[tokenId];

        IERC721(token).safeTransferFrom(seller, msg.sender, tokenId);

        netPrice = price - (price * s_fee) / FEE_MULTIPLIER;
    }

    /* ====== View / Pure Functions ====== */

    function getFee() external view returns (uint256) {
        return s_fee;
    }

    function getNFTAddress() external view returns (address) {
        return token;
    }

    function getListing(
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[tokenId];
    }

    function isPaymentToken(address _token) external view returns (bool) {
        return s_paymentTokens[_token];
    }
}
