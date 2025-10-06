// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
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
 * @title FullDeploymentCL
 * @notice Complete CL deployment test that mirrors deploy-cl-flow.sh
 * @dev This test deploys all CL contracts in the correct order without optimization
 *      Assembled directly from deployment scripts:
 *      - DeployCL_Step1_Core.s.sol
 *      - DeployCL_Step2_NFT.s.sol
 *      - DeployCL_Step3_Fees.s.sol
 *      - DeployCL_Step4_Config.s.sol
 *      - DeployCL_Step5_Periphery.s.sol
 */
contract C4PoCTestbed is Test {
    // Deployer
    address public deployer;

    // Token addresses
    address public USDC;
    address public USDT;
    address public DAI;
    address public WETH;

    // Deployment addresses 
    CLFactory public poolFactory;
    CLPool public poolImplementation;
    NonfungiblePositionManager public nonfungiblePositionManager;
    NonfungibleTokenPositionDescriptor public nftPositionDescriptor;
    SwapRouter public swapRouter;
    QuoterV2 public quoter;
    DynamicSwapFeeModule public swapFeeModule;
    CustomUnstakedFeeModule public unstakedFeeModule;
    CustomProtocolFeeModule public protocolFeeModule;

    // Configurational Variables
    address public team;
    address public poolFactoryOwner;
    address public feeManager;
    string public nftName;
    string public nftSymbol;

    function setUp() public virtual {
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

        // Set up configuration variables
        team = deployer;
        poolFactoryOwner = deployer;
        feeManager = deployer;
        nftName = "Hybra Finance CL Positions NFT";
        nftSymbol = "HYBRA-CL-POS";

        // Configure contracts
        _configureContracts();
    }

    function _deployCLCore() internal returns (CLFactory, CLPool) {
        CLPool poolImplementation_ = new CLPool();
        return (new CLFactory({_poolImplementation: address(poolImplementation_)}), poolImplementation_);
    }

    function _deployCLNFT() internal returns (NonfungibleTokenPositionDescriptor, NonfungiblePositionManager) {
        NonfungibleTokenPositionDescriptor nftPositionDescriptor_ = new NonfungibleTokenPositionDescriptor({
            _WETH9: address(WETH), 
            _nativeCurrencyLabelBytes: bytes32("ETH")
        });
        return (nftPositionDescriptor_, new NonfungiblePositionManager({
            _factory: address(poolFactory),
            _WETH9: address(WETH),
            _tokenDescriptor: address(nftPositionDescriptor_),
            name: "Concentrated Liquidity Positions NFT",
            symbol: "CL-POS"
        }));
    }

    function _deployCLFees() internal returns (DynamicSwapFeeModule, CustomUnstakedFeeModule, CustomProtocolFeeModule) {
        // Prepare initial fee configuration
        address[] memory initialPools = new address[](0);
        uint24[] memory initialFees = new uint24[](0);

        return (new DynamicSwapFeeModule({
            _factory: address(poolFactory),
            _defaultScalingFactor: 10000,  // 1 basis point per tick deviation
            _defaultFeeCap: 10000,          // 1% max total fee
            _pools: initialPools,
            _fees: initialFees
        }), new CustomUnstakedFeeModule({_factory: address(poolFactory)}), new CustomProtocolFeeModule({_factory: address(poolFactory)}));
    }

    function _deployCLPeriphery() internal returns (QuoterV2, SwapRouter) {
        return (new QuoterV2({_factory: address(poolFactory), _WETH9: address(WETH)}), new SwapRouter({_factory: address(poolFactory), _WETH9: address(WETH)}));
    }

    function _configureContracts() internal {
        // Transaction 1: Set swap fee module
        poolFactory.setSwapFeeModule({_swapFeeModule: address(swapFeeModule)});

        // Transaction 2: Set unstaked fee module
        poolFactory.setUnstakedFeeModule({_unstakedFeeModule: address(unstakedFeeModule)});

        // Transaction 3: Set protocol fee module
        poolFactory.setProtocolFeeModule({_protocolFeeModule: address(protocolFeeModule)});

        // Transaction 4: Set NFT owner
        nonfungiblePositionManager.setOwner(team);

        // Transaction 5: Set factory owner
        poolFactory.setOwner(poolFactoryOwner);

        // Transaction 6: Set fee managers
        poolFactory.setSwapFeeManager(feeManager);

        poolFactory.setUnstakedFeeManager(feeManager);

        poolFactory.setProtocolFeeManager(feeManager);
    }

    // ========== Test Cases ==========

    /**
     * @notice Test that all contracts deployed successfully
     */
    function testDeploymentSuccess() public view {
        // Core Contracts
        require(address(poolImplementation) != address(0), "Pool Implementation not deployed");
        require(address(poolFactory) != address(0), "Pool Factory not deployed");

        // Fee Modules
        require(address(swapFeeModule) != address(0), "Swap Fee Module not deployed");
        require(address(unstakedFeeModule) != address(0), "Unstaked Fee Module not deployed");
        require(address(protocolFeeModule) != address(0), "Protocol Fee Module not deployed");

        // Periphery Contracts
        require(address(nftPositionDescriptor) != address(0), "NFT Descriptor not deployed");
        require(address(nonfungiblePositionManager) != address(0), "NFT Position Manager not deployed");
        require(address(quoter) != address(0), "Quoter not deployed");
        require(address(swapRouter) != address(0), "Swap Router not deployed");
    }

    /**
     * @notice Test that factory configuration is correct
     */
    function testFactoryConfiguration() public view {
        // Check owner
        require(poolFactory.owner() == poolFactoryOwner, "Factory owner incorrect");

        // Check fee modules are set
        require(poolFactory.swapFeeModule() == address(swapFeeModule), "Swap fee module not set");
        require(poolFactory.unstakedFeeModule() == address(unstakedFeeModule), "Unstaked fee module not set");
        require(poolFactory.protocolFeeModule() == address(protocolFeeModule), "Protocol fee module not set");

        // Check fee managers
        require(poolFactory.swapFeeManager() == feeManager, "Swap fee manager not set");
        require(poolFactory.unstakedFeeManager() == feeManager, "Unstaked fee manager not set");
        require(poolFactory.protocolFeeManager() == feeManager, "Protocol fee manager not set");
    }

    /**
     * @notice Test that NFT configuration is correct
     */
    function testNFTConfiguration() public view {
        require(nonfungiblePositionManager.owner() == team, "NFT owner incorrect");
        require(nonfungiblePositionManager.factory() == address(poolFactory), "NFT factory incorrect");
        require(nonfungiblePositionManager.WETH9() == address(WETH), "NFT WETH incorrect");
    }

    /**
     * @notice Print all deployed contract addresses
     */
    function testPrintAllAddresses() public view {
        console2.log("\n========== ALL DEPLOYED CONTRACT ADDRESSES ==========\n");

        console2.log("Core Contracts:");
        console2.log("  Pool Implementation:", address(poolImplementation));
        console2.log("  Pool Factory:", address(poolFactory));
        console2.log("");

        console2.log("Fee Modules:");
        console2.log("  Swap Fee Module:", address(swapFeeModule));
        console2.log("  Unstaked Fee Module:", address(unstakedFeeModule));
        console2.log("  Protocol Fee Module:", address(protocolFeeModule));
        console2.log("");

        console2.log("Periphery Contracts:");
        console2.log("  NFT Descriptor:", address(nftPositionDescriptor));
        console2.log("  NFT Position Manager:", address(nonfungiblePositionManager));
        console2.log("  Quoter V2:", address(quoter));
        console2.log("  Swap Router:", address(swapRouter));
        console2.log("");
    }
}
