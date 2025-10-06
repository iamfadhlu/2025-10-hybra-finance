// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdJson.sol";

// Configuration import
import {IPoolFactory} from "contracts/interfaces/IPoolFactory.sol";
import {IDynamicSwapFeeModule} from "contracts/interfaces/IDynamicSwapFeeModule.sol";
import {INonfungiblePositionManager} from "contracts/interfaces/INonfungiblePositionManager.sol";

/**
 * @title CLContractsImporter
 * @notice Helper contract to import CL contracts bytecode from cl repository
 * @dev Uses vm.etch() to deploy CL contracts at their original addresses in test environment
 *
 * This allows ve33 tests to interact with CL contracts (CLPool, NonfungiblePositionManager, etc.)
 * without needing to manually deploy them or modify the ve33 codebase.
 *
 * Usage in tests:
 *   contract MyTest is Test, CLContractsImporter {
 *       function setUp() public {
 *           importCLContracts("local");
 *           // Now CL contracts are available at their deployed addresses
 *       }
 *   }
 */
abstract contract CLContractsImporter is Test {
    using stdJson for string;

    // ========== CL Contract Addresses (populated after import) ==========
    address public clPoolFactory;
    address public clPoolImplementation;
    address public clNonfungiblePositionManager;
    address public clNftPositionDescriptor;
    address public clSwapRouter;
    address public clQuoter;
    address public clSwapFeeModule;
    address public clUnstakedFeeModule;
    address public clProtocolFeeModule;

    // Administrative Addresses
    address public team = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public poolFactoryOwner =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public feeManager = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /**
     * @notice Import all CL contracts from exported deployment file
     * @param network Network name (e.g., "local", "mainnet")
     * @dev Reads ../cl/deployments/cl-exports-{network}.json and uses vm.etch()
     */
    function importCLContracts(string memory network) internal {
        console.log("=== Importing CL Contracts ===");
        console.log("Network:", network);

        // Read export file from cl repository
        string memory exportPath = _getCLExportPath(network);
        string memory json = vm.readFile(exportPath);

        // Import each contract
        _importPoolFactory(json);
        _importPoolImplementation(json);
        _importNonfungiblePositionManager(json);
        _importNftPositionDescriptor(json);
        _importSwapRouter(json);
        _importQuoter(json);
        _importSwapFeeModule(json);
        _importUnstakedFeeModule(json);
        _importProtocolFeeModule(json);

        // Verify contracts were imported properly
        _verifyCLContractsImported();

        // Create constructor data entries
        _setConstructorDataEntries();

        // Setup contracts
        _configureCLContracts();

        console.log("=== CL Contracts Imported Successfully ===");
        console.log("");
    }

    /**
     * @notice Verify all CL contracts are properly imported
     * @dev Call this in tests to ensure contracts are available
     */
    function _verifyCLContractsImported() internal view {
        require(clPoolFactory != address(0), "CLPoolFactory not imported");
        require(
            clPoolImplementation != address(0),
            "CLPoolImplementation not imported"
        );
        require(
            clNonfungiblePositionManager != address(0),
            "CLNonfungiblePositionManager not imported"
        );
        require(
            clNftPositionDescriptor != address(0),
            "CLNftPositionDescriptor not imported"
        );
        require(clSwapRouter != address(0), "CLSwapRouter not imported");
        require(clQuoter != address(0), "CLQuoter not imported");
    }

    // ========== Internal Import Functions ==========

    function _importPoolFactory(string memory json) private {
        clPoolFactory = abi.decode(
            vm.parseJson(json, ".poolFactory_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".poolFactory_bytecode"),
            (bytes)
        );
        vm.etch(clPoolFactory, bytecode);
        console.log("  PoolFactory imported at:", clPoolFactory);
    }

    function _importPoolImplementation(string memory json) private {
        clPoolImplementation = abi.decode(
            vm.parseJson(json, ".poolImplementation_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".poolImplementation_bytecode"),
            (bytes)
        );
        vm.etch(clPoolImplementation, bytecode);
        console.log("  PoolImplementation imported at:", clPoolImplementation);
    }

    function _importNonfungiblePositionManager(string memory json) private {
        clNonfungiblePositionManager = abi.decode(
            vm.parseJson(json, ".nonfungiblePositionManager_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".nonfungiblePositionManager_bytecode"),
            (bytes)
        );
        vm.etch(clNonfungiblePositionManager, bytecode);
        console.log(
            "  NonfungiblePositionManager imported at:",
            clNonfungiblePositionManager
        );
    }

    function _importNftPositionDescriptor(string memory json) private {
        clNftPositionDescriptor = abi.decode(
            vm.parseJson(json, ".nftPositionDescriptor_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".nftPositionDescriptor_bytecode"),
            (bytes)
        );
        vm.etch(clNftPositionDescriptor, bytecode);
        console.log(
            "  NftPositionDescriptor imported at:",
            clNftPositionDescriptor
        );
    }

    function _importSwapRouter(string memory json) private {
        clSwapRouter = abi.decode(
            vm.parseJson(json, ".swapRouter_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".swapRouter_bytecode"),
            (bytes)
        );
        vm.etch(clSwapRouter, bytecode);
        console.log("  SwapRouter imported at:", clSwapRouter);
    }

    function _importQuoter(string memory json) private {
        clQuoter = abi.decode(vm.parseJson(json, ".quoter_address"), (address));
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".quoter_bytecode"),
            (bytes)
        );
        vm.etch(clQuoter, bytecode);
        console.log("  Quoter imported at:", clQuoter);
    }

    function _importSwapFeeModule(string memory json) private {
        clSwapFeeModule = abi.decode(
            vm.parseJson(json, ".swapFeeModule_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".swapFeeModule_bytecode"),
            (bytes)
        );
        vm.etch(clSwapFeeModule, bytecode);
        console.log("  SwapFeeModule imported at:", clSwapFeeModule);
    }

    function _importUnstakedFeeModule(string memory json) private {
        clUnstakedFeeModule = abi.decode(
            vm.parseJson(json, ".unstakedFeeModule_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".unstakedFeeModule_bytecode"),
            (bytes)
        );
        vm.etch(clUnstakedFeeModule, bytecode);
        console.log("  UnstakedFeeModule imported at:", clUnstakedFeeModule);
    }

    function _importProtocolFeeModule(string memory json) private {
        clProtocolFeeModule = abi.decode(
            vm.parseJson(json, ".protocolFeeModule_address"),
            (address)
        );
        bytes memory bytecode = abi.decode(
            vm.parseJson(json, ".protocolFeeModule_bytecode"),
            (bytes)
        );
        vm.etch(clProtocolFeeModule, bytecode);
        console.log("  ProtocolFeeModule imported at:", clProtocolFeeModule);
    }

    // As the bytecode was copied, constructors were not run and need to be simulated
    function _setConstructorDataEntries() private {
        // CLFactory
        // -> Sets defaultProtocolFee to initial value
        bytes32 offsetSlot = bytes32(uint256(250_00) << 160);
        vm.store(clPoolFactory, bytes32(uint256(7)), offsetSlot);

        // CustomProtocolFeeModule / CustomUnstakedFeeModule
        // -> Sets factory address
        offsetSlot = bytes32(uint256(uint160(clPoolFactory)));
        vm.store(clProtocolFeeModule, bytes32(uint256(0)), offsetSlot);
        vm.store(clUnstakedFeeModule, bytes32(uint256(0)), offsetSlot);

        // NonfungiblePositionManager
        // -> sets _nextId, _nextPoolId
        offsetSlot = bytes32(uint256(uint176(1) | (uint80(1) << 176)));
        vm.store(
            clNonfungiblePositionManager,
            bytes32(uint256(14)),
            offsetSlot
        );
    }

    // As the bytecode was copied, any setup is meant to be performed once again
    function _configureCLContracts() private {
        address authorizedCaller = IPoolFactory(clPoolFactory).swapFeeManager();
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setSwapFeeModule({
            _swapFeeModule: clSwapFeeModule
        });
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setSwapFeeManager(feeManager);

        // Update unstaked fee manager
        authorizedCaller = IPoolFactory(clPoolFactory).unstakedFeeManager();
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setUnstakedFeeModule({
            _unstakedFeeModule: clUnstakedFeeModule
        });
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setDefaultUnstakedFee(100_000);
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setUnstakedFeeManager(feeManager);

        // Update protocol fee manager
        authorizedCaller = IPoolFactory(clPoolFactory).protocolFeeManager();
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setProtocolFeeModule({
            _protocolFeeModule: clProtocolFeeModule
        });
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setProtocolFeeManager(feeManager);

        // Update NFT owner
        authorizedCaller = IPoolFactory(clPoolFactory).owner();
        vm.prank(authorizedCaller);
        IPoolFactory(clNonfungiblePositionManager).setOwner(team);

        // Update Factory owner
        authorizedCaller = IPoolFactory(clPoolFactory).owner();
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).enableTickSpacing(1, 100);
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).enableTickSpacing(50, 500);
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).enableTickSpacing(100, 500);
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).enableTickSpacing(200, 3_000);
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).enableTickSpacing(2_000, 10_000);
        vm.prank(authorizedCaller);
        IPoolFactory(clPoolFactory).setOwner(poolFactoryOwner);

        // Configure DynamicSwapFeeModule
        authorizedCaller = feeManager;
        IDynamicSwapFeeModule feeModule = IDynamicSwapFeeModule(
            clSwapFeeModule
        );
        vm.prank(authorizedCaller);
        feeModule.setDefaultScalingFactor(10000);
        vm.prank(authorizedCaller);
        feeModule.setDefaultFeeCap(10000);
        vm.prank(authorizedCaller);
        feeModule.setSecondsAgo(600);

        // Configure NonfungiblePositionManager
        INonfungiblePositionManager nftPositionManager = INonfungiblePositionManager(
                clNonfungiblePositionManager
            );
        authorizedCaller = nftPositionManager.owner();
        vm.prank(authorizedCaller);
        nftPositionManager.setTokenDescriptor(clNftPositionDescriptor);
        vm.prank(authorizedCaller);
        nftPositionManager.setOwner(team);
    }

    // ========== Helper Functions ==========

    function _getCLExportPath(
        string memory network
    ) private view returns (string memory) {
        string memory root = vm.projectRoot();
        return
            string(
                abi.encodePacked(
                    root,
                    "/../cl/deployments/cl-exports-",
                    network,
                    ".json"
                )
            );
    }
}
