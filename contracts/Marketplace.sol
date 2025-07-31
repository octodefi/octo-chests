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

    uint256 private s_fee;

    mapping(address token => bool valid) private s_paymentTokens;

    // Map each NFT contract + tokenId pair to its listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    /* ====== Modifiers ====== */

    modifier isNFTOwner(address token, uint256 tokenId) {
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

    modifier isNotListed(address token, uint256 tokenId) {
        if (s_listings[token][tokenId].price > 0) {
            revert ListingAlreadyExist();
        }
        _;
    }

    modifier isListed(address token, uint256 tokenId) {
        if (s_listings[token][tokenId].price == 0) {
            revert ListingDoesNotExist();
        }
        _;
    }

    modifier isApproved(address token, uint256 tokenId) {
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
        uint256 fee,
        address[] memory paymentTokens
    ) Ownable(msg.sender) {
        _isValidFee(fee);

        s_fee = fee;
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            s_paymentTokens[paymentTokens[i]] = true;
        }

        emit FeeSet(fee);
    }

    function createListing(
        address token,
        uint256 tokenId,
        uint256 price
    )
        external
        isNFTOwner(token, tokenId)
        validPrice(price)
        isNotListed(token, tokenId)
        isApproved(token, tokenId)
    {
        _createListing(token, tokenId, price, address(0));
    }

    function createListingWithToken(
        address token,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    )
        external
        isNFTOwner(token, tokenId)
        validPrice(price)
        isNotListed(token, tokenId)
        isApproved(token, tokenId)
        isValidPaymentToken(paymentToken)
    {
        _createListing(token, tokenId, price, paymentToken);
    }

    function cancelListing(
        address token,
        uint256 tokenId
    ) external isNFTOwner(token, tokenId) isListed(token, tokenId) {
        delete s_listings[token][tokenId];

        emit ListingCancelled(msg.sender, token, tokenId);
    }

    function updateListing(
        address token,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isNFTOwner(token, tokenId)
        isListed(token, tokenId)
        validPrice(newPrice)
    {
        s_listings[token][tokenId].price = newPrice;

        emit ListingUpdated(msg.sender, token, tokenId, newPrice);
    }

    function purchaseListing(
        address token,
        uint256 tokenId
    ) external payable isListed(token, tokenId) {
        uint256 amount = msg.value;

        Listing memory listing = s_listings[token][tokenId];

        if (listing.paymentToken != address(0)) {
            revert NoValidPaymentToken();
        }

        if (amount < listing.price) {
            revert NotEnoughFundsSupplied();
        }

        uint256 netAmount = _executePurchase(
            token,
            amount,
            tokenId,
            listing.seller
        );

        emit ListingPurchased(
            msg.sender,
            listing.seller,
            token,
            tokenId,
            address(0)
        );

        (bool sent, ) = payable(listing.seller).call{value: netAmount}("");
        if (!sent) revert FailedToSendCoins();
    }

    function purchaseListingWithToken(
        address token,
        uint256 tokenId
    ) external isListed(token, tokenId) {
        Listing memory listing = s_listings[token][tokenId];

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
            token,
            listing.price,
            tokenId,
            listing.seller
        );
        emit ListingPurchased(
            msg.sender,
            listing.seller,
            token,
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
    ) external onlyOwner paymentTokenDoesNotExist(_token) {
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
        address token,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    ) internal {
        s_listings[token][tokenId] = Listing({
            price: price,
            seller: msg.sender,
            paymentToken: paymentToken
        });

        emit ListingCreated(msg.sender, token, tokenId, price, paymentToken);
    }

    function _executePurchase(
        address token,
        uint256 price,
        uint256 tokenId,
        address seller
    ) internal returns (uint256 netPrice) {
        delete s_listings[token][tokenId];

        IERC721(token).safeTransferFrom(seller, msg.sender, tokenId);

        netPrice = price - (price * s_fee) / FEE_MULTIPLIER;
    }

    /* ====== View / Pure Functions ====== */

    function getFee() external view returns (uint256) {
        return s_fee;
    }

    function getListing(
        address token,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[token][tokenId];
    }

    function isPaymentToken(address _token) external view returns (bool) {
        return s_paymentTokens[_token];
    }
}
