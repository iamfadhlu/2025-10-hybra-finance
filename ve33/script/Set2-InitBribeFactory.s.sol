// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {BribeFactoryV3} from "../contracts/factories/BribeFactoryV3.sol";

contract InitBribeFactory is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load deployed contracts
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory factoriesPath = getInputPath("Deploy3a_GaugeFactories");
        string memory votingPath = getInputPath("Deploy3c_Voting");
        
        string memory infraJson = vm.readFile(infraPath);
        string memory factoriesJson = vm.readFile(factoriesPath);
        string memory votingJson = vm.readFile(votingPath);
        
        address permissionsRegistry = abi.decode(vm.parseJson(infraJson, ".PermissionsRegistry"), (address));
        address tokenHandler = abi.decode(vm.parseJson(infraJson, ".TokenHandler"), (address));
        address gaugeManager = abi.decode(vm.parseJson(factoriesJson, ".GaugeManager"), (address));
        address bribeFactoryV3 = abi.decode(vm.parseJson(factoriesJson, ".BribeFactoryV3"), (address));
        address voter = abi.decode(vm.parseJson(votingJson, ".VoterV3"), (address));
        
        console.log("=== Initialize BribeFactoryV3 ===");
        console.log("BribeFactoryV3:", bribeFactoryV3);
        console.log("Voter:", voter);
        console.log("GaugeManager:", gaugeManager);
        console.log("PermissionsRegistry:", permissionsRegistry);
        console.log("TokenHandler:", tokenHandler);
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployer);
        
        // Initialize BribeFactoryV3
        console.log("Initializing BribeFactoryV3...");
        BribeFactoryV3(bribeFactoryV3).initialize(
            voter,                  // _voter
            gaugeManager,          // _gaugeManager
            permissionsRegistry,   // _permissionsRegistry
            tokenHandler          // _tokenHandler
        );
        console.log("BribeFactoryV3 initialized successfully");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Verification ===");
        
        // Verify initialization
        address storedVoter = BribeFactoryV3(bribeFactoryV3).voter();
        address storedGaugeManager = BribeFactoryV3(bribeFactoryV3).gaugeManager();
        
        console.log("Stored Voter:", storedVoter);
        console.log("Stored GaugeManager:", storedGaugeManager);
        console.log("Voter matches:", storedVoter == voter);
        console.log("GaugeManager matches:", storedGaugeManager == gaugeManager);
    }
}