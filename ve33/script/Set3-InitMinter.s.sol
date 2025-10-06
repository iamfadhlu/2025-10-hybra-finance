// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {MinterUpgradeable} from "../contracts/MinterUpgradeable.sol";
import {HYBR} from "../contracts/HYBR.sol";
import {RewardHYBR} from "../contracts/RewardHYBR.sol";

contract InitMinter is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load deployed contracts
        string memory tokenPath = getInputPath("Deploy2_TokenSystem");
        string memory minterPath = getInputPath("Deploy3b1_MinterRewards");
        string memory gaugeManagerPath = getInputPath("Deploy3a_GaugeFactories");
        string memory tokenJson = vm.readFile(tokenPath);
        string memory minterJson = vm.readFile(minterPath);
        string memory gaugeManagerJson = vm.readFile(gaugeManagerPath);

        address hybr = abi.decode(vm.parseJson(tokenJson, ".HYBR"), (address));
        address rewardHybr = abi.decode(vm.parseJson(tokenJson, ".RewardHYBR"), (address));
        address minter = abi.decode(vm.parseJson(minterJson, ".Minter"), (address));
        address gaugeManager = abi.decode(vm.parseJson(gaugeManagerJson, ".GaugeManager"), (address));
        address gHYBR = abi.decode(vm.parseJson(tokenJson, ".GrowthHYBR"), (address));
        console.log("=== Initialize Minter ===");
        console.log("HYBR:", hybr);
        console.log("RewardHYBR:", rewardHybr);
        console.log("Minter:", minter);
        console.log("Deployer:", deployer);
        
        // Check if initial mint was already done
        bool initialMinted = HYBR(hybr).initialMinted();
        console.log("Initial mint already done:", initialMinted);
        
        if (!initialMinted) {
            console.log("Performing initial mint first...");
            vm.startBroadcast(deployer);
            HYBR(hybr).initialMint(deployer);
            HYBR(hybr).setMinter(minter);
            vm.stopBroadcast();
            console.log("Initial mint completed - 500M HYBR minted to deployer");
        }
        
        vm.startBroadcast(deployer);
        
        // Initialize the minter with initial distribution
        // For this example, we'll just do a simple initialization with empty arrays
        // You can modify these arrays to include specific claimants and amounts
        address[] memory claimants = new address[](0);
        uint[] memory amounts = new uint[](0);
        uint max = 0; // Set to 0 for no additional minting during initialization
        
        console.log("Initializing Minter...");
        MinterUpgradeable(minter)._initialize(claimants, amounts, max);
        console.log("Minter initialized successfully");
        
        // Set minter on RewardHYBR (rHYBR)
        console.log("Setting minter on RewardHYBR...");
        RewardHYBR(rewardHybr).setGaugeManager(gaugeManager);
        RewardHYBR(rewardHybr).setGHYBR(gHYBR);
        console.log("Minter set on RewardHYBR successfully");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Verification ===");
        
        // Verify the minter can now be used
        bool canMint = MinterUpgradeable(minter).check();
        uint256 period = MinterUpgradeable(minter).period();
        uint256 activePeriod = MinterUpgradeable(minter).active_period();
        
        console.log("Can mint now:", canMint);
        console.log("Current period:", period);
        console.log("Active period:", activePeriod);
        
        // Check HYBR supply and balance
        uint256 totalSupply = HYBR(hybr).totalSupply();
        uint256 deployerBalance = HYBR(hybr).balanceOf(deployer);
        
        console.log("Total HYBR supply:", totalSupply);
        console.log("Deployer HYBR balance:", deployerBalance);
        
        // Verify RewardHYBR minter setup
        address rHybrGHYBR = RewardHYBR(rewardHybr).gHYBR();
        console.log("RewardHYBR gHYBR:", rHybrGHYBR);
        console.log("Minter matches:", rHybrGHYBR == gHYBR);
    }
}