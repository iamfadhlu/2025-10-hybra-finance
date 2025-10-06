// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface INonfungiblePositionManager {
    // Setters
    function setOwner(address _owner) external;
    function setTokenDescriptor(address _tokenDescriptor) external;

    // Getters
    function owner() external view returns (address);
}
