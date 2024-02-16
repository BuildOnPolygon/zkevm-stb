// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {L2Token} from "@src/L2Token.sol";
import {Proxy} from "@src/Proxy.sol";

import {ICREATE3Factory} from "./interfaces/ICREATE3Factory.sol";
import {L2TokenV2} from "./mocks/L2TokenV2.sol";

/**
 * @title L2TokenTest
 * @author sepyke.eth
 * @notice Tests for L2Token
 */
contract L2TokenTest is Test {
    string ZKEVM_RPC_URL = vm.envString("ZKEVM_RPC_URL");

    address deployer = vm.addr(0xC14C13);
    address admin = vm.addr(0xB453D);
    address escrow = vm.addr(0xD4DD10);
    address converter = vm.addr(0xD4DD11);
    address alice = vm.addr(0xA11CE);

    ICREATE3Factory create3Factory = ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1); // on zkevm
    L2Token token;

    function _getL2EscrowAddress() internal returns (address) {
        return create3Factory.getDeployed(deployer, keccak256(bytes("L2Escrow:WETH")));
    }

    /// @dev Step by step to deploy L2Token
    function _deployL2Token() internal returns (L2Token deployed) {
        vm.startPrank(deployer);
        // Step 1: Deploy implementation contract
        L2Token implementation = new L2Token();

        // Step 2: Deploy upgradeable proxy contract
        bytes memory data = abi.encodeWithSelector(L2Token.initialize.selector, admin, escrow, converter, "Test", "TEST");
        bytes32 salt = keccak256(bytes("L2Token:WETH"));
        bytes memory creationCode = abi.encodePacked(type(Proxy).creationCode, abi.encode(address(implementation), data));
        address deployedAddress = create3Factory.deploy(salt, creationCode);

        // Step 3: Return the address
        deployed = L2Token(deployedAddress);
        vm.stopPrank();
    }

    function setUp() public {
        uint256 fork = vm.createFork(ZKEVM_RPC_URL);
        vm.selectFork(fork);

        token = _deployL2Token();
    }

    // ****************************
    // *         Upgrade          *
    // ****************************

    /// @dev It should hit a snag and revert if someone who's not an admin tries to upgrade the L2Token
    function testUpgradeAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        token.upgradeToAndCall(vm.addr(2), "");
    }

    /// @dev It's all good if an admin is the one upgrading the L2Token
    function testUpgradeAsAdmin() public {
        // Step 1: Deploy implementation contract
        L2TokenV2 v2 = new L2TokenV2();

        // Step 2: Admin execute upgrade
        vm.startPrank(admin);
        token.upgradeToAndCall(address(v2), "");
        vm.stopPrank();

        // Make sure V1 storage is still valid
        assertTrue(token.hasRole(0x00, admin));
        assertTrue(token.hasRole(token.ESCROW_ROLE(), escrow));
        assertTrue(token.hasRole(token.CONVERTER_ROLE(), converter));
        assertEq(token.name(), "Test");
        assertEq(token.symbol(), "TEST");

        // Make sure new function(s) exists
        L2TokenV2 tokenV2 = L2TokenV2(address(token));
        tokenV2.setValue(1 ether);
        assertEq(tokenV2.getValue(), 1 ether);
    }

    // ****************************
    // *          Pause           *
    // ****************************

    /// @dev Some random person shouldn't have the power to pause the contract
    function testPauseAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        token.pause();
    }

    /// @dev Some random person shouldn't have the power to unpause the contract
    function testUnpauseAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        token.unpause();
    }

    /// @dev Admin should able to pause and unpause the contract
    function testPauseUnpauseAsAdmin() public {
        vm.startPrank(admin);
        token.pause();
        assertTrue(token.paused());
        token.unpause();
        assertFalse(token.paused());
    }
}
