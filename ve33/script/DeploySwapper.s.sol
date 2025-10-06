// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "./BaseDeployScript.sol";
import "../contracts/GovernanceHYBR.sol";
import "../contracts/swapper/HybrSwapper.sol";
import "../contracts/interfaces/ISwapper.sol";

/**
 * @title DeploySwapper
 * @notice Deployment script for the modular swapper architecture
 * @dev Demonstrates how to deploy and configure the swapper plugin system
 */
contract DeploySwapper is BaseDeployScript {
    // Contracts to deploy
    HybrSwapper public hybrSwapper;

    // Existing contracts (to be loaded from previous deployments)
    GrowthHYBR public growthHYBR;
    address public hybr;

    // Known aggregators to whitelist
    address constant PARASWAP = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address constant ONE_INCH = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    address constant OKX = 0x0000000000000000000000000000000000000000; // Replace with actual address

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);

        // Load existing contracts
        _loadExistingContracts();

        console.log("=== Deploying Modular Swapper Architecture ===");
        console.log("Deployer:", deployer);
        console.log("HYBR:", hybr);
        console.log("GrowthHYBR:", address(growthHYBR));
        console.log("");

        vm.startBroadcast(deployer);

        // Step 1: Deploy HybrSwapper
        _deploySwapper();

        // Step 2: Configure swapper with whitelisted aggregators
        _configureSwapper();

        // Step 3: Connect swapper to GrowthHYBR
        _connectSwapper();

        // Step 4: Verify configuration
        _verifyConfiguration();

        vm.stopBroadcast();

        // Save deployment addresses
        _saveDeployment();

        console.log("");
        console.log("=== Deployment Complete ===");
        console.log("HybrSwapper:", address(hybrSwapper));
    }

    function _loadExistingContracts() internal {
        // Load HYBR token address
        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory tokenJson = vm.readFile(tokenPath);
        hybr = abi.decode(vm.parseJson(tokenJson, ".HYBR"), (address));

            // Load GrowthHYBR address
        string memory governancePath = getInputPath("Deploy4_GrowthHYBR");
        string memory governanceJson = vm.readFile(governancePath);
        address growthHYBRAddress = abi.decode(vm.parseJson(governanceJson, ".GrowthHYBR"), (address));
        growthHYBR = GrowthHYBR(growthHYBRAddress);
    }

    function _deploySwapper() internal {
        console.log("=== Step 1: Deploying HybrSwapper ===");

        // Deploy with growthHYBR as the authorized caller
        hybrSwapper = new HybrSwapper(
            hybr
        );

        console.log("HybrSwapper deployed:", address(hybrSwapper));
        console.log("Authorized caller:", address(growthHYBR));
    }

    function _configureSwapper() internal {
        console.log("");
        console.log("=== Step 2: Configuring Swapper ===");

        // Whitelist aggregators
        console.log("Whitelisting Paraswap...");
        hybrSwapper.setAggregatorWhitelist(PARASWAP, true);

        console.log("Whitelisting 1inch...");
        hybrSwapper.setAggregatorWhitelist(ONE_INCH, true);

        if (OKX != address(0)) {
            console.log("Whitelisting OKX...");
            hybrSwapper.setAggregatorWhitelist(OKX, true);
        }

        console.log("Aggregators whitelisted");
    }

    function _connectSwapper() internal {
        console.log("");
        console.log("=== Step 3: Connecting Swapper to GrowthHYBR ===");

        // Set swapper in growthHYBR
        growthHYBR.setSwapper(address(hybrSwapper));

        console.log("Swapper connected to GrowthHYBR");
    }

    function _verifyConfiguration() internal view {
        console.log("");
        console.log("=== Step 4: Verifying Configuration ===");

        // Verify swapper is set
        require(address(growthHYBR.swapper()) == address(hybrSwapper), "Swapper not set correctly");
        console.log("Swapper correctly set in growthHYBR");

      

        // Verify aggregators are whitelisted
        require(hybrSwapper.isWhitelistedAggregator(PARASWAP), "Paraswap not whitelisted");
        console.log("Paraswap whitelisted");

        require(hybrSwapper.isWhitelistedAggregator(ONE_INCH), "1inch not whitelisted");
        console.log("1inch whitelisted");

        console.log("");
        console.log("All verifications passed!");
    }

    function _saveDeployment() internal {
        string memory json = "";
        json = vm.serializeAddress("deploy", "HybrSwapper", address(hybrSwapper));
        json = vm.serializeAddress("deploy", "HYBR", hybr);
        json = vm.serializeAddress("deploy", "GrowthHYBR", address(growthHYBR));
        json = vm.serializeAddress("deploy", "Paraswap", PARASWAP);
        json = vm.serializeAddress("deploy", "OneInch", ONE_INCH);

        string memory finalJson = vm.serializeString("deploy", "timestamp", vm.toString(block.timestamp));

        // Write to output file using getOutputPath from BaseDeployScript
        string memory outputPath = getOutputPath("Deploy_Swapper");
        vm.writeFile(outputPath, finalJson);

        console.log("Deployment saved to:", outputPath);
    }
}

/**
 * @title UpgradeSwapper
 * @notice Script to upgrade or replace the swapper module
 * @dev Shows how to swap out one swapper implementation for another
 */
contract UpgradeSwapper is BaseDeployScript {
    GrowthHYBR public growthHYBR;
    HybrSwapper public newSwapper;
    address public hybr;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);

        // Load existing contracts
        string memory governancePath = getInputPath("Deploy4_growthHYBR");
        string memory governanceJson = vm.readFile(governancePath);
        address growthHYBRAddress = abi.decode(vm.parseJson(governanceJson, ".GrowthHYBR"), (address));
        growthHYBR = GrowthHYBR(growthHYBRAddress);

        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory tokenJson = vm.readFile(tokenPath);
        hybr = abi.decode(vm.parseJson(tokenJson, ".HYBR"), (address));

        console.log("=== Upgrading Swapper Module ===");
        console.log("Current swapper:", address(growthHYBR.swapper()));

        vm.startBroadcast(deployer);

        // Deploy new swapper with updated logic
        newSwapper = new HybrSwapper(hybr);
        console.log("New swapper deployed:", address(newSwapper));

        // Configure new swapper (copy whitelist from old or set new)
        // This example sets new whitelist
        newSwapper.setAggregatorWhitelist(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57, true); // Paraswap
        newSwapper.setAggregatorWhitelist(0x1111111254EEB25477B68fb85Ed929f73A960582, true); // 1inch

        // Update growthHYBR to use new swapper
        growthHYBR.setSwapper(address(newSwapper));

        vm.stopBroadcast();

        console.log("Swapper upgrade complete!");
        console.log("New swapper:", address(growthHYBR.swapper()));
    }
}