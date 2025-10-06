// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {MinterUpgradeable} from "../contracts/MinterUpgradeable.sol";
import {RewardsDistributor} from "../contracts/RewardsDistributor.sol";
import {GaugeManager} from "../contracts/GaugeManager.sol";
import {GrowthHYBR} from "../contracts/GovernanceHYBR.sol";

contract Deploy3a2_SetupConnections is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load previous deployments
        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory factoriesPath = getInputPath("Deploy3a_GaugeFactories");
        string memory minterPath = getInputPath("Deploy3b1_MinterRewards");
        
        string memory tokenJson = vm.readFile(tokenPath);
        string memory factoriesJson = vm.readFile(factoriesPath);
        string memory minterJson = vm.readFile(minterPath);
        
        // Load addresses
        address gHybr = abi.decode(vm.parseJson(tokenJson, ".GrowthHYBR"), (address));
        address gaugeManager = abi.decode(vm.parseJson(factoriesJson, ".GaugeManager"), (address));
        address minter = abi.decode(vm.parseJson(minterJson, ".Minter"), (address));
        address rewardsDistributor = abi.decode(vm.parseJson(minterJson, ".RewardsDistributor"), (address));
        
        console.log("=== Step 2: Setup Contract Connections ===");
        console.log("Deployer:", deployer);
        console.log("Using GrowthHYBR:", gHybr);
        console.log("Using GaugeManager:", gaugeManager);
        console.log("Using Minter:", minter);
        console.log("Using RewardsDistributor:", rewardsDistributor);
        
        vm.startBroadcast(deployer);
        
        // 1. Set Minter on GaugeManager
        console.log("Setting Minter on GaugeManager...");
        GaugeManager(gaugeManager).setMinter(minter);
        console.log("Minter set on GaugeManager");
        
        // 2. Set Minter as depositor on RewardsDistributor
        console.log("Setting Minter as depositor on RewardsDistributor...");
        RewardsDistributor(rewardsDistributor).setDepositor(minter);
        console.log("Minter set as depositor on RewardsDistributor");
        
        // 3. Set RewardsDistributor on GrowthHYBR
        console.log("Setting RewardsDistributor on GovernanceHYBR...");
        GrowthHYBR(gHybr).setRewardsDistributor(rewardsDistributor);
        console.log("RewardsDistributor set on GovernanceHYBR");
        
        // 4. Set GaugeManager on GrowthHYBR
        console.log("Setting GaugeManager on GovernanceHYBR...");
        GrowthHYBR(gHybr).setGaugeManager(gaugeManager);
        console.log("GaugeManager set on GovernanceHYBR");
        
        vm.stopBroadcast();
        
        console.log("=== All Contract Connections Complete ===");
        
        // Create final combined output
       

        console.log("Final addresses saved to:");
    }
}