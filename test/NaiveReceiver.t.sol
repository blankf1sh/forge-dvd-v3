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
		utils = new Utilities();
		address payable[] memory users = utils.creatUsers(3);
		deployer = users[0];
		vm.deal(deployer, ETHER_IN_POOL);
		attacker = users[1];
		someUser = users[2];

		vm.startPrank(deployer);
		nrlp = new NaiveReceiverLenderPool();
		(bool sent, _) = payable(nrlp).call{value: ETHER_IN_POOL}("");
		require(sent, "Failed to send Ether");
	}

	function testExploit() public {

	}

	function validation() public {

	}
}
