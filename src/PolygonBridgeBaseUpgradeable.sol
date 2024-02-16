// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IPolygonZkEVMBridge.sol";

/**
 * @title PolygonBridgeBaseUpgradeable
 * @author sepyke.eth
 * @dev Upgradeable version of PolygonBridgeBase
 *
 * https://github.com/0xPolygonHermez/code-examples/blob/41d266590db4fcdabb56cd29f407c728f40210ec/customERC20-bridge-example/contracts/base/PolygonBridgeBase.sol
 */
abstract contract PolygonBridgeBaseUpgradeable is Initializable {
    /// @custom:storage-location erc7201:polygon.storage.PolygonBridgeBase
    struct PolygonBridgeBaseStorage {
        IPolygonZkEVMBridge polygonZkEVMBridge;
        address counterpartContract;
        uint32 counterpartNetwork;
    }

    // keccak256(abi.encode(uint256(keccak256("polygon.storage.PolygonBridgeBase")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PolygonBridgeBaseStorageLocation = 0xa2df0fe6db3ae7b9af51d186eeafd135102ceb6374bcad9534034e06f66daa00;

    function _getPolygonBridgeBaseStorage() private pure returns (PolygonBridgeBaseStorage storage $) {
        assembly {
            $.slot := PolygonBridgeBaseStorageLocation
        }
    }

    function polygonZkEVMBridge() public view returns (address) {
        PolygonBridgeBaseStorage storage $ = _getPolygonBridgeBaseStorage();
        return address($.polygonZkEVMBridge);
    }

    function counterpartContract() public view returns (address) {
        PolygonBridgeBaseStorage storage $ = _getPolygonBridgeBaseStorage();
        return $.counterpartContract;
    }

    function counterpartNetwork() public view returns (uint32) {
        PolygonBridgeBaseStorage storage $ = _getPolygonBridgeBaseStorage();
        return $.counterpartNetwork;
    }

    /**
     * @param _polygonZkEVMBridge Polygon zkevm bridge address
     * @param _counterpartContract Couterpart contract
     * @param _counterpartNetwork Couterpart network
     */
    function __PolygonBridgeBase_init(address _polygonZkEVMBridge, address _counterpartContract, uint32 _counterpartNetwork) internal onlyInitializing {
        __PolygonBridgeBase_init_unchained(_polygonZkEVMBridge, _counterpartContract, _counterpartNetwork);
    }

    function __PolygonBridgeBase_init_unchained(address _polygonZkEVMBridge, address _counterpartContract, uint32 _counterpartNetwork) internal onlyInitializing {
        PolygonBridgeBaseStorage storage $ = _getPolygonBridgeBaseStorage();
        $.polygonZkEVMBridge = IPolygonZkEVMBridge(_polygonZkEVMBridge);
        $.counterpartContract = _counterpartContract;
        $.counterpartNetwork = _counterpartNetwork;
    }

    /**
     * @notice Send a message to the bridge
     * @param messageData Message data
     * @param forceUpdateGlobalExitRoot Indicates if the global exit root is updated or not
     */
    function _bridgeMessage(bytes memory messageData, bool forceUpdateGlobalExitRoot) internal virtual {
        PolygonBridgeBaseStorage storage $ = _getPolygonBridgeBaseStorage();
        $.polygonZkEVMBridge.bridgeMessage($.counterpartNetwork, $.counterpartContract, forceUpdateGlobalExitRoot, messageData);
    }

    /**
     * @notice Function triggered by the bridge once a message is received by the other network
     * @param originAddress Origin address that the message was sended
     * @param originNetwork Origin network that the message was sended ( not usefull for this contract)
     * @param data Abi encoded metadata
     */
    function onMessageReceived(address originAddress, uint32 originNetwork, bytes memory data) external payable {
        PolygonBridgeBaseStorage storage $ = _getPolygonBridgeBaseStorage();

        // Can only be called by the bridge
        require(msg.sender == address($.polygonZkEVMBridge), "TokenWrapped::PolygonBridgeBase: Not PolygonZkEVMBridge");
        require($.counterpartContract == originAddress, "TokenWrapped::PolygonBridgeBase: Not counterpart contract");
        require($.counterpartNetwork == originNetwork, "TokenWrapped::PolygonBridgeBase: Not counterpart network");

        _onMessageReceived(data);
    }

    /**
     * @dev Handle the data of the message received
     * Must be implemented in parent contracts
     */
    function _onMessageReceived(bytes memory data) internal virtual;
}
