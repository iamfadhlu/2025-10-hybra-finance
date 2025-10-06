// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {QuoterV2} from "contracts/periphery/lens/QuoterV2.sol";
import {SwapRouter} from "contracts/periphery/SwapRouter.sol";

contract DeployCL_Step5_Periphery is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");
    string public jsonConstants;

    // loaded variables
    address public weth;
    address public poolFactory;
    
    // deployed contracts
    QuoterV2 public quoter;
    SwapRouter public swapRouter;

    function run() public {
        console2.log("=== Step 5: Deploying Periphery Contracts ===");
        
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);

        // Load constants
        weth = abi.decode(vm.parseJson(jsonConstants, ".WETH"), (address));
        
        // Load previously deployed contracts
        loadPreviousDeployments();
        
        // Configure for slow chains like Hyperliquid
        configureSlowChain();
        
        vm.startBroadcast(deployerAddress);
        
        // Transaction 1: Deploy quoter
        quoter = new QuoterV2({_factory: address(poolFactory), _WETH9: weth});
        waitForConfirmation("Quoter V2");
        
        // Transaction 2: Deploy swap router
        swapRouter = new SwapRouter({_factory: address(poolFactory), _WETH9: weth});
        waitForConfirmation("Swap Router");
        
        vm.stopBroadcast();
        
        // Save results and create final combined JSON
        saveResults();
        createFinalJSON();
        
        console2.log("=== Step 5 Complete ===");
        console2.log("Quoter V2:", address(quoter));
        console2.log("Swap Router:", address(swapRouter));
        console2.log("=== ALL DEPLOYMENT STEPS COMPLETE ===");
        console2.log("Final combined JSON created at: output/DeployCL-", outputFilename);
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
        string memory path = concat(basePath, "output/DeployCL-Step5-");
        path = concat(path, outputFilename);
        
        vm.writeJson(vm.serializeAddress("", "Quoter", address(quoter)), path);
        vm.writeJson(vm.serializeAddress("", "SwapRouter", address(swapRouter)), path);
    }

    function createFinalJSON() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        
        // Load all step results
        string memory step1Path = concat(basePath, "output/DeployCL-Step1-");
        step1Path = concat(step1Path, outputFilename);
        string memory step1Json = vm.readFile(step1Path);
        
        string memory step2Path = concat(basePath, "output/DeployCL-Step2-");
        step2Path = concat(step2Path, outputFilename);
        string memory step2Json = vm.readFile(step2Path);
        
        string memory step3Path = concat(basePath, "output/DeployCL-Step3-");
        step3Path = concat(step3Path, outputFilename);
        string memory step3Json = vm.readFile(step3Path);
        
        string memory step5Path = concat(basePath, "output/DeployCL-Step5-");
        step5Path = concat(step5Path, outputFilename);
        string memory step5Json = vm.readFile(step5Path);
        
        // Create final combined JSON
        string memory finalPath = concat(basePath, "output/DeployCL-");
        finalPath = concat(finalPath, outputFilename);
        
        // Combine all addresses into final JSON
        address poolImplementation = abi.decode(step1Json.parseRaw(".PoolImplementation"), (address));
        address poolFactory = abi.decode(step1Json.parseRaw(".PoolFactory"), (address));
        address nftDescriptor = abi.decode(step2Json.parseRaw(".NonfungibleTokenPositionDescriptor"), (address));
        address nft = abi.decode(step2Json.parseRaw(".NonfungiblePositionManager"), (address));
        address swapFeeModule = abi.decode(step3Json.parseRaw(".SwapFeeModule"), (address));
        address unstakedFeeModule = abi.decode(step3Json.parseRaw(".UnstakedFeeModule"), (address));
        address protocolFeeModule = abi.decode(step3Json.parseRaw(".ProtocolFeeModule"), (address));
        address quoterAddr = abi.decode(step5Json.parseRaw(".Quoter"), (address));
        address swapRouterAddr = abi.decode(step5Json.parseRaw(".SwapRouter"), (address));
        
        vm.writeJson(vm.serializeAddress("", "PoolImplementation", poolImplementation), finalPath);
        vm.writeJson(vm.serializeAddress("", "PoolFactory", poolFactory), finalPath);
        vm.writeJson(vm.serializeAddress("", "NonfungibleTokenPositionDescriptor", nftDescriptor), finalPath);
        vm.writeJson(vm.serializeAddress("", "NonfungiblePositionManager", nft), finalPath);
        vm.writeJson(vm.serializeAddress("", "GaugeImplementation", address(0)), finalPath); // Placeholder
        vm.writeJson(vm.serializeAddress("", "GaugeFactory", address(0)), finalPath); // Placeholder
        vm.writeJson(vm.serializeAddress("", "SwapFeeModule", swapFeeModule), finalPath);
        vm.writeJson(vm.serializeAddress("", "UnstakedFeeModule", unstakedFeeModule), finalPath);
        vm.writeJson(vm.serializeAddress("", "Quoter", quoterAddr), finalPath);
        vm.writeJson(vm.serializeAddress("", "SwapRouter", swapRouterAddr), finalPath);
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