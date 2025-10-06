// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {MinterUpgradeable} from "../contracts/MinterUpgradeable.sol";
import {VoterV3} from "../contracts/VoterV3.sol";
import {BribeFactoryV3} from "../contracts/factories/BribeFactoryV3.sol";
import {GaugeManager} from "../contracts/GaugeManager.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy3c_Voting is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer =  vm.rememberKey(deployerKey);
        
        // Load previous deployments
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory factoriesPath = getInputPath("Deploy3a_GaugeFactories");
        string memory infraJson = vm.readFile(infraPath);
        string memory tokenJson = vm.readFile(tokenPath);
        string memory factoriesJson = vm.readFile(factoriesPath);
        
        // Load addresses
        address proxyAdmin = abi.decode(vm.parseJson(infraJson, ".ProxyAdmin"), (address));
        address permissionsRegistry = abi.decode(vm.parseJson(infraJson, ".PermissionsRegistry"), (address));
        address tokenHandler = abi.decode(vm.parseJson(infraJson, ".TokenHandler"), (address));
        address votingEscrow = abi.decode(vm.parseJson(tokenJson, ".VotingEscrow"), (address));
        address gaugeManager = abi.decode(vm.parseJson(factoriesJson, ".GaugeManager"), (address));
        
        console.log("=== Deploy Voting System ===");
        console.log("Deployer:", deployer);
        console.log("Using GaugeManager:", gaugeManager);
        console.log("");
        
        vm.startBroadcast(deployer);
        
     
        
        // 2. Deploy VoterV3
        console.log("Deploying VoterV3...");
        VoterV3 voterImpl = new VoterV3();
        TransparentUpgradeableProxy voterProxy = new TransparentUpgradeableProxy(
            address(voterImpl),
            proxyAdmin,
            abi.encodeWithSelector(
                VoterV3.initialize.selector,
                votingEscrow,          // __ve
                tokenHandler,          // _tokenHandler  
                gaugeManager,          // _gaugeManager
                permissionsRegistry    // _permissionRegistry
            )
        );
        VoterV3 voter = VoterV3(address(voterProxy));
        console.log("VoterV3:", address(voter));
        
        // 3. Set Voter in GaugeManager
        console.log("\nSetting Voter in GaugeManager...");
        GaugeManager(gaugeManager).setVoter(address(voter));
        console.log("Voter set in GaugeManager:", address(voter));
        
        // 4. Set Voter in VotingEscrow
        console.log("\nSetting Voter in VotingEscrow...");
        VotingEscrow(votingEscrow).setVoter(address(voter));
        console.log("Voter set in VotingEscrow:", address(voter));
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Voting System Deployment and Setup Complete ===");
        console.log("Voter has been configured in both GaugeManager and VotingEscrow");
        
        // Save to JSON
        string memory path = getOutputPath("Deploy3c_Voting");
        
        string memory json = "";
        json = vm.serializeAddress("voting", "VoterV3", address(voter));
        json = vm.serializeAddress("voting", "Voter", address(voter)); // Also save as "Voter" for backward compatibility
        
        vm.writeJson(json, path);
        console.log("Addresses saved to:", path);
    }
}