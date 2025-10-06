// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPoolFactory {
    // Setters
    function setSwapFeeModule(address _swapFeeModule) external;
    function setUnstakedFeeModule(address _unstakedFeeModule) external;
    function setProtocolFeeModule(address _protocolFeeModule) external;
    function setOwner(address _owner) external;
    function setSwapFeeManager(address _swapFeeManager) external;
    function setUnstakedFeeManager(address _unstakedFeeManager) external;
    function setProtocolFeeManager(address _protocolFeeManager) external;
    function setDefaultUnstakedFee(uint24 _defaultUnstakedFee) external;
    function enableTickSpacing(int24 _tickSpacing, uint24 _fee) external;

    // Getters
    function protocolFeeModule() external view returns (address);
    function defaultProtocolFee() external view returns (uint24);
    function swapFeeManager() external view returns (address);
    function unstakedFeeManager() external view returns (address);
    function protocolFeeManager() external view returns (address);
    function owner() external view returns (address);
    function poolImplementation() external view returns (address);
}
