// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

contract Utilities is Test {
	string[] public labels;
	uint256[] public starting_amounts;

	constructor() {
		labels.push("Deployer");
		labels.push("Attacker");
		labels.push("SomeUser");
		starting_amounts.push(1_000e18);
		starting_amounts.push(1e18);
		starting_amounts.push(10e18);
	}


	function setUp() 
	   external returns (address[] memory) {
		address[] memory actors = new address[](3);
		for(uint256 i=0; i<3; ++i) {
			address actor = makeAddr(labels[i]);
			vm.deal(actor, starting_amounts[i]);
			actors[i] = actor;
		}
		return actors;
	}

    function stats(address account, string memory _user) external view {
	console2.log("~~~~~~~~~~~~~%s~~~~~~~~~~~~~", _user);
	console2.log("Address: %s", address(account));
	console2.log("Balance: %s ETH", address(account).balance/1e18);
	console2.log("~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    }

    /// @notice move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}
