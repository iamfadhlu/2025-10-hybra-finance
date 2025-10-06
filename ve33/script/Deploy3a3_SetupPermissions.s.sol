// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {GaugeManager} from "../contracts/GaugeManager.sol";
import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";

contract Deploy3a3_SetupPermissions is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load previous deployments
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory gaugeManagerPath = getInputPath("Deploy3a2_GaugeManagerAndBribes");
        
        string memory infraJson = vm.readFile(infraPath);
        string memory gaugeManagerJson = vm.readFile(gaugeManagerPath);
        
        address permissionsRegistry = abi.decode(vm.parseJson(infraJson, ".PermissionsRegistry"), (address));
        address gaugeManager = abi.decode(vm.parseJson(gaugeManagerJson, ".GaugeManager"), (address));
        address bribeFactoryV3 = abi.decode(vm.parseJson(gaugeManagerJson, ".BribeFactoryV3"), (address));
        
        console.log("=== Setup Permissions and Final Configuration ===");
        console.log("Deployer:", deployer);
        console.log("Using PermissionsRegistry:", permissionsRegistry);
        console.log("Using GaugeManager:", gaugeManager);
        console.log("Using BribeFactoryV3:", bribeFactoryV3);
        
        vm.startBroadcast(deployer);
        
        // Setup permissions for GaugeManager operations
        console.log("Setting up GAUGE_ADMIN role for deployer...");
        PermissionsRegistry(permissionsRegistry).setRoleFor(deployer, "GAUGE_ADMIN");
        console.log("GAUGE_ADMIN role assigned to deployer");
        
        // Set BribeFactory on GaugeManager
        console.log("Setting BribeFactory on GaugeManager...");
        GaugeManager(gaugeManager).setBribeFactory(bribeFactoryV3);
        console.log("BribeFactory set on GaugeManager");
        
        // Ensure PermissionsRegistry is properly set (redundant but explicit)
        console.log("Confirming PermissionsRegistry on GaugeManager...");
        GaugeManager(gaugeManager).setPermissionsRegistry(permissionsRegistry);
        console.log("PermissionsRegistry confirmed on GaugeManager");
        
        vm.stopBroadcast();
        
        // Create final combined output
        string memory path = getOutputPath("Deploy3a_GaugeFactories");

        // Load all previous outputs to combine
        string memory gaugeFactoriesPath = getInputPath("Deploy3a1_GaugeFactories");
        string memory gaugeFactoriesJson = vm.readFile(gaugeFactoriesPath);
        
        address gaugeFactory = abi.decode(vm.parseJson(gaugeFactoriesJson, ".GaugeFactory"), (address));
        address gaugeFactoryCL = abi.decode(vm.parseJson(gaugeFactoriesJson, ".GaugeFactoryCL"), (address));
        
        string memory json = "";
        json = vm.serializeAddress("factories", "GaugeFactory", gaugeFactory);
        json = vm.serializeAddress("factories", "GaugeFactoryCL", gaugeFactoryCL);
        json = vm.serializeAddress("factories", "GaugeManager", gaugeManager);
        json = vm.serializeAddress("factories", "BribeFactoryV3", bribeFactoryV3);
        
        vm.writeJson(json, path);
        console.log("Complete deployment addresses saved to:", path);
    }
}