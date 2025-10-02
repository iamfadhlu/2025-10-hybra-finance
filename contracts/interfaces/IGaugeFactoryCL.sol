// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IGaugeManager.sol";

interface IGaugeFactoryCL {
    function createGauge(address _rewardToken,address _ve,address _token,address _distribution, address _internal_bribe, address _external_bribe, bool _isPair, address nfpm) external returns (address) ;
    function gauges(uint256 i) external view returns(address);
    function length() external view returns(uint);
}