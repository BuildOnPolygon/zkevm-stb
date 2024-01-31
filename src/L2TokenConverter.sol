// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControlDefaultAdminRulesUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol"; // forgefmt: disable-line
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title L2TokenConverter
 * @author sepyke.eth
 * @dev Receives ERC20 and send L2Token at specified exchange rate
 */
contract L2TokenConverter is AccessControlDefaultAdminRulesUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    // ****************************
    // *         Libraries        *
    // ****************************

    using SafeERC20 for IERC20;

    // ****************************
    // *           Roles          *
    // ****************************

    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    bytes32 public constant RISK_MANAGER_ROLE = keccak256("RISK_MANAGER_ROLE");

    // ****************************
    // *        Initializer       *
    // ****************************

    /// @notice Disable initializer on deploy
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice L2TokenConverter initializer
     * @param _admin The admin address
     * @param _escrow The escrow manager address
     * @param _risk The risk manager address
     */
    function initialize(address _admin, address _escrow, address _risk) public virtual initializer {
        // Inits
        __AccessControlDefaultAdminRules_init(3 days, _admin);
        __UUPSUpgradeable_init();
        __Pausable_init();

        _grantRole(ESCROW_MANAGER_ROLE, _escrow);
        _grantRole(RISK_MANAGER_ROLE, _risk);
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
