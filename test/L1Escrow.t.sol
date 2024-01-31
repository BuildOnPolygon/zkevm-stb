// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {L1Escrow} from "@src/L1Escrow.sol";
import {Proxy} from "@src/Proxy.sol";

import {ICREATE3Factory} from "./interfaces/ICREATE3Factory.sol";
import {L1EscrowV2} from "./mocks/L1EscrowV2.sol";

/**
 * @title L1EscrowTest
 * @author sepyke.eth
 * @notice Tests for L1Escrow
 */
contract L1EscrowTest is Test {
    string ETH_RPC_URL = vm.envString("ETH_RPC_URL");

    address deployer = vm.addr(0xC14C13);
    address admin = vm.addr(0xB453D);
    address manager = vm.addr(0xD4DD1);
    address alice = vm.addr(0xA11CE);

    ICREATE3Factory create3Factory = ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1); // on mainnet
    L1Escrow escrow;

    /// @dev Step by step to deploy L1Escrow
    function _deployL1Escrow() internal returns (L1Escrow deployed) {
        vm.startPrank(deployer);
        // Step 1: Deploy implementation contract
        L1Escrow implementation = new L1Escrow();

        // Step 2: Deploy upgradeable proxy contract
        bytes memory data = abi.encodeWithSelector(L1Escrow.initialize.selector, admin, manager);
        bytes32 salt = keccak256(bytes("L1Escrow:SOMETOKEN")); // NOTE: this should be L1Escrow:USDC on mainnet
        bytes memory creationCode = abi.encodePacked(type(Proxy).creationCode, abi.encode(address(implementation), data));
        address deployedAddress = create3Factory.deploy(salt, creationCode);

        // Step 3: Return the address
        deployed = L1Escrow(deployedAddress);
        vm.stopPrank();
    }

    function setUp() public {
        uint256 ethFork = vm.createFork(ETH_RPC_URL);
        vm.selectFork(ethFork);

        escrow = _deployL1Escrow();
    }

    //****************************//
    //          Upgrade           //
    //****************************//

    /// @dev It should hit a snag and revert if someone who's not an admin tries to upgrade the L1Escrow
    function testUpgradeAsNonAdmin() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        escrow.upgradeToAndCall(vm.addr(2), "");
    }

    /// @dev It's all good if an admin is the one upgrading the L1Escrow
    function testUpgradeAsAdmin() public {
        // Step 1: Deploy implementation contract
        L1EscrowV2 v2 = new L1EscrowV2();

        // Step 2: Admin execute upgrade
        vm.startPrank(admin);
        escrow.upgradeToAndCall(address(v2), "");
        vm.stopPrank();

        // Make sure V1 storage is still valid
        assertTrue(escrow.hasRole(0x00, admin));
        assertTrue(escrow.hasRole(escrow.ESCROW_MANAGER(), manager));

        // Make sure new function(s) exists
        L1EscrowV2 escrowV2 = L1EscrowV2(address(escrow));
        escrowV2.setValue(1 ether);
        assertEq(escrowV2.getValue(), 1 ether);
    }
}
