// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {C4PoCTestbed} from "./C4PoCTestbed.t.sol";

/**
 * @title C4PoC
 * @notice A complete deployment of the CL contract suite
 * @dev All available variables are showcased in the commented
 *      storage slots of the contract.
 */

// Deployed contracts
// ProxyAdmin public proxyAdmin;
// PermissionsRegistry public permissionsRegistry;
// VeArtProxyUpgradeable public veArtProxy;
// TokenHandler public tokenHandler;

// HYBR public hybr;
// RewardHYBR public rewardHybr;
// GrowthHYBR public gHybr;
// VotingEscrow public votingEscrow;

// GaugeFactory public gaugeFactory;
// GaugeFactoryCL public gaugeFactoryCL;

// PairFactory public thenaFiFactory;

// GaugeManager public gaugeManager;
// BribeFactoryV3 public bribeFactoryV3;

// MinterUpgradeable public minter;
// RewardsDistributor public rewardsDistributor;

// VoterV3 public voter;

// address public deployer;

// Imported contracts
// address public clPoolFactory;
// address public clPoolImplementation;
// address public clNonfungiblePositionManager;
// address public clNftPositionDescriptor;
// address public clSwapRouter;
// address public clQuoter;
// address public clSwapFeeModule;
// address public clUnstakedFeeModule;
// address public clProtocolFeeModule;

// Administrative Addresses
// address public team = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
// address public poolFactoryOwner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
// address public feeManager = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

contract C4PoC is C4PoCTestbed {
    function setUp() public override {
        super.setUp();
    }

    function test_submissionValidity() external {}
}
