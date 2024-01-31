// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import {L2Token} from "@src/L2Token.sol";
import {L2Escrow} from "@src/L2Escrow.sol";
import {Proxy} from "@src/Proxy.sol";

import {ICREATE3Factory} from "./interfaces/ICREATE3Factory.sol";
import {L2EscrowV2} from "./mocks/L2EscrowV2.sol";

/**
 * @title L2EscrowTest
 * @author sepyke.eth
 * @notice Tests for L2Escrow
 */
contract L2EscrowTest is Test {
    string ZKEVM_RPC_URL = vm.envString("ZKEVM_RPC_URL");

    address deployer = vm.addr(0xC14C13);
    address admin = vm.addr(0xB453D);
    address manager = vm.addr(0xD4DD1);
    address alice = vm.addr(0xA11CE);

    address polygonZkEVMBridge = 0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe;
    IERC20 originToken = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH on mainnet

    ICREATE3Factory create3Factory = ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1); // on zkevm
    L2Escrow escrow;
    L2Token wrappedToken;

    function _getL1EscrowAddress() internal returns (address) {
        return create3Factory.getDeployed(deployer, keccak256(bytes("L1Escrow:WETH")));
    }

    function _getL2EscrowAddress() internal returns (address) {
        return create3Factory.getDeployed(deployer, keccak256(bytes("L2Escrow:WETH")));
    }

    function _getL2Tokenddress() internal returns (address) {
        return create3Factory.getDeployed(deployer, keccak256(bytes("L2Token:WETH")));
    }

    /// @dev Step by step to deploy L2Token
    function _deployL2Token() internal returns (L2Token deployed) {
        vm.startPrank(deployer);
        // Step 1: Deploy implementation contract
        L2Token implementation = new L2Token();

        // Step 2: Deploy upgradeable proxy contract
        bytes memory data = abi.encodeWithSelector(L2Token.initialize.selector, admin, _getL2EscrowAddress(), address(0), "Test", "TEST");
        bytes32 salt = keccak256(bytes("L2Token:WETH"));
        bytes memory creationCode = abi.encodePacked(type(Proxy).creationCode, abi.encode(address(implementation), data));
        address deployedAddress = create3Factory.deploy(salt, creationCode);

        // Step 3: Return the address
        deployed = L2Token(deployedAddress);
        vm.stopPrank();
    }

    /// @dev Step by step to deploy L2Escrow
    function _deployL2Escrow() internal returns (L2Escrow deployed) {
        vm.startPrank(deployer);
        // Step 1: Deploy implementation contract
        L2Escrow implementation = new L2Escrow();

        // Step 2: Deploy upgradeable proxy contract
        address counterpartContract = _getL1EscrowAddress();
        uint32 counterpartNetwork = 0;
        address wrappedTokenAddress = _getL2Tokenddress();
        bytes memory data = abi.encodeWithSelector(L2Escrow.initialize.selector, admin, polygonZkEVMBridge, counterpartContract, counterpartNetwork, address(originToken), wrappedTokenAddress);
        bytes32 salt = keccak256(bytes("L2Escrow:WETH"));
        bytes memory creationCode = abi.encodePacked(type(Proxy).creationCode, abi.encode(address(implementation), data));
        address deployedAddress = create3Factory.deploy(salt, creationCode);

        // Step 3: Return the address
        deployed = L2Escrow(deployedAddress);
        vm.stopPrank();
    }

    function setUp() public {
        uint256 fork = vm.createFork(ZKEVM_RPC_URL);
        vm.selectFork(fork);

        wrappedToken = _deployL2Token();
        escrow = _deployL2Escrow();
    }

    // ****************************
    // *         Upgrade          *
    // ****************************

    /// @dev It should hit a snag and revert if someone who's not an admin tries to upgrade the L2Escrow
    function testUpgradeAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        escrow.upgradeToAndCall(vm.addr(2), "");
    }

    /// @dev It's all good if an admin is the one upgrading the L2Escrow
    function testUpgradeAsAdmin() public {
        // Step 1: Deploy implementation contract
        L2EscrowV2 v2 = new L2EscrowV2();

        // Step 2: Admin execute upgrade
        vm.startPrank(admin);
        escrow.upgradeToAndCall(address(v2), "");
        vm.stopPrank();

        // Make sure V1 storage is still valid
        assertTrue(escrow.hasRole(0x00, admin));

        // Make sure new function(s) exists
        L2EscrowV2 escrowV2 = L2EscrowV2(address(escrow));
        escrowV2.setValue(1 ether);
        assertEq(escrowV2.getValue(), 1 ether);
    }

    // ****************************
    // *          Pause           *
    // ****************************

    /// @dev Some random person shouldn't have the power to pause the contract
    function testPauseAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        escrow.pause();
    }

    /// @dev Some random person shouldn't have the power to unpause the contract
    function testUnpauseAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        escrow.unpause();
    }

    /// @dev Admin should able to pause and unpause the contract
    function testPauseUnpauseAsAdmin() public {
        vm.startPrank(admin);
        escrow.pause();
        assertTrue(escrow.paused());
        escrow.unpause();
        assertFalse(escrow.paused());
    }

    // ****************************
    // *           Bridge         *
    // ****************************

    function testBridgeToken() public {
        deal(address(wrappedToken), alice, 10 ether);

        vm.startPrank(alice);
        wrappedToken.approve(address(escrow), 10 ether);
        escrow.bridgeToken(alice, 10 ether, true);
        vm.stopPrank();

        assertEq(wrappedToken.balanceOf(alice), 0);
    }

    function testBridgeTokenWhenPaused() public {
        vm.startPrank(admin);
        escrow.pause();
        vm.stopPrank();

        deal(address(wrappedToken), alice, 10 ether);

        vm.startPrank(alice);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        escrow.bridgeToken(alice, 10 ether, true);
        vm.stopPrank();
    }
}
