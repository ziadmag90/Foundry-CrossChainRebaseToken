// SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rebase;
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("zoro");

    function addRewardsToVault(uint256 amount) public {
        // send some rewards to the vault using the receive function
        (bool success,) = payable(address(vault)).call{value: amount}("");
    }

    function setUp() public {
        vm.startPrank(owner);
        rebase = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebase)));
        rebase.grantMintAndBurnRole(address(vault));
        vm.stopPrank();
    }

    function testDepositLinear(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        // deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        // check out rebase token balance
        uint256 startBalance = rebase.balanceOf(user);
        console.log("startBalance = ", startBalance);
        assertEq(startBalance, amount);
        // warp the time and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = rebase.balanceOf(user);
        assertGt(middleBalance, startBalance);
        // warp the time again by the same amount and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebase.balanceOf(user);
        assertGt(endBalance, middleBalance);

        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);
        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        // deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertEq(rebase.balanceOf(user), amount);
        // redeem
        vault.redeem(type(uint256).max);
        assertEq(rebase.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterTimePasses(uint256 depositAmount, uint256 time) public {
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        time = bound(time, 1000, type(uint96).max);

        // deposit
        vm.deal(user, depositAmount);
        vm.prank(user);
        vault.deposit{value: depositAmount}();
        // warp the time
        vm.warp(block.timestamp + time);
        uint256 balanceAfterSomeTime = rebase.balanceOf(user);
        // add the rewards to the vault
        vm.deal(owner, balanceAfterSomeTime - depositAmount);
        vm.prank(owner);
        addRewardsToVault(balanceAfterSomeTime - depositAmount);
        // redeem
        vm.prank(user);
        vault.redeem(type(uint256).max);

        uint256 ethBalance = address(user).balance;

        // Assert
        assertEq(balanceAfterSomeTime, ethBalance);
        assertGt(ethBalance, depositAmount);
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 1e5 + 1e15, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, amount - 1e5);

        //deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        address user2 = makeAddr("user2");
        uint256 userBalance = rebase.balanceOf(user);
        uint256 user2Balance = rebase.balanceOf(user2);

        assert(userBalance == amount);
        assert(user2Balance == 0);

        // owner reduces the interest rate
        vm.prank(owner);
        rebase.setInterestRate(4e10);

        // transfer
        vm.prank(user);
        rebase.transfer(user2, amountToSend);

        uint256 userBalanceAfterTransfer = rebase.balanceOf(user);
        uint256 user2BalanceAfterTransfer = rebase.balanceOf(user2);

        // Assert
        assertEq(user2BalanceAfterTransfer, amountToSend);
        assertEq(userBalanceAfterTransfer, userBalance - amountToSend);

        assertEq(rebase.getUserInterestRate(user), 5e10);
        assertEq(rebase.getUserInterestRate(user2), 5e10);
    }

    function testCanNotSetInterestRate(uint256 newInterestRate) public {
        newInterestRate = bound(newInterestRate, 1e5, type(uint96).max);
        // define the error selector for unauthorized account
        bytes4 errorSelector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(errorSelector, user));
        vm.prank(user);
        rebase.setInterestRate(newInterestRate);
    }

    function testCanNotCallMintAndBurn(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        uint256 interestRate = rebase.getInterestRate();

        vm.prank(user);
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebase.mint(user, amount, interestRate);

        vm.prank(user);
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebase.burn(user, amount);
    }

    function testGetPrincipalAmount(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        // deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        uint256 userBalance = rebase.principalBalance(user);
        assertEq(userBalance, amount);

        vm.warp(block.timestamp + 1 hours);
        assertEq(rebase.principalBalance(user), amount);
    }

    function testGetRebaseTokenAddress() public view {
        assertEq(vault.getRebaseTokenAddress(), address(rebase));
    }

    function testInterestRateCanOnlyDecrease(uint256 newInterestRate) public {
        uint256 initialInterestRate = rebase.getInterestRate();
        newInterestRate = bound(newInterestRate, initialInterestRate, type(uint96).max);
        vm.prank(owner);
        vm.expectPartialRevert(bytes4(RebaseToken.RebaseToken__InterestRateCanOnlyDecrease.selector));
        rebase.setInterestRate(newInterestRate);

        assertEq(initialInterestRate, rebase.getInterestRate());
    }

    function testTransferFrom(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 1e15 + 1e15, type(uint96).max);
        amountToSend = bound(amountToSend, 1e15, amount - 1e15);

        // deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        uint256 userBalance = rebase.balanceOf(user);
        assertEq(userBalance, amount);

        // create user2
        address user2 = makeAddr("user2");
        uint256 user2Balance = rebase.balanceOf(user2);
        assertEq(user2Balance, 0);

        // owner reduces the interest rate
        vm.prank(owner);
        rebase.setInterestRate(4e10);

        // user approves user2 to transfer amountToSend from user
        vm.prank(user);
        rebase.approve(user2, amountToSend);

        // Transfer From
        vm.prank(user2);
        rebase.transferFrom(user, user2, amountToSend);

        uint256 userBalanceAfterTransferFrom = amount - amountToSend;
        uint256 user2BalanceAfterTransferFrom = amountToSend;

        // Assert
        assertEq(userBalanceAfterTransferFrom, rebase.balanceOf(user));
        assertEq(user2BalanceAfterTransferFrom, rebase.balanceOf(user2));

        assertEq(rebase.getUserInterestRate(user), 5e10);
        assertEq(rebase.getUserInterestRate(user2), 5e10);
    }

    function testCalculateLinearInterest() public {
        uint256 amount = 5e18;

        // deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        uint256 userInterestRate = rebase.getUserInterestRate(user);

        // warp the time by 1 hour
        vm.warp(block.timestamp + 1 hours);
        uint256 userTimeStampAfterWarp = rebase.getUserTimeStamp(user);
        uint256 timeElapsed = block.timestamp - userTimeStampAfterWarp;

        // calculate linearInterest
        uint256 expectedLinearInterest = (timeElapsed * userInterestRate) + 1e18;
        uint256 actualLinearInterest = rebase.getLinearInterest(user);

        assertEq(actualLinearInterest, expectedLinearInterest);
    }

    function testGetUserInterestRate(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        uint256 expectedInterestRate = 5e10;
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        // Check the interest rate for the user
        uint256 actualinterestRate = rebase.getUserInterestRate(user);
        assertEq(actualinterestRate, expectedInterestRate);
    }

    function testGetInterestRate() public view {
        uint256 expectedInterestRate = 5e10;
        uint256 actualinterestRate = rebase.getInterestRate();
        assertEq(actualinterestRate, expectedInterestRate);
    }
}
