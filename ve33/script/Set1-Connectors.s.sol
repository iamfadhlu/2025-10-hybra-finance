// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";

import {TokenHandler} from "../contracts/TokenHandler.sol";

contract SetConnectors is BaseDeployScript {
    using stdJson for string;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        
        // Load deployed contracts
        string memory infrastructurePath = getInputPath("Deploy1_Infrastructure");
        string memory infrastructureJson = vm.readFile(infrastructurePath);
        
        address tokenHandler = abi.decode(vm.parseJson(infrastructureJson, ".TokenHandler"), (address));
        
        // Pool token addresses that need to be connectors
        address token0 = 0x6C63c32D46e3e1D62Bdc98d5d07D0d093ea39BBF;
        address token1 = 0x8D0825829A5B33fAf44e885a196B5a3cc590B4d1;
        address token2 = 0x5555555555555555555555555555555555555555;
        address token3 = 0x5B176A9DcBCcb34d327e2416D00b1e77707d0169;
        address token4 = 0x8a52f09EFC79b416fF7B6DF5cfE99a269571c682;
        address token5 = 0x0BA507423422Face6ee0914234b53D686975F772;
        address token6 = 0xa5c1Ec69a87566BB9Ce1D86896d4B1AB1c576b44;

        // address token0 =0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1;
        // address token1 =0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44;
        // address token2 =0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f;
        // address token3 =0xc6e7DF5E7b4f2A278906862b61205850344D4e7d;
        // address token4 =0x59b670e9fA9D0A427751Af201D676719a970857b;
        console.log("=== Set Tokens as Connectors ===");
        console.log("TokenHandler:", tokenHandler);
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployer);
        
        // First whitelist the tokens
        address[] memory tokens = new address[](1);
        // tokens[0] = token0;
        // tokens[1] = token1;
        // tokens[2] = token2;
        // tokens[3] = token3;
        // tokens[4] = token4;
        // tokens[5] = token5;
        tokens[0] = token6;
        
        console.log("Whitelisting tokens...");
        TokenHandler(tokenHandler).whitelistTokens(tokens);
        console.log("Tokens whitelisted successfully");
        
        // Then set tokens as connectors
        console.log("Setting tokens as connectors...");
        TokenHandler(tokenHandler).whitelistConnectors(tokens);
        console.log("Tokens set as connectors successfully");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Verification ===");
        
        // Verify tokens are whitelisted and connectors
        // bool token0Whitelisted = TokenHandler(tokenHandler).isWhitelisted(token0);
        // bool token1Whitelisted = TokenHandler(tokenHandler).isWhitelisted(token1);
        // bool token2Whitelisted = TokenHandler(tokenHandler).isWhitelisted(token2);
        // bool token3Whitelisted = TokenHandler(tokenHandler).isWhitelisted(token3);
        // bool token4Whitelisted = TokenHandler(tokenHandler).isWhitelisted(token4);
        // bool token5Whitelisted = TokenHandler(tokenHandler).isWhitelisted(token5);
        // // bool token0Connector = TokenHandler(tokenHandler).isConnector(token0);
        // // bool token1Connector = TokenHandler(tokenHandler).isConnector(token1);
        // bool token2Connector = TokenHandler(tokenHandler).isConnector(token2);
        // bool token3Connector = TokenHandler(tokenHandler).isConnector(token3);
        // bool token4Connector = TokenHandler(tokenHandler).isConnector(token4);
        // bool token5Connector = TokenHandler(tokenHandler).isConnector(token5);
        // // console.log("Token0 is whitelisted:", token0Whitelisted);
        // // console.log("Token1 is whitelisted:", token1Whitelisted);
        // console.log("Token2 is whitelisted:", token2Whitelisted);
        // console.log("Token3 is whitelisted:", token3Whitelisted);
        // console.log("Token4 is whitelisted:", token4Whitelisted);
        // console.log("Token5 is whitelisted:", token5Whitelisted);
        // // console.log("Token0 is connector:", token0Connector);
        // // console.log("Token1 is connector:", token1Connector);
        // console.log("Token2 is connector:", token2Connector);
        // console.log("Token3 is connector:", token3Connector);
        // console.log("Token4 is connector:", token4Connector);
        // console.log("Token5 is connector:", token5Connector);
    }
}