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

        bytes32 PolygonBridgeBaseStorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.PolygonBridgeBase")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("PolygonBridgeBaseStorageLocation");
        console2.logBytes32(PolygonBridgeBaseStorageLocation);

        bytes32 L2TokenStorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L2Token")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L2TokenStorageLocation");
        console2.logBytes32(L2TokenStorageLocation);

        bytes32 L2TokenV2StorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L2TokenV2")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L2TokenV2StorageLocation");
        console2.logBytes32(L2TokenV2StorageLocation);

        bytes32 L2EscrowStorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L2Escrow")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L2EscrowStorageLocation");
        console2.logBytes32(L2EscrowStorageLocation);

        bytes32 L2EscrowV2StorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L2EscrowV2")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L2EscrowV2StorageLocation");
        console2.logBytes32(L2EscrowV2StorageLocation);

        bytes32 L2TokenConverterStorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L2TokenConverter")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L2TokenConverterStorageLocation");
        console2.logBytes32(L2TokenConverterStorageLocation);

        bytes32 L2TokenConverterV2StorageLocation = keccak256(abi.encode(uint256(keccak256("pyk.storage.L2TokenConverterV2")) - 1)) & ~bytes32(uint256(0xff));
        console2.logString("L2TokenConverterV2StorageLocation");
        console2.logBytes32(L2TokenConverterV2StorageLocation);
    }
}
