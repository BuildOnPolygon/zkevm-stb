// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

contract StorageLocationScript is Script {
    function setUp() public {}

    function run() public pure {
        bytes32 L1EscrowStorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L1Escrow")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L1EscrowStorageLocation");
        console2.logBytes32(L1EscrowStorageLocation);

        bytes32 L1EscrowV2StorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L1EscrowV2")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L1EscrowV2StorageLocation");
        console2.logBytes32(L1EscrowV2StorageLocation);
    }
}
