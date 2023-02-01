// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Challenge} from "./utils/Challenge.sol";

import {Exchange} from "dvd-v3/compromised/Exchange.sol";
import {TrustfulOracle} from "dvd-v3/compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "dvd-v3/compromised/TrustfulOracleInitializer.sol";

contract Compromised is Challenge {
    Exchange internal exchange;
    TrustfulOracle internal oracle;

    address[] internal sources;
    string[] internal names;
    uint256[] internal prices;

    uint256 constant EXCHANGE_INITIAL_ETH_BALANCE = 999e18;
    uint256 constant INITIAL_NFT_PRICE = 999e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 1e17;
    uint256 constant TRUSTED_SOURCE_INITIAL_ETH_BALANCE = 2e18;

    function setUp() public {
        newActors(PLAYER_INITIAL_ETH_BALANCE, 1e18);
        assertEq(attacker.balance, PLAYER_INITIAL_ETH_BALANCE);

        sources.push(0xA73209FB1a42495120166736362A1DfA9F95A105);
        sources.push(0xe92401A4d3af5E446d93D11EEc806b1462b39D15);
        sources.push(0x81A5D6E50C214044bE44cA0CB057fe119097850c);

        for(uint8 i=0; i<3; ++i) {
            deal(sources[i], TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
            assertEq(sources[i].balance, TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
            names.push("DVNFT");
            prices.push(INITIAL_NFT_PRICE);
        }

        vm.startPrank(deployer);
        oracle = new TrustfulOracleInitializer(sources, names, prices).oracle();
        exchange = new Exchange(address(oracle));
        dvnft = exchange.token();
        vm.stopPrank();
        deal(address(exchange), EXCHANGE_INITIAL_ETH_BALANCE);
        assertEq(dvnft.owner(), address(0));
        assertEq(dvnft.rolesOf(address(exchange)), dvnft.MINTER_ROLE());
        vm.label(sources[0], "Oracle 1");
        vm.label(sources[1], "Oracle 2");
        vm.label(sources[2], "Oracle 3");
        vm.label(address(oracle), "Oracle Contract");
        vm.label(address(exchange), "Exchange");
        vm.label(address(dvnft), "DVNFT");

    }

    function test_ExploitCompromised() public {
        vm.startPrank(attacker);
        // 4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35
        // get median price < 0.1 eth
        // buy lots
        // get median price >> 100 eth
        // sell all until exchange runs out
        oracle.getMedianPrice(dvnft.symbol());
        oracle.getRoleAdmin(oracle.TRUSTED_SOURCE_ROLE());
        oracle.getRoleMemberCount(oracle.TRUSTED_SOURCE_ROLE());
        oracle.getRoleMemberCount(oracle.DEFAULT_ADMIN_ROLE());
        vm.stopPrank();
    }
}