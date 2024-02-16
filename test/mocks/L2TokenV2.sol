// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {L2Token} from "@src/L2Token.sol";

/**
 * @title L2TokenV2
 * @author sepyke.eth
 */
contract L2TokenV2 is L2Token {
    /// @custom:storage-location erc7201:polygon.storage.L2TokenV2
    struct L2TokenV2Storage {
        uint256 value;
    }

    // keccak256(abi.encode(uint256(keccak256("polygon.storage.L2TokenV2")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant L2TokenV2StorageLocation = 0xb493d6daf66d9aea9286425311fdbdb252690146dc5967b92e457ad803f64600;

    function _getL2TokenV2Storage() private pure returns (L2TokenV2Storage storage $) {
        assembly {
            $.slot := L2TokenV2StorageLocation
        }
    }

    function setValue(uint256 _value) public {
        L2TokenV2Storage storage $ = _getL2TokenV2Storage();
        $.value = _value;
    }

    function getValue() public view returns (uint256 _value) {
        L2TokenV2Storage storage $ = _getL2TokenV2Storage();
        _value = $.value;
    }
}
