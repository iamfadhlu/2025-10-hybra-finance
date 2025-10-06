// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IDynamicSwapFeeModule {
    // Setters
    function setDefaultFeeCap(uint256 _defaultFeeCap) external;
    function setDefaultScalingFactor(uint256 _defaultScalingFactor) external;
    function setSecondsAgo(uint32 _secondsAgo) external;
}
