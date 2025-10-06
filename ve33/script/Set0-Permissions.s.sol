// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";

contract SetPermissions is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load deployed contracts
        string memory infrastructurePath = getInputPath("Deploy1_Infrastructure");
        string memory infrastructureJson = vm.readFile(infrastructurePath);
        
        address permissionsRegistry = abi.decode(vm.parseJson(infrastructureJson, ".PermissionsRegistry"), (address));
        
        console.log("=== Set Permissions ===");
        console.log("PermissionsRegistry:", permissionsRegistry);
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployer);
        
        // Set GOVERNANCE role for deployer
        console.log("Setting GOVERNANCE role for deployer...");
        PermissionsRegistry(permissionsRegistry).setRoleFor(deployer, "GOVERNANCE");
        console.log("GOVERNANCE role set successfully");
        
        // Set GAUGE_ADMIN role for deployer  
        // console.log("Setting GAUGE_ADMIN role for deployer...");
        // PermissionsRegistry(permissionsRegistry).setRoleFor(deployer, "GAUGE_ADMIN");
        // console.log("GAUGE_ADMIN role set successfully");
        
        // Set GENESIS_MANAGER role for deployer
        console.log("Setting GENESIS_MANAGER role for deployer...");
        PermissionsRegistry(permissionsRegistry).setRoleFor(deployer, "GENESIS_MANAGER");
        console.log("GENESIS_MANAGER role set successfully");
        
        // Set VOTER_ADMIN role for deployer
        console.log("Setting VOTER_ADMIN role for deployer...");
        PermissionsRegistry(permissionsRegistry).setRoleFor(deployer, "VOTER_ADMIN");
        console.log("VOTER_ADMIN role set successfully");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Verification ===");
        
        // Verify roles
        bool hasGovernance = PermissionsRegistry(permissionsRegistry).hasRole("GOVERNANCE", deployer);
        bool hasGaugeAdmin = PermissionsRegistry(permissionsRegistry).hasRole("GAUGE_ADMIN", deployer);
        bool hasGenesisManager = PermissionsRegistry(permissionsRegistry).hasRole("GENESIS_MANAGER", deployer);
        bool hasVoterAdmin = PermissionsRegistry(permissionsRegistry).hasRole("VOTER_ADMIN", deployer);
        
        console.log("Deployer has GOVERNANCE role:", hasGovernance);
        console.log("Deployer has GAUGE_ADMIN role:", hasGaugeAdmin);
        console.log("Deployer has GENESIS_MANAGER role:", hasGenesisManager);
        console.log("Deployer has VOTER_ADMIN role:", hasVoterAdmin);
    }
}