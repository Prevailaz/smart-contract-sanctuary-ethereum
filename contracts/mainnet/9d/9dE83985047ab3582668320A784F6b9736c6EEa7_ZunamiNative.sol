//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IStrategy.sol';
import './interfaces/IZunamiRebalancer.sol';

/**
 *
 * @title Zunami Protocol v2
 *
 * @notice Contract for StakeDAO & Convex & Curve protocols optimize.
 * Users can use this contract for optimize yield and gas.
 *
 *
 * @dev Zunami is main contract.
 * Contract does not store user funds.
 * All user funds goes to StakeDAO & Convex & Curve pools.
 *
 */

contract ZunamiNative is ERC20, Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    uint256 public constant LP_RATIO_MULTIPLIER = 1e18;
    uint256 public constant FEE_DENOMINATOR = 100000;
    uint256 public constant MAX_FEE = 30000; // 30%
    uint256 public constant MIN_LOCK_TIME = 1 days;
    uint256 public constant FUNDS_DENOMINATOR = 10000000000;
    uint8 public constant ALL_WITHDRAWAL_TYPES_MASK = uint8(3); // Binary 11 = 2^0 + 2^1;
    address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant ETH_MOCK_TOKEN_ID = 0;

    uint8 public constant POOL_ASSETS = 5;

    struct PendingWithdrawal {
        uint256 lpShares;
        uint256[POOL_ASSETS] tokenAmounts;
    }

    struct PoolInfo {
        IStrategy strategy;
        uint256 startTime;
        uint256 lpShares;
        bool enabled;
    }

    PoolInfo[] internal _poolInfo;

    uint256 public defaultDepositPid;
    uint256 public defaultWithdrawPid;

    uint8 public availableWithdrawalTypes;
    uint128 public tokenCount;

    address[POOL_ASSETS] public tokens;
    uint256[POOL_ASSETS] public decimalsMultipliers;

    mapping(address => uint256[POOL_ASSETS]) internal _pendingDeposits;
    mapping(address => PendingWithdrawal) internal _pendingWithdrawals;

    uint256 public totalDeposited = 0;
    uint256 public managementFee = 15000; // 15%
    bool public launched = false;

    IZunamiRebalancer public rebalancer;

    event ManagementFeeSet(uint256 oldManagementFee, uint256 newManagementFee);
    event ChangedAvailableWithdrawalTypes(uint256 oldAvailableWithdrawalTypes, uint256 newAvailableWithdrawalTypes);
    event CreatedPendingDeposit(address indexed depositor, uint256[POOL_ASSETS] amounts);
    event CreatedPendingWithdrawal(
        address indexed withdrawer,
        uint256 lpShares,
        uint256[POOL_ASSETS] tokenAmounts
    );
    event RemovedPendingDeposit(address indexed depositor);

    event Deposited(
        address indexed depositor,
        uint256 depositedValue,
        uint256[POOL_ASSETS] amounts,
        uint256 lpShares,
        uint256 pid,
        bool optimized
    );

    event Withdrawn(
        address indexed withdrawer,
        uint256 lpShares,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex,
        uint256 pid,
        bool optimized
    );
    event FailedWithdrawal(
        address indexed withdrawer,
        uint256[POOL_ASSETS] amounts,
        uint256 lpShares,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex
    );

    event AddedPool(uint256 pid, address strategyAddr, uint256 startTime);
    event SetDefaultDepositPid(uint256 pid);
    event SetDefaultWithdrawPid(uint256 pid);
    event SetRebalancer(address rebalancerAddr);
    event ClaimedAllManagementFee(uint256 feeValue);
    event AutoCompoundAll(uint256 compoundedValue);
    event ChangedPoolEnabledStatus(address pool, bool newStatus);
    event UpdatedToken(
        uint256 tid,
        address token,
        uint256 tokenDecimalMultiplier,
        address tokenOld
    );

    modifier startedPool() {
        require(_poolInfo.length != 0, 'pools empty');
        require(
            block.timestamp >= _poolInfo[defaultDepositPid].startTime,
            'deposit not started'
        );
        require(
            block.timestamp >= _poolInfo[defaultWithdrawPid].startTime,
            'withdraw not started'
        );
        _;
    }

    modifier enabledPool(uint256 poolIndex) {
        require(poolIndex < _poolInfo.length && _poolInfo[poolIndex].enabled, 'not enabled');
        _;
    }

    constructor() ERC20('Zunami ETH LP', 'ethZLP') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        availableWithdrawalTypes = ALL_WITHDRAWAL_TYPES_MASK;

        tokens[0] = ETH_MOCK_ADDRESS;
        decimalsMultipliers[0] = 1;
        tokenCount = 1;
    }

    receive() external payable {
        // receive ETH from strategy on moving funds
    }

    function addTokens(address[] memory _tokens, uint256[] memory _tokenDecimalMultipliers)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_tokens.length > 0, 'wrong length');
        uint128 tokenCount_ = tokenCount;
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), 'zero address');
            require(_tokenDecimalMultipliers[i] > 0, 'wrong multiplier');
            tokens[tokenCount_] = _tokens[i];
            emit UpdatedToken(tokenCount_, _tokens[i], _tokenDecimalMultipliers[i], address(0));
            decimalsMultipliers[tokenCount_] = _tokenDecimalMultipliers[i];
            tokenCount_ += 1;
        }
        tokenCount = tokenCount_;
    }

    function replaceToken(
        uint256 _tokenIndex,
        address _token,
        uint256 _tokenDecimalMultiplier
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenIndex <= tokenCount && _tokenIndex > 0, 'wrong index');
        require(_token != address(0), 'zero address');
        require(_tokenDecimalMultiplier > 0, 'wrong multiplier');
        emit UpdatedToken(_tokenIndex, _token, _tokenDecimalMultiplier, tokens[_tokenIndex]);
        tokens[_tokenIndex] = _token;
        decimalsMultipliers[_tokenIndex] = _tokenDecimalMultiplier;
    }

    function poolInfo(uint256 pid) external view returns (PoolInfo memory) {
        return _poolInfo[pid];
    }

    function pendingDeposits(address user) external view returns (uint256[POOL_ASSETS] memory) {
        return _pendingDeposits[user];
    }

    function pendingWithdrawals(address user) external view returns (PendingWithdrawal memory) {
        return _pendingWithdrawals[user];
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setAvailableWithdrawalTypes(uint8 newAvailableWithdrawalTypes)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newAvailableWithdrawalTypes <= ALL_WITHDRAWAL_TYPES_MASK, 'wrong types');
        emit ChangedAvailableWithdrawalTypes(availableWithdrawalTypes, newAvailableWithdrawalTypes);
        availableWithdrawalTypes = newAvailableWithdrawalTypes;
    }

    /**
     * @dev update managementFee, this is a Zunami commission from protocol profit
     * @param  newManagementFee - minAmount 0, maxAmount MAX_FEE
     */
    function setManagementFee(uint256 newManagementFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newManagementFee <= MAX_FEE, 'wrong fee');
        emit ManagementFeeSet(managementFee, newManagementFee);
        managementFee = newManagementFee;
    }

    /**
     * @dev Returns managementFee for strategy's when contract sell rewards
     * @return Returns commission on the amount of profit in the transaction
     * @param amount - amount of profit for calculate managementFee
     */
    function calcManagementFee(uint256 amount) external view returns (uint256) {
        return (amount * managementFee) / FEE_DENOMINATOR;
    }

    /**
     * @dev Claims managementFee from all active strategies
     */
    function claimAllManagementFee() external {
        uint256 feeTotalValue;
        for (uint256 i = 0; i < _poolInfo.length; i++) {
            feeTotalValue += _poolInfo[i].strategy.claimManagementFees();
        }

        emit ClaimedAllManagementFee(feeTotalValue);
    }

    function autoCompoundAll() external {
        uint256 totalCompounded = 0;
        for (uint256 i = 0; i < _poolInfo.length; i++) {
            PoolInfo memory poolInfo_ = _poolInfo[i];
            if (poolInfo_.lpShares > 0 && poolInfo_.enabled) {
                totalCompounded += poolInfo_.strategy.autoCompound();
            }
        }
        emit AutoCompoundAll(totalCompounded);
    }

    /**
     * @dev Returns total holdings for all pools (strategy's)
     * @return Returns sum holdings (USD) for all pools
     */
    function totalHoldings() public view returns (uint256) {
        uint256 length = _poolInfo.length;
        uint256 totalHold = 0;
        for (uint256 pid = 0; pid < length; pid++) {
            PoolInfo memory poolInfo_ = _poolInfo[pid];
            if (poolInfo_.lpShares > 0 && poolInfo_.enabled) {
                totalHold += poolInfo_.strategy.totalHoldings();
            }
        }
        return totalHold;
    }

    /**
     * @dev Returns price depends on the income of users
     * @return Returns currently price of ZLP (1e18 = 1$)
     */
    function lpPrice() public view returns (uint256) {
        return calcTokenPrice(totalHoldings(), totalSupply());
    }

    function calcTokenPrice(uint256 _holdings, uint256 _tokens) public pure returns (uint256) {
        return (_holdings * 1e18) / _tokens;
    }

    /**
     * @dev Returns number of pools
     * @return number of pools
     */
    function poolCount() external view returns (uint256) {
        return _poolInfo.length;
    }

    /**
     * @dev in this func user sends funds to the contract and then waits for the completion
     * of the transaction for all users
     * @param amounts - array of deposit amounts by user
     */
    function delegateDeposit(uint256[POOL_ASSETS] memory amounts) external payable whenNotPaused startedPool nonReentrant {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                safeTransferFromNative(IERC20Metadata(tokens[i]), _msgSender(), address(this), amounts[i]);
                _pendingDeposits[_msgSender()][i] += amounts[i];
            }
        }

        emit CreatedPendingDeposit(_msgSender(), amounts);
    }

    /**
     * @dev deposit in one tx, without waiting complete by dev
     * @return Returns amount of lpShares minted for user
     * @param amounts - user send amounts of stablecoins to deposit
     */
    function deposit(uint256[POOL_ASSETS] memory amounts)
        external
        payable
        whenNotPaused
        startedPool
        nonReentrant
        returns (uint256)
    {
        IStrategy strategy = _poolInfo[defaultDepositPid].strategy;

        uint256 holdingsBefore = totalHoldings();

        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                safeTransferFromNative(IERC20Metadata(tokens[i]), _msgSender(), address(strategy), amounts[i]);
            }
        }
        uint256 depositedValue = strategy.deposit{ value: amounts[ETH_MOCK_TOKEN_ID] }(amounts);
        require(depositedValue > 0, 'low deposit');

        return
            processSuccessfulDeposit(_msgSender(), depositedValue, amounts, holdingsBefore, false);
    }

    function processSuccessfulDeposit(
        address user,
        uint256 depositedValue,
        uint256[POOL_ASSETS] memory depositedTokens,
        uint256 holdingsBefore,
        bool optimized
    ) internal returns (uint256 lpShares) {
        if (totalSupply() == 0) {
            lpShares = depositedValue;
        } else {
            lpShares = (totalSupply() * depositedValue) / holdingsBefore;
        }

        _mint(user, lpShares);
        _poolInfo[defaultDepositPid].lpShares += lpShares;
        emit Deposited(
            user,
            depositedValue,
            depositedTokens,
            lpShares,
            defaultDepositPid,
            optimized
        );
        totalDeposited += depositedValue;
    }

    /**
     * @dev Zunami protocol owner complete all active pending deposits of users
     * @param userList - dev send array of users from pending to complete
     */
    function completeDeposits(address[] memory userList)
        external
        nonReentrant
        onlyRole(OPERATOR_ROLE)
    {
        IStrategy strategy = _poolInfo[defaultDepositPid].strategy;
        uint256 holdingsBefore = totalHoldings();

        uint256 holdingsNew;
        uint256[POOL_ASSETS] memory totalAmounts;
        uint256[] memory holdingsPerUser = new uint256[](userList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            holdingsNew = 0;
            for (uint256 x = 0; x < totalAmounts.length; x++) {
                uint256 userTokenDeposit = _pendingDeposits[userList[i]][x];
                totalAmounts[x] += userTokenDeposit;
                holdingsNew += userTokenDeposit * decimalsMultipliers[x];
            }
            holdingsPerUser[i] = holdingsNew;
        }

        uint256 holdingsTotal = 0;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            uint256 tokenAmountTotal = totalAmounts[y];
            if (tokenAmountTotal > 0) {
                holdingsTotal += tokenAmountTotal * decimalsMultipliers[y];
                if (y != 0) {
                    safeTransferNative(IERC20Metadata(tokens[y]), address(strategy), tokenAmountTotal);
                }
            }
        }
        uint256 depositedValue = strategy.deposit{ value: totalAmounts[ETH_MOCK_TOKEN_ID] }(totalAmounts);
        require(depositedValue > 0, 'low deposit');

        uint256 holdingsCounted = 0;
        uint256 userDepositedValue = 0;
        for (uint256 z = 0; z < userList.length; z++) {
            address userAddr = userList[z];
            userDepositedValue = (depositedValue * holdingsPerUser[z]) / holdingsTotal;
            processSuccessfulDeposit(
                userAddr,
                userDepositedValue,
                _pendingDeposits[userAddr],
                holdingsBefore + holdingsCounted,
                true
            );
            holdingsCounted += userDepositedValue;
            delete _pendingDeposits[userAddr];
        }
    }

    /**
     * @dev in this func user sends pending withdraw to the contract and then waits
     * for the completion of the transaction for all users
     * @param  lpShares - amount of ZLP for withdraw
     * @param tokenAmounts - array of amounts stablecoins that user want minimum receive
     */
    function delegateWithdrawal(
        uint256 lpShares,
        uint256[POOL_ASSETS] memory tokenAmounts
    ) external whenNotPaused startedPool nonReentrant {
        require(lpShares > 0, 'zero lp');

        PendingWithdrawal memory withdrawal;
        address userAddr = _msgSender();

        withdrawal.lpShares = lpShares;
        withdrawal.tokenAmounts = tokenAmounts;

        _pendingWithdrawals[userAddr] = withdrawal;

        emit CreatedPendingWithdrawal(userAddr, lpShares, tokenAmounts);
    }

    /**
     * @dev withdraw in one tx, without waiting complete by dev
     * @param lpShares - amount of ZLP for withdraw
     * @param tokenAmounts -  array of amounts stablecoins that user want minimum receive
     */
    function withdraw(
        uint256 lpShares,
        uint256[POOL_ASSETS] memory tokenAmounts,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external whenNotPaused startedPool nonReentrant {
        require(availableWithdrawalTypes & (0x01 << uint8(withdrawalType)) != 0, 'wrong type');

        IStrategy strategy = _poolInfo[defaultWithdrawPid].strategy;
        address userAddr = _msgSender();

        require(balanceOf(userAddr) >= lpShares, 'wrong lp');
        require(
            strategy.withdraw(
                userAddr,
                calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares),
                tokenAmounts,
                withdrawalType,
                tokenIndex
            ),
            'wrong params'
        );

        uint256 userDeposit = (totalDeposited * lpShares) / totalSupply();

        processSuccessfulWithdrawal(
            userAddr,
            userDeposit,
            lpShares,
            withdrawalType,
            tokenIndex,
            false
        );
    }

    function processSuccessfulWithdrawal(
        address user,
        uint256 userDeposit,
        uint256 lpShares,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex,
        bool optimized
    ) internal {
        _burn(user, lpShares);
        _poolInfo[defaultWithdrawPid].lpShares -= lpShares;
        totalDeposited -= userDeposit;
        emit Withdrawn(user, lpShares, withdrawalType, tokenIndex, defaultWithdrawPid, optimized);
    }

    function processSuccessfulOptimizedWithdrawal(
        address[] memory userList,
        uint256[POOL_ASSETS] memory lpSharesTotals,
        uint256[POOL_ASSETS] memory prevBalances
    ) internal {
        uint256[POOL_ASSETS] memory diffBalances;
        for (uint256 i = 0; i < POOL_ASSETS; i++) {
            address token = tokens[i];
            if (token == address(0)) break;
            diffBalances[i] = balanceOfNative(IERC20Metadata(token)) - prevBalances[i];
        }

        for (uint256 i = 0; i < userList.length; i++) {
            address user = userList[i];
            PendingWithdrawal memory withdrawal = _pendingWithdrawals[user];

            uint256 userDeposit = (totalDeposited * withdrawal.lpShares) / totalSupply();

            processSuccessfulWithdrawal(
                user,
                userDeposit,
                withdrawal.lpShares,
                IStrategy.WithdrawalType.Base,
                0,
                true
            );

            uint256 transferAmount;
            for (uint256 j = 0; j < POOL_ASSETS; j++) {
                if (lpSharesTotals[j] == 0) continue;
                transferAmount = (diffBalances[j] * withdrawal.lpShares) / lpSharesTotals[j];

                if (transferAmount == 0) continue;
                safeTransferNative(IERC20Metadata(tokens[j]), user, transferAmount);
            }

            delete _pendingWithdrawals[user];
        }
    }

    function calcLpRatioSafe(uint256 outLpShares, uint256 strategyLpShares)
        internal
        pure
        returns (uint256 lpShareRatio)
    {
        lpShareRatio = (outLpShares * LP_RATIO_MULTIPLIER) / strategyLpShares;
        require(lpShareRatio > 0 && lpShareRatio <= LP_RATIO_MULTIPLIER, 'wrong ratio');
    }

    /**
     * @dev Zunami protocol owner complete all active pending withdrawals of users
     * @param userList - users owns pending withdraw to complete
     */
    function completeWithdrawals(
        address[] memory userList,
        uint256[POOL_ASSETS] memory minAmountsTotal
    ) external nonReentrant onlyRole(OPERATOR_ROLE) {
        require(userList.length > 0, 'zero requests');

        IStrategy strategy = _poolInfo[defaultWithdrawPid].strategy;

        uint256 lpSharesTotal;

        uint256 i;
        address user;
        PendingWithdrawal memory withdrawal;
        for (i = 0; i < userList.length; i++) {
            user = userList[i];

            withdrawal = _pendingWithdrawals[user];
            if (balanceOf(user) < withdrawal.lpShares) {
                emit FailedWithdrawal(
                    user,
                    withdrawal.tokenAmounts,
                    withdrawal.lpShares,
                    IStrategy.WithdrawalType.Base,
                    0
                );
                delete _pendingWithdrawals[user];
                continue;
            }

            lpSharesTotal += withdrawal.lpShares;
        }

        require(lpSharesTotal <= _poolInfo[defaultWithdrawPid].lpShares, 'not enough lp');

        uint256[POOL_ASSETS] memory prevBalances = calcPrevTokenBalances();

        if (
            !strategy.withdraw(
                address(this),
                calcLpRatioSafe(lpSharesTotal, _poolInfo[defaultWithdrawPid].lpShares),
                minAmountsTotal,
                IStrategy.WithdrawalType.Base,
                0
            )
        ) {
            removeAllFailedWithdrawals(userList);
            return;
        }

        processSuccessfulOptimizedWithdrawal(userList, fillArrayN(lpSharesTotal), prevBalances);
    }

    function calcPrevTokenBalances()
        internal
        view
        returns (uint256[POOL_ASSETS] memory prevBalances)
    {
        for (uint256 i = 0; i < POOL_ASSETS; i++) {
            address token = tokens[i];
            if (token == address(0)) break;
            prevBalances[i] = balanceOfNative(IERC20Metadata(token));
        }
    }

    function removeAllFailedWithdrawals(address[] memory userList) internal {
        for (uint256 i = 0; i < userList.length; i++) {
            address user = userList[i];
            PendingWithdrawal memory withdrawal = _pendingWithdrawals[user];

            emit FailedWithdrawal(
                user,
                withdrawal.tokenAmounts,
                withdrawal.lpShares,
                IStrategy.WithdrawalType.Base,
                0
            );
            delete _pendingWithdrawals[user];
        }
    }

    function calcWithdrawOneCoin(uint256 lpShares, uint128 tokenIndex)
        external
        view
        returns (uint256 tokenAmount)
    {
        uint256 lpShareRatio = calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares);
        return _poolInfo[defaultWithdrawPid].strategy.calcWithdrawOneCoin(lpShareRatio, tokenIndex);
    }

    function calcSharesAmount(uint256[POOL_ASSETS] memory tokenAmounts, bool isDeposit)
        external
        view
        returns (uint256 lpShares)
    {
        return _poolInfo[defaultWithdrawPid].strategy.calcSharesAmount(tokenAmounts, isDeposit);
    }

    /**
     * @dev add a new pool, deposits in the new pool are blocked for one day for safety
     * @param _strategyAddr - the new pool strategy address
     */
    function addPool(address _strategyAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_strategyAddr != address(0), 'zero addr');
        uint256 poolInfoLength_ = _poolInfo.length;
        for (uint256 i = 0; i < poolInfoLength_; i++) {
            require(_strategyAddr != address(_poolInfo[i].strategy), 'duplicate');
        }

        uint256 startTime = block.timestamp + (launched ? MIN_LOCK_TIME : 0);
        _poolInfo.push(
            PoolInfo({
                strategy: IStrategy(_strategyAddr),
                startTime: startTime,
                lpShares: 0,
                enabled: true
            })
        );
        emit AddedPool(poolInfoLength_, _strategyAddr, startTime);
    }

    /**
     * @dev set a default pool for deposit funds
     * @param _newPoolId - new pool id
     */
    function setDefaultDepositPid(uint256 _newPoolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        enabledPool(_newPoolId)
    {
        require(_newPoolId < _poolInfo.length, 'wrong pid');

        defaultDepositPid = _newPoolId;
        emit SetDefaultDepositPid(_newPoolId);
    }

    /**
     * @dev set a default pool for withdraw funds
     * @param _newPoolId - new pool id
     */
    function setDefaultWithdrawPid(uint256 _newPoolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        enabledPool(_newPoolId)
    {
        require(_newPoolId < _poolInfo.length, 'incorrect pid');

        defaultWithdrawPid = _newPoolId;
        emit SetDefaultWithdrawPid(_newPoolId);
    }

    function launch() external onlyRole(DEFAULT_ADMIN_ROLE) {
        launched = true;
    }

    modifier onlyRebalancer() {
        require(_msgSender() == address(rebalancer), 'rebalancer');
        _;
    }

    function setRebalancer(address rebalancerAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rebalancerAddr != address(0), 'zero address');

        rebalancer = IZunamiRebalancer(rebalancerAddr);
        emit SetRebalancer(rebalancerAddr);
    }

    function rebalance() external onlyRole(DEFAULT_ADMIN_ROLE) {
        rebalancer.rebalance();
    }

    function increasePoolShares(uint256 pid, uint256 amount) external onlyRebalancer {
        _poolInfo[pid].lpShares += amount;
    }

    function decreasePoolShares(uint256 pid, uint256 amount) external onlyRebalancer {
        _poolInfo[pid].lpShares -= amount;
    }

    /**
     * @dev dev can transfer funds from few strategy's to one strategy for better APY
     * @param _strategies - array of strategy's, from which funds are withdrawn
     * @param withdrawalsPercents - A percentage of the funds that should be transferred
     * @param _receiverStrategy - number strategy, to which funds are deposited
     */
    function moveFundsBatch(
        uint256[] memory _strategies,
        uint256[] memory withdrawalsPercents,
        uint256 _receiverStrategy
    ) external onlyRole(DEFAULT_ADMIN_ROLE) enabledPool(_receiverStrategy) {
        require(_strategies.length == withdrawalsPercents.length, 'wrong arguments');
        require(_receiverStrategy < _poolInfo.length, 'wrong receiver');

        uint256[POOL_ASSETS] memory tokenBalance;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            address token = tokens[y];
            if (token == address(0)) break;
            tokenBalance[y] = balanceOfNative(IERC20Metadata(token));
        }

        uint256 pid;
        uint256 zunamiLp;
        for (uint256 i = 0; i < _strategies.length; i++) {
            pid = _strategies[i];
            zunamiLp += _moveFunds(pid, withdrawalsPercents[i]);
        }

        uint256[POOL_ASSETS] memory tokensRemainder;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            address token = tokens[y];
            if (token == address(0)) break;
            tokensRemainder[y] = balanceOfNative(IERC20Metadata(token)) - tokenBalance[y];
            if (tokensRemainder[y] > 0) {
                safeTransferNative(
                    IERC20Metadata(token),
                    address(_poolInfo[_receiverStrategy].strategy),
                    tokensRemainder[y]
                );
            }
        }

        _poolInfo[_receiverStrategy].lpShares += zunamiLp;

        require(_poolInfo[_receiverStrategy].strategy.deposit(tokensRemainder) > 0, 'low amount');
    }

    function _moveFunds(uint256 pid, uint256 withdrawPercent) private returns (uint256) {
        uint256 currentLpAmount;

        if (withdrawPercent == FUNDS_DENOMINATOR) {
            _poolInfo[pid].strategy.withdrawAll();

            currentLpAmount = _poolInfo[pid].lpShares;
            _poolInfo[pid].lpShares = 0;
        } else {
            currentLpAmount = (_poolInfo[pid].lpShares * withdrawPercent) / FUNDS_DENOMINATOR;
            uint256[POOL_ASSETS] memory minAmounts;

            _poolInfo[pid].strategy.withdraw(
                address(this),
                calcLpRatioSafe(currentLpAmount, _poolInfo[pid].lpShares),
                minAmounts,
                IStrategy.WithdrawalType.Base,
                0
            );
            _poolInfo[pid].lpShares = _poolInfo[pid].lpShares - currentLpAmount;
        }

        return currentLpAmount;
    }

    /**
     * @dev user remove his active pending deposit
     */
    function removePendingDeposit() external nonReentrant {
        uint256[POOL_ASSETS] memory pendingDeposit =  _pendingDeposits[_msgSender()];
        delete _pendingDeposits[_msgSender()];
        emit RemovedPendingDeposit(_msgSender());

        uint256 tokenAmount_;
        for (uint256 i = 0; i < POOL_ASSETS; i++) {
            tokenAmount_ = pendingDeposit[i];
            if (tokenAmount_ > 0) {
                safeTransferNative(IERC20Metadata(tokens[i]), _msgSender(), tokenAmount_);
            }
        }
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from Zunami
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenBalance = balanceOfNative(_token);
        if (tokenBalance > 0) {
            safeTransferNative(_token, _msgSender(), tokenBalance);
        }
    }

    function disablePool(uint256 _pid) external onlyRole(PAUSER_ROLE) {
        require(_poolInfo[_pid].enabled, "not enabled");
        _poolInfo[_pid].enabled = false;

        emit ChangedPoolEnabledStatus(address(_poolInfo[_pid].strategy), _poolInfo[_pid].enabled);
    }

    function enablePool(uint256 _pid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_poolInfo[_pid].enabled, "not disabled");
        _poolInfo[_pid].enabled = true;

        emit ChangedPoolEnabledStatus(address(_poolInfo[_pid].strategy), _poolInfo[_pid].enabled);
    }

    function fillArrayN(uint256 _value) internal pure returns (uint256[POOL_ASSETS] memory values) {
        for (uint256 i; i < POOL_ASSETS; i++) {
            values[i] = _value;
        }
    }

    function balanceOfNative(IERC20Metadata token_) internal view returns (uint256) {
        if (address(token_) == ETH_MOCK_ADDRESS) {
            return address(this).balance;
        } else {
            return token_.balanceOf(address(this));
        }
    }

    function safeTransferNative(
        IERC20Metadata token,
        address receiver,
        uint256 amount
    ) internal {
        if (address(token) == ETH_MOCK_ADDRESS) {
            receiver.call{ value: amount }(''); // don't fail if user contract doesn't accept ETH
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function safeTransferFromNative(
        IERC20Metadata token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        if (address(token) == ETH_MOCK_ADDRESS) {
            require(msg.value == amount, 'ETH wrong');
        } else {
            token.safeTransferFrom(sender, receiver, amount);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategy {
    enum WithdrawalType {
        Base,
        OneCoin
    }

    function deposit(uint256[5] memory amounts) external payable returns (uint256);

    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[5] memory tokenAmounts,
        WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external returns (bool);

    function withdrawAll() external;

    function totalHoldings() external view returns (uint256);

    function claimManagementFees() external returns (uint256);

    function autoCompound() external returns (uint256);

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps, uint128 tokenIndex)
        external
        view
        returns (uint256 tokenAmount);

    function calcSharesAmount(uint256[5] memory tokenAmounts, bool isDeposit)
        external
        view
        returns (uint256 sharesAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IStrategy.sol';

interface IZunamiRebalancer {
    function rebalance() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}