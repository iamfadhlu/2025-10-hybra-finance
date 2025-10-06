// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";
import {VeArtProxyUpgradeable} from "../contracts/VeArtProxyUpgradeable.sol";
import {TokenHandler} from "../contracts/TokenHandler.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract Deploy1_Infrastructure is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.rememberKey(deployPrivateKey);
        
        console.log("=== Phase 1: Deploy Infrastructure ===");
        console.log("Deployer:", deployerAddress);
        vm.txGasPrice(30 gwei);
        vm.startBroadcast(deployerAddress);
        
        // 1. Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin:", address(proxyAdmin));
        
        // 2. Deploy PermissionsRegistry
        PermissionsRegistry permissionsRegistry = new PermissionsRegistry();
        console.log("PermissionsRegistry:", address(permissionsRegistry));
        
        // 3. Deploy VeArtProxy
        VeArtProxyUpgradeable veArtProxyImpl = new VeArtProxyUpgradeable();
        TransparentUpgradeableProxy veArtProxyProxy = new TransparentUpgradeableProxy(
            address(veArtProxyImpl),
            address(proxyAdmin),
            ""
        );
        VeArtProxyUpgradeable veArtProxy = VeArtProxyUpgradeable(address(veArtProxyProxy));
        veArtProxy.initialize();
        console.log("VeArtProxy:", address(veArtProxy));
        
        // 4. Deploy TokenHandler
        TokenHandler tokenHandler = new TokenHandler(address(permissionsRegistry));
        console.log("TokenHandler:", address(tokenHandler));
        
        vm.stopBroadcast();

        // Save to JSON
        string memory path = getOutputPath("Deploy1_Infrastructure");

        string memory json = "";
        json = vm.serializeAddress("infrastructure", "ProxyAdmin", address(proxyAdmin));
        json = vm.serializeAddress("infrastructure", "PermissionsRegistry", address(permissionsRegistry));
        json = vm.serializeAddress("infrastructure", "VeArtProxy", address(veArtProxy));
        json = vm.serializeAddress("infrastructure", "TokenHandler", address(tokenHandler));

        vm.writeJson(json, path);
        console.log("Addresses saved to:", path);
        
        console.log("\n=== Infrastructure Deployment Complete ===");
    }
}