// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import {VotingEscrow} from "../contracts/VotingEscrow.sol";

contract EnableSplitPermission is Script {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load VotingEscrow address
        string memory root = vm.projectRoot();
        string memory tokenPath = string.concat(root, "/script/constants/output/Deploy2_TokenSystem.json");
        string memory tokenJson = vm.readFile(tokenPath);
        
        address votingEscrowAddress = abi.decode(vm.parseJson(tokenJson, ".VotingEscrow"), (address));
        VotingEscrow votingEscrow = VotingEscrow(votingEscrowAddress);
        
        console.log("=== Enable Split Permission ===");
        console.log("VotingEscrow:", votingEscrowAddress);
        console.log("Team address:", deployer);
        
        vm.startBroadcast(deployer);
        
        // Enable global split permission (allow everyone to split)
        console.log("Enabling global split permission...");
        votingEscrow.toggleSplit(address(0), true);
        console.log("Global split permission enabled");
        
        // Also enable for deployer specifically
        console.log("Enabling split permission for deployer...");
        votingEscrow.toggleSplit(deployer, true);
        console.log("Deployer split permission enabled");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Verification ===");
        
        // Verify permissions
        bool globalPermission = votingEscrow.canSplit(address(0));
        bool deployerPermission = votingEscrow.canSplit(deployer);
        
        console.log("Global split permission:", globalPermission);
        console.log("Deployer split permission:", deployerPermission);
        
        console.log("=== Setup Complete ===");
    }
}