// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPairGenerator {
    function pairCodeHash() external pure returns (bytes32);
    function createPair(address token0, address token1, bool stable) external returns (address pair);
}
