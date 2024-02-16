// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {L2Escrow} from "@src/L2Escrow.sol";

/**
 * @title L2EscrowV2
 * @author sepyke.eth
 */
contract L2EscrowV2 is L2Escrow {
    /// @custom:storage-location erc7201:polygon.storage.L2EscrowV2
    struct L2EscrowV2Storage {
        uint256 value;
    }

    // keccak256(abi.encode(uint256(keccak256("polygon.storage.L2EscrowV2")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant L2EscrowV2StorageLocation = 0xb3b3c0d8b46c768ae2bbff4c9d287cbe5be19e6bf307c965c46beff86c99f200;

    function _getL2EscrowV2Storage() private pure returns (L2EscrowV2Storage storage $) {
        assembly {
            $.slot := L2EscrowV2StorageLocation
        }
    }

    function setValue(uint256 _value) public {
        L2EscrowV2Storage storage $ = _getL2EscrowV2Storage();
        $.value = _value;
    }

    function getValue() public view returns (uint256 _value) {
        L2EscrowV2Storage storage $ = _getL2EscrowV2Storage();
        _value = $.value;
    }
}
