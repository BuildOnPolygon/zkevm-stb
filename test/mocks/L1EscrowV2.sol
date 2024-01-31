// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {L1Escrow} from "@src/L1Escrow.sol";

/**
 * @title L1EscrowV2
 * @author sepyke.eth
 * @notice A mock contract to play around with and test how the L1Escrow can be upgraded
 */
contract L1EscrowV2 is L1Escrow {
    uint256 public some;

    /// @dev Add new function for testing purpose
    function setValue(uint256 _some) public {
        some = _some;
    }

    /// @dev Add new function for testing purpose
    function getValue() public view returns (uint256 b) {
        b = some;
    }
}
