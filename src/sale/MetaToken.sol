// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MetaToken is ERC20 {
    uint256 private constant _INITIAL_TOTAL_SUPPLY = 1_000_000_000e18;

    constructor() ERC20("Metalamp token", "META", 18) {
        _mint(msg.sender, _INITIAL_TOTAL_SUPPLY);
    }
}