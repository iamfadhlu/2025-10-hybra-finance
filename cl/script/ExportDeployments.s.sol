// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/console2.sol";

import "./FullCLDeployment.s.sol";

/**
 * @title ExportDeployments
 * @notice Exports deployed CL contract bytecode for ve33 testing
 * @dev Reads deployment addresses from DeployCL-local.json and exports bytecode
 *      This allows ve33 tests to use vm.etch() to replicate CL contracts at exact addresses
 */
contract ExportDeployments is Script, FullCLDeployment {
    using stdJson for string;

    function run() public override {
        super.run();

        console2.log("=== Exporting CL Deployments for ve33 Integration ===");

        // Extract bytecode from deployed contracts
        bytes memory poolFactoryCode = getDeployedBytecode(poolFactory);
        bytes memory poolImplCode = getDeployedBytecode(poolImplementation);
        bytes memory npmCode = getDeployedBytecode(nonfungiblePositionManager);
        bytes memory descriptorCode = getDeployedBytecode(
            nftPositionDescriptor
        );
        bytes memory routerCode = getDeployedBytecode(swapRouter);
        bytes memory quoterCode = getDeployedBytecode(quoter);
        bytes memory swapFeeModuleCode = getDeployedBytecode(swapFeeModule);
        bytes memory unstakedFeeModuleCode = getDeployedBytecode(
            unstakedFeeModule
        );
        bytes memory protocolFeeModuleCode = getDeployedBytecode(
            protocolFeeModule
        );

        // Build export JSON
        string memory json = buildExportJson(
            poolFactoryCode,
            poolImplCode,
            npmCode,
            descriptorCode,
            routerCode,
            quoterCode,
            swapFeeModuleCode,
            unstakedFeeModuleCode,
            protocolFeeModuleCode
        );

        // Write export file
        string memory exportPath = getExportPath();
        vm.writeJson(json, exportPath);

        console2.log("=== Export Complete ===");
        console2.log("Export file:", exportPath);
        console2.log("");
        console2.log("Summary:");
        console2.log("PoolFactory:", poolFactory);
        console2.log("PoolImplementation:", poolImplementation);
        console2.log("NonfungiblePositionManager:", nonfungiblePositionManager);
        console2.log("SwapRouter:", swapRouter);
        console2.log("Quoter:", quoter);
        console2.log("");
        console2.log(
            "Next step: Use this file in ve33 test setup with vm.etch()"
        );
    }

    function getDeployedBytecode(
        address contractAddr
    ) internal view returns (bytes memory) {
        require(
            contractAddr != address(0),
            "Cannot fetch bytecode from zero address"
        );

        // Solidity 0.7.6 compatible way to get bytecode
        uint256 size;
        assembly {
            size := extcodesize(contractAddr)
        }
        require(size > 0, "No bytecode at address");

        bytes memory code = new bytes(size);
        assembly {
            extcodecopy(contractAddr, add(code, 0x20), 0, size)
        }

        return code;
    }

    function buildExportJson(
        bytes memory poolFactoryCode,
        bytes memory poolImplCode,
        bytes memory npmCode,
        bytes memory descriptorCode,
        bytes memory routerCode,
        bytes memory quoterCode,
        bytes memory swapFeeModuleCode,
        bytes memory unstakedFeeModuleCode,
        bytes memory protocolFeeModuleCode
    ) internal returns (string memory) {
        string memory obj = "cl_export";

        // Metadata
        vm.serializeUint(obj, "timestamp", block.timestamp);
        // Note: block.chainid not available in Solidity 0.7.6, use assembly
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        vm.serializeUint(obj, "chainId", chainId);
        vm.serializeString(obj, "network", "local");
        vm.serializeAddress(obj, "deployer", deployer);

        // Mock Tokens
        vm.serializeAddress(obj, "USDC", USDC);
        vm.serializeAddress(obj, "USDT", USDT);
        vm.serializeAddress(obj, "DAI", DAI);
        vm.serializeAddress(obj, "WETH", WETH);

        // PoolFactory
        vm.serializeAddress(obj, "poolFactory_address", poolFactory);
        vm.serializeBytes(obj, "poolFactory_bytecode", poolFactoryCode);

        // PoolImplementation
        vm.serializeAddress(
            obj,
            "poolImplementation_address",
            poolImplementation
        );
        vm.serializeBytes(obj, "poolImplementation_bytecode", poolImplCode);

        // NonfungiblePositionManager
        vm.serializeAddress(
            obj,
            "nonfungiblePositionManager_address",
            nonfungiblePositionManager
        );
        vm.serializeBytes(obj, "nonfungiblePositionManager_bytecode", npmCode);

        // NftPositionDescriptor
        vm.serializeAddress(
            obj,
            "nftPositionDescriptor_address",
            nftPositionDescriptor
        );
        vm.serializeBytes(
            obj,
            "nftPositionDescriptor_bytecode",
            descriptorCode
        );

        // SwapRouter
        vm.serializeAddress(obj, "swapRouter_address", swapRouter);
        vm.serializeBytes(obj, "swapRouter_bytecode", routerCode);

        // Quoter
        vm.serializeAddress(obj, "quoter_address", quoter);
        vm.serializeBytes(obj, "quoter_bytecode", quoterCode);

        // SwapFeeModule
        vm.serializeAddress(obj, "swapFeeModule_address", swapFeeModule);
        vm.serializeBytes(obj, "swapFeeModule_bytecode", swapFeeModuleCode);

        // UnstakedFeeModule
        vm.serializeAddress(
            obj,
            "unstakedFeeModule_address",
            unstakedFeeModule
        );
        vm.serializeBytes(
            obj,
            "unstakedFeeModule_bytecode",
            unstakedFeeModuleCode
        );

        // ProtocolFeeModule
        vm.serializeAddress(
            obj,
            "protocolFeeModule_address",
            protocolFeeModule
        );
        string memory finalJson = vm.serializeBytes(
            obj,
            "protocolFeeModule_bytecode",
            protocolFeeModuleCode
        );

        return finalJson;
    }

    function getExportPath() internal view returns (string memory) {
        string memory root = vm.projectRoot();
        return
            string(
                abi.encodePacked(root, "/deployments/cl-exports-local.json")
            );
    }
}
