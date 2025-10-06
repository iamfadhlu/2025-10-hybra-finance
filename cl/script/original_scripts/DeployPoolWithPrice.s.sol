// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";
import {CLFactory} from "contracts/core/CLFactory.sol";
import {ICLPool} from "contracts/core/interfaces/ICLPool.sol";
import "forge-std/console2.sol";
import {FullMath} from "contracts/core/libraries/FullMath.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Babylonian} from "lib/solidity-lib/contracts/libraries/Babylonian.sol";

contract DeployPoolWithPrice is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString("CONSTANTS_FILENAME");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");

    CLFactory public factory;

    address public wethAddress;
    address public usdtAddress;
    address public usdcAddress;
    address public token0;
    address public token1;
    address public tokenA;
    address public tokenB;
    int24 public constant TICK_SPACING = 50;

    string public constant TOKEN_A_HUMAN_AMOUNT = "1";
    string public constant TOKEN_B_HUMAN_AMOUNT = "50";

    struct ParsedAmount {
        uint256 value;
        uint8 decimals;
    }

    struct TokenData {
        address token;
        string symbol;
        uint8 decimals;
        string humanReadable;
        ParsedAmount amount;
    }

    function run() public {
        loadFactory();
        loadTokenAddresses();

        tokenA = 0xa5c1Ec69a87566BB9Ce1D86896d4B1AB1c576b44;
        tokenB = usdcAddress;

        TokenData memory tokenAData = buildTokenData(tokenA, TOKEN_A_HUMAN_AMOUNT);
        TokenData memory tokenBData = buildTokenData(tokenB, TOKEN_B_HUMAN_AMOUNT);

        (TokenData memory token0Data, TokenData memory token1Data) = sortTokenData(tokenAData, tokenBData);

        token0 = token0Data.token;
        token1 = token1Data.token;

        console2.log("=== Deploying Pool with Custom Price ===");
        console2.log("Factory:", address(factory));
        console2.log("Token A:", tokenA);
        console2.log("Token B:", tokenB);
        console2.log("Token0 (sorted):", token0);
        console2.log("Token1 (sorted):", token1);
        console2.log("Tick Spacing:", uint256(TICK_SPACING));
        console2.log("Token0 amount (human):", token0Data.humanReadable);
        console2.log("Token1 amount (human):", token1Data.humanReadable);
        console2.log("Token0 symbol:", token0Data.symbol);
        console2.log("Token0 decimals:", uint256(token0Data.decimals));
        console2.log("Token1 symbol:", token1Data.symbol);
        console2.log("Token1 decimals:", uint256(token1Data.decimals));

        uint160 sqrtPriceX96 = calculateSqrtPriceX96FromAmounts(token0Data, token1Data);

        console2.log("Calculated sqrtPriceX96:", uint256(sqrtPriceX96));

        uint256 amount0Raw = toRawAmount(token0Data.amount, token0Data.decimals);
        uint256 amount1Raw = toRawAmount(token1Data.amount, token1Data.decimals);

        string memory priceToken1PerToken0 = formatDecimal(
            FullMath.mulDiv(amount1Raw, pow10(token0Data.decimals), amount0Raw),
            token1Data.decimals
        );
        string memory priceToken0PerToken1 = formatDecimal(
            FullMath.mulDiv(amount0Raw, pow10(token1Data.decimals), amount1Raw),
            token0Data.decimals
        );

        console2.log("Price token1/token0:", priceToken1PerToken0);
        console2.log("Price token0/token1:", priceToken0PerToken1);

        vm.startBroadcast(deployerAddress);

        address existingPool = factory.getPool(token0, token1, TICK_SPACING);
        if (existingPool != address(0)) {
            console2.log("Pool already exists at:", existingPool);
            displayPoolState(existingPool, token0Data, token1Data);
            vm.stopBroadcast();
            return;
        }

        address newPool = factory.createPool({
            tokenA: token0,
            tokenB: token1,
            tickSpacing: TICK_SPACING,
            sqrtPriceX96: sqrtPriceX96
        });

        console2.log("Pool created at:", newPool);

        displayPoolState(newPool, token0Data, token1Data);

        vm.stopBroadcast();

        savePoolInfo(newPool, token0Data, token1Data, sqrtPriceX96);
    }

    function loadFactory() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/");
        string memory path = concat(basePath, "output/DeployCL-");
        path = concat(path, outputFilename);

        string memory jsonOutput = vm.readFile(path);
        factory = CLFactory(abi.decode(jsonOutput.parseRaw(".PoolFactory"), (address)));
    }

    function loadTokenAddresses() internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/output/");
        string memory path = concat(basePath, "TestTokens-");
        
        path = concat(path, outputFilename);

        string memory jsonOutput = vm.readFile(path);
        wethAddress = abi.decode(jsonOutput.parseRaw(".WETH"), (address));
        usdtAddress = abi.decode(jsonOutput.parseRaw(".USDT"), (address));
        usdcAddress = abi.decode(jsonOutput.parseRaw(".USDC"), (address));

        console2.log("Loaded token addresses:");
        console2.log("  WETH:", wethAddress);
        console2.log("  USDT:", usdtAddress);
        console2.log("  USDC:", usdcAddress);
    }

    function buildTokenData(address token, string memory humanAmount) internal view returns (TokenData memory data) {
        (string memory symbol, uint8 decimals) = getTokenInfo(token);
        data = TokenData({
            token: token,
            symbol: symbol,
            decimals: decimals,
            humanReadable: humanAmount,
            amount: parseDecimalString(humanAmount)
        });
    }

    function sortTokenData(TokenData memory first, TokenData memory second)
        internal
        pure
        returns (TokenData memory token0Data, TokenData memory token1Data)
    {
        if (first.token < second.token) {
            token0Data = first;
            token1Data = second;
        } else {
            token0Data = second;
            token1Data = first;
        }
    }

    function getTokenInfo(address token) internal view returns (string memory symbol, uint8 decimals) {
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
         
        }
    }

    function calculateSqrtPriceX96FromAmounts(
        TokenData memory token0Data,
        TokenData memory token1Data
    ) internal pure returns (uint160) {
        uint256 amount0 = toRawAmount(token0Data.amount, token0Data.decimals);
        uint256 amount1 = toRawAmount(token1Data.amount, token1Data.decimals);
        return encodeSqrtRatioX96(amount1, amount0);
    }

    function displayPoolState(
        address poolAddress,
        TokenData memory token0Data,
        TokenData memory token1Data
    ) internal view {
        ICLPool pool = ICLPool(poolAddress);
        (uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();

        console2.log("Pool state:");
        console2.log("  Current sqrtPriceX96:", uint256(sqrtPriceX96));
        console2.log("  Current tick:", int256(tick));

        (string memory priceToken1PerToken0, string memory priceToken0PerToken1) =
            describePrices(sqrtPriceX96, token0Data.decimals, token1Data.decimals);

        console2.log("Pool prices:");
        console2.log("  Price token1/token0:", priceToken1PerToken0);
        console2.log("  Price token0/token1:", priceToken0PerToken1);
    }

    function describePrices(
        uint160 sqrtPriceX96,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) internal pure returns (string memory token1PerToken0, string memory token0PerToken1) {
        uint256 ratioX192 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 numerator1 = FullMath.mulDiv(ratioX192, pow10(token0Decimals), uint256(1) << 192);
        uint256 numerator0 = FullMath.mulDiv(uint256(1) << 192, pow10(token1Decimals), ratioX192);
        token1PerToken0 = formatDecimal(numerator1, token1Decimals);
        token0PerToken1 = formatDecimal(numerator0, token0Decimals);
    }

    function savePoolInfo(
        address poolAddress,
        TokenData memory token0Data,
        TokenData memory token1Data,
        uint160 sqrtPriceX96
    ) internal {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, "/script/constants/output/");
        string memory filename = concat("PoolWithPrice-", outputFilename);
        string memory path = concat(basePath, filename);

        string memory output = "{\n";
        output = concat(output, '  "poolAddress": "');
        output = concat(output, vm.toString(poolAddress));
        output = concat(output, '",\n');
        output = concat(output, '  "token0": {\n');
        output = concat(output, '    "address": "');
        output = concat(output, vm.toString(token0Data.token));
        output = concat(output, '",\n');
        output = concat(output, '    "symbol": "');
        output = concat(output, token0Data.symbol);
        output = concat(output, '",\n');
        output = concat(output, '    "humanAmount": "');
        output = concat(output, token0Data.humanReadable);
        output = concat(output, '"\n  },\n');
        output = concat(output, '  "token1": {\n');
        output = concat(output, '    "address": "');
        output = concat(output, vm.toString(token1Data.token));
        output = concat(output, '",\n');
        output = concat(output, '    "symbol": "');
        output = concat(output, token1Data.symbol);
        output = concat(output, '",\n');
        output = concat(output, '    "humanAmount": "');
        output = concat(output, token1Data.humanReadable);
        output = concat(output, '"\n  },\n');
        output = concat(output, '  "tickSpacing": ');
        output = concat(output, vm.toString(uint256(TICK_SPACING)));
        output = concat(output, ',\n');
        output = concat(output, '  "sqrtPriceX96": "');
        output = concat(output, vm.toString(uint256(sqrtPriceX96)));
        output = concat(output, '",\n');
        (string memory token1PerToken0, string memory token0PerToken1) =
            describePrices(sqrtPriceX96, token0Data.decimals, token1Data.decimals);
        output = concat(output, '  "initialPrice": {\n');
        output = concat(output, '    "token1PerToken0": "');
        output = concat(output, token1PerToken0);
        output = concat(output, '",\n');
        output = concat(output, '    "token0PerToken1": "');
        output = concat(output, token0PerToken1);
        output = concat(output, '"\n  },\n');
        output = concat(output, '  "deployedAt": ');
        output = concat(output, vm.toString(block.timestamp));
        output = concat(output, '\n}');

        vm.writeFile(path, output);
        console2.log("Pool info saved to:", path);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function encodeSqrtRatioX96(uint256 amount1, uint256 amount0) internal pure returns (uint160) {
        require(amount0 > 0 && amount1 > 0, "ZERO_AMOUNTS");
        uint256 ratioX192 = FullMath.mulDiv(amount1, uint256(1) << 192, amount0);
        uint160 sqrtPriceX96 = uint160(Babylonian.sqrt(ratioX192));
        require(sqrtPriceX96 > 0, "INVALID_RATIO");
        return sqrtPriceX96;
    }

    function toRawAmount(ParsedAmount memory amount, uint8 tokenDecimals) internal pure returns (uint256) {
        require(amount.decimals <= tokenDecimals, "AMOUNT_DECIMALS_EXCEED_TOKEN");
        uint8 diff = tokenDecimals - amount.decimals;
        return amount.value * pow10(diff);
    }

    function parseDecimalString(string memory amountStr) internal pure returns (ParsedAmount memory) {
        bytes memory data = bytes(amountStr);
        require(data.length > 0, "EMPTY_AMOUNT");
        uint256 integerPart;
        uint256 fractionPart;
        uint8 fractionDigits;
        bool hasDecimal;

        for (uint256 i = 0; i < data.length; i++) {
            bytes1 char = data[i];
            if (char == 0x2E) {
                require(!hasDecimal, "MULTIPLE_DECIMALS");
                hasDecimal = true;
                continue;
            }
            require(char >= 0x30 && char <= 0x39, "INVALID_CHARACTER");
            uint8 digit = uint8(char) - 48;
            if (!hasDecimal) {
                integerPart = integerPart * 10 + digit;
            } else {
                fractionPart = fractionPart * 10 + digit;
                fractionDigits++;
            }
        }

        uint256 scale = pow10(fractionDigits);
        uint256 combined = integerPart * scale + fractionPart;
        return ParsedAmount({value: combined, decimals: fractionDigits});
    }

    function pow10(uint8 exponent) internal pure returns (uint256) {
        uint256 result = 1;
        for (uint8 i = 0; i < exponent; i++) {
            result *= 10;
        }
        return result;
    }

    function formatDecimal(uint256 amount, uint8 decimals) internal pure returns (string memory) {
        if (decimals == 0) {
            return Strings.toString(amount);
        }
        uint256 scale = pow10(decimals);
        uint256 integerPart = amount / scale;
        uint256 fractionPart = amount % scale;

        if (fractionPart == 0) {
            return Strings.toString(integerPart);
        }

        string memory integerStr = Strings.toString(integerPart);
        string memory fractionStr = toFixedLengthString(fractionPart, decimals);
        bytes memory fractionBytes = bytes(fractionStr);
        uint256 cut = fractionBytes.length;
        while (cut > 0 && fractionBytes[cut - 1] == bytes1(uint8(48))) {
            cut--;
        }
        if (cut == 0) {
            return Strings.toString(integerPart);
        }
        bytes memory trimmed = new bytes(cut);
        for (uint256 i = 0; i < cut; i++) {
            trimmed[i] = fractionBytes[i];
        }
        return string(abi.encodePacked(integerStr, ".", string(trimmed)));
    }

    function toFixedLengthString(uint256 value, uint8 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(length);
        for (uint256 i = length; i > 0; i--) {
            buffer[i - 1] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
