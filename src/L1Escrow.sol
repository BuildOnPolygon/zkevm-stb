// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControlDefaultAdminRulesUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol"; // forgefmt: disable-line
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title L1Escrow
 * @author sepyke.eth
 * @dev This contract is what keeps the L2Token backed up on the origin chain
 */
contract L1Escrow is AccessControlDefaultAdminRulesUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    /// @notice Escrow manager role identifier
    bytes32 public constant ESCROW_MANAGER = keccak256("ESCROW_MANAGER");

    /// @notice Disable initializer on deploy
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _manager) public virtual initializer {
        // Inits
        __AccessControlDefaultAdminRules_init(3 days, _admin);
        __UUPSUpgradeable_init();
        __Pausable_init();

        _grantRole(ESCROW_MANAGER, _manager);
    }

    // ****************************
    // *          Upgrade         *
    // ****************************

    /**
     * @dev Only the owner can upgrade the L1Escrow
     * @param _newVersion The contract address of a new version
     */
    function _authorizeUpgrade(address _newVersion) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ****************************
    // *          Pause           *
    // ****************************

    /**
     * @notice Pause the L1Escrow
     * @dev Only EMERGENCY_ROLE can pause the L1Escrow
     */
    function pause() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Resume the L1Escrow
     * @dev Only EMERGENCY_ROLE can resume the L1Escrow
     */
    function unpause() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
