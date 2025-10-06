// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import {CLFactory} from "contracts/core/CLFactory.sol";
import {ICLPool} from "contracts/core/interfaces/ICLPool.sol";
import {TickMath} from "contracts/core/libraries/TickMath.sol";
import {IUniswapV3Factory} from "script/original_scripts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "script/original_scripts/interfaces/IUniswapV3Pool.sol";
import "forge-std/console2.sol";

contract DeploySinglePool is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");
    
    CLFactory public factory;
    
    // Pool parameters - can be set via environment variables or directly
    address public tokenA;
    address public tokenB;
    int24 public tickSpacing;
    uint160 public sqrtPriceX96;
    
    // Optional: reference V3 pool to copy price from
    address public referenceV3Pool;
    
    function run() public {
        // Load CLFactory address from deployment output
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, "output/DeployCL-");
        path = concat(path, outputFilename);
        
        string memory jsonOutput = vm.readFile(path);
        factory = CLFactory(abi.decode(jsonOutput.parseRaw(".PoolFactory"), (address)));
        
        // Set pool parameters directly for WETH/USDT pool
        setWETHUSDTPoolParameters();
        
        // Validate parameters
        require(tokenA != address(0), "Token A not set");
        require(tokenB != address(0), "Token B not set");
        require(tickSpacing > 0, "Tick spacing not set");
        
        // Order tokens correctly (tokenA should be < tokenB)
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        
        // Get initial price if not set
        if (sqrtPriceX96 == 0) {
            sqrtPriceX96 = getInitialPrice();
        }
        
        console2.log("Creating pool:");
        console2.log("  Token A:", tokenA);
        console2.log("  Token B:", tokenB);
        console2.log("  Tick Spacing:", uint256(tickSpacing));
        console2.log("  Initial sqrtPriceX96:", uint256(sqrtPriceX96));
        
        vm.startBroadcast(deployerAddress);
        
        // Check if pool already exists
        address existingPool = factory.getPool(tokenA, tokenB, tickSpacing);
        if (existingPool != address(0)) {
            console2.log("Pool already exists at:", existingPool);
            vm.stopBroadcast();
            return;
        }
        
        // Create new pool
        address newPool = factory.createPool({
            tokenA: tokenA,
            tokenB: tokenB,
            tickSpacing: tickSpacing,
            sqrtPriceX96: sqrtPriceX96
        });
        
        console2.log("Pool created at:", newPool);
        
        // Verify pool was created successfully
        ICLPool pool = ICLPool(newPool);
        (uint160 currentSqrtPrice, int24 currentTick, , , , ) = pool.slot0();
        console2.log("Pool initialized with:");
        console2.log("  Current sqrtPriceX96:", uint256(currentSqrtPrice));
        console2.log("  Current tick:", int256(currentTick));
        
        vm.stopBroadcast();
        
        // Write pool address to output file
        savePoolAddress(newPool);
    }
    
    function setWETHUSDTPoolParameters() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, constantsFilename);
        string memory jsonConstants = vm.readFile(path);
        
        // Load token addresses from Local.json
        address weth = abi.decode(jsonConstants.parseRaw(".testTokens.WETH"), (address));
        address usdt = abi.decode(jsonConstants.parseRaw(".testTokens.USDT"), (address));
        
        // Set WETH/USDT pool parameters
        tokenA = usdt;  // USDT (6 decimals)
        tokenB = weth;  // WETH (18 decimals)
        tickSpacing = 100;  // 0.3% fee tier
        
        // Set initial price: 1 ETH = 46 USDT
        // Since USDT < WETH (token0 < token1), price = token1/token0 = WETH/USDT
        // With decimals: (1 * 10^18) / (46 * 10^6) = 10^12 / 46
        // sqrtPriceX96 = sqrt(10^12 / 46) * 2^96 ≈ 11668374747036095663583936
        sqrtPriceX96 =  544307866242890057287260;
        
        console2.log("Pool configuration:");
        console2.log("  USDT (TokenA):", tokenA);
        console2.log("  WETH (TokenB):", tokenB);
        console2.log("  Tick Spacing:", uint256(tickSpacing));
    }

    function loadPoolParameters() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, constantsFilename);
        string memory jsonConstants = vm.readFile(path);
        
        // Try to load from environment variables first
        try vm.envAddress("TOKEN_A") returns (address _tokenA) {
            tokenA = _tokenA;
        } catch {
            // Fall back to constants file
            tokenA = abi.decode(jsonConstants.parseRaw(".singlePool.tokenA"), (address));
        }
        
        try vm.envAddress("TOKEN_B") returns (address _tokenB) {
            tokenB = _tokenB;
        } catch {
            tokenB = abi.decode(jsonConstants.parseRaw(".singlePool.tokenB"), (address));
        }
        
        try vm.envInt("TICK_SPACING") returns (int256 _tickSpacing) {
            tickSpacing = int24(_tickSpacing);
        } catch {
            tickSpacing = abi.decode(jsonConstants.parseRaw(".singlePool.tickSpacing"), (int24));
        }
        
        try vm.envUint("SQRT_PRICE_X96") returns (uint256 _sqrtPrice) {
            sqrtPriceX96 = uint160(_sqrtPrice);
        } catch {
            sqrtPriceX96 = abi.decode(jsonConstants.parseRaw(".singlePool.sqrtPriceX96"), (uint160));
        }
        
        // Optional: Load reference V3 pool
        try vm.envAddress("REFERENCE_V3_POOL") returns (address _pool) {
            referenceV3Pool = _pool;
        } catch {
            referenceV3Pool = abi.decode(jsonConstants.parseRaw(".singlePool.referenceV3Pool"), (address));
        }
    }
    
    function getInitialPrice() internal view returns (uint160) {
        // If reference V3 pool is set, copy its price
        if (referenceV3Pool != address(0)) {
            try IUniswapV3Pool(referenceV3Pool).slot0() returns (
                uint160 _sqrtPriceX96,
                int24,
                uint16,
                uint16,
                uint16,
                uint8,
                bool
            ) {
                console2.log("Using price from reference V3 pool:", referenceV3Pool);
                return _sqrtPriceX96;
            } catch {
                console2.log("Failed to get price from reference V3 pool");
            }
        }
        
        // Try to find existing V3 pool with common fee tiers
        IUniswapV3Factory v3Factory = IUniswapV3Factory(0x7a2088a1bFc9d81c55368AE168C2C02570cB814F);
        uint24[4] memory commonFees = [uint24(100), uint24(500), uint24(3000), uint24(10000)];
        
        for (uint i = 0; i < commonFees.length; i++) {
            address v3Pool = v3Factory.getPool(tokenA, tokenB, commonFees[i]);
            if (v3Pool != address(0)) {
                try IUniswapV3Pool(v3Pool).slot0() returns (
                    uint160 _sqrtPriceX96,
                    int24,
                    uint16,
                    uint16,
                    uint16,
                    uint8,
                    bool
                ) {
                    console2.log("Using price from existing V3 pool with fee:", uint256(commonFees[i]));
                    return _sqrtPriceX96;
                } catch {}
            }
        }
        
        // Default to 1:1 price if no reference found
        console2.log("No reference price found, using 1:1 ratio");
        return uint160(1 << 96); // sqrt(1) * 2^96
    }
    
    function savePoolAddress(address poolAddress) internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/output/");
        string memory filename = concat("SinglePool-", outputFilename);
        string memory path = concat(basePath, filename);
        
        string memory output = "{\n";
        output = concat(output, '  "poolAddress": "');
        output = concat(output, vm.toString(poolAddress));
        output = concat(output, '",\n');
        output = concat(output, '  "tokenA": "');
        output = concat(output, vm.toString(tokenA));
        output = concat(output, '",\n');
        output = concat(output, '  "tokenB": "');
        output = concat(output, vm.toString(tokenB));
        output = concat(output, '",\n');
        output = concat(output, '  "tickSpacing": ');
        output = concat(output, vm.toString(uint256(tickSpacing)));
        output = concat(output, ',\n');
        output = concat(output, '  "sqrtPriceX96": "');
        output = concat(output, vm.toString(uint256(sqrtPriceX96)));
        output = concat(output, '",\n');
        output = concat(output, '  "deployedAt": ');
        output = concat(output, vm.toString(block.timestamp));
        output = concat(output, '\n}');
        
        vm.writeFile(path, output);
        console2.log("Pool details saved to:", path);
    }
    
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}