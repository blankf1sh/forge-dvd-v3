// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {DamnValuableToken} from "dvd-v3/DamnValuableToken.sol";
import {DamnValuableTokenSnapshot} from "dvd-v3/DamnValuableTokenSnapshot.sol";


abstract contract Challenge is Test {
    mapping(uint256 => address payable) internal users;

    DamnValuableToken internal dvt;
    DamnValuableTokenSnapshot internal dvts;


    address payable internal attacker;
    address payable internal deployer;

    function newActors(uint256 attacker_eth, uint256 deployer_eth) public {
        attacker = payable(makeAddr("Attacker"));
        vm.deal(attacker, attacker_eth);
        deployer = payable(makeAddr("Deployer"));
        vm.deal(deployer, deployer_eth);
    }

    function newUsers() public {
        string[4] memory labels = ["Alice", "Bob", "Charlie", "David"];
        for(uint256 i=0; i<4; ++i) {
            users[i] = payable(makeAddr(labels[i]));
        }
    }

    function deployDVT() public {
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "Token");
    }

    function deployDVTS(uint256 amount) public {
        dvts = new DamnValuableTokenSnapshot(amount);
        vm.label(address(dvts), "Token with Snapshot");
    }

    function validation() public virtual {

    }
}