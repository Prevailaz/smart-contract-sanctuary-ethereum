/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CErc20 {
  function balanceOf(address) external view returns (uint);

  function mint(uint) external returns (uint);

  function exchangeRateCurrent() external returns (uint);

  function supplyRatePerBlock() external returns (uint);

  function balanceOfUnderlying(address) external returns (uint);

  function redeem(uint) external returns (uint);

  function redeemUnderlying(uint) external returns (uint);

  function borrow(uint) external returns (uint);

  function borrowBalanceCurrent(address) external returns (uint);

  function borrowRatePerBlock() external view returns (uint);

  function repayBorrow(uint) external returns (uint);

  function liquidateBorrow(
    address borrower,
    uint amount,
    address collateral
  ) external returns (uint);
}

interface CEth {
  function balanceOf(address) external view returns (uint);

  function mint() external payable;

  function exchangeRateCurrent() external returns (uint);

  function supplyRatePerBlock() external returns (uint);

  function balanceOfUnderlying(address) external returns (uint);

  function redeem(uint) external returns (uint);

  function redeemUnderlying(uint) external returns (uint);

  function borrow(uint) external returns (uint);

  function borrowBalanceCurrent(address) external returns (uint);

  function borrowRatePerBlock() external view returns (uint);

  function repayBorrow() external payable;
}

interface Comptroller {
  function markets(address)
    external
    view
    returns (
      bool,
      uint,
      bool
    );

  function enterMarkets(address[] calldata) external returns (uint[] memory);

  function getAccountLiquidity(address)
    external
    view
    returns (
      uint,
      uint,
      uint
    );

  function closeFactorMantissa() external view returns (uint);

  function liquidationIncentiveMantissa() external view returns (uint);

  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint actualRepayAmount
  ) external view returns (uint, uint);
}

interface PriceFeed {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}



interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

  
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



pragma solidity ^0.8.0;



// supply
// borrow
// repay
// redeem

contract TestCompoundErc20 {
  IERC20 public token;
  CErc20 public cToken;

  event Log(string message, uint val);

  constructor(address _token, address _cToken) {
    token = IERC20(_token);
    cToken = CErc20(_cToken);
  }

  function supply(uint _amount) external {
    token.transferFrom(msg.sender, address(this), _amount);
    token.approve(address(cToken), _amount);
    require(cToken.mint(_amount) == 0, "mint failed");
  }

  function getCTokenBalance() external view returns (uint) {
    return cToken.balanceOf(address(this));
  }

  // not view function
  function getInfo() external returns (uint exchangeRate, uint supplyRate) {
    // Amount of current exchange rate from cToken to underlying
    exchangeRate = cToken.exchangeRateCurrent();
    // Amount added to you supply balance this block
    supplyRate = cToken.supplyRatePerBlock();
  }

  // not view function
  function estimateBalanceOfUnderlying() external returns (uint) {
    uint cTokenBal = cToken.balanceOf(address(this));
    uint exchangeRate = cToken.exchangeRateCurrent();
    uint decimals = 8; // WBTC = 8 decimals
    uint cTokenDecimals = 8;

    return (cTokenBal * exchangeRate) / 10**(18 + decimals - cTokenDecimals);
  }

  // not view function
  function balanceOfUnderlying() external returns (uint) {
    return cToken.balanceOfUnderlying(address(this));
  }

  function redeem(uint _cTokenAmount) external {
    require(cToken.redeem(_cTokenAmount) == 0, "redeem failed");
    // cToken.redeemUnderlying(underlying amount);
  }

  // borrow and repay //
  Comptroller public comptroller =
    Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

  PriceFeed public priceFeed = PriceFeed(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1);

  // collateral
  function getCollateralFactor() external view returns (uint) {
    (bool isListed, uint colFactor, bool isComped) = comptroller.markets(
      address(cToken)
    );
    return colFactor; // divide by 1e18 to get in %
  }

  // account liquidity - calculate how much can I borrow?
  // sum of (supplied balance of market entered * col factor) - borrowed
  function getAccountLiquidity()
    external
    view
    returns (uint liquidity, uint shortfall)
  {
    // liquidity and shortfall in USD scaled up by 1e18
    (uint error, uint _liquidity, uint _shortfall) = comptroller.getAccountLiquidity(
      address(this)
    );
    require(error == 0, "error");
   
    return (_liquidity, _shortfall);
  }

  // open price feed - USD price of token to borrow
  function getPriceFeed(address _cToken) external view returns (uint) {
    // scaled up by 1e18
    return priceFeed.getUnderlyingPrice(_cToken);
  }

  // enter market and borrow
  function borrow(address _cTokenToBorrow, uint _decimals) external {
    // enter market
    // enter the supply market so you can borrow another type of asset
    address[] memory cTokens = new address[](1);
    cTokens[0] = address(cToken);
    uint[] memory errors = comptroller.enterMarkets(cTokens);
    require(errors[0] == 0, "Comptroller.enterMarkets failed.");

    // check liquidity
    (uint error, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(
      address(this)
    );
    require(error == 0, "error");
    require(shortfall == 0, "shortfall > 0");
    require(liquidity > 0, "liquidity = 0");

    // calculate max borrow
    uint price = priceFeed.getUnderlyingPrice(_cTokenToBorrow);

    // liquidity - USD scaled up by 1e18
    // price - USD scaled up by 1e18
    // decimals - decimals of token to borrow
    uint maxBorrow = (liquidity * (10**_decimals)) / price;
    require(maxBorrow > 0, "max borrow = 0");

    // borrow 50% of max borrow
    uint amount = (maxBorrow * 50) / 100;
    require(CErc20(_cTokenToBorrow).borrow(amount) == 0, "borrow failed");
  }

  // borrowed balance (includes interest)
  // not view function
  function getBorrowedBalance(address _cTokenBorrowed) public returns (uint) {
    return CErc20(_cTokenBorrowed).borrowBalanceCurrent(address(this));
  }

  // borrow rate
  function getBorrowRatePerBlock(address _cTokenBorrowed) external view returns (uint) {
    // scaled up by 1e18
    return CErc20(_cTokenBorrowed).borrowRatePerBlock();
  }

  // repay borrow
  function repay(
    address _tokenBorrowed,
    address _cTokenBorrowed,
    uint _amount
  ) external {
    IERC20(_tokenBorrowed).approve(_cTokenBorrowed, _amount);
    // _amount = 2 ** 256 - 1 means repay all
    require(CErc20(_cTokenBorrowed).repayBorrow(_amount) == 0, "repay failed");
  }
}