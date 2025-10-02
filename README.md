# Hybra Finance audit details
- Total Prize Pool: $33,000 in USDC
  - HM awards: up to $28,800 in USDC
    - If no valid Highs or Mediums are found, the HM pool is $0 
  - QA awards: $1,200 in USDC
  - Judge awards: $2,500 in USDC
  - Scout awards: $500 in USDC
- [Read our guidelines for more details](https://docs.code4rena.com/competitions)
- Starts October 3, 2025 20:00 UTC
- Ends October 13, 2025 20:00 UTC

**❗ Important notes for wardens** 
1. A coded, runnable PoC is required for all High/Medium submissions to this audit. 
  - This repo includes a basic template to run the test suite.
  - PoCs must use the test suite provided in this repo.
  - Your submission will be marked as Insufficient if the POC is not runnable and working with the provided test suite.
  - Exception: PoC is optional (though recommended) for wardens with signal ≥ 0.68.
1. Judging phase risk adjustments (upgrades/downgrades):
  - High- or Medium-risk submissions downgraded by the judge to Low-risk (QA) will be ineligible for awards.
  - Upgrading a Low-risk finding from a QA report to a Medium- or High-risk finding is not supported.
  - As such, wardens are encouraged to select the appropriate risk level carefully during the submission phase.

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2025-10-hybra-finance/blob/main/4naly3er-report.md).

_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

The issues identified in [Peckshield's September 2025 audit report](https://github.com/peckshield/publications/blob/master/audit_reports/PeckShield-Audit-Report-Hybra-ve33-v1.0.pdf) are considered publicly known issues and are therefore ineligible for awards, including:

1.Possible ERC7702 Incompatibility in Contract Check
2.Voting Delegate Denial-of-Service With Dust Delegates
3.Trust Issue of Admin Keys
4.Improved Dynamic Fee Calculation in `DynamicSwapFeeModule`
5.Improper `estimateAmount0/1()` logic in `SugarHelper`

# Overview

[ ⭐️ SPONSORS: add info here ]

## Links

- **Previous audits:**  [Peckshield: September 29, 2025](https://github.com/peckshield/publications/blob/master/audit_reports/PeckShield-Audit-Report-Hybra-ve33-v1.0.pdf)
- **Documentation:** https://hybra-foundation.gitbook.io/hybra-foundation/
- **Website:** https://www.hybra.finance/
- **X/Twitter:** https://x.com/hybrafinance

---

# Scope

[ ✅ SCOUTS: add scoping and technical details here ]

### Files in scope
- ✅ This should be completed using the `metrics.md` file
- ✅ Last row of the table should be Total: SLOC
- ✅ SCOUTS: Have the sponsor review and and confirm in text the details in the section titled "Scoping Q amp; A"

*For sponsors that don't use the scoping tool: list all files in scope in the table below (along with hyperlinks) -- and feel free to add notes to emphasize areas of focus.*

| Contract | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| [contracts/folder/sample.sol](https://github.com/code-423n4/repo-name/blob/contracts/folder/sample.sol) | 123 | This contract does XYZ | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |

### Files out of scope
✅ SCOUTS: List files/directories out of scope

# Additional context

## Areas of concern (where to focus for bugs)

### 1. CL Gauge
- When users deposit a tokenId into the NFT, does the reward distribution from emissions correctly match the active liquidity range they provide, or could there be a mismatch in reward calculations?

### 2. ve(3,3) Epoch Cycle, Rotation, and Reward Distribution / Rebase
- For the entire ve(3,3) epoch cycle rollover: is the process of reward distribution (Distribute), rebase, etc. functioning correctly? Could there be cases of uneven reward allocation? If the epoch rollover fails, would it cause impact? When claiming rewards across epochs, can users still fully claim all rewards from previous epochs?
- For voters claiming rewards, if rewards have already been distributed but not yet fully claimed, what happens when they extend their lock duration or merge positions — will this affect the reward data?

### 3. RewardHYBR
- During the reward claiming process, when converting rewards into veHYBR, HYBR, or gHYBR, can the claim always be executed successfully under all circumstances?
- Could there be any asset loss or abnormal situations?

### 4. gHYBR
- Are there any potential fund security vulnerabilities within gHYBR?
- For deposits and withdrawals, are fund flows handled correctly? When splitting, slicing, or merging veNFTs within gHYBR, does the system ensure funds remain intact and properly accounted for?



## Main invariants



### 1. Global & Supply

* **[G-1] Token Supply Conservation**
  No token within the protocol may be minted or burned out of thin air: any increase or decrease in supply must originate from clearly defined mint/burn paths (e.g., emissions, penalty burns, treasury mints). All amounts and events must be auditable and traceable.

* **[G-2] Balance Conservation**
  On-chain balances must always be greater than or equal to the sum of all accrued/claimable balances (rewards, bribes, fees). Negative balances or overflows must never occur.

* **[G-3] Time Monotonicity**
  Time-dependent cumulative quantities (e.g., feeGrowth, rewardDebt, emission distributions) must only increase monotonically or decay according to defined rules; they must never retrogress.

---

### 2. Locks & Voting Power (veNFT / Lock / Voting Power)

* **[V-1] Lock Bounds**
  `lock_start < lock_end ≤ lock_start + MAX_LOCK`; MAX_LOCK cannot be bypassed or extended. Early withdrawals before expiry are prohibited unless explicitly documented via penalty or escape-hatch mechanisms.

* **[V-2] Voting Power Decay**
  The derivative of veBalance with respect to time must be non-positive: without relocking or extending the lock, `veBalance(t+Δ) ≤ veBalance(t)`.

* **[V-3] Transfer Rules**
  Transfers, merges, and splits of veNFTs must follow rules:

  * *Merge*: New NFT voting power = result of deterministic merge logic (typically a function of amounts and remaining durations). No artificial increase of voting power is allowed.
  * *Split*: Sum of child NFT weights = parent NFT weight (evaluated at the same timestamp).
  * Restrictions must be consistent and verifiable when NFTs are under active votes or pending rewards/bribes.

* **[V-4] Delegation & Caps**
  Delegation only reassigns accounting, without changing the global voting power. If MAX_DELEGATES or checkpoint limits exist, failed writes are By Design but must never break settlement or compromise fund safety of other accounts.

---

### 3. Voting, Gauges & Epochs

* **[W-1] Weight Sum Conservation**
  Within an epoch, the sum of all gauge weights = the effective total voting power (or its normalized form). A single veNFT’s total vote allocation ≤ its available voting power.

* **[W-2] Epoch Boundary Consistency**
  Weight snapshots take effect strictly at epoch boundaries. Updates in one epoch must not retroactively affect settled allocations from the previous epoch.

* **[W-3] No Overvote / No Reuse**
  The same veNFT cannot have its voting share double-counted within the same window. Unvoting/revoting must follow predictable activation timing.

---

### 4. Emissions & Bribes

* **[E-1] Emission Cap**
  Per-epoch emissions must not exceed the formula or governance-set budget. No hidden inflation is allowed.

* **[E-2] Proportionality**
  Emissions allocated to gauges must be strictly proportional to their effective weight snapshots. Gauges with zero weight must receive zero emissions.

* **[E-3] Bribe Accounting Conservation**
  For each bribe pool, the accounting identity must hold at all times:
  `inflows – claimed – refunds = remaining ≥ 0`. Negative values must never occur.

* **[E-4] Multi-Token & Precision**
  For multi-token rewards/bribes, accounting across different decimals/precisions must follow consistent rounding/dust-handling rules. User value must never be lost.

---

### 5. Rewards & Fees

* **[R-1] Non-negative Claimables**
  Any user/veNFT claimable balance ≥ 0; under no sequence or precision case may it become negative.

* **[R-2] Monotone Accrual**
  Without user interaction, `claimable(t+Δ) ≥ claimable(t)` (or, after claims reduce the balance, subsequent accrual resumes monotonically increasing).

* **[R-3] Accrue-then-Claim**
  Claims must first checkpoint/accrue all pending rewards to ensure “slow users” are not diluted.

---

### 6. Access Control & Governance

* **[A-1] Least Privilege**
  Only governance/multisig may alter global critical parameters (emission rates, fees, whitelists, etc.). Regular users cannot escalate privilege.

* **[A-2] Upgrade/Pause Safety**
  Upgrades, pauses, or resumes must not alter existing entitlements or accrued balances. In paused state, critical invariants must still hold (assets can be safely withdrawn and cannot be siphoned).

---

### 7. Checkpointing

* **[C-1] Order Independence**
  Different valid call orders must not change the final cumulative results (audit guidance: use differential testing against reentrancy/order-dependence).

* **[C-2] Context Isolation**
  The settlement of a single veNFT must not depend on the settlement order of other veNFTs, unless explicitly documented as shared state.

---

### 8. Math & Bounds

* **[M-1] No Over/Underflow**
  All multiplications/divisions must be safe within bounded ranges (e.g., 256-bit/128-bit). Use safe-math utilities such as FullMath/mulDiv.

* **[M-2] Precision & Rounding**
  Explicit rounding strategy (“round down” / “round to nearest”) must be defined. Precision handling must not create exploitable arbitrage or liabilities.


## All trusted roles in the protocol

Based on PermissionsRegistry contract analysis:

  Core Multisigs

  1. hybraMultisig (PermissionsRegistry:11)
    - Main 4/6 multisig controlling the protocol
    - Can add/remove roles, assign roles to addresses, change itself
  2. hybraTeamMultisig (PermissionsRegistry:14)
    - Team 2/2 multisig
    - Can change itself
  3. emergencyCouncil (PermissionsRegistry:17)
    - Emergency functions control
    - Can change itself

  Role-Based Access Control

  All roles defined in PermissionsRegistry constructor (lines 45-67):

  4. GOVERNANCE - High-level governance decisions
  5. VOTER_ADMIN - Manage voter contract settings
  6. GAUGE_ADMIN - Manage gauge contracts
  7. BRIBE_ADMIN - Manage bribe contracts


  Additional Trusted Addresses

  12. team (MinterUpgradeable:36) - Controls emission parameters and rewards
  13. owner - Standard Ownable admin on various contracts"

✅ SCOUTS: Please format the response above 👆 using the template below👇

| Role                                | Description                       |
| --------------------------------------- | ---------------------------- |
| Owner                          | Has superpowers                |
| Administrator                             | Can change fees                       |

✅ SCOUTS: Please format the response above 👆 so its not a wall of text and its readable.

## Running tests

common clone build run

✅ SCOUTS: Please format the response above 👆 using the template below👇

```bash
git clone https://github.com/code-423n4/2023-08-arbitrum
git submodule update --init --recursive
cd governance
foundryup
make install
make build
make sc-election-test
```
To run code coverage
```bash
make coverage
```

✅ SCOUTS: Add a screenshot of your terminal showing the test coverage

## Miscellaneous
Employees of Hybra Finance and employees' family members are ineligible to participate in this audit.

Code4rena's rules cannot be overridden by the contents of this README. In case of doubt, please check with C4 staff.



# Scope

*See [scope.txt](https://github.com/code-423n4/2025-10-hybra-finance/blob/main/scope.txt)*

### Files in scope


| File   | Logic Contracts | Interfaces | nSLOC | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /contracts/GaugeManager.sol | 1| **** | 401 | |@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol<br>@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol<br>@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol<br>@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol|
| /contracts/GaugeV2.sol | 1| 1 | 258 | |@openzeppelin/contracts/security/ReentrancyGuard.sol<br>@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol|
| /contracts/MinterUpgradeable.sol | 1| **** | 161 | |@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol|
| /contracts/VoterV3.sol | 1| **** | 168 | |@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol<br>@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol<br>@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol<br>@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol|
| /contracts/VotingEscrow.sol | 1| **** | 749 | |@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol<br>@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol|
| /contracts/CLGauge/GaugeCL.sol | 1| **** | 258 | |@openzeppelin/contracts/security/ReentrancyGuard.sol<br>@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /contracts/CLGauge/GaugeFactoryCL.sol | 1| 1 | 71 | |@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol|
| /contracts/GovernanceHYBR.sol | 1| **** | 378 | |@openzeppelin/contracts/token/ERC20/ERC20.sol<br>@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/security/ReentrancyGuard.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol|
| /contracts/HYBR.sol | 1| **** | 81 | ||
| /contracts/RewardHYBR.sol | 1| **** | 203 | |@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/security/ReentrancyGuard.sol<br>@openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>@openzeppelin/contracts/security/Pausable.sol<br>@openzeppelin/contracts/token/ERC20/ERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol|
| /contracts/CL/core/CLFactory.sol | 1| **** | 201 | |@openzeppelin/contracts/proxy/Clones.sol<br>@nomad-xyz/src/ExcessivelySafeCall.sol|
| /contracts/CL/core/CLPool.sol | 1| **** | 700 | ||
| /contracts/CL/core/fees/DynamicSwapFeeModule.sol | 1| **** | 149 | ||
| /contracts/swapper/HybrSwapper.sol | 1| **** | 68 | |@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/security/ReentrancyGuard.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol|
| **Totals** | **14** | **2** | **3846** | | |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2025-10-hybra-finance/blob/main/out_of_scope.txt)*

| File         |
| ------------ |
| ./contracts/APIHelper/RewardAPI.sol |
| ./contracts/APIHelper/veNFTAPIV1.sol |
| ./contracts/Bribes.sol |
| ./contracts/CL/core/fees/CustomProtocolFeeModule.sol |
| ./contracts/CL/core/fees/CustomSwapFeeModule.sol |
| ./contracts/CL/core/fees/CustomUnstakedFeeModule.sol |
| ./contracts/CL/core/interfaces/ICLFactory.sol |
| ./contracts/CL/core/interfaces/ICLPool.sol |
| ./contracts/CL/core/interfaces/IERC20Minimal.sol |
| ./contracts/CL/core/interfaces/IFactoryRegistry.sol |
| ./contracts/CL/core/interfaces/IGaugeManager.sol |
| ./contracts/CL/core/interfaces/IMinter.sol |
| ./contracts/CL/core/interfaces/IPool.sol |
| ./contracts/CL/core/interfaces/IPoolFactory.sol |
| ./contracts/CL/core/interfaces/IVoter.sol |
| ./contracts/CL/core/interfaces/IVotingEscrow.sol |
| ./contracts/CL/core/interfaces/callback/ICLFlashCallback.sol |
| ./contracts/CL/core/interfaces/callback/ICLMintCallback.sol |
| ./contracts/CL/core/interfaces/callback/ICLSwapCallback.sol |
| ./contracts/CL/core/interfaces/fees/ICustomFeeModule.sol |
| ./contracts/CL/core/interfaces/fees/IDynamicFeeModule.sol |
| ./contracts/CL/core/interfaces/fees/IFeeModule.sol |
| ./contracts/CL/core/interfaces/pool/ICLPoolActions.sol |
| ./contracts/CL/core/interfaces/pool/ICLPoolConstants.sol |
| ./contracts/CL/core/interfaces/pool/ICLPoolDerivedState.sol |
| ./contracts/CL/core/interfaces/pool/ICLPoolEvents.sol |
| ./contracts/CL/core/interfaces/pool/ICLPoolOwnerActions.sol |
| ./contracts/CL/core/interfaces/pool/ICLPoolState.sol |
| ./contracts/CL/core/libraries/BitMath.sol |
| ./contracts/CL/core/libraries/FixedPoint128.sol |
| ./contracts/CL/core/libraries/FixedPoint96.sol |
| ./contracts/CL/core/libraries/FullMath.sol |
| ./contracts/CL/core/libraries/LiquidityMath.sol |
| ./contracts/CL/core/libraries/LowGasSafeMath.sol |
| ./contracts/CL/core/libraries/Oracle.sol |
| ./contracts/CL/core/libraries/Position.sol |
| ./contracts/CL/core/libraries/SafeCast.sol |
| ./contracts/CL/core/libraries/SqrtPriceMath.sol |
| ./contracts/CL/core/libraries/SwapMath.sol |
| ./contracts/CL/core/libraries/Tick.sol |
| ./contracts/CL/core/libraries/TickBitmap.sol |
| ./contracts/CL/core/libraries/TickMath.sol |
| ./contracts/CL/core/libraries/TransferHelper.sol |
| ./contracts/CL/core/libraries/UnsafeMath.sol |
| ./contracts/CL/libraries/EnumerableSet.sol |
| ./contracts/CL/libraries/ProtocolTimeLibrary.sol |
| ./contracts/CL/periphery/NonfungiblePositionManager.sol |
| ./contracts/CL/periphery/NonfungibleTokenPositionDescriptor.sol |
| ./contracts/CL/periphery/PositionValueQuery.sol |
| ./contracts/CL/periphery/SugarHelper.sol |
| ./contracts/CL/periphery/SwapRouter.sol |
| ./contracts/CL/periphery/base/BlockTimestamp.sol |
| ./contracts/CL/periphery/base/ERC721Permit.sol |
| ./contracts/CL/periphery/base/LiquidityManagement.sol |
| ./contracts/CL/periphery/base/Multicall.sol |
| ./contracts/CL/periphery/base/PeripheryImmutableState.sol |
| ./contracts/CL/periphery/base/PeripheryPayments.sol |
| ./contracts/CL/periphery/base/PeripheryPaymentsWithFee.sol |
| ./contracts/CL/periphery/base/PeripheryValidation.sol |
| ./contracts/CL/periphery/base/SelfPermit.sol |
| ./contracts/CL/periphery/examples/PairFlash.sol |
| ./contracts/CL/periphery/interfaces/IERC20Metadata.sol |
| ./contracts/CL/periphery/interfaces/IERC4906.sol |
| ./contracts/CL/periphery/interfaces/IERC721Permit.sol |
| ./contracts/CL/periphery/interfaces/IMixedRouteQuoterV1.sol |
| ./contracts/CL/periphery/interfaces/IMulticall.sol |
| ./contracts/CL/periphery/interfaces/INonfungiblePositionManager.sol |
| ./contracts/CL/periphery/interfaces/INonfungibleTokenPositionDescriptor.sol |
| ./contracts/CL/periphery/interfaces/IPeripheryImmutableState.sol |
| ./contracts/CL/periphery/interfaces/IPeripheryPayments.sol |
| ./contracts/CL/periphery/interfaces/IPeripheryPaymentsWithFee.sol |
| ./contracts/CL/periphery/interfaces/IQuoter.sol |
| ./contracts/CL/periphery/interfaces/IQuoterV2.sol |
| ./contracts/CL/periphery/interfaces/ISelfPermit.sol |
| ./contracts/CL/periphery/interfaces/ISugarHelper.sol |
| ./contracts/CL/periphery/interfaces/ISwapRouter.sol |
| ./contracts/CL/periphery/interfaces/ITickLens.sol |
| ./contracts/CL/periphery/interfaces/external/IERC1271.sol |
| ./contracts/CL/periphery/interfaces/external/IERC20PermitAllowed.sol |
| ./contracts/CL/periphery/interfaces/external/IWETH9.sol |
| ./contracts/CL/periphery/lens/CLInterfaceMulticall.sol |
| ./contracts/CL/periphery/lens/MixedRouteQuoterV1.sol |
| ./contracts/CL/periphery/lens/Quoter.sol |
| ./contracts/CL/periphery/lens/QuoterV2.sol |
| ./contracts/CL/periphery/lens/TickLens.sol |
| ./contracts/CL/periphery/libraries/BytesLib.sol |
| ./contracts/CL/periphery/libraries/CallbackValidation.sol |
| ./contracts/CL/periphery/libraries/ChainId.sol |
| ./contracts/CL/periphery/libraries/HexStrings.sol |
| ./contracts/CL/periphery/libraries/LiquidityAmounts.sol |
| ./contracts/CL/periphery/libraries/NFTDescriptor.sol |
| ./contracts/CL/periphery/libraries/NFTSVG.sol |
| ./contracts/CL/periphery/libraries/OracleLibrary.sol |
| ./contracts/CL/periphery/libraries/Path.sol |
| ./contracts/CL/periphery/libraries/PoolAddress.sol |
| ./contracts/CL/periphery/libraries/PoolTicksCounter.sol |
| ./contracts/CL/periphery/libraries/PositionKey.sol |
| ./contracts/CL/periphery/libraries/PositionValue.sol |
| ./contracts/CL/periphery/libraries/SqrtPriceMathPartial.sol |
| ./contracts/CL/periphery/libraries/TokenRatioSortOrder.sol |
| ./contracts/CL/periphery/libraries/TransferHelper.sol |
| ./contracts/CLGauge/interface/ICLFactory.sol |
| ./contracts/CLGauge/interface/ICLPool.sol |
| ./contracts/CLGauge/interface/IERC4906.sol |
| ./contracts/CLGauge/interface/IERC721Permit.sol |
| ./contracts/CLGauge/interface/INonfungiblePositionManager.sol |
| ./contracts/CLGauge/interface/IPeripheryImmutableState.sol |
| ./contracts/CLGauge/interface/IPeripheryPayments.sol |
| ./contracts/CLGauge/interface/PoolAddress.sol |
| ./contracts/CLGauge/interface/pool/ICLPoolActions.sol |
| ./contracts/CLGauge/interface/pool/ICLPoolConstants.sol |
| ./contracts/CLGauge/interface/pool/ICLPoolDerivedState.sol |
| ./contracts/CLGauge/interface/pool/ICLPoolEvents.sol |
| ./contracts/CLGauge/interface/pool/ICLPoolOwnerActions.sol |
| ./contracts/CLGauge/interface/pool/ICLPoolState.sol |
| ./contracts/CLGauge/libraries/FixedPoint128.sol |
| ./contracts/CLGauge/libraries/FullMath.sol |
| ./contracts/HybraGovernor.sol |
| ./contracts/PermissionsRegistry.sol |
| ./contracts/RewardsDistributor.sol |
| ./contracts/TokenHandler.sol |
| ./contracts/VeArtProxyUpgradeable.sol |
| ./contracts/factories/BribeFactoryV3.sol |
| ./contracts/factories/GaugeFactory.sol |
| ./contracts/interfaces/IBribe.sol |
| ./contracts/interfaces/IBribeAPI.sol |
| ./contracts/interfaces/IBribeDistribution.sol |
| ./contracts/interfaces/IBribeFactory.sol |
| ./contracts/interfaces/IBribeFull.sol |
| ./contracts/interfaces/IDibs.sol |
| ./contracts/interfaces/IERC20.sol |
| ./contracts/interfaces/IGHYBR.sol |
| ./contracts/interfaces/IGauge.sol |
| ./contracts/interfaces/IGaugeAPI.sol |
| ./contracts/interfaces/IGaugeCL.sol |
| ./contracts/interfaces/IGaugeDistribution.sol |
| ./contracts/interfaces/IGaugeFactory.sol |
| ./contracts/interfaces/IGaugeFactoryCL.sol |
| ./contracts/interfaces/IGaugeManager.sol |
| ./contracts/interfaces/IHybra.sol |
| ./contracts/interfaces/IHybraClaims.sol |
| ./contracts/interfaces/IHybraGovernor.sol |
| ./contracts/interfaces/IHybraPairApiV2.sol |
| ./contracts/interfaces/IHybraVotes.sol |
| ./contracts/interfaces/IMinter.sol |
| ./contracts/interfaces/IPair.sol |
| ./contracts/interfaces/IPairCallee.sol |
| ./contracts/interfaces/IPairFactory.sol |
| ./contracts/interfaces/IPairGenerator.sol |
| ./contracts/interfaces/IPairInfo.sol |
| ./contracts/interfaces/IPermissionsRegistry.sol |
| ./contracts/interfaces/IRHYBR.sol |
| ./contracts/interfaces/IRewardsDistributor.sol |
| ./contracts/interfaces/IRouter.sol |
| ./contracts/interfaces/ISwapper.sol |
| ./contracts/interfaces/ITokenHandler.sol |
| ./contracts/interfaces/ITopNPoolsStrategy.sol |
| ./contracts/interfaces/IUniswapRouterETH.sol |
| ./contracts/interfaces/IUniswapV2Pair.sol |
| ./contracts/interfaces/IVeArtProxy.sol |
| ./contracts/interfaces/IVoteWeightStrategy.sol |
| ./contracts/interfaces/IVoter.sol |
| ./contracts/interfaces/IVotingEscrow.sol |
| ./contracts/interfaces/IWETH.sol |
| ./contracts/interfaces/IWrappedBribeFactory.sol |
| ./contracts/libraries/Base64.sol |
| ./contracts/libraries/HybraTimeLibrary.sol |
| ./contracts/libraries/Math.sol |
| ./contracts/libraries/PoolsAndRewardsLibrary.sol |
| ./contracts/libraries/SignedSafeMath.sol |
| ./contracts/libraries/VoterFactoryLib.sol |
| ./contracts/libraries/VotingBalanceLogic.sol |
| ./contracts/libraries/VotingDelegationLib.sol |
| Totals: 173 |

