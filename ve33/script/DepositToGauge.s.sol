// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "./BaseDeployScript.sol";
interface IERC721 {
    function approve(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IGaugeCL {
    function deposit(uint256 tokenId) external;
}

contract DepositToGauge is BaseDeployScript {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerKey);
        string memory configPath = getConfigPath();
        string memory configJson = vm.readFile(configPath);
        // Addresses
        address nftPositionManager = abi.decode(vm.parseJson(configJson, ".nonfungiblePositionManager"), (address));
        address gauge = 0xCC943A3E9c9Ae72b37b8d5858E710F340D7Afa5D;
        
        // TokenIds to deposit
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] =10;
        // tokenIds[1] = 2;
        
        console.log("=== Deposit NFT LP to CL Gauge ===");
        console.log("Deployer:", deployer);
        console.log("NFT Position Manager:", nftPositionManager);
        console.log("Gauge:", gauge);
        console.log("TokenId 1:", tokenIds[0]);
        // console.log("TokenId 2:", tokenIds[1]);
        
        vm.startBroadcast(deployer);
        
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            // Verify ownership
            address owner = IERC721(nftPositionManager).ownerOf(tokenId);
            require(owner == deployer, "Not token owner");
            
            console.log("Processing tokenId:", tokenId);
            
            // Approve gauge to spend the NFT
            console.log("Approving tokenId", tokenId, "to gauge...");
            IERC721(nftPositionManager).approve(gauge, tokenId);
            
            // Deposit to gauge
            console.log("Depositing tokenId", tokenId, "to gauge...");
            IGaugeCL(gauge).deposit(tokenId);
            
            console.log("Successfully deposited tokenId:", tokenId);
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Deposit Complete ===");
        console.log("Deposited", tokenIds.length, "NFT LP positions to gauge");
    }
}