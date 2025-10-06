// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import {ICLPool} from "contracts/core/interfaces/ICLPool.sol";
import {CLFactory} from "contracts/core/CLFactory.sol";
import {NonfungiblePositionManager} from "contracts/periphery/NonfungiblePositionManager.sol";
import {TickMath} from "contracts/core/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INonfungiblePositionManager} from "contracts/periphery/interfaces/INonfungiblePositionManager.sol";
import {ISugarHelper} from "contracts/periphery/interfaces/ISugarHelper.sol";
import "forge-std/console2.sol";

contract AddLiquidity5Percent is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");

    CLFactory public factory;
    NonfungiblePositionManager public nftManager;
    ICLPool public pool;
    ISugarHelper public sugarHelper;

    address public tokenA;
    address public tokenB;
    int24 public tickSpacing;
    
    // Liquidity amounts will be calculated based on target ETH amount
    uint256 public targetETHAmount = 30005e6;  // 3 ETH (can be modified)
    uint256 public priceRangePercent = 10;  // 10% price range (can be modified to 5, 10, 15, etc.)
    uint256 public liquidityAmount0;  // Will be calculated
    uint256 public liquidityAmount1;  // Will be calculated

    function run() public {
        loadContracts();
        loadPoolInfo();

        console2.log("=== Adding Liquidity with 5% Price Range ===");
        console2.log("Pool:", address(pool));
        console2.log("Token0:", tokenA);
        console2.log("Token1:", tokenB);
        console2.log("Deployer:", deployerAddress);
        
        vm.startBroadcast(deployerAddress);
        
        addLiquidityWith5PercentRange();
        
        vm.stopBroadcast();
        
        console2.log("\n=== Liquidity Addition Complete ===");
    }

    function loadContracts() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, "output/DeployCL-");
        path = concat(path, outputFilename);
        
        string memory jsonOutput = vm.readFile(path);
        factory = CLFactory(abi.decode(jsonOutput.parseRaw(".PoolFactory"), (address)));
        nftManager = NonfungiblePositionManager(abi.decode(jsonOutput.parseRaw(".NonfungiblePositionManager"), (address)));
        
        // Use the provided SugarHelper address
        sugarHelper = ISugarHelper(0x1c85638e118b37167e9298c2268758e058DdfDA0);
    }

    function loadPoolInfo() internal {
        // Load pool address from latest deployment
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/output/");
        string memory path = concat(basePath, "PoolWithPrice-");
        path = concat(path, outputFilename);
        
        string memory jsonOutput = vm.readFile(path);
        address poolAddress = abi.decode(jsonOutput.parseRaw(".poolAddress"), (address));
        
        pool = ICLPool(poolAddress);
        console2.log("Using pool at:", poolAddress);
        
        if (address(pool) != address(0)) {
            tokenA = pool.token0();
            tokenB = pool.token1();
            tickSpacing = pool.tickSpacing();
            
            console2.log("Pool tokens:");
            console2.log("  Token0:", tokenA);
            console2.log("  Token1:", tokenB);
            console2.log("  Tick spacing:", uint256(tickSpacing));
        } else {
            revert("Pool not initialized");
        }
    }

    function addLiquidityWith5PercentRange() internal {
        (uint160 sqrtPriceX96, int24 currentTick, , , , ) = pool.slot0();
        
        console2.log("Current pool state:");
        console2.log("  Current tick:", currentTick);
        console2.log("  Tick spacing:", tickSpacing);
        
        // Calculate price range based on priceRangePercent
        // For X% range: (100-X)% to (100+X)% of current price
        // We need sqrt((100-X)/100) and sqrt((100+X)/100)
        
        uint256 lowerPercent = 100 - priceRangePercent;  // e.g., 90 for 10% range
        uint256 upperPercent = 100 + priceRangePercent;  // e.g., 110 for 10% range
        
        // Calculate sqrt values with precision
        // sqrt(lowerPercent/100) * 1e9 for precision
        uint256 sqrtLowerRatio = sqrt(lowerPercent * 1e18 / 100) * 1e9 / 1e9;
        uint256 sqrtUpperRatio = sqrt(upperPercent * 1e18 / 100) * 1e9 / 1e9;
        
        console2.log("\nPrice range calculation:");
        console2.log("  Range percentage:", priceRangePercent, "%");
        console2.log("  Lower bound:", lowerPercent, "% of current price");
        console2.log("  Upper bound:", upperPercent, "% of current price");
        console2.log("  Sqrt lower ratio:", sqrtLowerRatio);
        console2.log("  Sqrt upper ratio:", sqrtUpperRatio);
        
        uint160 sqrtRatio_lower = uint160(uint256(sqrtPriceX96) * sqrtLowerRatio / 1e9);
        uint160 sqrtRatio_upper = uint160(uint256(sqrtPriceX96) * sqrtUpperRatio / 1e9);
        
        int24 tickLower = TickMath.getTickAtSqrtRatio(sqrtRatio_lower);
        int24 tickUpper = TickMath.getTickAtSqrtRatio(sqrtRatio_upper);
        
        // Round to tick spacing
        tickLower = (tickLower / tickSpacing) * tickSpacing;
        tickUpper = ((tickUpper / tickSpacing) + 1) * tickSpacing;
        

        
        uint256 price_lower = getPriceFromTick(tickLower);
        uint256 price_upper = getPriceFromTick(tickUpper);
      
        
        // Get token information dynamically
        (string memory token0Symbol, uint8 token0Decimals) = getTokenInfo(tokenA);
        (string memory token1Symbol, uint8 token1Decimals) = getTokenInfo(tokenB);
        
  
        
        // Calculate liquidity amounts - use token0 as base to reduce variables
        bool useToken0AsBase = true; // Simplified to avoid stack too deep
        
     
        
        // Simplified calculation - always use token0 as base
        liquidityAmount0 = targetETHAmount; // Use targetETHAmount directly
        liquidityAmount1 = sugarHelper.estimateAmount1(
            liquidityAmount0,
            address(pool),
            0,
            tickLower,
            tickUpper
        );
        
     
        
        uint256 balanceA = IERC20(tokenA).balanceOf(deployerAddress);
        uint256 balanceB = IERC20(tokenB).balanceOf(deployerAddress);
        
        console2.log("\nToken balances:");
        console2.log("  Token0 (", token0Symbol);
        console2.log(") balance:", balanceA / (10 ** token0Decimals));
        console2.log("  Token1 (", token1Symbol);
        console2.log(") balance:", balanceB / (10 ** token1Decimals));
        
        if (balanceA < liquidityAmount0 || balanceB < liquidityAmount1) {
            console2.log("\nEnsuring sufficient token balance...");
            
            if (balanceA < liquidityAmount0) {
                // Try to get more of token0
                bool success = false;
                if (keccak256(abi.encodePacked(token0Symbol)) == keccak256(abi.encodePacked("WETH"))) {
                    // For WETH, try to deposit ETH
                    (success,) = tokenA.call{value: liquidityAmount0 - balanceA}(
                        abi.encodeWithSignature("deposit()")
                    );
                } else {
                    // For other tokens, try to mint
                    (success,) = tokenA.call(
                        abi.encodeWithSignature("mint(address,uint256)", deployerAddress, liquidityAmount0 - balanceA)
                    );
                }
                if (!success) {
                    console2.log("Warning: Could not get more token0");
                }
            }
            
            if (balanceB < liquidityAmount1) {
                // Try to get more of token1
                bool success = false;
                if (keccak256(abi.encodePacked(token1Symbol)) == keccak256(abi.encodePacked("WETH"))) {
                    // For WETH, try to deposit ETH
                    (success,) = tokenB.call{value: liquidityAmount1 - balanceB}(
                        abi.encodeWithSignature("deposit()")
                    );
                } else {
                    // For other tokens, try to mint
                    (success,) = tokenB.call(
                        abi.encodeWithSignature("mint(address,uint256)", deployerAddress, liquidityAmount1 - balanceB)
                    );
                }
                if (!success) {
                    console2.log("Warning: Could not get more token1");
                }
            }
            
            balanceA = IERC20(tokenA).balanceOf(deployerAddress);
            balanceB = IERC20(tokenB).balanceOf(deployerAddress);
            console2.log("  Updated Token0 (", token0Symbol);
            console2.log(") balance:", balanceA / (10 ** token0Decimals));
            console2.log("  Updated Token1 (", token1Symbol);
            console2.log(") balance:", balanceB / (10 ** token1Decimals));
        }
        
        uint256 amount0ToUse = balanceA > liquidityAmount0 ? liquidityAmount0 : balanceA;
        uint256 amount1ToUse = balanceB > liquidityAmount1 ? liquidityAmount1 : balanceB;
        
        IERC20(tokenA).approve(address(nftManager), amount0ToUse);
        IERC20(tokenB).approve(address(nftManager), amount1ToUse);
        console2.log("\nTokens approved for NFT Manager");
        
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: tokenA,
            token1: tokenB,
            tickSpacing: tickSpacing,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0ToUse,
            amount1Desired: amount1ToUse,
            amount0Min: 0,
            amount1Min: 0,
            recipient: deployerAddress,
            deadline: block.timestamp + 1 hours,
            sqrtPriceX96: 0
        });
        
        console2.log("\nMinting position...");
        console2.log("  Amount0 (", token0Symbol);
        console2.log(") desired:", amount0ToUse / (10 ** token0Decimals));
        console2.log("  Amount1 (", token1Symbol);
        console2.log(") desired:", amount1ToUse / (10 ** token1Decimals));
        
        try nftManager.mint(params) returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) {
            console2.log("\n=== Position Created Successfully ===");
            console2.log("  Token ID:", tokenId);
            console2.log("  Liquidity:", uint256(liquidity));
            console2.log("  Amount0 (", token0Symbol);
            console2.log(") deposited:", amount0 / (10 ** token0Decimals));
            console2.log("  Amount1 (", token1Symbol);
            console2.log(") deposited:", amount1 / (10 ** token1Decimals));
            
            uint256 utilizationRate0 = amount0ToUse > 0 ? (amount0 * 100) / amount0ToUse : 0;
            uint256 utilizationRate1 = amount1ToUse > 0 ? (amount1 * 100) / amount1ToUse : 0;
            console2.log("\nUtilization rates:");
            console2.log("  Token0 utilization:", utilizationRate0, "%");
            console2.log("  Token1 utilization:", utilizationRate1, "%");
            
        } catch Error(string memory reason) {
            console2.log("ERROR: Mint failed -", reason);
        } catch (bytes memory lowLevelData) {
            console2.log("ERROR: Mint failed with low level error");
            console2.logBytes(lowLevelData);
        }
    }
    
    function getPriceFromTick(int24 tick) internal pure returns (uint256) {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        uint256 price = uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18 / (1 << 192);
        return price;
    }

    function getTokenInfo(address token) internal view returns (string memory symbol, uint8 decimals) {
        // Use low-level calls to get token metadata
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
        if (success && data.length > 0) {
            symbol = abi.decode(data, (string));
        } else {
            symbol = "UNKNOWN";
        }
        
        (success, data) = token.staticcall(abi.encodeWithSignature("decimals()"));
        if (success && data.length > 0) {
            decimals = abi.decode(data, (uint8));
        } else {
            decimals = 18; // Default to 18 decimals
        }
    }

    function isPreferredToken(string memory symbol) internal pure returns (bool) {
        // Check if the token symbol is a preferred base token
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        return (
            symbolHash == keccak256(abi.encodePacked("WETH")) ||
            symbolHash == keccak256(abi.encodePacked("ETH")) ||
            symbolHash == keccak256(abi.encodePacked("USDT")) ||
            symbolHash == keccak256(abi.encodePacked("USDC")) ||
            symbolHash == keccak256(abi.encodePacked("WBTC"))
        );
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    // Square root function using Babylonian method
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}