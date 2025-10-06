// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "./helpers/CLContractsImporter.sol";

// Infrastructure
import {PermissionsRegistry} from "../contracts/PermissionsRegistry.sol";
import {VeArtProxyUpgradeable} from "../contracts/VeArtProxyUpgradeable.sol";
import {TokenHandler} from "../contracts/TokenHandler.sol";

// Token System
import {HYBR} from "../contracts/HYBR.sol";
import {RewardHYBR} from "../contracts/RewardHYBR.sol";
import {GrowthHYBR} from "../contracts/GovernanceHYBR.sol";
import {VotingEscrow} from "../contracts/VotingEscrow.sol";

// Gauge System
import {GaugeFactory} from "../contracts/factories/GaugeFactory.sol";
import {GaugeFactoryCL} from "../contracts/CLGauge/GaugeFactoryCL.sol";
import {GaugeManager} from "../contracts/GaugeManager.sol";

// ThenaFi Mocks
import {PairFactory} from "../contracts/mocks/thenafi/PairFactory.sol";

// Bribe System
import {BribeFactoryV3} from "../contracts/factories/BribeFactoryV3.sol";

// Minter & Rewards
import {MinterUpgradeable} from "../contracts/MinterUpgradeable.sol";
import {RewardsDistributor} from "../contracts/RewardsDistributor.sol";

// Voting
import {VoterV3} from "../contracts/VoterV3.sol";

// Proxy
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title C4PoCTestbed
 * @notice Complete deployment test assembled from deployment scripts
 * @dev Imports CL contracts and configures ve33 system with them
 */
contract C4PoCTestbed is Test, CLContractsImporter {
    // Deployed contracts
    ProxyAdmin public proxyAdmin;
    PermissionsRegistry public permissionsRegistry;
    VeArtProxyUpgradeable public veArtProxy;
    TokenHandler public tokenHandler;

    HYBR public hybr;
    RewardHYBR public rewardHybr;
    GrowthHYBR public gHybr;
    VotingEscrow public votingEscrow;

    GaugeFactory public gaugeFactory;
    GaugeFactoryCL public gaugeFactoryCL;

    PairFactory public thenaFiFactory;

    GaugeManager public gaugeManager;
    BribeFactoryV3 public bribeFactoryV3;

    MinterUpgradeable public minter;
    RewardsDistributor public rewardsDistributor;

    VoterV3 public voter;

    address public deployer;

    function setUp() public virtual {
        deployer = address(this);

        // Import CL contracts
        importCLContracts("local");

        // Run all deployment phases
        phase1_Infrastructure();
        phase2_TokenSystem();
        phase3a1_GaugeFactories();
        phase3a2_GaugeManagerAndBribes();
        phase3a3_SetupPermissions();
        phase3b1_MinterRewards();
        phase3b2_SetupConnections();
        phase3c_Voting();
        setup_InitMinter();
    }

    // ========== Deploy1_Infrastructure.s.sol ==========
    function phase1_Infrastructure() internal {
        console.log("=== Phase 1: Deploy Infrastructure ===");
        console.log("Deployer:", deployer);

        // 1. Deploy ProxyAdmin
        proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin:", address(proxyAdmin));

        // 2. Deploy PermissionsRegistry
        permissionsRegistry = new PermissionsRegistry();
        console.log("PermissionsRegistry:", address(permissionsRegistry));

        // 3. Deploy VeArtProxy
        VeArtProxyUpgradeable veArtProxyImpl = new VeArtProxyUpgradeable();
        TransparentUpgradeableProxy veArtProxyProxy = new TransparentUpgradeableProxy(
            address(veArtProxyImpl),
            address(proxyAdmin),
            ""
        );
        veArtProxy = VeArtProxyUpgradeable(address(veArtProxyProxy));
        veArtProxy.initialize();
        console.log("VeArtProxy:", address(veArtProxy));

        // 4. Deploy TokenHandler
        tokenHandler = new TokenHandler(address(permissionsRegistry));
        console.log("TokenHandler:", address(tokenHandler));

        console.log("\n=== Infrastructure Deployment Complete ===");
    }

    // ========== Deploy2_TokenSystem.s.sol ==========
    function phase2_TokenSystem() internal {
        console.log("=== Phase 2: Deploy Token System ===");
        console.log("Deployer:", deployer);
        console.log("Using VeArtProxy:", address(veArtProxy));

        // 1. Deploy HYBR Token
        hybr = new HYBR();
        console.log("HYBR:", address(hybr));

        // 2. Deploy VotingEscrow
        votingEscrow = new VotingEscrow(
            address(hybr),
            address(veArtProxy)
        );
        console.log("VotingEscrow:", address(votingEscrow));

        // 3. Deploy RewardHYBR Token
        rewardHybr = new RewardHYBR(address(hybr), address(votingEscrow));
        console.log("RewardHYBR:", address(rewardHybr));

        // 4. Deploy GovernanceHYBR Token
        gHybr = new GrowthHYBR(
            address(hybr),
            address(votingEscrow)
        );
        console.log("GrowthHYBR:", address(gHybr));

        console.log("\n=== Token System Deployment Complete ===");
    }

    // ========== Deploy3a1_GaugeFactories.s.sol ==========
    function phase3a1_GaugeFactories() internal {
        console.log("=== Deploy Gauge Factories ===");
        console.log("Deployer:", deployer);
        console.log("Using PermissionsRegistry:", address(permissionsRegistry));
        console.log("Using rHYBR:", address(rewardHybr));

        // 1. Deploy GaugeFactory
        console.log("Deploying GaugeFactory...");
        GaugeFactory gaugeFactoryImpl = new GaugeFactory();
        TransparentUpgradeableProxy gaugeFactoryProxy = new TransparentUpgradeableProxy(
            address(gaugeFactoryImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                GaugeFactory.initialize.selector,
                address(permissionsRegistry)
            )
        );
        gaugeFactory = GaugeFactory(address(gaugeFactoryProxy));
        console.log("GaugeFactory:", address(gaugeFactory));

        gaugeFactory.setRHYBR(address(rewardHybr));

        // 2. Deploy GaugeFactoryCL
        console.log("Deploying GaugeFactoryCL...");
        GaugeFactoryCL gaugeFactoryCLImpl = new GaugeFactoryCL();
        TransparentUpgradeableProxy gaugeFactoryCLProxy = new TransparentUpgradeableProxy(
            address(gaugeFactoryCLImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                GaugeFactoryCL.initialize.selector,
                address(permissionsRegistry)
            )
        );
        gaugeFactoryCL = GaugeFactoryCL(address(gaugeFactoryCLProxy));
        console.log("GaugeFactoryCL:", address(gaugeFactoryCL));

        gaugeFactoryCL.setRHYBR(address(rewardHybr));
    }

    // ========== Deploy3a2_GaugeManagerAndBribes.s.sol ==========
    function phase3a2_GaugeManagerAndBribes() internal {
        console.log("=== Deploy GaugeManager and BribeFactory ===");
        console.log("Deployer:", deployer);
        console.log("Using VotingEscrow:", address(votingEscrow));
        console.log("Using GaugeFactory:", address(gaugeFactory));
        console.log("Using GaugeFactoryCL:", address(gaugeFactoryCL));

        // 1. Deploy GaugeManager
        console.log("Deploying GaugeManager...");
        GaugeManager gaugeManagerImpl = new GaugeManager();
        TransparentUpgradeableProxy gaugeManagerProxy = new TransparentUpgradeableProxy(
            address(gaugeManagerImpl),
            address(proxyAdmin),
            ""
        );
        gaugeManager = GaugeManager(address(gaugeManagerProxy));
        console.log("GaugeManager:", address(gaugeManager));

        thenaFiFactory = new PairFactory();

        // Initialize GaugeManager
        console.log("Initializing GaugeManager...");
        gaugeManager.initialize(
            address(votingEscrow),              // __ve
            address(tokenHandler),              // _tokenHandler
            address(gaugeFactory),              // _gaugeFactory
            address(gaugeFactoryCL),            // _gaugeFactoryCL
            address(thenaFiFactory),            // _pairFactory
            clPoolFactory,                      // _pairFactoryCL (CL factory)
            address(permissionsRegistry),       // _permissionRegistory
            clNonfungiblePositionManager        // _nfpm (CL NFT manager)
        );

        // 2. Deploy BribeFactoryV3
        console.log("Deploying BribeFactoryV3...");
        BribeFactoryV3 bribeFactoryV3Impl = new BribeFactoryV3();
        TransparentUpgradeableProxy bribeFactoryV3Proxy = new TransparentUpgradeableProxy(
            address(bribeFactoryV3Impl),
            address(proxyAdmin),
            ""
        );
        bribeFactoryV3 = BribeFactoryV3(address(bribeFactoryV3Proxy));
        console.log("BribeFactoryV3:", address(bribeFactoryV3));
    }

    // ========== Deploy3a3_SetupPermissions.s.sol ==========
    function phase3a3_SetupPermissions() internal {
        console.log("=== Setup Permissions and Final Configuration ===");
        console.log("Deployer:", deployer);
        console.log("Using PermissionsRegistry:", address(permissionsRegistry));
        console.log("Using GaugeManager:", address(gaugeManager));
        console.log("Using BribeFactoryV3:", address(bribeFactoryV3));

        // Setup permissions for GaugeManager operations
        console.log("Setting up GAUGE_ADMIN role for deployer...");
        permissionsRegistry.setRoleFor(deployer, "GAUGE_ADMIN");
        console.log("GAUGE_ADMIN role assigned to deployer");

        // Set BribeFactory on GaugeManager
        console.log("Setting BribeFactory on GaugeManager...");
        gaugeManager.setBribeFactory(address(bribeFactoryV3));
        console.log("BribeFactory set on GaugeManager");

        // Ensure PermissionsRegistry is properly set
        console.log("Confirming PermissionsRegistry on GaugeManager...");
        gaugeManager.setPermissionsRegistry(address(permissionsRegistry));
        console.log("PermissionsRegistry confirmed on GaugeManager");
    }

    // ========== Deploy3b1_MinterRewards.s.sol ==========
    function phase3b1_MinterRewards() internal {
        console.log("=== Step 1: Deploy Minter and RewardsDistributor ===");
        console.log("Deployer:", deployer);
        console.log("Using VotingEscrow:", address(votingEscrow));
        console.log("Using RewardHYBR:", address(rewardHybr));
        console.log("Using GaugeManager:", address(gaugeManager));

        // 1. Deploy RewardsDistributor
        console.log("Deploying RewardsDistributor...");
        rewardsDistributor = new RewardsDistributor(address(votingEscrow));
        console.log("RewardsDistributor deployed at:", address(rewardsDistributor));

        // 2. Deploy Minter
        console.log("Deploying Minter...");
        MinterUpgradeable minterImpl = new MinterUpgradeable();
        TransparentUpgradeableProxy minterProxy = new TransparentUpgradeableProxy(
            address(minterImpl),
            address(proxyAdmin),
            ""
        );
        minter = MinterUpgradeable(address(minterProxy));
        console.log("Minter deployed at:", address(minter));

        // 3. Initialize Minter
        console.log("Initializing Minter...");
        minter.initialize(
            address(gaugeManager),
            address(votingEscrow),
            address(rewardsDistributor)
        );
        console.log("Minter initialized");

        // 5. Set team address
        console.log("Setting team address...");
        minter.setTeam(deployer);
        console.log("Team address set to:", deployer);
    }

    // ========== Deploy3b2_SetupConnections.s.sol ==========
    function phase3b2_SetupConnections() internal {
        console.log("=== Step 2: Setup Contract Connections ===");
        console.log("Deployer:", deployer);
        console.log("Using GrowthHYBR:", address(gHybr));
        console.log("Using GaugeManager:", address(gaugeManager));
        console.log("Using Minter:", address(minter));
        console.log("Using RewardsDistributor:", address(rewardsDistributor));

        // 1. Set Minter on GaugeManager
        console.log("Setting Minter on GaugeManager...");
        gaugeManager.setMinter(address(minter));
        console.log("Minter set on GaugeManager");

        // 2. Set Minter as depositor on RewardsDistributor
        console.log("Setting Minter as depositor on RewardsDistributor...");
        rewardsDistributor.setDepositor(address(minter));
        console.log("Minter set as depositor on RewardsDistributor");

        // 3. Set RewardsDistributor on GrowthHYBR
        console.log("Setting RewardsDistributor on GovernanceHYBR...");
        gHybr.setRewardsDistributor(address(rewardsDistributor));
        console.log("RewardsDistributor set on GovernanceHYBR");

        // 4. Set GaugeManager on GrowthHYBR
        console.log("Setting GaugeManager on GovernanceHYBR...");
        gHybr.setGaugeManager(address(gaugeManager));
        console.log("GaugeManager set on GovernanceHYBR");

        console.log("=== All Contract Connections Complete ===");
    }

    // ========== Deploy3c_Voting.s.sol ==========
    function phase3c_Voting() internal {
        console.log("=== Deploy Voting System ===");
        console.log("Deployer:", deployer);
        console.log("Using GaugeManager:", address(gaugeManager));
        console.log("");

        // 2. Deploy VoterV3
        console.log("Deploying VoterV3...");
        VoterV3 voterImpl = new VoterV3();
        TransparentUpgradeableProxy voterProxy = new TransparentUpgradeableProxy(
            address(voterImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                VoterV3.initialize.selector,
                address(votingEscrow),          // __ve
                address(tokenHandler),          // _tokenHandler
                address(gaugeManager),          // _gaugeManager
                address(permissionsRegistry)    // _permissionRegistry
            )
        );
        voter = VoterV3(address(voterProxy));
        console.log("VoterV3:", address(voter));

        // 3. Set Voter in GaugeManager
        console.log("\nSetting Voter in GaugeManager...");
        gaugeManager.setVoter(address(voter));
        console.log("Voter set in GaugeManager:", address(voter));

        // 4. Set Voter in VotingEscrow
        console.log("\nSetting Voter in VotingEscrow...");
        votingEscrow.setVoter(address(voter));
        console.log("Voter set in VotingEscrow:", address(voter));

        console.log("");
        console.log("=== Voting System Deployment and Setup Complete ===");
        console.log("Voter has been configured in both GaugeManager and VotingEscrow");
    }

    // ========== Set3-InitMinter.s.sol ==========
    function setup_InitMinter() internal {
        console.log("=== Initialize Minter ===");
        console.log("HYBR:", address(hybr));
        console.log("RewardHYBR:", address(rewardHybr));
        console.log("Minter:", address(minter));
        console.log("Deployer:", deployer);

        // Check if initial mint was already done
        bool initialMinted = hybr.initialMinted();
        console.log("Initial mint already done:", initialMinted);

        if (!initialMinted) {
            console.log("Performing initial mint first...");
            hybr.initialMint(deployer);
            hybr.setMinter(address(minter));
            console.log("Initial mint completed - 500M HYBR minted to deployer");
        }

        // Initialize the minter with initial distribution
        address[] memory claimants = new address[](0);
        uint[] memory amounts = new uint[](0);
        uint max = 0;

        console.log("Initializing Minter...");
        minter._initialize(claimants, amounts, max);
        console.log("Minter initialized successfully");

        // Set minter on RewardHYBR (rHYBR)
        console.log("Setting minter on RewardHYBR...");
        rewardHybr.setGaugeManager(address(gaugeManager));
        rewardHybr.setGHYBR(address(gHybr));
        console.log("Minter set on RewardHYBR successfully");

        console.log("");
        console.log("=== Verification ===");

        // Verify the minter can now be used
        bool canMint = minter.check();
        uint256 period = minter.period();
        uint256 activePeriod = minter.active_period();

        console.log("Can mint now:", canMint);
        console.log("Current period:", period);
        console.log("Active period:", activePeriod);

        // Check HYBR supply and balance
        uint256 totalSupply = hybr.totalSupply();
        uint256 deployerBalance = hybr.balanceOf(deployer);

        console.log("Total HYBR supply:", totalSupply);
        console.log("Deployer HYBR balance:", deployerBalance);

        // Verify RewardHYBR minter setup
        address rHybrGHYBR = rewardHybr.gHYBR();
        console.log("RewardHYBR gHYBR:", rHybrGHYBR);
        console.log("Minter matches:", rHybrGHYBR == address(gHybr));
    }
}
