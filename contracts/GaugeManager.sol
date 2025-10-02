// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './libraries/Math.sol';
import './interfaces/IVoter.sol';
import './interfaces/ITokenHandler.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPairInfo.sol';
import './interfaces/IPairFactory.sol';
import './interfaces/IVotingEscrow.sol';
import './interfaces/IPermissionsRegistry.sol';
import './interfaces/IGaugeFactoryCL.sol';
import './interfaces/IGaugeManager.sol';
import './interfaces/IBribe.sol';
import './interfaces/IBribeFactory.sol';
import './interfaces/IGauge.sol';
import './interfaces/IMinter.sol';
import './interfaces/IGaugeCL.sol';
import './interfaces/IBribe.sol';
import './interfaces/IGaugeFactory.sol';
import "./CLGauge/interface/ICLPool.sol";
import {VoterFactoryLib} from "./libraries/VoterFactoryLib.sol";
import {HybraTimeLibrary} from "./libraries/HybraTimeLibrary.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


contract GaugeManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address[] public pools;
    
    address public minter; 
    uint256 internal index; 
    address internal base; 
    address public bribefactory; 
    address public _ve; 
    mapping(address => uint256) internal supplyIndex;              // gauge    => index
    mapping(address => uint256) public claimable;                  // gauge    => claimable $the
    mapping(address => address) public gauges;                  // pool     => gauge
    mapping(address => uint256) public gaugesDistributionTimestmap;// gauge    => last Distribution Time
    mapping(address => address) public poolForGauge;            // gauge    => pool    
    mapping(address => address) public internal_bribes;         // gauge    => internal bribe (only fees)
    mapping(address => address) public external_bribes;         // gauge    => external bribe (real bribes)
    
    VoterFactoryLib.Data private _factoriesData;
    address public permissionRegistry;  
    address public voter;  
    address public tokenHandler; 
    address public HybraGovernor;
    address public nfpm;
    mapping(address => bool) public isGauge;                    // gauge    => boolean [is a gauge?]
    mapping(address => bool) public isCLGauge;
    mapping(address => bool) public isAlive;                    // gauge    => boolean [is the gauge alive?]




  
    event GaugeCreated(address indexed gauge, address creator, address internal_bribe, address indexed external_bribe, address indexed pool);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
    event SetBribeFor(bool isInternal, address indexed old, address indexed latest, address indexed gauge);
    event SetMinter(address indexed old, address indexed latest);
    event SetBribeFactory(address indexed old, address indexed latest);
    event SetPermissionRegistry(address indexed old, address indexed latest);

    constructor() {}

    function initialize(address __ve, address _tokenHandler, address _gaugeFactory, address _gaugeFactoryCL, 
                        address _pairFactory, address _pairFactoryCL, address _permissionRegistory, address _nfpm) initializer public {
     __Ownable_init();
     __ReentrancyGuard_init();
      _ve = __ve;  
      base = IVotingEscrow(__ve).token();  
      tokenHandler = _tokenHandler;
       permissionRegistry = _permissionRegistory;
      _factoriesData.gaugeFactories.push(_gaugeFactory);
      _factoriesData.gaugeFactories.push(_gaugeFactoryCL);
      _factoriesData.pairFactories.push(_pairFactory);
      _factoriesData.pairFactories.push(_pairFactoryCL);
      nfpm = _nfpm;
    }

    modifier GaugeAdmin() {
        require(IPermissionsRegistry(permissionRegistry).hasRole("GAUGE_ADMIN",msg.sender), 'GAUGE_ADMIN');
        _;
    }

    modifier Governance() {
        require(IPermissionsRegistry(permissionRegistry).hasRole("GOVERNANCE",msg.sender), 'GOVERNANCE');
        _;
    }

    /// @notice Set a new Bribe Factory
    function setBribeFactory(address _bribeFactory) external GaugeAdmin {
        require(_bribeFactory.code.length > 0, "CODELEN");
        require(_bribeFactory != address(0), "ZA");
        bribefactory = _bribeFactory;
        emit SetBribeFactory(bribefactory, _bribeFactory);
    }

    /// @notice Set a new PermissionRegistry
    function setPermissionsRegistry(address _permissionRegistry) external GaugeAdmin {
        require(_permissionRegistry.code.length > 0, "CODELEN");
        require(_permissionRegistry != address(0), "ZA");
        emit SetPermissionRegistry(permissionRegistry, _permissionRegistry);
        permissionRegistry = _permissionRegistry;
    }

    function setVoter(address _voter) external GaugeAdmin{
        require(_voter.code.length > 0, "CODELEN");
        require(_voter != address(0), "ZA");
        voter = _voter;
    }

   
    function getHybraGovernor() external view returns (address){
        return HybraGovernor;
    }

    function setHybraGovernor(address _HybraGovernor) external GaugeAdmin {
        require(_HybraGovernor != address(0), "ZA");
        HybraGovernor = _HybraGovernor;
    }
    
    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    GAUGE CREATION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */
    /// @notice create multiple gauges
    function createGauges(address[] memory _pool, uint256[] memory _gaugeTypes) external nonReentrant returns(address[] memory, address[] memory, address[] memory)  {
        require(_pool.length == _gaugeTypes.length, "MISMATCH_LEN");
        require(_pool.length <= 10, "MAXVAL");
        address[] memory _gauge = new address[](_pool.length);
        address[] memory _int = new address[](_pool.length);
        address[] memory _ext = new address[](_pool.length);

        uint256 i = 0;
        for(i; i < _pool.length; i++){
            (_gauge[i], _int[i], _ext[i]) = _createGauge(_pool[i], _gaugeTypes[i]);
        }
        return (_gauge, _int, _ext);
    }

    /// @notice create a gauge  
    function createGauge(address _pool, uint256 _gaugeType) external nonReentrant returns (address _gauge, address _internal_bribe, address _external_bribe)  {
        (_gauge, _internal_bribe, _external_bribe) = _createGauge(_pool, _gaugeType);
    }



    /// @notice create a gauge
    /// @param  _pool       LP address 
    /// @param  _gaugeType  the type of the gauge you want to create
    /// @dev    To create stable/Volatile pair gaugeType = 0, Concentrated liqudity = 1, ...
    ///         Make sure to use the corrcet gaugeType or it will fail

    function _createGauge(address _pool, uint256 _gaugeType) internal returns (address _gauge, address _internal_bribe, address _external_bribe) {
        require(_gaugeType < _factoriesData.pairFactories.length, "GAUGETYPE");
        require(gauges[_pool] == address(0x0), "DNE");
        require(_pool.code.length > 0, "CODELEN");
        bool isPair;
        address _factory = _factoriesData.pairFactories[_gaugeType];
        address _gaugeFactory = _factoriesData.gaugeFactories[_gaugeType];
        require(_factory != address(0), "ZA");
        require(_gaugeFactory != address(0), "ZA");
        

        address tokenA = address(0);
        address tokenB = address(0);
        (tokenA) = IPairInfo(_pool).token0();
        (tokenB) = IPairInfo(_pool).token1();

        // for future implementation add isPair() in factory
        if(_gaugeType == 0){
            isPair = IPairFactory(_factory).isPair(_pool);
        } 
        if(_gaugeType == 1) {
            // removed due to code size
            // require(_pool_hyper == _pool_factory, 'wrong tokens');    
            isPair = true;
        }

        require(ITokenHandler(tokenHandler).isWhitelisted(tokenA) && ITokenHandler(tokenHandler).isWhitelisted(tokenB), "!WHITELISTED");
        require(ITokenHandler(tokenHandler).isConnector(tokenA) || ITokenHandler(tokenHandler).isConnector(tokenB), "!CONNECTOR");
        require(isPair, "!POOL");
        require(tokenA != address(0) && tokenB != address(0), "!TOKENS");

        (_internal_bribe, _external_bribe) = _deployBribes(_pool, tokenA, tokenB, _gaugeType);
        // create gauge
        if(_gaugeType == 0) {
            _gauge = IGaugeFactory(_gaugeFactory).createGauge(base, _ve, _pool, address(this), _internal_bribe, _external_bribe, isPair);
        }
        if(_gaugeType == 1) {
            _gauge = IGaugeFactoryCL(_gaugeFactory).createGauge(base, _ve, _pool, address(this), _internal_bribe, _external_bribe, isPair, nfpm);
            isCLGauge[_gauge] = true;
            ICLPool(_pool).setGaugeAndPositionManager(_gauge, nfpm);
        }
        // approve spending for $the
        IERC20(base).approve(_gauge, type(uint256).max);
        _saveBribeData(_pool, _gauge, _internal_bribe, _external_bribe);
        emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _pool);
    }

    function _saveBribeData(address _pool, address _gauge, address _internal_bribe, address _external_bribe) private {
        // save data
        internal_bribes[_gauge] = _internal_bribe;
        external_bribes[_gauge] = _external_bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        pools.push(_pool);

        // update index
        // todo: below line will go to ve33 rewarder. 
        supplyIndex[_gauge] = index; // new gauges are set to the default global state
    }
    
    function _deployBribes(address _pool, address tokenA, address tokenB, uint256 _gaugeType) private returns (address _internal_bribe, address _external_bribe) 
    {
        // create internal and external bribe
        address _owner = IPermissionsRegistry(permissionRegistry).hybraTeamMultisig();
        string memory _internalType;
        string memory _extrenalType;
        if(_gaugeType == 0) {
            _internalType =  string.concat("Hybra LP Fees: ", IERC20(_pool).symbol() );
            _extrenalType = string.concat("Hybra Bribes: ", IERC20(_pool).symbol() );
        }
        if(_gaugeType == 1) {
            string memory poolStr = addressToString(_pool);
            _internalType = string.concat("Hybra LP Fees: ", poolStr);
            _extrenalType = string.concat("Hybra Bribes: ", poolStr);
        }
        
        _internal_bribe = IBribeFactory(bribefactory).createBribe(_owner, tokenA, tokenB, _internalType);
        _external_bribe = IBribeFactory(bribefactory).createBribe(_owner, tokenA, tokenB, _extrenalType);
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        bytes20 value = bytes20(_addr);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';

        for (uint i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }

        return string(str);
    }



    /// @notice notify reward amount for gauge
    /// @dev    the function is called by the minter each epoch. Anyway anyone can top up some extra rewards.
    /// @param  amount  amount to distribute
    function notifyRewardAmount(uint256 amount) external {
        require(msg.sender == minter, "NA");
        IERC20Upgradeable(base).safeTransferFrom(msg.sender, address(this), amount);

        uint256 _ratio = 0;
        uint256 totalWeight = IVoter(voter).totalWeight();
        if(totalWeight > 0) _ratio = amount * 1e18 / Math.max(totalWeight, 1);     // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }

        emit NotifyReward(msg.sender, base, amount);
    }

    function distributeFees() external nonReentrant {
        uint256 i = 0;
        uint256 poolsLength = pools.length;
        for (i; i < poolsLength; i++) {
            address _pool = pools[i];
            _distributeFees(_pool);
        }
    }

   function distributeFees(uint256 _start, uint256 _finish) external nonReentrant {
        for (uint256 x = _start; x < _finish; x++) {
            address _pool = pools[x];
            _distributeFees(_pool);
        }
    }


    function _distributeFees(address _pool) internal {
        if (isGauge[gauges[_pool]] && isAlive[gauges[_pool]]){
            if(!isCLGauge[gauges[_pool]]) {
                IGauge(gauges[_pool]).claimFees();
            } else {
                IGaugeCL(gauges[_pool]).claimFees();
            }
        }
    }
    
    /// @notice Distribute the emission for ALL gauges 
    function distributeAll() external nonReentrant {
        
        IMinter(minter).update_period();

        uint256 x = 0;
        uint256 stop = pools.length;
        for (x; x < stop; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    function distribute(uint256 _start, uint256 _finish) external nonReentrant {
        IMinter(minter).update_period();
        for (uint256 x = _start; x < _finish; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    /// @notice distribute reward onyl for given gauges
    /// @dev    this function is used in case some distribution fails
    function distribute(address[] memory _gauges) external nonReentrant {
        IMinter(minter).update_period();
        for (uint256 x = 0; x < _gauges.length; x++) {
            _distribute(_gauges[x]);
        }
    }

    /// @notice distribute the emission
    function _distribute(address _gauge) internal {

        uint256 lastTimestamp = gaugesDistributionTimestmap[_gauge];
        uint256 currentTimestamp = HybraTimeLibrary.epochStart(block.timestamp);
        if(lastTimestamp < currentTimestamp){
            _updateForAfterDistribution(_gauge); // should set claimable to 0 if killed

            uint256 _claimable = claimable[_gauge];

            // distribute only if claimable is > 0, currentEpoch != lastepoch and gauge is alive
            if (_claimable > 0 && isAlive[_gauge] && !IGauge(_gauge).emergency()) {
                claimable[_gauge] = 0;
                gaugesDistributionTimestmap[_gauge] = currentTimestamp;
                if(!isCLGauge[_gauge]) {
                    IGauge(_gauge).notifyRewardAmount(base, _claimable);
                } else {
                    IGaugeCL(_gauge).notifyRewardAmount(base, _claimable);
                }
                emit DistributeReward(msg.sender, _gauge, _claimable);
            }
        }
    }


    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    HELPERS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */
 
  
    /// @notice update info for gauges
    /// @dev    this function track the gauge index to emit the correct $the amount after the distribution
    function _updateForAfterDistribution(address _gauge) private {
        address _pool = poolForGauge[_gauge];
        //uint256 _supplied = weightsPerEpoch[_time][_pool];
        uint256 _supplied = IVoter(voter).weights(_pool);

        if (_supplied > 0) {
            uint256 _supplyIndex = supplyIndex[_gauge];
            uint256 _index = index; // get global index0 for accumulated distro
            // SupplyIndex will be updated for Killed Gauges as well so we don't need to udpate index while reviving gauge.
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint256 _share = _supplied * _delta / 1e18; // add accrued difference for each supplied token
                if (isAlive[_gauge]) {
                    claimable[_gauge] += _share;
                } else {
                    IERC20Upgradeable(base).safeTransfer(minter, _share); // send rewards back to Minter so they're not stuck in GaugeManager
                }
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    GOVERNANCE
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */
    

     /// @notice Kill a malicious gauge 
    /// @param  _gauge gauge to kill
    function killGauge(address _gauge) external Governance {
        require(isAlive[_gauge], "DEAD");
        isAlive[_gauge] = false;

        // Return claimable back to minter
        uint256 _claimable = claimable[_gauge];
        if (_claimable > 0) {
            IERC20Upgradeable(base).safeTransfer(minter, _claimable);
        }
        claimable[_gauge] = 0;

        // We shouldn't update totalWeight because if we decrease it other pools will get more emission while in current scenario 
        // emissionAmount of killed gauge will get transferred back to Minter
        // We're decreasing totalWeight in case of Reset functionality while resetting vote from killed gauge.
        //totalWeight = totalWeight - weights[poolForGauge[_gauge]];
        emit GaugeKilled(_gauge);
    }

    /// @notice Revive a malicious gauge 
    /// @param  _gauge gauge to revive
    function reviveGauge(address _gauge) external Governance {
        require(!isAlive[_gauge], "ALIVE");
        require(isGauge[_gauge], 'DEAD');
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }



      /// @notice Set a new bribes for a given gauge
    function setNewBribes(address _gauge, address _internal, address _external) external GaugeAdmin {
        require(isGauge[_gauge], "!GAUGE");
        require(_gauge.code.length > 0, "CODELEN");
        _setInternalBribe(_gauge, _internal);
        _setExternalBribe(_gauge, _external);
    }

    /// @notice Set a new internal bribe for a given gauge
    function setInternalBribeFor(address _gauge, address _internal) external GaugeAdmin {
        require(isGauge[_gauge], "!GAUGE");
        _setInternalBribe(_gauge, _internal);
    }

    /// @notice Set a new External bribe for a given gauge
    function setExternalBribeFor(address _gauge, address _external) external GaugeAdmin {
        require(isGauge[_gauge], "!GAUGE");
        _setExternalBribe(_gauge, _external);
    }

    function _setInternalBribe(address _gauge, address _internal) private {
        require(_internal.code.length > 0, "CODELEN");
        emit SetBribeFor(true, internal_bribes[_gauge], _internal, _gauge);
        internal_bribes[_gauge] = _internal;
    }

    function _setExternalBribe(address _gauge, address _external) private {
        require(_external.code.length > 0, "CODELEN");
        emit SetBribeFor(false, internal_bribes[_gauge], _external, _gauge);
        external_bribes[_gauge] = _external;
    }

    /// @notice claim LP gauge rewards
    function claimRewards(address[] memory _gauges, uint8 _redeemType) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender, _redeemType);
        }
    }

    /// @notice claim LP gauge rewards
    function claimRewards(address _gauge, uint256[] memory _nftIds, uint8 _redeemType) external {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            IGaugeCL(_gauge).getReward(_nftIds[i], msg.sender, _redeemType);
        }
    }

    function claimAllRewards(address[] memory _gauges, uint256[][] memory _nftIds, uint8 _redeemType) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            for (uint256 j = 0; j < _nftIds[i].length; j++) {
                IGaugeCL(_gauges[i]).getReward(_nftIds[i][j], msg.sender, _redeemType);
            }
        }
    }

    /// @notice claim bribes rewards given a TokenID
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId), "NAO");
        for (uint256 i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getReward(_tokenId, _tokens[i]);
        }
    }

    function claimAllBribes(address[] memory _bribes, address[][] memory _tokens, uint256[][] memory _nftIds) external {
        require(_bribes.length == _tokens.length && _bribes.length == _nftIds.length, "Array length mismatch");

        for (uint256 i = 0; i < _bribes.length; i++) {
            for (uint256 j = 0; j < _nftIds[i].length; j++) {
                require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _nftIds[i][j]), "NAO");
                IBribe(_bribes[i]).getReward(_nftIds[i][j], _tokens[i]);
            }
        }
    }

    function fetchInternalBribeFromPool(address _pool) external returns (address) {
        return internal_bribes[gauges[_pool]];
    }

    function fetchExternalBribeFromPool(address _pool) external returns (address) {
        return external_bribes[gauges[_pool]];
    }

    function isGaugeAliveForPool(address _pool) external returns (bool) {
        return isGauge[gauges[_pool]] && isAlive[gauges[_pool]];
    }

        /// @notice Set a new Minter
    function setMinter(address _minter) external GaugeAdmin {
        require(_minter != address(0), "ZA");
        require(_minter.code.length > 0, "CODELEN");
        emit SetMinter(minter, _minter);
        minter = _minter;
    }

    function addGaugeFactory(address _gaugeFactory) external GaugeAdmin {
        VoterFactoryLib.addGaugeFactory(_factoriesData, _gaugeFactory);
    }

    function replaceGaugeFactory(address _gaugeFactory, uint256 _pos) external GaugeAdmin {
        VoterFactoryLib.replaceGaugeFactory(_factoriesData, _gaugeFactory, _pos);
    }

    function removeGaugeFactory(uint256 _pos) external GaugeAdmin {
        VoterFactoryLib.removeGaugeFactory(_factoriesData, _pos);
    }

    function addPairFactory(address _pairFactory) external GaugeAdmin {
        VoterFactoryLib.addPairFactory(_factoriesData, _pairFactory);
    }

    function replacePairFactory(address _pairFactory, uint256 _pos) external GaugeAdmin {
        VoterFactoryLib.replacePairFactory(_factoriesData, _pairFactory, _pos);
    }

    function removePairFactory(uint256 _pos) external GaugeAdmin {
        VoterFactoryLib.removePairFactory(_factoriesData, _pos);
    }
    


}