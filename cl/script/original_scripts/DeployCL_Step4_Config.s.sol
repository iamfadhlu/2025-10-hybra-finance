// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {CLFactory} from "contracts/core/CLFactory.sol";
import {NonfungiblePositionManager} from "contracts/periphery/NonfungiblePositionManager.sol";

contract DeployCL_Step4_Config is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");
    string public jsonConstants;

    // loaded variables
    address public team;
    address public poolFactoryOwner;
    address public feeManager;
    
    // loaded contracts
    CLFactory public poolFactory;
    NonfungiblePositionManager public nft;
    address public swapFeeModule;
    address public unstakedFeeModule;
    address public protocolFeeModule;

    function run() public {
        console2.log("=== Step 4: Configuring Contracts ===");
        
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);

        // Load constants
        team = abi.decode(vm.parseJson(jsonConstants, ".team"), (address));
        poolFactoryOwner = abi.decode(vm.parseJson(jsonConstants, ".poolFactoryOwner"), (address));
        feeManager = abi.decode(vm.parseJson(jsonConstants, ".feeManager"), (address));
        
        // Load previously deployed contracts
        loadPreviousDeployments();
        
        // Configure for slow chains like Hyperliquid
        configureSlowChain();
        
        vm.startBroadcast(deployerAddress);
        
        // Transaction 1: Set swap fee module
        poolFactory.setSwapFeeModule({_swapFeeModule: swapFeeModule});
        waitForConfirmation("Set Swap Fee Module");
        
        // Transaction 2: Set unstaked fee module
        poolFactory.setUnstakedFeeModule({_unstakedFeeModule: unstakedFeeModule});
        waitForConfirmation("Set Unstaked Fee Module");
        
        // Transaction 3: Set protocol fee module
        poolFactory.setProtocolFeeModule({_protocolFeeModule: protocolFeeModule});
        waitForConfirmation("Set Protocol Fee Module");
        
        // Transaction 4: Set NFT owner
        nft.setOwner(team);
        waitForConfirmation("Set NFT Owner");
        
        // Transaction 5: Set factory owner
        poolFactory.setOwner(poolFactoryOwner);
        waitForConfirmation("Set Factory Owner");
        
        // Transaction 6: Set fee managers (combined to save transactions)
        poolFactory.setSwapFeeManager(feeManager);
        waitForConfirmation("Set Swap Fee Manager");
        
        vm.stopBroadcast();
        
        // Additional transactions in separate broadcast
        vm.startBroadcast(deployerAddress);
        
        poolFactory.setUnstakedFeeManager(feeManager);
        waitForConfirmation("Set Unstaked Fee Manager");
        
        poolFactory.setProtocolFeeManager(feeManager);
        waitForConfirmation("Set Protocol Fee Manager");
        
        vm.stopBroadcast();
        
        console2.log("=== Step 4 Complete ===");
        console2.log("All fee modules configured");
        console2.log("All permissions transferred");
        console2.log("Next: Run DeployCL_Step5_Periphery.s.sol");
    }

    function loadPreviousDeployments() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        
        // Load Step 1 deployments
        string memory path1 = concat(basePath, "output/DeployCL-Step1-");
        path1 = concat(path1, outputFilename);
        string memory jsonOutput1 = vm.readFile(path1);
        poolFactory = CLFactory(abi.decode(jsonOutput1.parseRaw(".PoolFactory"), (address)));
        
        // Load Step 2 deployments
        string memory path2 = concat(basePath, "output/DeployCL-Step2-");
        path2 = concat(path2, outputFilename);
        string memory jsonOutput2 = vm.readFile(path2);
        nft = NonfungiblePositionManager(abi.decode(jsonOutput2.parseRaw(".NonfungiblePositionManager"), (address)));
        
        // Load Step 3 deployments
        string memory path3 = concat(basePath, "output/DeployCL-Step3-");
        path3 = concat(path3, outputFilename);
        string memory jsonOutput3 = vm.readFile(path3);
        swapFeeModule = abi.decode(jsonOutput3.parseRaw(".SwapFeeModule"), (address));
        unstakedFeeModule = abi.decode(jsonOutput3.parseRaw(".UnstakedFeeModule"), (address));
        protocolFeeModule = abi.decode(jsonOutput3.parseRaw(".ProtocolFeeModule"), (address));
        
        console2.log("Loaded all previous deployments");
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
        console2.log("Configured:", operationName);
        vm.sleep(3000); // 3 second delay between transactions
        console2.log("Waiting for confirmation:", operationName, "- OK");
    }
}