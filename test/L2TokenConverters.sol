// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import {L2TokenConverter} from "@src/L2TokenConverter.sol";
import {Proxy} from "@src/Proxy.sol";

import {ICREATE3Factory} from "./interfaces/ICREATE3Factory.sol";
import {L2TokenConverterV2} from "./mocks/L2TokenConverterV2.sol";

/**
 * @title L2TokenConverterTest
 * @author sepyke.eth
 * @notice Tests for L2TokenConverter
 */
contract L2TokenConverterTest is Test {
    string ZKEVM_RPC_URL = vm.envString("ZKEVM_RPC_URL");

    address deployer = vm.addr(0xC14C13);
    address admin = vm.addr(0xB453D);
    address escrower = vm.addr(0xD4DD11);
    address risker = vm.addr(0xD4DD12);
    address alice = vm.addr(0xA11CE);

    ICREATE3Factory create3Factory = ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1); // on mainnet
    L2TokenConverter converter;

    /// @dev Step by step to deploy L2TokenConverter
    function _deployL2TokenConverter() internal returns (L2TokenConverter deployed) {
        vm.startPrank(deployer);
        // Step 1: Deploy implementation contract
        L2TokenConverter implementation = new L2TokenConverter();

        // Step 2: Deploy upgradeable proxy contract
        bytes memory data = abi.encodeWithSelector(L2TokenConverter.initialize.selector, admin, escrower, risker);
        bytes32 salt = keccak256(bytes("L2TokenConverter"));
        bytes memory creationCode = abi.encodePacked(type(Proxy).creationCode, abi.encode(address(implementation), data));
        address deployedAddress = create3Factory.deploy(salt, creationCode);

        // Step 3: Return the address
        deployed = L2TokenConverter(deployedAddress);
        vm.stopPrank();
    }

    function setUp() public {
        uint256 fork = vm.createFork(ZKEVM_RPC_URL);
        vm.selectFork(fork);

        converter = _deployL2TokenConverter();
    }

    // ****************************
    // *         Upgrade          *
    // ****************************

    /// @dev It should hit a snag and revert if someone who's not an admin tries to upgrade the L2TokenConverter
    function testUpgradeAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        converter.upgradeToAndCall(vm.addr(2), "");
    }

    /// @dev It's all good if an admin is the one upgrading the L2TokenConverter
    function testUpgradeAsAdmin() public {
        // Step 1: Deploy implementation contract
        L2TokenConverterV2 v2 = new L2TokenConverterV2();

        // Step 2: Admin execute upgrade
        vm.startPrank(admin);
        converter.upgradeToAndCall(address(v2), "");
        vm.stopPrank();

        // Make sure V1 storage is still valid
        assertTrue(converter.hasRole(0x00, admin));
        assertTrue(converter.hasRole(converter.ESCROW_MANAGER_ROLE(), escrower));
        assertTrue(converter.hasRole(converter.RISK_MANAGER_ROLE(), risker));

        // Make sure new function(s) exists
        L2TokenConverterV2 converterV2 = L2TokenConverterV2(address(converter));
        converterV2.setValue(1 ether);
        assertEq(converterV2.getValue(), 1 ether);
    }

    // ****************************
    // *          Pause           *
    // ****************************

    /// @dev Some random person shouldn't have the power to pause the contract
    function testPauseAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        converter.pause();
    }

    /// @dev Some random person shouldn't have the power to unpause the contract
    function testUnpauseAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        converter.unpause();
    }

    /// @dev Admin should able to pause and unpause the contract
    function testPauseUnpauseAsAdmin() public {
        vm.startPrank(admin);
        converter.pause();
        assertTrue(converter.paused());
        converter.unpause();
        assertFalse(converter.paused());
    }

    // ****************************
    // *          Manager         *
    // ****************************

    // function testWithdrawAsNonManager() public {
    //     vm.startPrank(alice);
    //     vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, escrow.ESCROW_MANAGER_ROLE()));
    //     escrow.withdraw(alice, 10 ether);
    // }

    // function testWithdrawAsManager() public {
    //     deal(address(originToken), address(escrow), 10 ether);

    //     vm.startPrank(manager);
    //     escrow.withdraw(manager, 10 ether);
    //     vm.stopPrank();

    //     assertEq(originToken.balanceOf(manager), 10 ether);
    //     assertEq(originToken.balanceOf(address(escrow)), 0);
    // }
}
