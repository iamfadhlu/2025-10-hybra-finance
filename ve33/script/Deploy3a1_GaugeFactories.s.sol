// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {GaugeFactory} from "../contracts/factories/GaugeFactory.sol";
import {GaugeFactoryCL} from "../contracts/CLGauge/GaugeFactoryCL.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Deploy3a1_GaugeFactories is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load previous deployments
        string memory infraPath = getInputPath("Deploy1_Infrastructure");
        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory infraJson = vm.readFile(infraPath);
        string memory tokenJson = vm.readFile(tokenPath);
        
        address proxyAdmin = abi.decode(vm.parseJson(infraJson, ".ProxyAdmin"), (address));
        address permissionsRegistry = abi.decode(vm.parseJson(infraJson, ".PermissionsRegistry"), (address));
        address rHYBR = abi.decode(vm.parseJson(tokenJson, ".RewardHYBR"), (address));
        
        console.log("=== Deploy Gauge Factories ===");
        console.log("Deployer:", deployer);
        console.log("Using PermissionsRegistry:", permissionsRegistry);
        console.log("Using rHYBR:", rHYBR);
        
        vm.startBroadcast(deployer);
        
        // 1. Deploy GaugeFactory  
        console.log("Deploying GaugeFactory...");
        GaugeFactory gaugeFactoryImpl = new GaugeFactory();
        TransparentUpgradeableProxy gaugeFactoryProxy = new TransparentUpgradeableProxy(
            address(gaugeFactoryImpl),
            proxyAdmin,
            abi.encodeWithSelector(
                GaugeFactory.initialize.selector,
                permissionsRegistry
            )
        );
        GaugeFactory gaugeFactory = GaugeFactory(address(gaugeFactoryProxy));
        console.log("GaugeFactory:", address(gaugeFactory));
        
        gaugeFactory.setRHYBR(rHYBR);
        
        // 2. Deploy GaugeFactoryCL
        console.log("Deploying GaugeFactoryCL...");
        GaugeFactoryCL gaugeFactoryCLImpl = new GaugeFactoryCL();
        TransparentUpgradeableProxy gaugeFactoryCLProxy = new TransparentUpgradeableProxy(
            address(gaugeFactoryCLImpl),
            proxyAdmin,
            abi.encodeWithSelector(
                GaugeFactoryCL.initialize.selector,
                permissionsRegistry
            )
        );
        GaugeFactoryCL gaugeFactoryCL = GaugeFactoryCL(address(gaugeFactoryCLProxy));
        console.log("GaugeFactoryCL:", address(gaugeFactoryCL));
        
        gaugeFactoryCL.setRHYBR(rHYBR);
        
        vm.stopBroadcast();
        
        // Save to JSON
        string memory path = getOutputPath("Deploy3a1_GaugeFactories");
        
        string memory json = "";
        json = vm.serializeAddress("factories", "GaugeFactory", address(gaugeFactory));
        json = vm.serializeAddress("factories", "GaugeFactoryCL", address(gaugeFactoryCL));
        
        vm.writeJson(json, path);
        console.log("Addresses saved to:", path);
    }
}