// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

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

    address polygonZkEVMBridge = 0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe;
    IERC20 originToken = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH

    ICREATE3Factory create3Factory = ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1); // on mainnet
    L1Escrow escrow;

    function _getL2EscrowAddress() internal returns (address) {
        return create3Factory.getDeployed(deployer, keccak256(bytes("L2Escrow:WETH")));
    }

    function _getL2Tokenddress() internal returns (address) {
        return create3Factory.getDeployed(deployer, keccak256(bytes("L2Token:WETH")));
    }

    /// @dev Step by step to deploy L1Escrow
    function _deployL1Escrow() internal returns (L1Escrow deployed) {
        vm.startPrank(deployer);
        // Step 1: Deploy implementation contract
        L1Escrow implementation = new L1Escrow();

        // Step 2: Deploy upgradeable proxy contract
        address counterpartContract = _getL2EscrowAddress();
        uint32 counterpartNetwork = 1;
        address wrappedTokenAddress = _getL2Tokenddress();
        bytes memory data = abi.encodeWithSelector(L1Escrow.initialize.selector, admin, manager, polygonZkEVMBridge, counterpartContract, counterpartNetwork, address(originToken), wrappedTokenAddress);
        bytes32 salt = keccak256(bytes("L1Escrow:WETH"));
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

    // ****************************
    // *         Upgrade          *
    // ****************************

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
        assertTrue(escrow.hasRole(escrow.ESCROW_MANAGER_ROLE(), manager));

        // Make sure new function(s) exists
        L1EscrowV2 escrowV2 = L1EscrowV2(address(escrow));
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
        deal(address(originToken), alice, 10 ether);

        vm.startPrank(alice);
        originToken.approve(address(escrow), 10 ether);
        escrow.bridgeToken(alice, 10 ether, true);
        vm.stopPrank();

        assertEq(originToken.balanceOf(alice), 0);
    }

    function testBridgeTokenWhenPaused() public {
        vm.startPrank(admin);
        escrow.pause();
        vm.stopPrank();

        deal(address(originToken), alice, 10 ether);

        vm.startPrank(alice);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        escrow.bridgeToken(alice, 10 ether, true);
        vm.stopPrank();
    }

    // ****************************
    // *          Manager         *
    // ****************************

    function testWithdrawAsNonManager() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, escrow.ESCROW_MANAGER_ROLE()));
        escrow.withdraw(alice, 10 ether);
    }

    function testWithdrawAsManager() public {
        deal(address(originToken), address(escrow), 10 ether);

        vm.startPrank(manager);
        escrow.withdraw(manager, 10 ether);
        vm.stopPrank();

        assertEq(originToken.balanceOf(manager), 10 ether);
        assertEq(originToken.balanceOf(address(escrow)), 0);
    }
}
