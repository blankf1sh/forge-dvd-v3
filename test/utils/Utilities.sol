// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

contract Utilities is Test {
	string[] public labels;

	constructor() {
		labels.push("Deployer");
		labels.push("Attacker");
		labels.push("SomeUser");
	}


	function setUp() 
	   external returns (address[] memory) {
		address[] memory actors = new address[](3);
		for(uint256 i=0; i<3; ++i) {
			address actor = makeAddr(labels[i]);
			vm.deal(actor, 100e18);
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
