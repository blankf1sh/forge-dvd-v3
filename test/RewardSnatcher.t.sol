// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FlashLoanerPool} from "dvd-v3/the-rewarder/FlashLoanerPool.sol";
import "forge-std/Test.sol";
import {Challenge} from "./utils/Challenge.sol";
import {Utilities} from "./utils/Utilities.sol";
import {AccountingToken} from "dvd-v3/the-rewarder/AccountingToken.sol";
import {RewardToken} from "dvd-v3/the-rewarder/RewardToken.sol";
import {TheRewarderPool} from "dvd-v3/the-rewarder/TheRewarderPool.sol";
import {DamnValuableToken} from "dvd-v3/DamnValuableToken.sol";


contract RewardSnatcher is Test, Challenge {
    uint256 public constant TOKENS_IN_LENDER_POOL = 1_000_000e18;

    DamnValuableToken internal dvt;

    FlashLoanerPool internal flp;

    AccountingToken internal at;
    RewardToken internal rt;
    TheRewarderPool internal trp;

    function setUp() public {
        Utilities utils = new Utilities();
        string[6] memory labels = ["Deployer", "Alice", "Bob", "Charlie", "David", "Attacker"];
        for(uint256 i=0; i<6; ++i) {
            actors[labels[i]] = utils.getActor(labels[i], 1e18);
        }
        attacker = actors["Attacker"];
        
    }

    function test_StoryReward() public view {

    }

    function test_ExploitRewarder() public {
        vm.startPrank(attacker);
        vm.stopPrank();
    }

    function validation() public {
        assertEq(trp.roundNumber(), 3);
    }
}
