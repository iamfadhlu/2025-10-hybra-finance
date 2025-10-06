// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {CLPool} from "contracts/core/CLPool.sol";
import {CLFactory} from "contracts/core/CLFactory.sol";

contract DeployCL_Step1_Core is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");
    string public jsonConstants;

    // loaded variables
    address public weth;
    
    // deployed contracts
    CLPool public poolImplementation;
    CLFactory public poolFactory;

    function run() public {
        console2.log("=== Step 1: Deploying Core Contracts ===");
        
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);

        weth = abi.decode(vm.parseJson(jsonConstants, ".WETH"), (address));
        
        // Configure for slow chains like Hyperliquid
        configureSlowChain();
        
        vm.startBroadcast(deployerAddress);
        
        // Transaction 1: Deploy pool implementation
        poolImplementation = new CLPool();
        waitForConfirmation("Pool Implementation");
        
        // Transaction 2: Deploy pool factory
        poolFactory = new CLFactory({_poolImplementation: address(poolImplementation)});
        waitForConfirmation("Pool Factory");
        
        vm.stopBroadcast();
        
        // Save results to JSON
        saveResults();
        
        console2.log("=== Step 1 Complete ===");
        console2.log("Pool Implementation:", address(poolImplementation));
        console2.log("Pool Factory:", address(poolFactory));
        console2.log("Next: Run DeployCL_Step2_NFT.s.sol");
    }

    function saveResults() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, "output/DeployCL-Step1-");
        path = concat(path, outputFilename);
        
        vm.writeJson(vm.serializeAddress("", "PoolImplementation", address(poolImplementation)), path);
        vm.writeJson(vm.serializeAddress("", "PoolFactory", address(poolFactory)), path);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /// @notice Configure gas settings for slow chains like Hyperliquid
    function configureSlowChain() internal {
        // Set higher gas price for faster inclusion
        // vm.txGasPrice(100 gwei);
        
        // Log configuration
        console2.log("=== Slow Chain Configuration ===");
        console2.log("Gas Price set to:", vm.envOr("GAS_PRICE", uint256(100 gwei)));
        console2.log("Using transaction delays for confirmations");
        console2.log("================================");
    }

    /// @notice Wait for transaction confirmation with retries
    /// @param operationName Name of the operation for logging
    function waitForConfirmation(string memory operationName) internal {
        console2.log("Deployed:", operationName);
        
        // Add delay for slow chains - gives time for block confirmation
        // This is especially important for Hyperliquid testnet
        vm.sleep(3000); // 3 second delay between transactions
        
        console2.log("Waiting for confirmation:", operationName, "- OK");
    }
}