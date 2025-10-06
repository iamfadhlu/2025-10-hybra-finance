// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "forge-std/Script.sol";
import "contracts/core/CLFactory.sol";

contract SetGaugeManager is Script {
    function run() external {
        string memory constantsFilename = vm.envString("CONSTANTS_FILENAME");
        // Load the CLFactory address from deployments
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/output/DeployCL-");
        string memory path = concat(basePath, constantsFilename);
        string memory deployments = vm.readFile(path);
        address clFactoryAddress = vm.parseJsonAddress(deployments, ".PoolFactory");
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
        address deployerAddress = vm.rememberKey(deployPrivateKey);
        // The gauge manager address to set
        address gaugeManagerAddress = 0x46c96Db6bB22EaD450247D8DF40fc99e305135A2;
        
        vm.startBroadcast(deployerAddress);
        
        CLFactory factory = CLFactory(clFactoryAddress);
        
        console.log("Setting gauge manager for CLFactory at:", clFactoryAddress);
        console.log("New gauge manager address:", gaugeManagerAddress);
        
        // Set the gauge manager
        factory.setGaugeManager(gaugeManagerAddress);
        
        // Verify the gauge manager was set
        address newGaugeManager = address(factory.gaugeManager());
        console.log("Gauge manager successfully set to:", newGaugeManager);
        
        vm.stopBroadcast();
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

}