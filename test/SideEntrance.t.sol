// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utilities} from "./utils/Utilities.sol";
import "dvd-v3/side-entrance/SideEntranceLenderPool.sol";
import "src/SideEntrant.sol";

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;
    uint256 internal constant ATTACKER_INITIAL_BALANCE = 1e18;

    address payable internal deployer;
    address payable internal attacker;
    address payable internal someUser;

    SideEntranceLenderPool internal selp;

    function setUp() public {
        Utilities utils = new Utilities();
        deployer = utils.getActor("Deployer", ETHER_IN_POOL);
        attacker = utils.getActor("Attacker", ATTACKER_INITIAL_BALANCE);

        vm.startPrank(deployer);
        selp = new SideEntranceLenderPool();
        selp.deposit{value: ETHER_IN_POOL}();
        vm.stopPrank();

        assertEq(address(selp).balance, ETHER_IN_POOL);
    }

    function test_StorySideEntrance() public view {

    }

    function test_ExploitSideEntrance() public {
        vm.startPrank(attacker);
        SideEntrant se = new SideEntrant(address(selp), address(attacker));
        se.start(ETHER_IN_POOL);
        se.recover();
        vm.stopPrank();

        assertEq(address(selp).balance, 0);
        assertEq(address(attacker).balance, ETHER_IN_POOL + ATTACKER_INITIAL_BALANCE);
    }
}