// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {MinterUpgradeable} from "../contracts/MinterUpgradeable.sol";
import {RewardsDistributor} from "../contracts/RewardsDistributor.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy3a1_MinterRewards is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load previous deployments
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory factoriesPath = getInputPath("Deploy3a_GaugeFactories");
        
        string memory infraJson = vm.readFile(infraPath);
        string memory tokenJson = vm.readFile(tokenPath);
        string memory factoriesJson = vm.readFile(factoriesPath);
        
        // Load addresses
        address proxyAdmin = abi.decode(vm.parseJson(infraJson, ".ProxyAdmin"), (address));
        address votingEscrow = abi.decode(vm.parseJson(tokenJson, ".VotingEscrow"), (address));
        address rewardHybr = abi.decode(vm.parseJson(tokenJson, ".RewardHYBR"), (address));
        address gaugeManager = abi.decode(vm.parseJson(factoriesJson, ".GaugeManager"), (address));
        
        console.log("=== Step 1: Deploy Minter and RewardsDistributor ===");
        console.log("Deployer:", deployer);
        console.log("Using VotingEscrow:", votingEscrow);
        console.log("Using RewardHYBR:", rewardHybr);
        console.log("Using GaugeManager:", gaugeManager);
        
        vm.startBroadcast(deployer);
        
        // 1. Deploy RewardsDistributor
        console.log("Deploying RewardsDistributor...");
        RewardsDistributor rewardsDistributor = new RewardsDistributor(votingEscrow);
        console.log("RewardsDistributor deployed at:", address(rewardsDistributor));
        
        // 2. Deploy Minter
        console.log("Deploying Minter...");
        MinterUpgradeable minterImpl = new MinterUpgradeable();
        TransparentUpgradeableProxy minterProxy = new TransparentUpgradeableProxy(
            address(minterImpl),
            proxyAdmin,
            ""
        );
        MinterUpgradeable minter = MinterUpgradeable(address(minterProxy));
        console.log("Minter deployed at:", address(minter));
        
        // 3. Initialize Minter
        console.log("Initializing Minter...");
        minter.initialize(
            gaugeManager,
            votingEscrow,
            address(rewardsDistributor)
        );
        console.log("Minter initialized");
        
   
        // 5. Set team address
        console.log("Setting team address...");
        minter.setTeam(deployer);
        console.log("Team address set to:", deployer);
        
        vm.stopBroadcast();
        
        // Save to JSON
        string memory path = getOutputPath("Deploy3b1_MinterRewards");
        
        string memory json = "";
        json = vm.serializeAddress("contracts", "Minter", address(minter));
        json = vm.serializeAddress("contracts", "RewardsDistributor", address(rewardsDistributor));
        
        vm.writeJson(json, path);
        console.log("Addresses saved to:", path);
    }
}