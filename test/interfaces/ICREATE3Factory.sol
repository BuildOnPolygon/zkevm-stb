// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ICREATE3Factory {
    function getDeployed(address deployer, bytes32 salt) external returns (address);
    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed);
}
