// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControlDefaultAdminRulesUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol"; // forgefmt: disable-line
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IL2Token} from "./interfaces/IL2Token.sol";

/**
 * @title L2TokenConverter
 * @author sepyke.eth
 * @dev Receives ERC20 and send L2Token at specified exchange rate
 */
contract L2TokenConverter is AccessControlDefaultAdminRulesUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    // ****************************
    // *         Libraries        *
    // ****************************

    using SafeERC20 for IERC20Metadata;

    // ****************************
    // *           Roles          *
    // ****************************

    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    bytes32 public constant RISK_MANAGER_ROLE = keccak256("RISK_MANAGER_ROLE");

    // ****************************
    // *      ERC-7201 Storage    *
    // ****************************

    /// @custom:storage-location erc7201:pyk.storage.L2TokenConverter
    struct L2TokenConverterStorage {
        mapping(IERC20Metadata source => mapping(IL2Token target => uint256 max)) issuances;
    }

    // keccak256(abi.encode(uint256(keccak256("pyk.storage.L2TokenConverter")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant L2TokenConverterStorageLocation = 0x0b3c8f661f5aed732bd10af3c82ca6cbf45e1ca2e6b04cc93e80372aaa927e00;

    function _getL2TokenConverterStorage() private pure returns (L2TokenConverterStorage storage $) {
        assembly {
            $.slot := L2TokenConverterStorageLocation
        }
    }

    function getMaxIssuance(IERC20Metadata _token, IL2Token _l2Token) public view virtual returns (uint256) {
        L2TokenConverterStorage storage $ = _getL2TokenConverterStorage();
        return $.issuances[_token][_l2Token];
    }

    // ****************************
    // *           Event          *
    // ****************************

    event IssuanceUpdated(IERC20Metadata indexed token, IL2Token indexed l2token, uint256 amount);
    event Deposit(IERC20Metadata indexed token, IL2Token indexed l2token, address sender, address recipient, uint256 amount);
    event Withdraw(IERC20Metadata indexed token, IL2Token indexed l2token, address sender, address recipient, uint256 amount);
    event ManagerWithdraw(IERC20Metadata indexed token, address recipient, uint256 amount);

    // ****************************
    // *           Error          *
    // ****************************

    error TokenDecimalsInvalid();
    error MaxIssuance();

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

    // ****************************
    // *      L2Token Issuance    *
    // ****************************

    /// @dev Set issuance cap for source token (ERC-20) <-> target token (L2Token)
    /// @dev Risk manager can execute this function multiple time in order to reduce or increase the issuance cap
    /// @param _token ERC-20 address
    /// @param _l2Token L2Token address
    /// @param _max maximum amount
    function setIssuanceCap(IERC20Metadata _token, IL2Token _l2Token, uint256 _max) external virtual onlyRole(RISK_MANAGER_ROLE) whenNotPaused {
        if (_token.decimals() != IERC20Metadata(address(_l2Token)).decimals()) revert TokenDecimalsInvalid();
        L2TokenConverterStorage storage $ = _getL2TokenConverterStorage();
        $.issuances[_token][_l2Token] = _max;
        emit IssuanceUpdated(_token, _l2Token, _max);
    }

    /// @dev User can deposit ERC-20 in exchange for L2Token
    function deposit(IERC20Metadata _token, IL2Token _l2Token, address _recipient, uint256 _amount) external virtual {
        L2TokenConverterStorage storage $ = _getL2TokenConverterStorage();
        uint256 maxIssuance = $.issuances[_token][_l2Token];
        if (_amount > maxIssuance) revert MaxIssuance();

        // Reduce max issuance
        $.issuances[_token][_l2Token] -= _amount;

        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _l2Token.converterMint(_recipient, _amount);

        emit Deposit(_token, _l2Token, msg.sender, _recipient, _amount);
    }

    /// @dev User can withdraw ERC-20 by burning L2Token
    function withdraw(IERC20Metadata _token, IL2Token _l2Token, address _recipient, uint256 _amount) external virtual {
        L2TokenConverterStorage storage $ = _getL2TokenConverterStorage();

        // Freed up some issuance quota
        $.issuances[_token][_l2Token] += _amount;

        _l2Token.converterBurn(msg.sender, _amount);
        _token.safeTransfer(_recipient, _amount);

        emit Withdraw(_token, _l2Token, msg.sender, _recipient, _amount);
    }

    // ****************************
    // *          Manager         *
    // ****************************

    /**
     * @dev Escrow manager can withdraw the token backing
     * @param _recipient the recipient address
     * @param _amount The amount of token
     */
    function managerWithdraw(IERC20Metadata _token, address _recipient, uint256 _amount) external virtual onlyRole(ESCROW_MANAGER_ROLE) whenNotPaused {
        _token.safeTransfer(_recipient, _amount);
        emit ManagerWithdraw(_token, _recipient, _amount);
    }
}
