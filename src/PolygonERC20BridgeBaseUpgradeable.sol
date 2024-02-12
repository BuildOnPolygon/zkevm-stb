// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./PolygonBridgeBaseUpgradeable.sol";

/**
 * @title PolygonERC20BridgeBaseUpgradeable
 * @author sepyke.eth
 * @dev Upgradeable version of PolygonERC20BridgeBase
 *
 * https://github.com/0xPolygonHermez/code-examples/blob/41d266590db4fcdabb56cd29f407c728f40210ec/customERC20-bridge-example/contracts/base/PolygonERC20BridgeBase.sol
 */
abstract contract PolygonERC20BridgeBaseUpgradeable is PolygonBridgeBaseUpgradeable {
    /**
     * @param _polygonZkEVMBridge Polygon zkevm bridge address
     * @param _counterpartContract Couterpart contract
     * @param _counterpartNetwork Couterpart network
     */
    function __PolygonERC20BridgeBase_init(address _polygonZkEVMBridge, address _counterpartContract, uint32 _counterpartNetwork) internal onlyInitializing {
        __PolygonERC20BridgeBase_init_unchained(_polygonZkEVMBridge, _counterpartContract, _counterpartNetwork);
    }

    function __PolygonERC20BridgeBase_init_unchained(address _polygonZkEVMBridge, address _counterpartContract, uint32 _counterpartNetwork) internal onlyInitializing {
        __PolygonBridgeBase_init_unchained(_polygonZkEVMBridge, _counterpartContract, _counterpartNetwork);
    }

    /**
     * @dev Emitted when bridge tokens to the counterpart network
     */
    event BridgeTokens(address destinationAddress, uint256 amount);

    /**
     * @dev Emitted when claim tokens from the counterpart network
     */
    event ClaimTokens(address destinationAddress, uint256 amount);

    /**
     * @notice Send a message to the bridge that contains the destination address and the token amount
     * The parent contract should implement the receive token protocol and afterwards call this function
     * @param destinationAddress Address destination that will receive the tokens on the other network
     * @param amount Token amount
     * @param forceUpdateGlobalExitRoot Indicates if the global exit root is updated or not
     */
    function bridgeToken(address destinationAddress, uint256 amount, bool forceUpdateGlobalExitRoot) external {
        require(destinationAddress != address(0), "TokenWrapped::PolygonBridgeERC20Base: Zero Address");
        _receiveTokens(amount);

        // Encode message data
        bytes memory messageData = abi.encode(destinationAddress, amount);

        // Send message data through the bridge
        _bridgeMessage(messageData, forceUpdateGlobalExitRoot);

        emit BridgeTokens(destinationAddress, amount);
    }

    /**
     * @notice Internal function triggered when receive a message
     * @param data message data containing the destination address and the token amount
     */
    function _onMessageReceived(bytes memory data) internal override {
        // Decode message data
        (address destinationAddress, uint256 amount) = abi.decode(data, (address, uint256));

        _transferTokens(destinationAddress, amount);
        emit ClaimTokens(destinationAddress, amount);
    }

    /**
     * @dev Handle the reception of the tokens
     * Must be implemented in parent contracts
     */
    function _receiveTokens(uint256 amount) internal virtual;

    /**
     * @dev Handle the transfer of the tokens
     * Must be implemented in parent contracts
     */
    function _transferTokens(address destinationAddress, uint256 amount) internal virtual;
}
