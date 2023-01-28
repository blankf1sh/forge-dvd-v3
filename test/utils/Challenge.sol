// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Challenge {
    mapping(string => address payable) internal actors;

    address payable internal attacker;
    address payable internal deployer;
    address payable internal someUser;

    function normSetUp(uint256 v1, uint256 v2, uint256 v3) public {

    }

    function validation() public {

    }
}