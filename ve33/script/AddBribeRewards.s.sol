// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "./BaseDeployScript.sol";
import {IGaugeManager} from "../contracts/interfaces/IGaugeManager.sol";
import {IBribe} from "../contracts/interfaces/IBribe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddBribeRewards is BaseDeployScript {

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);

        // Load GaugeManager
        string memory votingPath = getInputPath("Deploy3a_GaugeFactories");
        string memory votingJson = vm.readFile(votingPath);
        address gaugeManager = abi.decode(vm.parseJson(votingJson, ".GaugeManager"), (address));

        console.log("=== Add Bribe Rewards ===");
        console.log("GaugeManager:", gaugeManager);
        console.log("Deployer:", deployer);

        // 直接写死配置
        address gauge = 0xAF8CA882E8Cd7a0B939B82e2318fDf7347d979a2; // 替换为实际的 gauge 地址
        address rewardToken = 0x0BA507423422Face6ee0914234b53D686975F772; // USDC 地址
        uint256 amount = 500 * 10**18; // 10000 DAI (6 decimals)

        // 获取 external bribe 地址
        address externalBribe = IGaugeManager(gaugeManager).external_bribes(gauge);
        require(externalBribe != address(0), "External bribe not found for gauge");

        console.log("Gauge:", gauge);
        console.log("External Bribe:", externalBribe);
        console.log("Reward Token:", rewardToken);
        console.log("Amount:", amount);

        vm.startBroadcast(deployer);

        // 批准代币
        IERC20(rewardToken).approve(externalBribe, amount);
        console.log("Token approved");

        // 发放奖励
        IBribe(externalBribe).notifyRewardAmount(rewardToken, amount);
        console.log("Reward added successfully");

        vm.stopBroadcast();
    }

    // 通过 pool 地址添加奖励
    function addByPool() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);

        string memory votingPath = getInputPath("Deploy3c_Voting");
        string memory votingJson = vm.readFile(votingPath);
        address gaugeManager = abi.decode(vm.parseJson(votingJson, ".GaugeManager"), (address));

        // 直接写死配置
        address pool = 0x9999999999999999999999999999999999999999; // 替换为实际的 pool 地址
        address rewardToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        uint256 amount = 5000 * 10**6; // 5000 USDC

        // 通过 pool 获取 gauge
        address gauge = IGaugeManager(gaugeManager).gauges(pool);
        require(gauge != address(0), "Gauge not found for pool");

        address externalBribe = IGaugeManager(gaugeManager).external_bribes(gauge);
        require(externalBribe != address(0), "External bribe not found");

        console.log("Pool:", pool);
        console.log("Gauge:", gauge);
        console.log("External Bribe:", externalBribe);

        vm.startBroadcast(deployer);

        IERC20(rewardToken).approve(externalBribe, amount);
        IBribe(externalBribe).notifyRewardAmount(rewardToken, amount);

        vm.stopBroadcast();

        console.log("Reward added successfully");
    }

    // 添加多种代币奖励
    function addMultipleTokens() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);

        string memory votingPath = getInputPath("Deploy3c_Voting");
        string memory votingJson = vm.readFile(votingPath);
        address gaugeManager = abi.decode(vm.parseJson(votingJson, ".GaugeManager"), (address));

        // 直接写死 gauge 和多种奖励代币
        address gauge = 0x1234567890123456789012345678901234567890; // 替换为实际 gauge

        // 代币地址和数量
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

        uint256 usdcAmount = 10000 * 10**6;  // 10000 USDC
        uint256 usdtAmount = 8000 * 10**6;   // 8000 USDT
        uint256 daiAmount = 5000 * 10**18;   // 5000 DAI

        address externalBribe = IGaugeManager(gaugeManager).external_bribes(gauge);
        require(externalBribe != address(0), "External bribe not found");

        vm.startBroadcast(deployer);

        // 添加 USDC 奖励
        IERC20(usdc).approve(externalBribe, usdcAmount);
        IBribe(externalBribe).notifyRewardAmount(usdc, usdcAmount);
        console.log("Added USDC reward:", usdcAmount);

        // 添加 USDT 奖励
        IERC20(usdt).approve(externalBribe, usdtAmount);
        IBribe(externalBribe).notifyRewardAmount(usdt, usdtAmount);
        console.log("Added USDT reward:", usdtAmount);

        // 添加 DAI 奖励
        IERC20(dai).approve(externalBribe, daiAmount);
        IBribe(externalBribe).notifyRewardAmount(dai, daiAmount);
        console.log("Added DAI reward:", daiAmount);

        vm.stopBroadcast();

        console.log("All rewards added successfully");
    }
}