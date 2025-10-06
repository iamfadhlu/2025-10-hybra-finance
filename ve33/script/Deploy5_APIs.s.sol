// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {RewardAPI} from "../contracts/APIHelper/RewardAPI.sol";
import {veNFTAPIV1} from "../contracts/APIHelper/veNFTAPIV1.sol";
import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy5_APIs is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load previous deployments
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory voterPath = getInputPath("Deploy3c_Voting");
        string memory gaugeFactoriesPath = getInputPath("Deploy3a_GaugeFactories");
        string memory minterPath = getInputPath("Deploy3b1_MinterRewards");
        
        string memory infraJson = vm.readFile(infraPath);
        string memory voterJson = vm.readFile(voterPath);
        string memory gaugeFactoriesJson = vm.readFile(gaugeFactoriesPath);
        string memory minterJson = vm.readFile(minterPath);
        
        // Load addresses
        address proxyAdmin = abi.decode(vm.parseJson(infraJson, ".ProxyAdmin"), (address));
        address voter = abi.decode(vm.parseJson(voterJson, ".VoterV3"), (address));
        address gaugeManager = abi.decode(vm.parseJson(gaugeFactoriesJson, ".GaugeManager"), (address));
        address gaugeFactory = abi.decode(vm.parseJson(gaugeFactoriesJson, ".GaugeFactory"), (address));
        address gaugeFactoryCL = abi.decode(vm.parseJson(gaugeFactoriesJson, ".GaugeFactoryCL"), (address));
        address rewardsDistributor = abi.decode(vm.parseJson(minterJson, ".RewardsDistributor"), (address));
        
        console.log("=== Deploy API Contracts ===");
        console.log("Deployer:", deployer);
        console.log("Using Voter:", voter);
        console.log("Using GaugeManager:", gaugeManager);
        console.log("Using GaugeFactory:", gaugeFactory);
        console.log("Using GaugeFactoryCL:", gaugeFactoryCL);
        console.log("Using RewardsDistributor:", rewardsDistributor);
        vm.txGasPrice(80 gwei);
        vm.startBroadcast(deployer);
        
        // 1. Deploy RewardAPI
        console.log("\n1. Deploying RewardAPI...");
        RewardAPI rewardAPIImpl = new RewardAPI();
        TransparentUpgradeableProxy rewardAPIProxy = new TransparentUpgradeableProxy(
            address(rewardAPIImpl),
            proxyAdmin,
            abi.encodeWithSelector(
                RewardAPI.initialize.selector,
                voter,
                gaugeManager,
                gaugeFactory,
                gaugeFactoryCL
            )
        );
        RewardAPI rewardAPI = RewardAPI(address(rewardAPIProxy));
        console.log("RewardAPI deployed at:", address(rewardAPI));
        
        // 2. Deploy veNFTAPIV1 (using V1 for better functionality)
        console.log("\n2. Deploying veNFTAPIV1...");
        veNFTAPIV1 veNFTAPIV1Impl = new veNFTAPIV1();
        TransparentUpgradeableProxy veNFTAPIV1Proxy = new TransparentUpgradeableProxy(
            address(veNFTAPIV1Impl),
            proxyAdmin,
            abi.encodeWithSelector(
                veNFTAPIV1.initialize.selector,
                voter,
                rewardsDistributor,
                gaugeFactory,
                gaugeFactoryCL,
                gaugeManager
            )
        );
        veNFTAPIV1 veNftApi = veNFTAPIV1(address(veNFTAPIV1Proxy));
        console.log("veNFTAPIV1 deployed at:", address(veNftApi));
        
        // 3. Set ownership (optional - can be transferred to multisig later)
        console.log("\n3. Setting ownership...");
        rewardAPI.setOwner(deployer);
        veNftApi.setOwner(deployer);
        console.log("Owner set to:", deployer);
        
        vm.stopBroadcast();
        
        console.log("\n=== API Deployment Complete ===");
        console.log("RewardAPI:", address(rewardAPI));
        console.log("veNFTAPIV1:", address(veNftApi));
        
        // Save to JSON
        string memory path = getOutputPath("Deploy5_APIs");
        
        string memory json = "";
        json = vm.serializeAddress("apis", "RewardAPI", address(rewardAPI));
        json = vm.serializeAddress("apis", "veNFTAPIV1", address(veNftApi));
        
        vm.writeJson(json, path);
        console.log("\nAddresses saved to:", path);
    }
}