// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { EGH } from "../../src/token/EGH.sol";

contract EGHTest is Test {
    EGH public egh;
    address public owner;
    address public user1;
    address public user2;
    address public spender;

    uint256 public constant INITIAL_MINT_AMOUNT = 1000 ether;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensMinted(address indexed to, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        spender = makeAddr("spender");

        vm.prank(owner);
        egh = new EGH("Egghead Token", "EGH");
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    function testConstructorSetsNameAndSymbol() public view {
        assertEq(egh.name(), "Egghead Token");
        assertEq(egh.symbol(), "EGH");
    }

    function testConstructorSetsDecimals() public view {
        assertEq(egh.decimals(), 18);
    }

    function testConstructorSetsOwner() public view {
        assertEq(egh.owner(), owner);
    }

    function testConstructorSetsInitialSupplyToZero() public view {
        assertEq(egh.totalSupply(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                               MINT TESTS
    //////////////////////////////////////////////////////////////*/
    function testMint() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        assertEq(egh.balanceOf(user1), INITIAL_MINT_AMOUNT);
        assertEq(egh.totalSupply(), INITIAL_MINT_AMOUNT);
    }

    function testMintEmitsTokensMintedEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit TokensMinted(user1, INITIAL_MINT_AMOUNT);
        egh.mint(user1, INITIAL_MINT_AMOUNT);
    }

    function testMintEmitsTransferEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, INITIAL_MINT_AMOUNT);
        egh.mint(user1, INITIAL_MINT_AMOUNT);
    }

    function testMintRevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        egh.mint(user2, INITIAL_MINT_AMOUNT);
    }

    function testMintRevertsIfAmountIsZero() public {
        vm.prank(owner);
        vm.expectRevert(EGH.EGH__MustBeMoreThanZero.selector);
        egh.mint(user1, 0);
    }

    function testMintRevertsIfToIsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(EGH.EGH__NotZeroAddress.selector);
        egh.mint(address(0), INITIAL_MINT_AMOUNT);
    }

    function testMintRevertsIfExceedsMaxSupply() public {
        uint256 amountToMint = MAX_SUPPLY + 1;
        vm.prank(owner);
        vm.expectRevert(EGH.EGH__MintAmountExceedsMaxSupply.selector);
        egh.mint(user1, amountToMint);
    }

    function testMintCanReachMaxSupply() public {
        vm.prank(owner);
        egh.mint(user1, MAX_SUPPLY);

        assertEq(egh.totalSupply(), MAX_SUPPLY);
        assertEq(egh.balanceOf(user1), MAX_SUPPLY);
    }

    function testMintMultipleTimes() public {
        vm.startPrank(owner);
        egh.mint(user1, 100 ether);
        egh.mint(user2, 200 ether);
        egh.mint(user1, 50 ether);
        vm.stopPrank();

        assertEq(egh.balanceOf(user1), 150 ether);
        assertEq(egh.balanceOf(user2), 200 ether);
        assertEq(egh.totalSupply(), 350 ether);
    }

    /*//////////////////////////////////////////////////////////////
                             TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/
    function testTransfer() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        uint256 transferAmount = 100 ether;
        vm.prank(user1);
        egh.transfer(user2, transferAmount);

        assertEq(egh.balanceOf(user1), INITIAL_MINT_AMOUNT - transferAmount);
        assertEq(egh.balanceOf(user2), transferAmount);
    }

    function testTransferEmitsTransferEvent() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        uint256 transferAmount = 100 ether;
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, transferAmount);
        egh.transfer(user2, transferAmount);
    }

    function testTransferRevertsIfInsufficientBalance() public {
        vm.prank(owner);
        egh.mint(user1, 100 ether);

        vm.prank(user1);
        vm.expectRevert();
        egh.transfer(user2, 200 ether);
    }

    function testTransferRevertsIfToIsZeroAddress() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(user1);
        vm.expectRevert();
        egh.transfer(address(0), 100 ether);
    }

    function testTransferToSelf() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        uint256 transferAmount = 100 ether;
        vm.prank(user1);
        egh.transfer(user1, transferAmount);

        assertEq(egh.balanceOf(user1), INITIAL_MINT_AMOUNT);
    }

    function testTransferReturnsTrue() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(user1);
        bool success = egh.transfer(user2, 100 ether);
        assertTrue(success);
    }

    /*//////////////////////////////////////////////////////////////
                             APPROVE TESTS
    //////////////////////////////////////////////////////////////*/
    function testApprove() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        uint256 approveAmount = 500 ether;
        vm.prank(user1);
        egh.approve(spender, approveAmount);

        assertEq(egh.allowance(user1, spender), approveAmount);
    }

    function testApproveEmitsApprovalEvent() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        uint256 approveAmount = 500 ether;
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Approval(user1, spender, approveAmount);
        egh.approve(spender, approveAmount);
    }

    function testApproveCanBeUpdated() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.startPrank(user1);
        egh.approve(spender, 100 ether);
        assertEq(egh.allowance(user1, spender), 100 ether);

        egh.approve(spender, 200 ether);
        assertEq(egh.allowance(user1, spender), 200 ether);
        vm.stopPrank();
    }

    function testApproveReturnsTrue() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(user1);
        bool success = egh.approve(spender, 100 ether);
        assertTrue(success);
    }

    function testAllowanceInitiallyZero() public view {
        assertEq(egh.allowance(user1, spender), 0);
    }

    /*//////////////////////////////////////////////////////////////
                          TRANSFERFROM TESTS
    //////////////////////////////////////////////////////////////*/
    function testTransferFrom() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        uint256 approveAmount = 500 ether;
        uint256 transferAmount = 300 ether;

        vm.prank(user1);
        egh.approve(spender, approveAmount);

        vm.prank(spender);
        egh.transferFrom(user1, user2, transferAmount);

        assertEq(egh.balanceOf(user1), INITIAL_MINT_AMOUNT - transferAmount);
        assertEq(egh.balanceOf(user2), transferAmount);
        assertEq(egh.allowance(user1, spender), approveAmount - transferAmount);
    }

    function testTransferFromEmitsTransferEvent() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(user1);
        egh.approve(spender, 500 ether);

        uint256 transferAmount = 300 ether;
        vm.prank(spender);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, transferAmount);
        egh.transferFrom(user1, user2, transferAmount);
    }

    function testTransferFromRevertsIfInsufficientAllowance() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(user1);
        egh.approve(spender, 100 ether);

        vm.prank(spender);
        vm.expectRevert();
        egh.transferFrom(user1, user2, 200 ether);
    }

    function testTransferFromRevertsIfInsufficientBalance() public {
        vm.prank(owner);
        egh.mint(user1, 100 ether);

        vm.prank(user1);
        egh.approve(spender, 200 ether);

        vm.prank(spender);
        vm.expectRevert();
        egh.transferFrom(user1, user2, 200 ether);
    }

    function testTransferFromRevertsIfNoAllowance() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(spender);
        vm.expectRevert();
        egh.transferFrom(user1, user2, 100 ether);
    }

    function testTransferFromCanUseFullAllowance() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        uint256 approveAmount = 500 ether;
        vm.prank(user1);
        egh.approve(spender, approveAmount);

        vm.prank(spender);
        egh.transferFrom(user1, user2, approveAmount);

        assertEq(egh.allowance(user1, spender), 0);
        assertEq(egh.balanceOf(user2), approveAmount);
    }

    function testTransferFromReturnsTrue() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(user1);
        egh.approve(spender, 500 ether);

        vm.prank(spender);
        bool success = egh.transferFrom(user1, user2, 300 ether);
        assertTrue(success);
    }

    /*//////////////////////////////////////////////////////////////
                          INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    function testCompleteWorkflow() public {
        // 1. Owner mints tokens to user1
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);
        assertEq(egh.balanceOf(user1), INITIAL_MINT_AMOUNT);

        // 2. User1 transfers some tokens to user2
        vm.prank(user1);
        egh.transfer(user2, 200 ether);
        assertEq(egh.balanceOf(user1), 800 ether);
        assertEq(egh.balanceOf(user2), 200 ether);

        // 3. User1 approves spender
        vm.prank(user1);
        egh.approve(spender, 300 ether);
        assertEq(egh.allowance(user1, spender), 300 ether);

        // 4. Spender transfers from user1 to user2
        vm.prank(spender);
        egh.transferFrom(user1, user2, 150 ether);
        assertEq(egh.balanceOf(user1), 650 ether);
        assertEq(egh.balanceOf(user2), 350 ether);
        assertEq(egh.allowance(user1, spender), 150 ether);
    }

    function testMultipleSpenders() public {
        address spender2 = makeAddr("spender2");

        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.startPrank(user1);
        egh.approve(spender, 300 ether);
        egh.approve(spender2, 400 ether);
        vm.stopPrank();

        assertEq(egh.allowance(user1, spender), 300 ether);
        assertEq(egh.allowance(user1, spender2), 400 ether);

        vm.prank(spender);
        egh.transferFrom(user1, user2, 200 ether);

        vm.prank(spender2);
        egh.transferFrom(user1, user2, 300 ether);

        assertEq(egh.balanceOf(user1), 500 ether);
        assertEq(egh.balanceOf(user2), 500 ether);
        assertEq(egh.allowance(user1, spender), 100 ether);
        assertEq(egh.allowance(user1, spender2), 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            EDGE CASES
    //////////////////////////////////////////////////////////////*/
    function testMaxSupplyEdgeCase() public {
        vm.startPrank(owner);
        egh.mint(user1, MAX_SUPPLY / 2);
        egh.mint(user2, MAX_SUPPLY / 2);
        vm.stopPrank();

        assertEq(egh.totalSupply(), MAX_SUPPLY);

        // Should revert if trying to mint even 1 wei more
        vm.prank(owner);
        vm.expectRevert(EGH.EGH__MintAmountExceedsMaxSupply.selector);
        egh.mint(user1, 1);
    }

    function testAllowanceAfterTransferFrom() public {
        vm.prank(owner);
        egh.mint(user1, INITIAL_MINT_AMOUNT);

        vm.prank(user1);
        egh.approve(spender, 500 ether);

        vm.prank(spender);
        egh.transferFrom(user1, user2, 200 ether);

        // Allowance should be reduced
        assertEq(egh.allowance(user1, spender), 300 ether);

        // Can still transfer remaining allowance
        vm.prank(spender);
        egh.transferFrom(user1, user2, 300 ether);

        assertEq(egh.allowance(user1, spender), 0);
    }
}
