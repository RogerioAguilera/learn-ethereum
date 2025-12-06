// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Marketplace} from "../src/Marketplace.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    constructor() ERC721("Test NFT", "TNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    TestNFT public testNft;
    address public seller = address(0x1);
    address public buyer = address(0x2);
    uint256 public tokenId = 1;
    uint256 public price = 1 ether;

    function setUp() public {
        marketplace = new Marketplace();
        testNft = new TestNFT();
        vm.deal(seller, 10 ether);
        vm.deal(buyer, 10 ether);

        vm.startPrank(seller);
        testNft.mint(seller, tokenId);
        testNft.setApprovalForAll(address(marketplace), true);
        vm.stopPrank();
    }

    function test_ListItem() public {
        vm.prank(seller);
        marketplace.listItem(address(testNft), tokenId, price);
        (address listingSeller, , , uint256 listingPrice) = marketplace.listings(
            address(testNft),
            tokenId
        );
        assertEq(listingSeller, seller);
        assertEq(listingPrice, price);
    }

    function test_BuyItem() public {
        vm.prank(seller);
        marketplace.listItem(address(testNft), tokenId, price);

        vm.prank(buyer, buyer);
        marketplace.buyItem{value: price}(address(testNft), tokenId);

        (, , , uint256 listingPrice) = marketplace.listings(address(testNft), tokenId);
        assertEq(listingPrice, 0);
    }

    function test_CancelListing() public {
        vm.prank(seller);
        marketplace.listItem(address(testNft), tokenId, price);
        marketplace.cancelListing(address(testNft), tokenId);

        (, , , uint256 listingPrice) = marketplace.listings(address(testNft), tokenId);
        assertEq(listingPrice, 0);
    }

    function test_UpdateListing() public {
        uint256 newPrice = 2 ether;
        vm.prank(seller);
        marketplace.listItem(address(testNft), tokenId, price);
        marketplace.updateListing(address(testNft), tokenId, newPrice);

        (, , , uint256 listingPrice) = marketplace.listings(address(testNft), tokenId);
        assertEq(listingPrice, newPrice);
    }

    function test_WithdrawProceeds() public {
        vm.prank(seller);
        marketplace.listItem(address(testNft), tokenId, price);

        vm.prank(buyer, buyer);
        marketplace.buyItem{value: price}(address(testNft), tokenId);

        uint256 sellerBalanceBefore = seller.balance;
        vm.prank(seller);
        marketplace.withdrawProceeds();
        
        assertEq(seller.balance, sellerBalanceBefore + price);
    }
}
