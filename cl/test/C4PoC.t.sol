// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";

import {C4PoCTestbed} from "./C4PoCTestbed.t.sol";

/**
 * @title C4PoC
 * @notice A complete deployment of the CL contract suite
 * @dev All available variables are showcased in the commented
 *      storage slots of the contract.
 */
 
// Deployer
// address public deployer;

// Token addresses
// address public USDC;
// address public USDT;
// address public DAI;
// address public WETH;

// Deployment addresses 
// CLFactory public poolFactory;
// CLPool public poolImplementation;
// NonfungiblePositionManager public nonfungiblePositionManager;
// NonfungibleTokenPositionDescriptor public nftPositionDescriptor;
// SwapRouter public swapRouter;
// QuoterV2 public quoter;
// DynamicSwapFeeModule public swapFeeModule;
// CustomUnstakedFeeModule public unstakedFeeModule;
// CustomProtocolFeeModule public protocolFeeModule;

// Configurational Variables
// address public team;
// address public poolFactoryOwner;
// address public feeManager;
// string public nftName;
// string public nftSymbol;

contract C4PoC is C4PoCTestbed {
    function setUp() public override {
        super.setUp();
    }

    function test_submissionValidity() external {

    }
}
