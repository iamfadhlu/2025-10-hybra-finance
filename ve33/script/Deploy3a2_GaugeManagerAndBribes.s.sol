// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {GaugeManager} from "../contracts/GaugeManager.sol";
import {BribeFactoryV3} from "../contracts/factories/BribeFactoryV3.sol";
import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy3a2_GaugeManagerAndBribes is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load previous deployments
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory gaugeFactoriesPath = getInputPath("Deploy3a1_GaugeFactories");
        string memory configPath = getConfigPath();
        
        string memory infraJson = vm.readFile(infraPath);
        string memory tokenJson = vm.readFile(tokenPath);
        string memory gaugeFactoriesJson = vm.readFile(gaugeFactoriesPath);
        string memory configJson = vm.readFile(configPath);
        
        address proxyAdmin = abi.decode(vm.parseJson(infraJson, ".ProxyAdmin"), (address));
        address permissionsRegistry = abi.decode(vm.parseJson(infraJson, ".PermissionsRegistry"), (address));
        address tokenHandler = abi.decode(vm.parseJson(infraJson, ".TokenHandler"), (address));
        address pairFactory = abi.decode(vm.parseJson(configJson, ".v2Factory"), (address));
        address votingEscrow = abi.decode(vm.parseJson(tokenJson, ".VotingEscrow"), (address));
        address clFactory = abi.decode(vm.parseJson(configJson, ".clFactory"), (address));
        address nfpm = abi.decode(vm.parseJson(configJson, ".nonfungiblePositionManager"), (address));
        address gaugeFactory = abi.decode(vm.parseJson(gaugeFactoriesJson, ".GaugeFactory"), (address));
        address gaugeFactoryCL = abi.decode(vm.parseJson(gaugeFactoriesJson, ".GaugeFactoryCL"), (address));
        
        console.log("=== Deploy GaugeManager and BribeFactory ===");
        console.log("Deployer:", deployer);
        console.log("Using VotingEscrow:", votingEscrow);
        console.log("Using GaugeFactory:", gaugeFactory);
        console.log("Using GaugeFactoryCL:", gaugeFactoryCL);
        
        vm.startBroadcast(deployer);
        
        // 1. Deploy GaugeManager
        console.log("Deploying GaugeManager...");
        GaugeManager gaugeManagerImpl = new GaugeManager();
        TransparentUpgradeableProxy gaugeManagerProxy = new TransparentUpgradeableProxy(
            address(gaugeManagerImpl),
            proxyAdmin,
            ""
        );
        GaugeManager gaugeManager = GaugeManager(address(gaugeManagerProxy));
        console.log("GaugeManager:", address(gaugeManager));
        
        // Initialize GaugeManager
        console.log("Initializing GaugeManager...");
        gaugeManager.initialize(
            votingEscrow,                    // __ve
            tokenHandler,                    // _tokenHandler
            gaugeFactory,                    // _gaugeFactory
            gaugeFactoryCL,                  // _gaugeFactoryCL
            pairFactory,                     // _pairFactory
            clFactory,                       // _pairFactoryCL (external Algebra CL factory)
            permissionsRegistry,             // _permissionRegistory
            nfpm                            // _nfpm (external NonFungible Position Manager)
        );
        
        // 2. Deploy BribeFactoryV3
        console.log("Deploying BribeFactoryV3...");
        BribeFactoryV3 bribeFactoryV3Impl = new BribeFactoryV3();
        TransparentUpgradeableProxy bribeFactoryV3Proxy = new TransparentUpgradeableProxy(
            address(bribeFactoryV3Impl),
            proxyAdmin,
            ""
        );
        BribeFactoryV3 bribeFactoryV3 = BribeFactoryV3(address(bribeFactoryV3Proxy));
        console.log("BribeFactoryV3:", address(bribeFactoryV3));
        
        vm.stopBroadcast();
        
        // Save to JSON
        string memory path = getOutputPath("Deploy3a2_GaugeManagerAndBribes");
        
        string memory json = "";
        json = vm.serializeAddress("deployment", "GaugeManager", address(gaugeManager));
        json = vm.serializeAddress("deployment", "BribeFactoryV3", address(bribeFactoryV3));
        
        vm.writeJson(json, path);
        console.log("Addresses saved to:", path);
    }
}