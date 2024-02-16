// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControlDefaultAdminRulesUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol"; // forgefmt: disable-line
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PolygonERC20BridgeBaseUpgradeable} from "./PolygonERC20BridgeBaseUpgradeable.sol";
import {IL2Token} from "./interfaces/IL2Token.sol";

/**
 * @title L2Escrow
 * @author sepyke.eth
 * @dev This contract is responsible for receive message from L1Escrow then interact with L2Token
 */
contract L2Escrow is AccessControlDefaultAdminRulesUpgradeable, UUPSUpgradeable, PausableUpgradeable, PolygonERC20BridgeBaseUpgradeable {
    // ****************************
    // *      ERC-7201 Storage    *
    // ****************************

    /// @custom:storage-location erc7201:polygon.storage.L2Escrow
    struct L2EscrowStorage {
        address originTokenAddress;
        IL2Token wrappedTokenAddress;
    }

    // keccak256(abi.encode(uint256(keccak256("polygon.storage.L2Escrow")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant L2EscrowStorageLocation = 0xe8e2340b90fc26fa948a17a0ba78b4daffcbc869b4f5a93b9b6cdc8ddc39b700;

    function _getL2EscrowStorage() private pure returns (L2EscrowStorage storage $) {
        assembly {
            $.slot := L2EscrowStorageLocation
        }
    }

    function originTokenAddress() public view returns (address) {
        L2EscrowStorage storage $ = _getL2EscrowStorage();
        return $.originTokenAddress;
    }

    function wrappedTokenAddress() public view returns (IL2Token) {
        L2EscrowStorage storage $ = _getL2EscrowStorage();
        return $.wrappedTokenAddress;
    }

    // ****************************
    // *        Initializer       *
    // ****************************

    /// @notice Disable initializer on deploy
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice L2Escrow initializer
     * @param _admin The admin address
     * @param _polygonZkEVMBridge Polygon ZkEVM bridge address
     * @param _counterpartContract Couterpart contract
     * @param _counterpartNetwork Couterpart network
     * @param _originTokenAddress Token address
     * @param _wrappedTokenAddress L2Token address on Polygon ZkEVM
     */
    function initialize(address _admin, address _polygonZkEVMBridge, address _counterpartContract, uint32 _counterpartNetwork, address _originTokenAddress, address _wrappedTokenAddress)
        public
        virtual
        initializer
    {
        // Inits
        __AccessControlDefaultAdminRules_init(3 days, _admin);
        __UUPSUpgradeable_init();
        __Pausable_init();
        __PolygonERC20BridgeBase_init(_polygonZkEVMBridge, _counterpartContract, _counterpartNetwork);

        // Set storage
        L2EscrowStorage storage $ = _getL2EscrowStorage();
        $.originTokenAddress = _originTokenAddress;
        $.wrappedTokenAddress = IL2Token(_wrappedTokenAddress);
    }

    // ****************************
    // *          Upgrade         *
    // ****************************

    /**
     * @dev Only the owner can upgrade the L2Escrow
     * @param _newVersion The contract address of a new version
     */
    function _authorizeUpgrade(address _newVersion) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ****************************
    // *          Pause           *
    // ****************************

    /**
     * @notice Pause the L2Escrow
     * @dev Only EMERGENCY_ROLE can pause the L2Escrow
     */
    function pause() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Resume the L2Escrow
     * @dev Only EMERGENCY_ROLE can resume the L2Escrow
     */
    function unpause() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // ****************************
    // *           Bridge         *
    // ****************************

    /**
     * @dev Handle the reception of the tokens
     * @param amount Token amount
     */
    function _receiveTokens(uint256 amount) internal virtual override whenNotPaused {
        L2EscrowStorage storage $ = _getL2EscrowStorage();
        $.wrappedTokenAddress.bridgeBurn(msg.sender, amount);
    }

    /**
     * @dev Handle the transfer of the tokens
     * @param destinationAddress Address destination that will receive the tokens on the other network
     * @param amount Token amount
     */
    function _transferTokens(address destinationAddress, uint256 amount) internal virtual override whenNotPaused {
        L2EscrowStorage storage $ = _getL2EscrowStorage();
        $.wrappedTokenAddress.bridgeMint(destinationAddress, amount);
    }
}
