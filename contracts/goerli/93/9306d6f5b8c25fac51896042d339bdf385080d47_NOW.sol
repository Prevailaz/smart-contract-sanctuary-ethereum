/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

    modifier isHuman() {
        require(tx.origin == msg.sender, "Humans only");
        _;
    }
}


//Base class that implements: ERC20 interface, fees & swaps
abstract contract NOWBase is Context, IERC20Metadata, Ownable, ReentrancyGuard {
    // MAIN TOKEN PROPERTIES
    string private constant NAME = "Now";
    string private constant SYMBOL = "NOW";
    uint8 private constant DECIMALS = 18;
    uint8 private _liquidityFee; //% of each transaction that will be added as liquidity
    uint8 private _rewardFee; //% of each transaction that will be used for ETH reward pool
    uint8 private _poolFee; //The total fee to be taken and added to the pool, this includes all fees
    uint8 private _highBuyFee;

    uint256 private constant _totalTokens = 100000000 * 10**DECIMALS;    //total supply
    mapping (address => uint256) private _balances; //The balance of each address.  This is before applying distribution rate.  To get the actual balance, see balanceOf() method
    mapping (address => mapping (address => uint256)) private _allowances;

    // FEES & REWARDS
    bool private _isSwapEnabled; // True if the contract should swap for liquidity & reward pool, false otherwise
    bool private _isFeeEnabled; // True if fees should be applied on transactions, false otherwise
    bool private _isTokenHoldEnabled;
    address public constant BURN_WALLET = 0x000000000000000000000000000000000000dEaD; //The address that keeps track of all tokens burned
    uint256 private _tokenSwapThreshold = _totalTokens / 10000; //There should be at least 0.0001% of the total supply in the contract before triggering a swap
    uint256 private _totalFeesPooled; // The total fees pooled (in number of tokens)
    uint256 private _totalETHLiquidityAddedFromFees; // The total number of ETH added to the pool through fees
    mapping (address => bool) private _addressesExcludedFromFees; // The list of addresses that do not pay a fee for transactions
    mapping (address => bool) private _addressesExcludedFromHold; // The list of addresses that hold token amount

    // TRANSACTION LIMIT
    uint256 private _transactionSellLimit = _totalTokens; // The amount of tokens that can be sold at once
    uint256 private _transactionBuyLimit = _totalTokens; // The amount of tokens that can be bought at once
    bool private _isBuyingAllowed; // This is used to make sure that the contract is activated before anyone makes a purchase on PCS.  The contract will be activated once liquidity is added.

    // HOLD LIMIT
    uint256 private _maxHoldAmount;

    // UNISWAP INTERFACEs
    address private _uniswapRouterAddress;
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    address private _autoLiquidityWallet;

    // EVENTS
    event Swapped(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity, uint256 ethIntoLiquidity);
    event AutoBurned(uint256 ethAmount);

    //Uniswap Router Address : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    constructor (address routerAddress) {
        _balances[_msgSender()] = totalSupply();
        
        // Exclude contract from fees
        _addressesExcludedFromFees[address(this)] = true;
        _addressesExcludedFromFees[_msgSender()] = true;

        _addressesExcludedFromHold[address(this)] = true;
        _addressesExcludedFromHold[_msgSender()] = true;

        // Initialize Uniswap V2 router and NOW <-> ETH pair.
        setUniswapRouter(routerAddress);

        _maxHoldAmount = 1200000 * 10**DECIMALS;

        // 2% liquidity fee, 2% reward fee, no marketing or dev fee
        setFees(2, 2);
        _highBuyFee = 99;

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    // This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
    function activate() public onlyOwner {
        setSwapEnabled(true);
        setFeeEnabled(true);
        setTokenHoldEnabled(true);
        setAutoLiquidityWallet(owner());
        setTransactionSellLimit(400000 * 10**DECIMALS);
        setTransactionBuyLimit(600000 * 10**DECIMALS);
        activateBuying(true);
        onActivated();
    }    

    function onActivated() internal virtual { }

    function setUniswapRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0), "Cannot use the zero address as router address");

        _uniswapRouterAddress = routerAddress;
        _uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        onUniSwapRouterUpdated();        
    }

    function onUniSwapRouterUpdated() internal virtual { }

    // This function can also be used in case the fees of the contract need to be adjusted later on as the volume grows
    function setFees(uint8 liquidityFee, uint8 rewardFee) public onlyOwner {
        require(liquidityFee >= 0 && liquidityFee <= 5, "Liquidity fee must be between 0% and 5%");
        require(rewardFee >= 0 && rewardFee <= 5, "Reward fee must be between 1% and 5%");
        
        _liquidityFee = liquidityFee;
        _rewardFee = rewardFee;
        
        // Enforce invariant
        _poolFee = _rewardFee + _liquidityFee;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        doTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        doTransfer(sender, recipient, amount);
        doApprove(sender, _msgSender(), _allowances[sender][_msgSender()] - amount); // Will fail when there is not enough allowance
        return true;
    } 

    function approve(address spender, uint256 amount) public override returns (bool) {
        doApprove(_msgSender(), spender, amount);
        return true;
    }

    function doTransfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Transfer from the zero address is not allowed");
        require(recipient != address(0), "Transfer to the zero address is not allowed");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isUniSwapPair(sender) || _isBuyingAllowed, "Buying is not allowed before contract activation");

        if (_isSwapEnabled) {
            // Ensure that amount is within the limit in case we are selling
            if (isSellTransferLimited(sender, recipient)) {
                require(amount <= _transactionSellLimit, "Sell amount exceeds the maximum allowed");
            }

            // Ensure that amount is within the limit in case we are buying
            if (isUniSwapPair(sender)) {
                require(amount <= _transactionBuyLimit, "Buy amount exceeds the maximum allowed");
            }
        }

        // Perform a swap if needed.  A swap in the context of this contract is the process of swapping the contract's token balance with ETH in order to provide liquidity and increase the reward pool
        executeSwapIfNeeded(sender, recipient);

        onBeforeTransfer(sender, recipient, amount);

        // Calculate fee rate
        uint256 feeRate = calculateFeeRate(sender, recipient);
        
        uint256 feeAmount = amount * feeRate / 100;
        uint256 transferAmount = amount - feeAmount;

        bool applyTokenHold = _isTokenHoldEnabled && !isUniSwapPair(recipient) && !_addressesExcludedFromHold[recipient];

        if (applyTokenHold) {
            require(_balances[recipient] + transferAmount < _maxHoldAmount, "Cannot hold more than Maximum hold amount");
        }

        // Update balances
        updateBalances(sender, recipient, amount, feeAmount);

        // Update total fees, this is just a counter provided for visibility
        _totalFeesPooled += feeAmount;

        emit Transfer(sender, recipient, transferAmount); 

        onTransfer(sender, recipient, amount);
    }

    function onBeforeTransfer(address sender, address recipient, uint256 amount) internal virtual { }

    function onTransfer(address sender, address recipient, uint256 amount) internal virtual { }

    function updateBalances(address sender, address recipient, uint256 sentAmount, uint256 feeAmount) private {
        // Calculate amount to be received by recipient
        uint256 receivedAmount = sentAmount - feeAmount;

        // Update balances
        _balances[sender] -= sentAmount;
        _balances[recipient] += receivedAmount;
        
        // Add fees to contract
        _balances[address(this)] += feeAmount;
    }

    function doApprove(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");

        _allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }

    function calculateFeeRate(address sender, address recipient) private view returns(uint256) {
        bool applyFees = _isFeeEnabled && !_addressesExcludedFromFees[sender] && !_addressesExcludedFromFees[recipient];
        if (applyFees) {
            bool antiBotFalg = onBeforeCalculateFeeRate();
            if (isUniSwapPair(sender) && antiBotFalg) {
                return _highBuyFee;
            }
            
            if (isUniSwapPair(recipient) || isUniSwapPair(sender)) {
                return _poolFee;
            }
        }

        return 0;
    }
    
    function onBeforeCalculateFeeRate() internal virtual view returns(bool) {
        return false;
    }
        
    function executeSwapIfNeeded(address sender, address recipient) private {
        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Check if it's time to swap for liquidity & reward pool
        uint256 tokensAvailableForSwap = balanceOf(address(this));
        if (tokensAvailableForSwap >= _tokenSwapThreshold) {

            // Limit to threshold
            tokensAvailableForSwap = _tokenSwapThreshold;

            // Make sure that we are not stuck in a loop (Swap only once)
            bool isSelling = isUniSwapPair(recipient);
            if (isSelling) {
                executeSwap(tokensAvailableForSwap);
            }
        }
    }

    function executeSwap(uint256 amount) private {
        // Allow uniswap to spend the tokens of the address
        doApprove(address(this), _uniswapRouterAddress, amount);

        uint256 tokensReservedForLiquidity = amount * _liquidityFee / _poolFee;
        uint256 tokensReservedForReward = amount - tokensReservedForLiquidity;

        // For the liquidity portion, half of it will be swapped for ETH and the other half will be used to add the ETH into the liquidity
        uint256 tokensToSwapForLiquidity = tokensReservedForLiquidity / 2;
        uint256 tokensToAddAsLiquidity = tokensToSwapForLiquidity;

        uint256 tokensToSwap = tokensReservedForReward + tokensToSwapForLiquidity;
        uint256 ethSwapped = swapTokensForETH(tokensToSwap);
        
        // Calculate what portion of the swapped eth is for liquidity and supply it using the other half of the token liquidity portion.  The remaining eths in the contract represent the reward pool
        uint256 ethToBeAddedToLiquidity = ethSwapped * tokensToSwapForLiquidity / tokensToSwap;
        (,uint ethAddedToLiquidity,) = _uniswapV2Router.addLiquidityETH{value: ethToBeAddedToLiquidity}(address(this), tokensToAddAsLiquidity, 0, 0, _autoLiquidityWallet, block.timestamp + 360);

        // Keep track of how many ETH were added to liquidity this way
        _totalETHLiquidityAddedFromFees += ethAddedToLiquidity;
        
        emit Swapped(tokensToSwap, ethSwapped, tokensToAddAsLiquidity, ethToBeAddedToLiquidity);
    }    

    function swapTokensForETH(uint256 tokenAmount) internal returns(uint256) {
        uint256 initialBalance = address(this).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        // Swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 360);
        
        // Return the amount received
        return address(this).balance - initialBalance;
    }

    function swapETHForTokens(uint256 ethAmount, address to) internal returns(bool) { 
        // Generate pair for ETH -> NOW
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(this);


        // Swap and send the tokens to the 'to' address
        try _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethAmount }(0, path, to, block.timestamp + 360) { 
            return true;
        } 
        catch { 
            return false;
        }        
    }

    // Returns true if the transfer between the two given addresses should be limited by the transaction limit and false otherwise
    function isSellTransferLimited(address sender, address recipient) private view returns(bool) {
        bool isSelling = isUniSwapPair(recipient);
        return isSelling && isMarketTransfer(sender, recipient);
    }

    function isSwapTransfer(address sender, address recipient) private view returns(bool) {
        bool isContractSelling = sender == address(this) && isUniSwapPair(recipient);
        return isContractSelling;
    }

    // Function that is used to determine whether a transfer occurred due to a user buying/selling/transfering and not due to the contract swapping tokens
    function isMarketTransfer(address sender, address recipient) internal virtual view returns(bool) {
        return !isSwapTransfer(sender, recipient);
    }

    // Returns how many more $NOW tokens are needed in the contract before triggering a swap
    function amountUntilSwap() public view returns (uint256) {
        uint256 balance = balanceOf(address(this));
        if (balance > _tokenSwapThreshold) {
            // Swap on next relevant transaction
            return 0;
        }

        return _tokenSwapThreshold - balance;
    }    

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }    

    function isUniSwapPair(address addr) internal view returns(bool) {
        return _uniswapV2Pair == addr;
    }

    /// - Set Params Functions - ///

    function name() public override pure returns (string memory) {
        return NAME;
    }

    function symbol() public override pure returns (string memory) {
        return SYMBOL;
    }

    function totalSupply() public override pure returns (uint256) {
        return _totalTokens;
    }

    function decimals() public override pure returns (uint8) {
        return DECIMALS;
    }

    function allowance(address user, address spender) public view override returns (uint256) {
        return _allowances[user][spender];
    }    

    function uniSwapRouterAddress() public view returns (address) {
        return _uniswapRouterAddress;
    }

    function uniSwapPairAddress() public view returns (address) {
        return _uniswapV2Pair;
    }

    function totalFeesPooled() public view returns (uint256) {
        return _totalFeesPooled;
    }
    
    function totalETHLiquidityAddedFromFees() public view returns (uint256) {
        return _totalETHLiquidityAddedFromFees;
    }

    function isSwapEnabled() public view returns (bool) {
        return _isSwapEnabled;
    }

    function setSwapEnabled(bool isEnabled) public onlyOwner {
        _isSwapEnabled = isEnabled;
    }

    function isFeeEnabled() public view returns (bool) {
        return _isFeeEnabled;
    }

    function setFeeEnabled(bool isEnabled) public onlyOwner {
        _isFeeEnabled = isEnabled;
    }

    function isTokenHoldEnabled() public view returns (bool) {
        return _isTokenHoldEnabled;
    }

    function setTokenHoldEnabled(bool isEnabled) public onlyOwner {
        _isTokenHoldEnabled = isEnabled;
    }

    function isExcludedFromFees(address addr) public view returns(bool) {
        return _addressesExcludedFromFees[addr];
    }

    function setExcludedFromFees(address addr, bool value) public onlyOwner {
        _addressesExcludedFromFees[addr] = value;
    }

    function isExcludedFromHold(address addr) public view returns(bool) {
        return _addressesExcludedFromHold[addr];
    }

    function setExcludedFromHold(address addr, bool value) public onlyOwner {
        _addressesExcludedFromHold[addr] = value;
    }

    function activateBuying(bool isEnabled) public onlyOwner {
        _isBuyingAllowed = isEnabled;
    }

    // for limit params
    function setTransactionSellLimit(uint256 limit) public onlyOwner {
        _transactionSellLimit = limit;
    }

    function transactionSellLimit() public view returns (uint256) {
        return _transactionSellLimit;
    }

    function setTransactionBuyLimit(uint256 limit) public onlyOwner {
        _transactionBuyLimit = limit;
    }
        
    function transactionBuyLimit() public view returns (uint256) {
        return _transactionBuyLimit;
    }
    
    function setHoldLimit(uint256 limit) public onlyOwner {
        _maxHoldAmount = limit;
    }

    function holdLimit() public view returns (uint256) {
        return _maxHoldAmount;
    }

    function setTokenSwapThreshold(uint256 threshold) public onlyOwner {
        require(threshold > 0, "Threshold must be greater than 0");
        _tokenSwapThreshold = threshold;
    }

    function tokenSwapThreshold() public view returns (uint256) {
        return _tokenSwapThreshold;
    }

    function autoLiquidityWallet() public view returns (address) {
        return _autoLiquidityWallet;
    }

    function setAutoLiquidityWallet(address liquidityWallet) public onlyOwner {
        _autoLiquidityWallet = liquidityWallet;
    }

    // Ensures that the contract is able to receive ETH
    receive() external payable {}
}

// Implements rewards & burns
contract NOW is NOWBase {
    //REWARD CYCLE
    uint256 private _rewardCyclePeriod = 86400; // The duration of the reward cycle (e.g. can claim rewards once 24 hours)
    uint256 private _rewardCycleExtensionThreshold; // If someone sends or receives more than a % of their balance in a transaction, their reward cycle date will increase accordingly
    mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address

    uint256 private _totalETHLiquidityAddedFromFees; // The total number of ETH added to the pool through fees
    uint256 private _totalETHClaimed; // The total number of ETH claimed by all addresses
    uint256 private _totalETHAsNOWClaimed; // The total number of ETH that was converted to $NOW and claimed by all addresses
    mapping(address => uint256) private _ethRewardClaimed; // The amount of ETH claimed by each address
    mapping(address => uint256) private _ethAsNOWClaimed; // The amount of ETH converted to $NOW and claimed by each address
    
    mapping(address => bool) private _addressesExcludedFromRewards; // The list of addresses excluded from rewards
    mapping(address => mapping(address => bool)) private _rewardClaimApprovals; //Used to allow an address to claim rewards on behalf of someone else
    mapping(address => uint256) private _claimRewardAsTokensPercentage; //Allows users to optionally use a % of the reward pool to buy $NOW automatically
    uint256 private _globalRewardDampeningPercentage = 3; // Rewards are reduced by 3% at the start to fill the main ETH pool faster and ensure consistency in rewards
    uint256 private _mainETHPoolSize = 1000 ether; // Any excess ETH after the main pool will be used as reserves to ensure consistency in rewards
    uint256 private _maxClaimAllowed = 20 ether; // Can only claim up to 20 ETH at a time.
    bool private _rewardAsTokensEnabled; //If enabled, the contract will give out tokens instead of ETH according to the preference of each user
    uint256 private _minRewardBalance; // The minimum balance required to be eligible for rewards
    //Burn
    uint256 private _lastBurnDate; //The last burn date
    uint256 private _gradualBurnTimespan = 1 days; //Burn every 1 day by default
    uint256 private _gradualBurnMagnitude; // The contract can optionally burn tokens (By buying them from reward pool).  This is the magnitude of the burn (1 = 0.01%).

    // AUTO-CLAIM
    bool private _autoClaimEnabled;
    bool private _reimburseAfterNOWClaimFailure; // If true, and NOW reward claim portion fails, the portion will be given as ETH instead
    uint256 private _maxGasForAutoClaim = 600000; // The maximum gas to consume for processing the auto-claim queue
    address[] _rewardClaimQueue;
    mapping(address => uint) _rewardClaimQueueIndices;
    uint256 private _rewardClaimQueueIndex;
    bool private _processingQueue; //Flag that indicates whether the queue is currently being processed and sending out rewards
    bool private _excludeNonHumansFromRewards = true;
    uint256 private _sendWeiGasLimit;
    mapping(address => bool) _addressesInRewardClaimQueue; // Mapping between addresses and false/true depending on whether they are queued up for auto-claim or not
    mapping(address => bool) private _whitelistedExternalProcessors; //Contains a list of addresses that are whitelisted for low-gas queue processing 


    //anti-bot
    uint256 public antiBlockNum = 3;
    bool public antiEnabled;
    uint256 private antiBotTimestamp;

    event RewardClaimed(address recipient, uint256 amountETH, uint256 amountTokens, uint256 nextAvailableClaimDate); 
    event Burned(uint256 ethAmount);

    constructor (address routerAddress) NOWBase(routerAddress) {
        // Exclude addresses from rewards
        _addressesExcludedFromRewards[BURN_WALLET] = true;
        _addressesExcludedFromRewards[owner()] = true;
        _addressesExcludedFromRewards[address(this)] = true;
        _addressesExcludedFromRewards[address(0)] = true;

        // If someone sends or receives more than 15% of their balance in a transaction, their reward cycle date will increase accordingly
        setRewardCycleExtensionThreshold(15);
    }

    // This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
    function onActivated() internal override {
        super.onActivated();

        setRewardAsTokensEnabled(true);
        setAutoClaimEnabled(true);
        setReimburseAfterNOWClaimFailure(true);
        setMinRewardBalance(50000 * 10**decimals());  //At least 50000 tokens are required to be eligible for rewards        
        setGradualBurnMagnitude(1); //Buy tokens using 0.01% of reward pool and burn them
        _lastBurnDate = block.timestamp;
        updateAntiBotStatus(true);
    }

    function onBeforeTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onBeforeTransfer(sender, recipient, amount);

        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Extend the reward cycle according to the amount transferred.  This is done so that users do not abuse the cycle (buy before it ends & sell after they claim the reward)
        _nextAvailableClaimDate[recipient] += calculateRewardCycleExtension(balanceOf(recipient), amount);
        _nextAvailableClaimDate[sender] += calculateRewardCycleExtension(balanceOf(sender), amount);

        bool isSelling = isUniSwapPair(recipient);
        if (!isSelling) {
            // Wait for a dip, stellar diamond hands
            return;
        }        
        
        // Process gradual burns
        bool burnTriggered = processGradualBurn();
        
        // Do not burn & process queue in the same transaction
        if (!burnTriggered && isAutoClaimEnabled()) {
            // Trigger auto-claim
            try this.processRewardClaimQueue(_maxGasForAutoClaim) { } catch { }
        }
    }

    function onTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onTransfer(sender, recipient, amount);

        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Update auto-claim queue after balances have been updated
        updateAutoClaimQueue(sender);
        updateAutoClaimQueue(recipient);
    }

    function processGradualBurn() private returns(bool) {
        if (!shouldBurn()) {
            return false;
        }

        uint256 burnAmount = address(this).balance * _gradualBurnMagnitude / 10000;
        doBuyAndBurn(burnAmount);
        return true;
    }

    // Auto-claim
    function updateAutoClaimQueue(address user) private {
        bool isQueued = _addressesInRewardClaimQueue[user];

        if (!isIncludedInRewards(user)) {
            if (isQueued) {
                // Need to dequeue
                uint index = _rewardClaimQueueIndices[user];
                address lastUser = _rewardClaimQueue[_rewardClaimQueue.length - 1];

                // Move the last one to this index, and pop it
                _rewardClaimQueueIndices[lastUser] = index;
                _rewardClaimQueue[index] = lastUser;
                _rewardClaimQueue.pop();

                // Clean-up
                delete _rewardClaimQueueIndices[user];
                delete _addressesInRewardClaimQueue[user];
            }
        } else {
            if (!isQueued) {
                // Need to enqueue
                _rewardClaimQueue.push(user);
                _rewardClaimQueueIndices[user] = _rewardClaimQueue.length - 1;
                _addressesInRewardClaimQueue[user] = true;
            }
        }
    }    


    function claimReward() isHuman nonReentrant external {
        claimReward(msg.sender);
    }

    function claimReward(address user) public {
        require(msg.sender == user, "You are not allowed to claim rewards on behalf of this user");
        require(isRewardReady(user), "Claim date for this address has not passed yet");
		require(isIncludedInRewards(user), "Address is excluded from rewards, make sure there is enough NOW balance");

        bool success = doClaimReward(user);
        require(success, "Reward claim failed");        
    }

    function doClaimReward(address user) private returns (bool) {
        // Update the next claim date & the total amount claimed
        _nextAvailableClaimDate[user] = block.timestamp + rewardCyclePeriod();

        (uint256 claimETH, uint256 claimETHAsTokens, uint256 taxFee) = calculateClaimRewards(user);
        
        claimETH = claimETH - claimETH * taxFee / 100;
        claimETHAsTokens = claimETHAsTokens - claimETHAsTokens * taxFee / 100;
        
        bool tokenClaimSuccess = true;
        // Claim NOW tokens
        if (!claimNOW(user, claimETHAsTokens)) {
            if (_reimburseAfterNOWClaimFailure) {
                claimETH += claimETHAsTokens;
            } else {
                tokenClaimSuccess = false;
            }

            claimETHAsTokens = 0;
        }

        // Claim ETH
        bool ethClaimSuccess = claimEth(user, claimETH);

        // Fire the event in case something was claimed
        if (tokenClaimSuccess || ethClaimSuccess) {
            emit RewardClaimed(user, claimETH, claimETHAsTokens, _nextAvailableClaimDate[user]);
        }
        
        return ethClaimSuccess && tokenClaimSuccess;
    }

    function claimEth(address user, uint256 ethAmount) private returns (bool) {
        if (ethAmount == 0) {
            return true;
        }

        // Send the reward to the caller
        if (_sendWeiGasLimit > 0) {
            (bool sent,) = user.call{value : ethAmount, gas: _sendWeiGasLimit}("");
            if (!sent) {
                return false;
            }
        } else {
            (bool sent,) = user.call{value : ethAmount}("");
            if (!sent) {
                return false;
            }
        }
    
        _ethRewardClaimed[user] += ethAmount;
        _totalETHClaimed += ethAmount;
        return true;
    }

    function claimNOW(address user, uint256 ethAmount) private returns (bool) {
        if (ethAmount == 0) {
            return true;
        }

        bool success = swapETHForTokens(ethAmount, user);
        if (!success) {
            return false;
        }

        _ethAsNOWClaimed[user] += ethAmount;
        _totalETHAsNOWClaimed += ethAmount;
        return true;
    }
    
    // Processes users in the claim queue and sends out rewards when applicable. The amount of users processed depends on the gas provided, up to 1 cycle through the whole queue. 
    // Note: Any external processor can process the claim queue (e.g. even if auto claim is disabled from the contract, an external contract/user/service can process the queue for it 
    // and pay the gas cost). "gas" parameter is the maximum amount of gas allowed to be consumed
    function processRewardClaimQueue(uint256 gas) public {
        require(gas > 0, "Gas limit is required");

        uint256 queueLength = _rewardClaimQueue.length;

        if (queueLength == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iteration = 0;
        _processingQueue = true;

        // Keep claiming rewards from the list until we either consume all available gas or we finish one cycle
        while (gasUsed < gas && iteration < queueLength) {
            if (_rewardClaimQueueIndex >= queueLength) {
                _rewardClaimQueueIndex = 0;
            }

            address user = _rewardClaimQueue[_rewardClaimQueueIndex];
            if (isRewardReady(user) && isIncludedInRewards(user)) {
                // Do claim
                doClaimReward(user);
            }

            uint256 newGasLeft = gasleft();
            
            if (gasLeft > newGasLeft) {
                uint256 consumedGas = gasLeft - newGasLeft;
                gasUsed += consumedGas;
                gasLeft = newGasLeft;
            }

            iteration++;
            _rewardClaimQueueIndex++;
        }

        _processingQueue = false;
    }

    // Allows a whitelisted external contract/user/service to process the queue and have a portion of the gas costs refunded.
    // This can be used to help with transaction fees and payout response time when/if the queue grows too big for the contract.
    // "gas" parameter is the maximum amount of gas allowed to be used.
    function processRewardClaimQueueAndRefundGas(uint256 gas) external {
        require(_whitelistedExternalProcessors[msg.sender], "Not whitelisted - use processRewardClaimQueue instead");

        uint256 startGas = gasleft();
        processRewardClaimQueue(gas);
        uint256 gasUsed = startGas - gasleft();

        payable(msg.sender).transfer(gasUsed);
    }

    function isRewardReady(address user) public view returns(bool) {
        return _nextAvailableClaimDate[user] <= block.timestamp;
    }

    function isIncludedInRewards(address user) public view returns(bool) {
        if (_excludeNonHumansFromRewards) {
            if (isContract(user)) {
                return false;
            }
        }

        return balanceOf(user) >= _minRewardBalance && !_addressesExcludedFromRewards[user];
    }

    function calculateClaimRewards(address ofAddress) public view returns (uint256, uint256, uint256) {
        uint256 reward = calculateETHReward(ofAddress);
        uint256 taxFee = 0;
        if (reward >= 35 * 10**16) {
            taxFee = 20;
        } else if(reward >= 20 * 10**16) {
            taxFee = 10;
        }
        uint256 claimETHAsTokens = 0;
        if (_rewardAsTokensEnabled) {
            uint256 percentage = _claimRewardAsTokensPercentage[ofAddress];
            claimETHAsTokens = reward * percentage / 100;
        } 

        uint256 claimETH = reward - claimETHAsTokens;

        return (claimETH, claimETHAsTokens, taxFee);
    }

    // This function calculates how much (and if) the reward cycle of an address should increase based on its current balance and the amount transferred in a transaction
    function calculateRewardCycleExtension(uint256 balance, uint256 amount) public view returns (uint256) {
        uint256 basePeriod = rewardCyclePeriod();

        if (balance == 0) {
            // Receiving $NOW on a zero balance address:
            // This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
            // Or the address has transferred all of its tokens in the past and has now received some again, in which case we will set the reward date to a date very far in the future
            return block.timestamp + basePeriod;
        }

        uint256 rate = amount * 100 / balance;

        // Depending on the % of $NOW tokens transferred, relative to the balance, we might need to extend the period
        if (rate >= _rewardCycleExtensionThreshold) {

            // If new balance is X percent higher, then we will extend the reward date by X percent
            uint256 extension = basePeriod * rate / 100;

            // Cap to the base period
            if (extension >= basePeriod) {
                extension = basePeriod;
            }

            return extension;
        }

        return 0;
    }

    function calculateETHReward(address ofAddress) public view returns (uint256) {
        uint256 holdersAmount = totalAmountOfTokensHeld();

        uint256 balance = balanceOf(ofAddress);
        uint256 ethPool =  address(this).balance * (100 - _globalRewardDampeningPercentage) / 100;

        // Limit to main pool size.  The rest of the pool is used as a reserve to improve consistency
        if (ethPool > _mainETHPoolSize) {
            ethPool = _mainETHPoolSize;
        }

        // If an address is holding X percent of the supply, then it can claim up to X percent of the reward pool
        uint256 reward = ethPool * balance / holdersAmount;

        if (reward > _maxClaimAllowed) {
            reward = _maxClaimAllowed;
        }

        return reward;
    }

    function onUniSwapRouterUpdated() internal override { 
        _addressesExcludedFromRewards[uniSwapRouterAddress()] = true;
        _addressesExcludedFromRewards[uniSwapPairAddress()] = true;
    }

    function isMarketTransfer(address sender, address recipient) internal override view returns(bool) {
        // Not a market transfer when we are burning or sending out rewards
        return super.isMarketTransfer(sender, recipient) && !isBurnTransfer(sender, recipient) && !_processingQueue;
    }

    // Burn function
    function isBurnTransfer(address sender, address recipient) private view returns (bool) {
        return isUniSwapPair(sender) && recipient == BURN_WALLET;
    }

    function shouldBurn() public view returns(bool) {
        return _gradualBurnMagnitude > 0 && block.timestamp - _lastBurnDate > _gradualBurnTimespan;
    }

    // Up to 1% manual buyback & burn
    function buyAndBurn(uint256 ethAmount) external onlyOwner {
        require(ethAmount <= address(this).balance / 100, "Manual burn amount is too high!");
        require(ethAmount > 0, "Amount must be greater than zero");

        doBuyAndBurn(ethAmount);
    }

    function doBuyAndBurn(uint256 ethAmount) private {
        if (ethAmount > address(this).balance) {
            ethAmount = address(this).balance;
        }

        if (ethAmount == 0) {
            return;
        }

        if (swapETHForTokens(ethAmount, BURN_WALLET)) {
            emit Burned(ethAmount);
        }

        _lastBurnDate = block.timestamp;
    }

    function isContract(address account) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function totalAmountOfTokensHeld() public view returns (uint256) {
        return totalSupply() - balanceOf(address(0)) - balanceOf(BURN_WALLET) - balanceOf(uniSwapPairAddress());
    }

    function ethRewardClaimed(address byAddress) public view returns (uint256) {
        return _ethRewardClaimed[byAddress];
    }

    function ethRewardClaimedAsNOW(address byAddress) public view returns (uint256) {
        return _ethAsNOWClaimed[byAddress];
    }

    function totalETHClaimed() public view returns (uint256) {
        return _totalETHClaimed;
    }

    function totalETHClaimedAsNOW() public view returns (uint256) {
        return _totalETHAsNOWClaimed;
    }

    function rewardCyclePeriod() public view returns (uint256) {
        return _rewardCyclePeriod;
    }

    function setRewardCyclePeriod(uint256 period) public onlyOwner {
        require(period >= 3600 && period <= 86400, "RewardCycle must be updated to between 1 and 24 hours");
        _rewardCyclePeriod = period;
    }

    function setRewardCycleExtensionThreshold(uint256 threshold) public onlyOwner {
        _rewardCycleExtensionThreshold = threshold;
    }

    function nextAvailableClaimDate(address ofAddress) public view returns (uint256) {
        return _nextAvailableClaimDate[ofAddress];
    }

    function maxClaimAllowed() public view returns (uint256) {
        return _maxClaimAllowed;
    }

    function setMaxClaimAllowed(uint256 value) public onlyOwner {
        require(value > 0, "Value must be greater than zero");
        _maxClaimAllowed = value;
    }  

    function minRewardBalance() public view returns (uint256) {
        return _minRewardBalance;
    }

    function setMinRewardBalance(uint256 balance) public onlyOwner {
        _minRewardBalance = balance;
    }

    function maxGasForAutoClaim() public view returns (uint256) {
        return _maxGasForAutoClaim;
    }

    function setMaxGasForAutoClaim(uint256 gas) public onlyOwner {
        _maxGasForAutoClaim = gas;
    }

    function isAutoClaimEnabled() public view returns (bool) {
        return _autoClaimEnabled;
    }

    function setAutoClaimEnabled(bool isEnabled) public onlyOwner {
        _autoClaimEnabled = isEnabled;
    }

    function isExcludedFromRewards(address addr) public view returns (bool) {
        return _addressesExcludedFromRewards[addr];
    }

    // Will be used to exclude unicrypt fees/token vesting addresses from rewards
    function setExcludedFromRewards(address addr, bool isExcluded) public onlyOwner {
        _addressesExcludedFromRewards[addr] = isExcluded;
        // auto claim
    }

    function approveClaim(address byAddress, bool isApproved) public {
        require(byAddress != address(0), "Invalid address");
        _rewardClaimApprovals[msg.sender][byAddress] = isApproved;
    }

    function isClaimApproved(address ofAddress, address byAddress) public view returns(bool) {
        return _rewardClaimApprovals[ofAddress][byAddress];
    }

    function claimRewardAsTokensPercentage(address ofAddress) public view returns(uint256) {
        return _claimRewardAsTokensPercentage[ofAddress];
    }

    function setClaimRewardAsTokensPercentage(uint256 percentage) public {
        require(percentage <= 100, "Cannot exceed 100%");
        _claimRewardAsTokensPercentage[msg.sender] = percentage;
    }

    function isInRewardClaimQueue(address addr) public view returns(bool) {
        return _addressesInRewardClaimQueue[addr];
    }

    function reimburseAfterNOWClaimFailure() public view returns(bool) {
        return _reimburseAfterNOWClaimFailure;
    }

    function setReimburseAfterNOWClaimFailure(bool value) public onlyOwner {
        _reimburseAfterNOWClaimFailure = value;
    }   

    function lastBurnDate() public view returns(uint256) {
        return _lastBurnDate;
    }

    function isWhitelistedExternalProcessor(address addr) public view returns(bool) {
        return _whitelistedExternalProcessors[addr];
    }

    function setWhitelistedExternalProcessor(address addr, bool isWhitelisted) public onlyOwner {
         require(addr != address(0), "Invalid address");
        _whitelistedExternalProcessors[addr] = isWhitelisted;
    }

    
    function setSendWeiGasLimit(uint256 amount) public onlyOwner {
        _sendWeiGasLimit = amount;
    }

    function setExcludeNonHumansFromRewards(bool exclude) public onlyOwner {
        _excludeNonHumansFromRewards = exclude;
    }

    // Anti-bot
    function setAntiBotEnabled(bool _isEnabled) public onlyOwner {
        updateAntiBotStatus(_isEnabled);
    }

    function updateAntiBotStatus(bool _flag) private {
        antiEnabled = _flag;
        antiBotTimestamp = block.timestamp + antiBlockNum;
    }

    function updateBlockNum(uint256 _blockNum) public onlyOwner {
        antiBlockNum = _blockNum;
    }

    function onBeforeCalculateFeeRate() internal override view returns (bool) {
        if (antiEnabled && block.timestamp < antiBotTimestamp) {
            return true;
        }
        return super.onBeforeCalculateFeeRate();
    }

    function isRewardAsTokensEnabled() public view returns(bool) {
        return _rewardAsTokensEnabled;
    }

    function setRewardAsTokensEnabled(bool isEnabled) public onlyOwner {
        _rewardAsTokensEnabled = isEnabled;
    }
    
    function gradualBurnMagnitude() public view returns (uint256) {
        return _gradualBurnMagnitude;
    }

    function setGradualBurnMagnitude(uint256 magnitude) public onlyOwner {
        require(magnitude <= 100, "Must be equal or less to 100");
        _gradualBurnMagnitude = magnitude;
    }

    function gradualBurnTimespan() public view returns (uint256) {
        return _gradualBurnTimespan;
    }

    function setGradualBurnTimespan(uint256 timespan) public onlyOwner {
        require(timespan >= 5 minutes, "Cannot be less than 5 minutes");
        _gradualBurnTimespan = timespan;
    }

    function rewardClaimQueueLength() public view returns(uint256) {
        return _rewardClaimQueue.length;
    }

    function rewardClaimQueueIndex() public view returns(uint256) {
        return _rewardClaimQueueIndex;
    }

    function globalRewardDampeningPercentage() public view returns(uint256) {
        return _globalRewardDampeningPercentage;
    }

    function setGlobalRewardDampeningPercentage(uint256 value) public onlyOwner {
        require(value <= 90, "Cannot be greater than 90%");
        _globalRewardDampeningPercentage = value;
    }    

    function mainETHPoolSize() public view returns (uint256) {
        return _mainETHPoolSize;
    }

    function setMainETHPoolSize(uint256 size) public onlyOwner {
        require(size >= 3 ether, "Size is too small");
        _mainETHPoolSize = size;
    }      
}