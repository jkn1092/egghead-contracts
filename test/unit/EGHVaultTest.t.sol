// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { EGHVault } from "../../src/token/EGHVault.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";

contract EGHVaultTest is Test {
    EGHVault public vault;
    ERC20Mock public asset;

    address public owner;
    address public user1;
    address public user2;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        asset = new ERC20Mock("Test Asset", "TST", owner, INITIAL_SUPPLY);
        vault = new EGHVault(asset, "EGH Vault Shares", "vEGH");
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    function testConstructorSetsAsset() public view {
        assertEq(vault.asset(), address(asset));
    }

    function testConstructorSetsNameAndSymbol() public view {
        assertEq(vault.name(), "EGH Vault Shares");
        assertEq(vault.symbol(), "vEGH");
    }

    function testConstructorSetsInitialState() public view {
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                               DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/
    function testDeposit() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, owner);
        vm.stopPrank();

        assertEq(vault.totalAssets(), depositAmount);
        assertEq(vault.balanceOf(owner), shares);
        assertEq(asset.balanceOf(owner), INITIAL_SUPPLY - depositAmount);
        assertEq(asset.balanceOf(address(vault)), depositAmount);
    }

    function testDepositEmitsEvent() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        vm.expectEmit(true, true, false, true);
        emit Deposit(owner, owner, depositAmount, vault.previewDeposit(depositAmount));
        vault.deposit(depositAmount, owner);
        vm.stopPrank();
    }

    function testDepositToDifferentReceiver() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        vm.stopPrank();

        assertEq(vault.balanceOf(user1), shares);
        assertEq(vault.balanceOf(owner), 0);
    }

    function testDepositReturnsPreviewDeposit() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        uint256 expectedShares = vault.previewDeposit(depositAmount);
        uint256 actualShares = vault.deposit(depositAmount, owner);
        vm.stopPrank();

        assertEq(actualShares, expectedShares);
    }

    /*//////////////////////////////////////////////////////////////
                                 MINT TESTS
    //////////////////////////////////////////////////////////////*/
    function testMint() public {
        uint256 sharesToMint = 100 ether;
        vm.startPrank(owner);
        uint256 assetsNeeded = vault.previewMint(sharesToMint);
        asset.approve(address(vault), assetsNeeded);
        uint256 assetsUsed = vault.mint(sharesToMint, owner);
        vm.stopPrank();

        assertEq(vault.balanceOf(owner), sharesToMint);
        assertEq(vault.totalAssets(), assetsUsed);
    }

    function testMintEmitsDepositEvent() public {
        uint256 sharesToMint = 100 ether;
        vm.startPrank(owner);
        uint256 assetsNeeded = vault.previewMint(sharesToMint);
        asset.approve(address(vault), assetsNeeded);
        vm.expectEmit(true, true, false, true);
        emit Deposit(owner, owner, assetsNeeded, sharesToMint);
        vault.mint(sharesToMint, owner);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/
    function testWithdraw() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, owner);
        uint256 withdrawAmount = 50 ether;
        uint256 sharesBurned = vault.withdraw(withdrawAmount, owner, owner);
        vm.stopPrank();

        assertEq(asset.balanceOf(owner), INITIAL_SUPPLY - depositAmount + withdrawAmount);
        assertEq(vault.totalAssets(), depositAmount - withdrawAmount);
        assertEq(vault.balanceOf(owner), vault.previewDeposit(depositAmount) - sharesBurned);
    }

    function testWithdrawEmitsEvent() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, owner);
        uint256 withdrawAmount = 50 ether;
        uint256 sharesBurned = vault.previewWithdraw(withdrawAmount);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(owner, owner, owner, withdrawAmount, sharesBurned);
        vault.withdraw(withdrawAmount, owner, owner);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               REDEEM TESTS
    //////////////////////////////////////////////////////////////*/
    function testRedeem() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, owner);
        uint256 redeemShares = shares / 2;
        uint256 assetsReceived = vault.redeem(redeemShares, owner, owner);
        vm.stopPrank();

        assertEq(vault.balanceOf(owner), shares - redeemShares);
        assertEq(asset.balanceOf(owner), INITIAL_SUPPLY - depositAmount + assetsReceived);
    }

    function testRedeemEmitsEvent() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, owner);
        uint256 redeemShares = shares / 2;
        uint256 assetsExpected = vault.previewRedeem(redeemShares);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(owner, owner, owner, assetsExpected, redeemShares);
        vault.redeem(redeemShares, owner, owner);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          CONVERSION TESTS
    //////////////////////////////////////////////////////////////*/
    function testConvertToShares() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, owner);
        vm.stopPrank();

        uint256 shares = vault.convertToShares(50 ether);
        assertEq(shares, vault.previewDeposit(50 ether));
    }

    function testConvertToAssets() public {
        uint256 depositAmount = 100 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, owner);
        vm.stopPrank();

        uint256 assets = vault.convertToAssets(shares / 2);
        assertEq(assets, vault.previewRedeem(shares / 2));
    }

    /*//////////////////////////////////////////////////////////////
                          INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    function testFullCycle() public {
        uint256 depositAmount = 1000 ether;
        vm.startPrank(owner);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, owner);
        assertEq(vault.balanceOf(owner), shares);
        assertEq(vault.totalAssets(), depositAmount);

        uint256 assetsOut = vault.redeem(shares, owner, owner);
        assertEq(assetsOut, depositAmount);
        assertEq(vault.balanceOf(owner), 0);
        assertEq(asset.balanceOf(owner), INITIAL_SUPPLY);
        vm.stopPrank();
    }

    function testMultipleUsers() public {
        vm.prank(owner);
        asset.transfer(user1, 500 ether);
        vm.prank(owner);
        asset.transfer(user2, 500 ether);

        vm.startPrank(user1);
        asset.approve(address(vault), 200 ether);
        uint256 shares1 = vault.deposit(200 ether, user1);
        vm.stopPrank();

        vm.startPrank(user2);
        asset.approve(address(vault), 300 ether);
        uint256 shares2 = vault.deposit(300 ether, user2);
        vm.stopPrank();

        assertEq(vault.totalAssets(), 500 ether);
        assertEq(vault.balanceOf(user1), shares1);
        assertEq(vault.balanceOf(user2), shares2);
    }
}
