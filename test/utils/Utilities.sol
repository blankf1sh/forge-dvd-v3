// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

contract Utilities is Test {

	constructor() {
	}

	function getActor(string memory label, uint256 initialBalance)
		external returns (address payable) {
			address payable actor = payable(makeAddr(label));
			vm.deal(actor, initialBalance);
			return actor;
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
