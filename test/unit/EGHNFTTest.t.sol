// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { EGHNFT } from "../../src/token/EGHNFT.sol";

contract EGHNFTTest is Test {
    EGHNFT public eghNFT;
    address public owner;
    address public user1;
    address public user2;
    address public operator;

    string public constant TOKEN_URI_1 = "https://example.com/token/1";
    string public constant TOKEN_URI_2 = "https://example.com/token/2";
    string public constant TOKEN_URI_3 = "https://example.com/token/3";

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        operator = makeAddr("operator");

        vm.prank(owner);
        eghNFT = new EGHNFT("Egghead NFT", "EGHNFT");
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    function testConstructorSetsNameAndSymbol() public view {
        assertEq(eghNFT.name(), "Egghead NFT");
        assertEq(eghNFT.symbol(), "EGHNFT");
    }

    function testConstructorSetsOwner() public view {
        assertEq(eghNFT.owner(), owner);
    }

    function testConstructorSetsInitialSupplyToZero() public view {
        assertEq(eghNFT.totalSupply(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                               MINT TESTS
    //////////////////////////////////////////////////////////////*/
    function testMint() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        assertEq(eghNFT.ownerOf(tokenId), user1);
        assertEq(eghNFT.balanceOf(user1), 1);
        assertEq(eghNFT.totalSupply(), 1);
        assertEq(eghNFT.tokenURI(tokenId), TOKEN_URI_1);
    }

    function testMintEmitsTokenMintedEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit TokenMinted(user1, 0);
        eghNFT.mint(user1, TOKEN_URI_1);
    }

    function testMintEmitsTransferEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), user1, 0);
        eghNFT.mint(user1, TOKEN_URI_1);
    }

    function testMintRevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        eghNFT.mint(user2, TOKEN_URI_1);
    }

    function testMintRevertsIfToIsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(EGHNFT.EGHNFT__NotZeroAddress.selector);
        eghNFT.mint(address(0), TOKEN_URI_1);
    }

    function testMintMultipleTokens() public {
        vm.startPrank(owner);
        uint256 tokenId1 = eghNFT.mint(user1, TOKEN_URI_1);
        uint256 tokenId2 = eghNFT.mint(user2, TOKEN_URI_2);
        uint256 tokenId3 = eghNFT.mint(user1, TOKEN_URI_3);
        vm.stopPrank();

        assertEq(eghNFT.ownerOf(tokenId1), user1);
        assertEq(eghNFT.ownerOf(tokenId2), user2);
        assertEq(eghNFT.ownerOf(tokenId3), user1);
        assertEq(eghNFT.balanceOf(user1), 2);
        assertEq(eghNFT.balanceOf(user2), 1);
        assertEq(eghNFT.totalSupply(), 3);
    }

    function testMintIncrementsTokenCounter() public {
        vm.startPrank(owner);
        uint256 tokenId1 = eghNFT.mint(user1, TOKEN_URI_1);
        uint256 tokenId2 = eghNFT.mint(user2, TOKEN_URI_2);
        vm.stopPrank();

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
    }

    /*//////////////////////////////////////////////////////////////
                             TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/
    function testTransfer() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        eghNFT.transfer(user2, tokenId);

        assertEq(eghNFT.ownerOf(tokenId), user2);
        assertEq(eghNFT.balanceOf(user1), 0);
        assertEq(eghNFT.balanceOf(user2), 1);
    }

    function testTransferEmitsTransferEvent() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user2, tokenId);
        eghNFT.transfer(user2, tokenId);
    }

    function testTransferRevertsIfNotOwner() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user2);
        vm.expectRevert();
        eghNFT.transfer(user2, tokenId);
    }

    function testTransferRevertsIfToIsZeroAddress() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        vm.expectRevert(EGHNFT.EGHNFT__NotZeroAddress.selector);
        eghNFT.transfer(address(0), tokenId);
    }

    function testTransferRevertsIfTokenDoesNotExist() public {
        vm.prank(user1);
        vm.expectRevert(EGHNFT.EGHNFT__TokenDoesNotExist.selector);
        eghNFT.transfer(user2, 999);
    }

    function testTransferToSelf() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        eghNFT.transfer(user1, tokenId);

        assertEq(eghNFT.ownerOf(tokenId), user1);
        assertEq(eghNFT.balanceOf(user1), 1);
    }

    /*//////////////////////////////////////////////////////////////
                          TRANSFERFROM TESTS
    //////////////////////////////////////////////////////////////*/
    function testTransferFrom() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        eghNFT.approve(operator, tokenId);

        vm.prank(operator);
        eghNFT.transferFrom(user1, user2, tokenId);

        assertEq(eghNFT.ownerOf(tokenId), user2);
        assertEq(eghNFT.balanceOf(user1), 0);
        assertEq(eghNFT.balanceOf(user2), 1);
    }

    function testTransferFromEmitsTransferEvent() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        eghNFT.approve(operator, tokenId);

        vm.prank(operator);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user2, tokenId);
        eghNFT.transferFrom(user1, user2, tokenId);
    }

    function testTransferFromRevertsIfNotApproved() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(operator);
        vm.expectRevert();
        eghNFT.transferFrom(user1, user2, tokenId);
    }

    function testTransferFromRevertsIfToIsZeroAddress() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        eghNFT.approve(operator, tokenId);

        vm.prank(operator);
        vm.expectRevert(EGHNFT.EGHNFT__NotZeroAddress.selector);
        eghNFT.transferFrom(user1, address(0), tokenId);
    }

    function testTransferFromRevertsIfTokenDoesNotExist() public {
        vm.prank(user1);
        vm.expectRevert(EGHNFT.EGHNFT__TokenDoesNotExist.selector);
        eghNFT.transferFrom(user1, user2, 999);
    }

    function testTransferFromByOwner() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        eghNFT.transferFrom(user1, user2, tokenId);

        assertEq(eghNFT.ownerOf(tokenId), user2);
    }

    /*//////////////////////////////////////////////////////////////
                             APPROVE TESTS
    //////////////////////////////////////////////////////////////*/
    function testApprove() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        eghNFT.approve(operator, tokenId);

        assertEq(eghNFT.getApproved(tokenId), operator);
    }

    function testApproveEmitsApprovalEvent() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit Approval(user1, operator, tokenId);
        eghNFT.approve(operator, tokenId);
    }

    function testApproveRevertsIfNotOwner() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user2);
        vm.expectRevert();
        eghNFT.approve(operator, tokenId);
    }

    function testApproveRevertsIfTokenDoesNotExist() public {
        vm.prank(user1);
        vm.expectRevert(EGHNFT.EGHNFT__TokenDoesNotExist.selector);
        eghNFT.approve(operator, 999);
    }

    function testApproveCanBeUpdated() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        address newOperator = makeAddr("newOperator");

        vm.startPrank(user1);
        eghNFT.approve(operator, tokenId);
        assertEq(eghNFT.getApproved(tokenId), operator);

        eghNFT.approve(newOperator, tokenId);
        assertEq(eghNFT.getApproved(tokenId), newOperator);
        vm.stopPrank();
    }

    function testApproveCanBeCleared() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.startPrank(user1);
        eghNFT.approve(operator, tokenId);
        assertEq(eghNFT.getApproved(tokenId), operator);

        eghNFT.approve(address(0), tokenId);
        assertEq(eghNFT.getApproved(tokenId), address(0));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        SETAPPROVALFORALL TESTS
    //////////////////////////////////////////////////////////////*/
    function testSetApprovalForAll() public {
        vm.prank(owner);
        uint256 tokenId1 = eghNFT.mint(user1, TOKEN_URI_1);
        uint256 tokenId2 = eghNFT.mint(user1, TOKEN_URI_2);

        vm.prank(user1);
        eghNFT.setApprovalForAll(operator, true);

        assertTrue(eghNFT.isApprovedForAll(user1, operator));

        vm.prank(operator);
        eghNFT.transferFrom(user1, user2, tokenId1);

        vm.prank(operator);
        eghNFT.transferFrom(user1, user2, tokenId2);

        assertEq(eghNFT.balanceOf(user1), 0);
        assertEq(eghNFT.balanceOf(user2), 2);
    }

    function testSetApprovalForAllEmitsEvent() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(user1, operator, true);
        eghNFT.setApprovalForAll(operator, true);
    }

    function testSetApprovalForAllCanBeRevoked() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.startPrank(user1);
        eghNFT.setApprovalForAll(operator, true);
        assertTrue(eghNFT.isApprovedForAll(user1, operator));

        eghNFT.setApprovalForAll(operator, false);
        assertFalse(eghNFT.isApprovedForAll(user1, operator));
        vm.stopPrank();

        vm.prank(operator);
        vm.expectRevert();
        eghNFT.transferFrom(user1, user2, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            TOKENURI TESTS
    //////////////////////////////////////////////////////////////*/
    function testTokenURI() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        assertEq(eghNFT.tokenURI(tokenId), TOKEN_URI_1);
    }

    function testTokenURIRevertsIfTokenDoesNotExist() public {
        vm.expectRevert();
        eghNFT.tokenURI(999);
    }

    function testSetTokenURI() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        string memory newURI = "https://example.com/token/new";
        vm.prank(owner);
        eghNFT.setTokenURI(tokenId, newURI);

        assertEq(eghNFT.tokenURI(tokenId), newURI);
    }

    function testSetTokenURIRevertsIfNotOwner() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        vm.prank(user1);
        vm.expectRevert();
        eghNFT.setTokenURI(tokenId, TOKEN_URI_2);
    }

    function testSetTokenURIRevertsIfTokenDoesNotExist() public {
        vm.prank(owner);
        vm.expectRevert(EGHNFT.EGHNFT__TokenDoesNotExist.selector);
        eghNFT.setTokenURI(999, TOKEN_URI_1);
    }

    /*//////////////////////////////////////////////////////////////
                          INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    function testCompleteWorkflow() public {
        // 1. Owner mints token to user1
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);
        assertEq(eghNFT.ownerOf(tokenId), user1);
        assertEq(eghNFT.balanceOf(user1), 1);

        // 2. User1 transfers token to user2
        vm.prank(user1);
        eghNFT.transfer(user2, tokenId);
        assertEq(eghNFT.ownerOf(tokenId), user2);
        assertEq(eghNFT.balanceOf(user2), 1);

        // 3. User2 approves operator
        vm.prank(user2);
        eghNFT.approve(operator, tokenId);
        assertEq(eghNFT.getApproved(tokenId), operator);

        // 4. Operator transfers token back to user1
        vm.prank(operator);
        eghNFT.transferFrom(user2, user1, tokenId);
        assertEq(eghNFT.ownerOf(tokenId), user1);
        assertEq(eghNFT.balanceOf(user1), 1);
        assertEq(eghNFT.balanceOf(user2), 0);
    }

    function testMultipleTokensWithApprovalForAll() public {
        vm.startPrank(owner);
        uint256 tokenId1 = eghNFT.mint(user1, TOKEN_URI_1);
        uint256 tokenId2 = eghNFT.mint(user1, TOKEN_URI_2);
        uint256 tokenId3 = eghNFT.mint(user1, TOKEN_URI_3);
        vm.stopPrank();

        vm.prank(user1);
        eghNFT.setApprovalForAll(operator, true);

        vm.startPrank(operator);
        eghNFT.transferFrom(user1, user2, tokenId1);
        eghNFT.transferFrom(user1, user2, tokenId2);
        eghNFT.transferFrom(user1, user2, tokenId3);
        vm.stopPrank();

        assertEq(eghNFT.balanceOf(user1), 0);
        assertEq(eghNFT.balanceOf(user2), 3);
    }

    /*//////////////////////////////////////////////////////////////
                            EDGE CASES
    //////////////////////////////////////////////////////////////*/
    function testOwnerOfRevertsIfTokenDoesNotExist() public {
        vm.expectRevert();
        eghNFT.ownerOf(999);
    }

    function testBalanceOfZeroAddress() public view {
        assertEq(eghNFT.balanceOf(address(0)), 0);
    }

    function testGetApprovedReturnsZeroIfNotApproved() public {
        vm.prank(owner);
        uint256 tokenId = eghNFT.mint(user1, TOKEN_URI_1);

        assertEq(eghNFT.getApproved(tokenId), address(0));
    }

    function testIsApprovedForAllReturnsFalseInitially() public view {
        assertFalse(eghNFT.isApprovedForAll(user1, operator));
    }
}
