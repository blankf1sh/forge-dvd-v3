// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TrustfulOracle} from "dvd-v3/compromised/TrustfulOracle.sol";

contract Compromiser is TrustfulOracle {
    constructor() {}

    // basic idea is deploy a contract that can give itself admin role for trustful oracle 
    // either grantRole or 
}