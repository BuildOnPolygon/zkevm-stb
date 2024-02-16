// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {L1Escrow} from "@src/L1Escrow.sol";

/**
 * @title L1EscrowV2
 * @author sepyke.eth
 */
contract L1EscrowV2 is L1Escrow {
    /// @custom:storage-location erc7201:polygon.storage.L1EscrowV2
    struct L1EscrowV2Storage {
        uint256 value;
    }

    // keccak256(abi.encode(uint256(keccak256("polygon.storage.L1EscrowV2")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant L1EscrowV2StorageLocation = 0xd8bfafcb52c0c43d2ab6d43d329f044eed49982336cc2ee45e95fc8864e0f900;

    function _getL1EscrowV2Storage() private pure returns (L1EscrowV2Storage storage $) {
        assembly {
            $.slot := L1EscrowV2StorageLocation
        }
    }

    function setValue(uint256 _value) public {
        L1EscrowV2Storage storage $ = _getL1EscrowV2Storage();
        $.value = _value;
    }

    function getValue() public view returns (uint256 _value) {
        L1EscrowV2Storage storage $ = _getL1EscrowV2Storage();
        _value = $.value;
    }
}
