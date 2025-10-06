// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {HYBR} from "../contracts/HYBR.sol";
import {RewardHYBR} from "../contracts/RewardHYBR.sol";
import {GrowthHYBR} from "../contracts/GovernanceHYBR.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";

contract Deploy2_TokenSystem is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.rememberKey(deployPrivateKey);
        
        // Load infrastructure addresses
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory infraJson = vm.readFile(infraPath);
        
        address veArtProxy = abi.decode(vm.parseJson(infraJson, ".VeArtProxy"), (address));
        
        console.log("=== Phase 2: Deploy Token System ===");
        console.log("Deployer:", deployerAddress);
        console.log("Using VeArtProxy:", veArtProxy);
        vm.startBroadcast(deployerAddress);
        
        // 1. Deploy HYBR Token
        HYBR hybr = new HYBR();
        console.log("HYBR:", address(hybr));
        
      
      
        
        // 2. Deploy VotingEscrow
        VotingEscrow votingEscrow = new VotingEscrow(
            address(hybr),
            veArtProxy
        );
        console.log("VotingEscrow:", address(votingEscrow));
        
          // 3. Deploy RewardHYBR Token
        RewardHYBR rewardHybr = new RewardHYBR(address(hybr), address(votingEscrow));
        console.log("RewardHYBR:", address(rewardHybr));
        
          // 4. Deploy GovernanceHYBR Token (will need additional addresses, deploy with placeholders for now)
        GrowthHYBR gHybr = new GrowthHYBR(
            address(hybr), 
            address(votingEscrow)
        );
        console.log("GrowthHYBR:", address(gHybr));
        vm.stopBroadcast();
        
        // Save to JSON
        string memory path = getOutputPath("Deploy2_TokenSystem");
        
        string memory json = "";
        json = vm.serializeAddress("tokenSystem", "HYBR", address(hybr));
        json = vm.serializeAddress("tokenSystem", "RewardHYBR", address(rewardHybr));
        json = vm.serializeAddress("tokenSystem", "GrowthHYBR", address(gHybr));
        json = vm.serializeAddress("tokenSystem", "VotingEscrow", address(votingEscrow));
        
        vm.writeJson(json, path);
        console.log("Addresses saved to:", path);
        
        console.log("\n=== Token System Deployment Complete ===");
    }
}