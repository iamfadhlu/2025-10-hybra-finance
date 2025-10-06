// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

// Mocks
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {MockNative} from "contracts/mocks/MockNative.sol";

// CL Core
import {CLPool} from "contracts/core/CLPool.sol";
import {CLFactory} from "contracts/core/CLFactory.sol";

// CL NFT
import {NonfungibleTokenPositionDescriptor} from "contracts/periphery/NonfungibleTokenPositionDescriptor.sol";
import {NonfungiblePositionManager} from "contracts/periphery/NonfungiblePositionManager.sol";

// CL Fees
import {DynamicSwapFeeModule} from "contracts/core/fees/DynamicSwapFeeModule.sol";
import {CustomUnstakedFeeModule} from "contracts/core/fees/CustomUnstakedFeeModule.sol";
import {CustomProtocolFeeModule} from "contracts/core/fees/CustomProtocolFeeModule.sol";

// CL Periphery
import {QuoterV2} from "contracts/periphery/lens/QuoterV2.sol";
import {SwapRouter} from "contracts/periphery/SwapRouter.sol";

/**
 * @title FullCLDeployment
 * @notice Deploys all contracts necessary for the CL system
 * @dev This is meant to be used as a dependency to export the relevant CL
 *      contract bytecodes for use by the ve33 system. Configuration
 *      MUST be done by contracts that utilize the system
 */
contract FullCLDeployment is Script {
    // Deployer
    address public deployer;

    // Token addresses
    address public USDC;
    address public USDT;
    address public DAI;
    address public WETH;

    // Deployment addresses 
    address public poolFactory;
    address public poolImplementation;
    address public nonfungiblePositionManager;
    address public nftPositionDescriptor;
    address public swapRouter;
    address public quoter;
    address public swapFeeModule;
    address public unstakedFeeModule;
    address public protocolFeeModule;

    function run() public virtual {
        console2.log("=== Deploying all CL contracts for ve33 Integration ===");

        // Store deployer of contacts
        deployer = msg.sender;

        // Deploy USDC, USDT, DAI, and WETH
        USDC = address(new MockERC20("USDC","USDC", 6));
        USDT = address(new MockERC20("USDT","USDT", 6));
        DAI = address(new MockERC20("DAI","DAI", 18));
        WETH = address(new MockNative("WETH","WETH"));

        // Deploy Pool Factory & Pool Implementation
        (poolFactory, poolImplementation) = _deployCLCore();

        // Deploy NFT contracts
        (nftPositionDescriptor, nonfungiblePositionManager) = _deployCLNFT();

        // Deploy Fee contracts
        (swapFeeModule, unstakedFeeModule, protocolFeeModule) = _deployCLFees();

        // Deploy Periphery contracts
        (quoter, swapRouter) = _deployCLPeriphery();

        console2.log("=== Deployment Complete ===");
        console2.log("");
        console2.log("Summary:");
        console2.log("- PoolFactory:", poolFactory);
        console2.log("- PoolImplementation:", poolImplementation);
        console2.log("- NonfungiblePositionManager:", nonfungiblePositionManager);
        console2.log("- SwapRouter:", swapRouter);
        console2.log("- Quoter:", quoter);
        console2.log("");
    }

    function _deployCLCore() internal returns (address, address) {
        address poolImplementation_ = address(new CLPool());
        return (address(new CLFactory({_poolImplementation: address(poolImplementation_)})), poolImplementation_);
    }

    function _deployCLNFT() internal returns (address, address) {
        address nftDescriptor = address(new NonfungibleTokenPositionDescriptor({
            _WETH9: WETH, 
            _nativeCurrencyLabelBytes: bytes32("ETH")
        }));
        return (nftDescriptor, address(new NonfungiblePositionManager({
            _factory: poolFactory,
            _WETH9: WETH,
            _tokenDescriptor: nftDescriptor,
            name: "Concentrated Liquidity Positions NFT",
            symbol: "CL-POS"
        })));
    }

    function _deployCLFees() internal returns (address, address, address) {
        // Prepare initial fee configuration
        address[] memory initialPools = new address[](0);
        uint24[] memory initialFees = new uint24[](0);

        return (address(new DynamicSwapFeeModule({
            _factory: poolFactory,
            _defaultScalingFactor: 10000,  // 1 basis point per tick deviation
            _defaultFeeCap: 10000,          // 1% max total fee
            _pools: initialPools,
            _fees: initialFees
        })), address(new CustomUnstakedFeeModule({_factory: poolFactory})), address(new CustomProtocolFeeModule({_factory: poolFactory})));
    }

    function _deployCLPeriphery() internal returns (address, address) {
        return (address(new QuoterV2({_factory: poolFactory, _WETH9: WETH})), address(new SwapRouter({_factory: poolFactory, _WETH9: WETH})));
    }
}
