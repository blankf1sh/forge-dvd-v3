// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utilities} from "./utils/Utilities.sol";
import "dvd-v3/the-rewarder/AccountingToken.sol";
import "dvd-v3/the-rewarder/RewardToken.sol";
import "dvd-v3/the-rewarder/TheRewarderPool.sol";

contract RewardSnatcher is Test {
    uint256 public constant TOKENS_IN_LENDER_POOL = 1_000_000e18;
    address payable[] public users;

    AccountingToken internal at;
    RewardToken internal rt;
    TheRewarderPool internal trp;

    function setUp() public {

    }

    function test_StoryReward() public view {

    }

    function test_ExploitRewarder() public {

    }

    function validation() public {
        assertEq(trp.roundNumber(), 3);

        for (uint256 i=0; i< users.length; ++i) {
            vm.startPrank(users[i]);
            trp.distributeRewards();

        }
    }
}
