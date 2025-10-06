// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import {BribeFactoryV3} from "../contracts/factories/BribeFactoryV3.sol";
import {GaugeManager} from "../contracts/GaugeManager.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployBribeFactoryV3 is Script {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load deployed contracts
        string memory root = vm.projectRoot();
        string memory infraPath = string.concat(root, "/script/constants/output/Deploy1_Infrastructure.json");
        string memory factoriesPath = string.concat(root, "/script/constants/output/Deploy3a_GaugeFactories.json");
        string memory votingPath = string.concat(root, "/script/constants/output/Deploy3b_Voting.json");
        
        string memory infraJson = vm.readFile(infraPath);
        string memory factoriesJson = vm.readFile(factoriesPath);
        string memory votingJson = vm.readFile(votingPath);
        
        // Load required addresses
        address proxyAdmin = abi.decode(vm.parseJson(infraJson, ".ProxyAdmin"), (address));
        address permissionsRegistry = abi.decode(vm.parseJson(infraJson, ".PermissionsRegistry"), (address));
        address tokenHandler = abi.decode(vm.parseJson(infraJson, ".TokenHandler"), (address));
        address gaugeManager = abi.decode(vm.parseJson(factoriesJson, ".GaugeManager"), (address));
        address voter = abi.decode(vm.parseJson(votingJson, ".VoterV3"), (address));
        
        console.log("=== Deploy New BribeFactoryV3 ===");
        console.log("Deployer:", deployer);
        console.log("ProxyAdmin:", proxyAdmin);
        console.log("Voter:", voter);
        console.log("GaugeManager:", gaugeManager);
        console.log("PermissionsRegistry:", permissionsRegistry);
        console.log("TokenHandler:", tokenHandler);
        console.log("");
        
        vm.startBroadcast(deployer);
        
        // 1. Deploy BribeFactoryV3 implementation
        console.log("Deploying BribeFactoryV3 implementation...");
        BribeFactoryV3 bribeFactoryV3Impl = new BribeFactoryV3();
        console.log("BribeFactoryV3 implementation:", address(bribeFactoryV3Impl));
        
        // 2. Deploy proxy with initialization
        console.log("");
        console.log("Deploying BribeFactoryV3 proxy with initialization...");
        TransparentUpgradeableProxy bribeFactoryV3Proxy = new TransparentUpgradeableProxy(
            address(bribeFactoryV3Impl),
            proxyAdmin,
            abi.encodeWithSelector(
                BribeFactoryV3.initialize.selector,
                voter,                  // _voter
                gaugeManager,          // _gaugeManager
                permissionsRegistry,   // _permissionsRegistry
                tokenHandler          // _tokenHandler
            )
        );
        BribeFactoryV3 bribeFactoryV3 = BribeFactoryV3(address(bribeFactoryV3Proxy));
        console.log("BribeFactoryV3 proxy deployed and initialized at:", address(bribeFactoryV3));
        
        // 3. Set BribeFactory on GaugeManager
        console.log("");
        console.log("Setting BribeFactory on GaugeManager...");
        GaugeManager(gaugeManager).setBribeFactory(address(bribeFactoryV3));
        console.log("BribeFactory set on GaugeManager successfully");
        
        vm.stopBroadcast();
        
        // Verification
        console.log("");
        console.log("=== Verification ===");
        
        // Verify BribeFactoryV3 initialization
        address storedVoter = bribeFactoryV3.voter();
        address storedGaugeManager = bribeFactoryV3.gaugeManager();
        
        console.log("BribeFactoryV3 voter:", storedVoter);
        console.log("Expected voter:", voter);
        console.log("Voter matches:", storedVoter == voter);
        
        console.log("BribeFactoryV3 gaugeManager:", storedGaugeManager);
        console.log("Expected gaugeManager:", gaugeManager);
        console.log("GaugeManager matches:", storedGaugeManager == gaugeManager);
        
        // Save to JSON
        string memory outputPath = string.concat(root, "/script/constants/output/Deploy_BribeFactoryV3.json");
        
        string memory json = "";
        json = vm.serializeAddress("deployment", "BribeFactoryV3", address(bribeFactoryV3));
        json = vm.serializeAddress("deployment", "BribeFactoryV3Implementation", address(bribeFactoryV3Impl));
        json = vm.serializeAddress("deployment", "deployer", deployer);
        json = vm.serializeString("deployment", "timestamp", vm.toString(block.timestamp));
        
        vm.writeJson(json, outputPath);
        console.log("");
        console.log("Deployment details saved to:", outputPath);
        
        // Summary
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("New BribeFactoryV3 deployed at:", address(bribeFactoryV3));
        console.log("Implementation:", address(bribeFactoryV3Impl));
        console.log("Initialized with:");
        console.log("  - Voter:", voter);
        console.log("  - GaugeManager:", gaugeManager);
        console.log("  - PermissionsRegistry:", permissionsRegistry);
        console.log("  - TokenHandler:", tokenHandler);
        console.log("Dependencies configured:");
        console.log("  - BribeFactory set on GaugeManager");
    }
}