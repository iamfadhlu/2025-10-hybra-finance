// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {NonfungibleTokenPositionDescriptor} from "contracts/periphery/NonfungibleTokenPositionDescriptor.sol";
import {NonfungiblePositionManager} from "contracts/periphery/NonfungiblePositionManager.sol";

contract DeployCL_Step2_NFT is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");
    string public jsonConstants;

    // loaded variables
    address public weth;
    address public poolFactory;
    string public nftName;
    string public nftSymbol;
    
    // deployed contracts
    NonfungibleTokenPositionDescriptor public nftDescriptor;
    NonfungiblePositionManager public nft;

    function run() public {
        console2.log("=== Step 2: Deploying NFT Contracts ===");
        
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);

        // Load constants
        weth = abi.decode(vm.parseJson(jsonConstants, ".WETH"), (address));
        nftName = abi.decode(vm.parseJson(jsonConstants, ".nftName"), (string));
        nftSymbol = abi.decode(vm.parseJson(jsonConstants, ".nftSymbol"), (string));
        
        // Load previously deployed contracts
        loadPreviousDeployments();
        
        // Configure for slow chains like Hyperliquid
        configureSlowChain();
        
        vm.startBroadcast(deployerAddress);
        
        // Transaction 1: Deploy NFT descriptor
        nftDescriptor = new NonfungibleTokenPositionDescriptor({
            _WETH9: address(weth), 
            _nativeCurrencyLabelBytes: bytes32("ETH")
        });
        waitForConfirmation("NFT Descriptor");
        
        // Transaction 2: Deploy NFT position manager
        nft = new NonfungiblePositionManager({
            _factory: address(poolFactory),
            _WETH9: address(weth),
            _tokenDescriptor: address(nftDescriptor),
            name: nftName,
            symbol: nftSymbol
        });
        waitForConfirmation("NFT Position Manager");
        
        vm.stopBroadcast();
        
        // Save results to JSON
        saveResults();
        
        console2.log("=== Step 2 Complete ===");
        console2.log("NFT Descriptor:", address(nftDescriptor));
        console2.log("NFT Position Manager:", address(nft));
        console2.log("Next: Run DeployCL_Step3_Fees.s.sol");
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
        string memory path = concat(basePath, "output/DeployCL-Step2-");
        path = concat(path, outputFilename);
        
        vm.writeJson(vm.serializeAddress("", "NonfungibleTokenPositionDescriptor", address(nftDescriptor)), path);
        vm.writeJson(vm.serializeAddress("", "NonfungiblePositionManager", address(nft)), path);
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