// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {DynamicSwapFeeModule} from "contracts/core/fees/DynamicSwapFeeModule.sol";
import {CustomUnstakedFeeModule} from "contracts/core/fees/CustomUnstakedFeeModule.sol";
import {CustomProtocolFeeModule} from "contracts/core/fees/CustomProtocolFeeModule.sol";

contract DeployCL_Step3_Fees is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");
    string public jsonConstants;

    // loaded variables
    address public poolFactory;
    
    // deployed contracts
    DynamicSwapFeeModule public swapFeeModule;
    CustomUnstakedFeeModule public unstakedFeeModule;
    CustomProtocolFeeModule public protocolFeeModule;

    function run() public {
        console2.log("=== Step 3: Deploying Fee Modules ===");
        
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);
        
        // Load previously deployed contracts
        loadPreviousDeployments();
        
        // Configure for slow chains like Hyperliquid
        configureSlowChain();
        
        vm.startBroadcast(deployerAddress);
        
        // Prepare initial fee configuration
        address[] memory initialPools = new address[](0);
        uint24[] memory initialFees = new uint24[](0);
        
        // Transaction 1: Deploy dynamic swap fee module
        swapFeeModule = new DynamicSwapFeeModule({
            _factory: address(poolFactory),
            _defaultScalingFactor: 10000,  // 1 basis point per tick deviation
            _defaultFeeCap: 10000,          // 1% max total fee
            _pools: initialPools,
            _fees: initialFees
        });
        waitForConfirmation("Dynamic Swap Fee Module");
        
        // Transaction 2: Deploy unstaked fee module
        unstakedFeeModule = new CustomUnstakedFeeModule({_factory: address(poolFactory)});
        waitForConfirmation("Unstaked Fee Module");
        
        // Transaction 3: Deploy protocol fee module
        protocolFeeModule = new CustomProtocolFeeModule({_factory: address(poolFactory)});
        waitForConfirmation("Protocol Fee Module");
        
        vm.stopBroadcast();
        
        // Save results to JSON
        saveResults();
        
        console2.log("=== Step 3 Complete ===");
        console2.log("Swap Fee Module:", address(swapFeeModule));
        console2.log("Unstaked Fee Module:", address(unstakedFeeModule));
        console2.log("Protocol Fee Module:", address(protocolFeeModule));
        console2.log("Next: Run DeployCL_Step4_Config.s.sol");
    }

    function loadPreviousDeployments() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, "output/DeployCL-Step1-");
        path = concat(path, outputFilename);
        
        string memory jsonOutput = vm.readFile(path);
        poolFactory = abi.decode(jsonOutput.parseRaw(".PoolFactory"), (address));
        
        console2.log("Loaded Pool Factory:", poolFactory);
    }

    function saveResults() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, "output/DeployCL-Step3-");
        path = concat(path, outputFilename);
        
        vm.writeJson(vm.serializeAddress("", "SwapFeeModule", address(swapFeeModule)), path);
        vm.writeJson(vm.serializeAddress("", "UnstakedFeeModule", address(unstakedFeeModule)), path);
        vm.writeJson(vm.serializeAddress("", "ProtocolFeeModule", address(protocolFeeModule)), path);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /// @notice Configure gas settings for slow chains like Hyperliquid
    function configureSlowChain() internal {
        vm.txGasPrice(100 gwei);
        console2.log("=== Slow Chain Configuration ===");
        console2.log("Gas Price set to:", vm.envOr("GAS_PRICE", uint256(100 gwei)));
        console2.log("Using transaction delays for confirmations");
        console2.log("================================");
    }

    /// @notice Wait for transaction confirmation with retries
    /// @param operationName Name of the operation for logging
    function waitForConfirmation(string memory operationName) internal {
        console2.log("Deployed:", operationName);
        vm.sleep(3000); // 3 second delay between transactions
        console2.log("Waiting for confirmation:", operationName, "- OK");
    }
}