// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Challenge} from "./utils/Challenge.sol";
import {console2} from "forge-std/console2.sol";
import {Utilities} from "./utils/Utilities.sol";

import {AccountingToken} from "dvd-v3/the-rewarder/AccountingToken.sol";
import {RewardToken} from "dvd-v3/the-rewarder/RewardToken.sol";
import {TheRewarderPool} from "dvd-v3/the-rewarder/TheRewarderPool.sol";
import {DamnValuableToken} from "dvd-v3/DamnValuableToken.sol";
import {FlashLoanerPool} from "dvd-v3/the-rewarder/FlashLoanerPool.sol";

import {Snatcher} from "../src/Snatcher.sol";


contract RewardSnatcher is Challenge {
    uint256 public constant TOKENS_IN_LENDER_POOL = 1_000_000e18;

    FlashLoanerPool internal flp;
    AccountingToken internal at;
    RewardToken internal rt;
    TheRewarderPool internal trp;

    function setUp() public {
        newActors(1e18, 1e18);
        newUsers();

        vm.startPrank(deployer);
        deployDVT();
        flp = new FlashLoanerPool(address(dvt));
        dvt.transfer(address(flp), TOKENS_IN_LENDER_POOL);
        trp = new TheRewarderPool(address(dvt));
        rt = trp.rewardToken();
        at = trp.accountingToken();
        vm.stopPrank();
        
        assertEq(at.owner(), address(trp));
        uint256 MINTER = at.MINTER_ROLE();
        uint256 SNAPSHOT = at.SNAPSHOT_ROLE();
        uint256 BURNER = at.BURNER_ROLE();
        assertEq(at.hasAllRoles(address(trp), MINTER | SNAPSHOT | BURNER), true);

        uint256 depositAmount = 100e18;
        for(uint256 i=0; i<4; ++i) {
            address current_user = address(users[i]);
            deal({token: address(dvt), to: current_user, give: depositAmount});

            vm.startPrank(current_user);
            dvt.approve(address(trp), depositAmount);
            trp.deposit(depositAmount);
            vm.stopPrank();

            assertEq(at.balanceOf(current_user), depositAmount);
        }

        assertEq(at.totalSupply(), depositAmount*uint256(4));
        assertEq(rt.totalSupply(), 0);

        vm.warp(block.timestamp + 5 days);


        uint256 rewardsInRound = trp.REWARDS();
        for (uint256 i=0; i<4; ++i) {
            address current_user = address(users[i]);
            vm.prank(current_user);
            trp.distributeRewards();

            assertEq(rt.balanceOf(current_user), rewardsInRound/4);
        }

        assertEq(rt.totalSupply(), rewardsInRound);
        assertEq(dvt.balanceOf(address(attacker)), 0);
        assertEq(trp.roundNumber(), 2);
    }

    function test_StoryReward() public view {

    }

    function test_ExploitRewarder() public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 5 days);
        Snatcher rs = new Snatcher(flp, trp, dvt, attacker);
        rs.snatch();
        vm.stopPrank();
        validation();
    }

    function validation() public override {
        assertEq(trp.roundNumber(), 3);
        uint256 delta;
        for (uint256 i=0; i<4; ++i) {
            address current_user = address(users[i]);
            vm.prank(current_user);
            trp.distributeRewards();
            uint256 userRewards = rt.balanceOf(current_user);
            delta = userRewards - (trp.REWARDS() / 4);
            assertLt(delta, 1e16);
        }

        assertGt(rt.totalSupply(), trp.REWARDS());
        uint256 attackerRewards = rt.balanceOf(address(attacker));
        assertGt(attackerRewards, 0);

        delta = trp.REWARDS() - attackerRewards;
        assertLt(delta, 1e17);

        assertEq(dvt.balanceOf(address(attacker)), 0);
        assertEq(dvt.balanceOf(address(flp)), TOKENS_IN_LENDER_POOL);
    }
}
