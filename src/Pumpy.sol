// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract PUMPY is ERC20 {
    uint constant MAX_SUPPLY = 1_000_000_000_000 ether;

    constructor() ERC20("PUMPY", "PUMP") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}
