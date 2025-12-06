// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => uint256) public proceeds;

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    modifier isOwner(address nftAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == spender, "Not the owner");
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.price > 0, "Not listed");
        _;
    }

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.price == 0, "Already listed");
        _;
    }

    function listItem(address nftAddress, uint256 tokenId, uint256 price)
        external
        notListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        require(price > 0, "Price must be greater than 0");
        IERC721 nft = IERC721(nftAddress);
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(tokenId) == address(this), "Not approved");

        listings[nftAddress][tokenId] = Listing(msg.sender, nftAddress, tokenId, price);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
    {
        Listing memory listing = listings[nftAddress][tokenId];
        require(msg.value == listing.price, "Incorrect price");

        delete listings[nftAddress][tokenId];
        proceeds[listing.seller] += msg.value;

        IERC721(nftAddress).safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit ItemSold(listing.seller, msg.sender, nftAddress, tokenId, listing.price);
    }

    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        delete listings[nftAddress][tokenId];
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice)
        external
        isListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        require(newPrice > 0, "Price must be greater than 0");
        listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProceeds() external {
        uint256 amount = proceeds[msg.sender];
        require(amount > 0, "No proceeds to withdraw");

        proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }
}
