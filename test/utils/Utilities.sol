// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

contract Utilities is Test {
	function setUp(string[3] memory _actors, uint64[3] memory amounts) 
	   external returns (address[] memory) {
		address[] memory actors = new address[](3);
		for(uint256 i=0; i<3; ++i) {
			address actor = makeAddr(_actors[i]);
			vm.deal(actor, amounts[i]);
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

    function stats_erc20(address token, address[3] memory addresses, string[3] memory actors) external {
	for (uint256 i=0; i<3; ++i) {
	   console2.log("~~~~~~~~~~~~%s~~~~~~~~~~", actors[i]);
	   console2.log("balance: ");
	   console2.log("~~~~~~~~~~~~~~~~~~~~~~~~");
	}
    }

    /// @notice move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}
