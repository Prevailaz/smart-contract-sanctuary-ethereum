pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */

library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }


  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

}

interface ISwap {
    /**
     * @dev Pricing function for converting between TRX && Tokens.
   * @param input_amount Amount of TRX or Tokens being sold.
   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
   * @return Amount of TRX or Tokens bought.
   */
    function getInputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);

    /**
     * @dev Pricing function for converting between TRX && Tokens.
   * @param output_amount Amount of TRX or Tokens being bought.
   * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
   * @return Amount of TRX or Tokens sold.
   */
    function getOutputPrice(
        uint256 output_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
   * @dev User specifies exact input (msg.value) && minimum output.
   * @param min_tokens Minimum Tokens bought.
   * @return Amount of Tokens bought.
   */
    function trxToTokenSwapInput(uint256 min_tokens)
    external
    payable
    returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @return Amount of TRX sold.
   */
    function trxToTokenSwapOutput(uint256 tokens_bought)
    external
    payable
    returns (uint256);

    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx)
    external
    returns (uint256);

    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens)
    external
    returns (uint256);

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    function getTrxToTokenInputPrice(uint256 trx_sold)
    external
    view
    returns (uint256);

    function getTrxToTokenOutputPrice(uint256 tokens_bought)
    external
    view
    returns (uint256);

    function getTokenToTrxInputPrice(uint256 tokens_sold)
    external
    view
    returns (uint256);

    function getTokenToTrxOutputPrice(uint256 trx_bought)
    external
    view
    returns (uint256);

    /**
     * @return Address of Token that is sold on this exchange.
   */
    function tokenAddress() external view returns (address);

    function tronBalance() external view returns (uint256);

    function tokenBalance() external view returns (uint256);

    function getTrxToLiquidityInputPrice(uint256 trx_sold)
    external
    view
    returns (uint256);

    function getLiquidityToReserveInputPrice(uint256 amount)
    external
    view
    returns (uint256, uint256);

    function txs(address owner) external view returns (uint256);

    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens)
    external
    payable
    returns (uint256);

    
   
    function removeLiquidity(
        uint256 amount,
        uint256 min_trx,
        uint256 min_tokens
    ) external returns (uint256, uint256);
}

interface EarthToken {
    function remainingMintableSupply() external view returns (uint256);

    function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    
    function customTransferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function mintedSupply() external returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);


}

interface ITokenMint {

    function mint(address beneficiary, uint256 tokenAmount) external returns (uint256);

    function estimateMint(uint256 _amount) external returns (uint256);

    function remainingMintableSupply() external returns (uint256);
}

interface IEarthVault {

    function withdraw(uint256 tokenAmount) external;

}

contract Faucet is OwnableUpgradeable {

    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    struct User {
        //Referral Info
        address upline;
        uint256 referrals;
        uint256 total_structure;

        //Long-term Referral Accounting
        uint256 direct_bonus;
        uint256 match_bonus;

        //Deposit Accounting
        uint256 deposits;
        uint256 deposit_time;

        //Payout and Roll Accounting
        uint256 payouts;
        uint256 rolls;

        //Upline Round Robin tracking
        uint256 ref_claim_pos;

        uint256 accumulatedDiv;
    }

    struct Airdrop {
        //Airdrop tracking
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop;
    }

    struct Custody {
        address manager;
        address beneficiary;
        uint256 last_heartbeat;
        uint256 last_checkin;
        uint256 heartbeat_interval;
    }

    address public earthVaultAddress;

    EarthToken private earthToken;
    ITokenMint private tokenMint;
    EarthToken private storm;
    IEarthVault private earthVault;

    mapping(address => User) public users;
    mapping(address => Airdrop) public airdrops;
    mapping(address => Custody) public custody;

    uint256 public CompoundTax;
    uint256 public ExitTax;

    int128 private payoutRate;
    uint256 private ref_depth;
    uint256 private ref_bonus;

    uint256 private minimumInitial;
    uint256 private minimumAmount;

    uint256 public deposit_bracket_size;     // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
    uint256 public max_payout_cap;          // or 5% of supply
    uint256 private deposit_bracket_max;     // sustainability fee is (bracket * 5)

    uint256[] public ref_balances;

    uint256 public total_airdrops;
    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_bnb;
    uint256 public total_txs;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event Leaderboard(address indexed addr, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event BalanceTransfer(address indexed _src, address indexed _dest, uint256 _deposits, uint256 _payouts);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event ManagerUpdate(address indexed addr, address indexed manager, uint256 timestamp);
    event BeneficiaryUpdate(address indexed addr, address indexed beneficiary);
    event HeartBeatIntervalUpdate(address indexed addr, uint256 interval);
    event HeartBeat(address indexed addr, uint256 timestamp);
    event Checkin(address indexed addr, uint256 timestamp);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    earthVaultAddress = 0xDb95B36AcDC120C5FC2A92Deff590f2C4B858a6e;
    earthToken = EarthToken(0x4A3e4E0677E8Ba157366Bef38c64Ef49e8F7Fe46);
    tokenMint = ITokenMint(0x4A3e4E0677E8Ba157366Bef38c64Ef49e8F7Fe46);
    storm = EarthToken(0x069571F5894D980C4dB3D03Ad59b711cbf156f61);
    earthVault = IEarthVault(earthVaultAddress);
    CompoundTax = 5;
    ExitTax = 17;
    ref_depth=15;
    ref_bonus = 10;
    minimumInitial = 1000e18;
    minimumAmount = 1000e18;

    deposit_bracket_size = 9600000e18;     // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
    max_payout_cap = 35000000e18;          // or 5% of supply
    deposit_bracket_max = 9600000e18; 
    ref_balances = [30,50,90,100,200,300,500,900,1000,1500,2000,3000,6000,10000,15000];
    payoutRate = ABDKMath64x64.divu(50,100);
    }

    //@dev Default payable is empty since Faucet executes trades and recieves BNB
    fallback() external payable {
        //Do nothing, BNB will be sent to contract when selling tokens
    }

    /****** Administrative Functions *******/
    function updatePayoutRate(uint256 _newPayoutRate) public onlyOwner {
        payoutRate = ABDKMath64x64.divu(_newPayoutRate,100);
    }

    function updateRefDepth(uint256 _newRefDepth) public onlyOwner {
        ref_depth = _newRefDepth;
    }

    function updateRefBonus(uint256 _newRefBonus) public onlyOwner {
        ref_bonus = _newRefBonus;
    }

    function updateInitialDeposit(uint256 _newInitialDeposit) public onlyOwner {
        minimumInitial = _newInitialDeposit;
    }

    function updateCompoundTax(uint256 _newCompoundTax) public onlyOwner {
        require(_newCompoundTax >= 0 && _newCompoundTax <= 20);
        CompoundTax = _newCompoundTax;
    }

    function updateExitTax(uint256 _newExitTax) public onlyOwner {
        require(_newExitTax >= 0 && _newExitTax <= 20);
        ExitTax = _newExitTax;
    }

    function updateDepositBracketSize(uint256 _newBracketSize) public onlyOwner {
        deposit_bracket_size = _newBracketSize;
    }

    function updateMaxPayoutCap(uint256 _newPayoutCap) public onlyOwner {
        max_payout_cap = _newPayoutCap;
    }

    function updateHoldRequirements(uint256[] memory _newRefBalances) public onlyOwner {
        require(_newRefBalances.length == ref_depth);
        delete ref_balances;
        for(uint8 i = 0; i < ref_depth; i++) {
            ref_balances.push(_newRefBalances[i]);
        }
    }

    /********** User Fuctions **************************************************/
    function checkin() public {
        address _addr = msg.sender;
        custody[_addr].last_checkin = block.timestamp;
        emit Checkin(_addr, custody[_addr].last_checkin);
    }

    //@dev Deposit specified DRIP amount supplying an upline referral
    function deposit(address _upline, uint256 _amount) external {

        address _addr = msg.sender;
        uint8 _tax = 3;
        uint256 taxAmount = _amount.mul(_tax).div(100);
        uint256 realizedDeposit = _amount.mul(SafeMath.sub(100, _tax)).div(100);
        uint256 _total_amount = realizedDeposit;

        //Checkin for custody management.
        checkin();

        require(_amount >= minimumAmount, "Minimum deposit");

        //If fresh account require a minimal amount of DRIP
        if (users[_addr].deposits == 0){
            require(_amount >= minimumInitial, "Initial deposit too low");
        }

        _setUpline(_addr, _upline);

        uint256 taxedDivs;
        // Claim if divs are greater than 1% of the deposit
        if (claimsAvailable(_addr) > _amount/100){
            uint256 claimedDivs = _claim(_addr, true);
            taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
            _total_amount += taxedDivs;
            taxedDivs = taxedDivs / 2;
        }

        //Transfer DRIP to the contract
        require(
            earthToken.customTransferFrom(
                _addr,
                address(earthVaultAddress),
                _amount
            ),
            "DRIP token transfer failed"
        );

        /*
        User deposits 10;
        1 goes for tax, 9 are realized deposit
        */

        _deposit(_addr, _total_amount);

        _refPayout(_addr, realizedDeposit + taxedDivs, ref_bonus);

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;

    }

    //@dev Claim, transfer, withdraw from vault
    function claim() external {

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        address _addr = msg.sender;

        _claim_out(_addr);
    }

    //@dev Claim and deposit;
    function roll() public {

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        address _addr = msg.sender;

        _roll(_addr);
    }

    /********** Internal Fuctions **************************************************/

    //@dev Add direct referral and update team structure of upline
    function _setUpline(address _addr, address _upline) internal {
        /*
        1) User must not have existing up-line
        2) Up-line argument must not be equal to senders own address
        3) Senders address must not be equal to the owner
        4) Up-lined user must have a existing deposit
        */
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner() && (users[_upline].deposit_time > 0 || _upline == owner() )) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_depth; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    //@dev Deposit
    function _deposit(address _addr, uint256 _amount) internal {
        //Can't maintain upline referrals without this being set

        require(users[_addr].upline != address(0) || _addr == owner(), "No upline");

        //stats
        users[_addr].deposits += _amount;
        users[_addr].deposit_time = block.timestamp;

        total_deposited += _amount;

        //events
        emit NewDeposit(_addr, _amount);

    }

    //Payout upline; Bonuses are from 5 - 30% on the 0.5% paid out daily; Referrals only help
    function _refPayout(address _addr, uint256 _amount, uint256 _refBonus) internal {
        //for deposit _addr is the sender/depositor

        address _up = users[_addr].upline;
        uint256 _bonus = _amount * _refBonus / 100; // 10% of amount
        uint256 _share = _bonus / 4;                // 2.5% of amount
        uint256 _up_share = _bonus.sub(_share);     // 7.5% of amount
        bool _team_found = false;

        for(uint8 i = 0; i < ref_depth; i++) {

            // If we have reached the top of the chain, the owner
            if(_up == address(0)){
                //The equivalent of looping through all available
                users[_addr].ref_claim_pos = ref_depth;
                break;
            }

            //We only match if the claim position is valid
            if(users[_addr].ref_claim_pos == i) {
                if (isBalanceCovered(_up, i + 1) && isNetPositive(_up)){

                    //Team wallets are split 75/25%
                    if(users[_up].referrals >= 5 && !_team_found) {

                        //This should only be called once
                        _team_found = true;

                        (uint256 gross_payout_upline,,,) = payoutOf(_up);
                        users[_up].accumulatedDiv = gross_payout_upline;
                        users[_up].deposits += _up_share;
                        users[_up].deposit_time = block.timestamp;

                        (uint256 gross_payout_addr,,,) = payoutOf(_addr);
                        users[_addr].accumulatedDiv = gross_payout_addr;
                        users[_addr].deposits += _share;
                        users[_addr].deposit_time = block.timestamp;

                        //match accounting
                        users[_up].match_bonus += _up_share;

                        //Synthetic Airdrop tracking; team wallets get automatic airdrop benefits
                        airdrops[_up].airdrops += _share;
                        airdrops[_up].last_airdrop = block.timestamp;
                        airdrops[_addr].airdrops_received += _share;

                        //Global airdrops
                        total_airdrops += _share;

                        //Events
                        emit NewDeposit(_addr, _share);
                        emit NewDeposit(_up, _up_share);

                        emit NewAirdrop(_up, _addr, _share, block.timestamp);
                        emit MatchPayout(_up, _addr, _up_share);
                    } else {

                        (uint256 gross_payout,,,) = payoutOf(_up);
                        users[_up].accumulatedDiv = gross_payout;
                        users[_up].deposits += _bonus;
                        users[_up].deposit_time = block.timestamp;


                        //match accounting
                        users[_up].match_bonus += _bonus;

                        //events
                        emit NewDeposit(_up, _bonus);
                        emit MatchPayout(_up, _addr, _bonus);
                    }

                    if (users[_up].upline == address(0)){
                        users[_addr].ref_claim_pos = ref_depth;
                    }

                    //The work has been done for the position; just break
                    break;
                }

                users[_addr].ref_claim_pos += 1;

            }

            _up = users[_up].upline;

        }

        //Reward the next
        users[_addr].ref_claim_pos += 1;

        //Reset if we've hit the end of the line
        if (users[_addr].ref_claim_pos >= ref_depth){
            users[_addr].ref_claim_pos = 0;
        }
    }

    //@dev General purpose heartbeat in the system used for custody/management planning
    function _heart(address _addr) internal {
        custody[_addr].last_heartbeat = block.timestamp;
        emit HeartBeat(_addr, custody[_addr].last_heartbeat);
    }

    //@dev Claim and deposit;
    function _roll(address _addr) internal {

        uint256 to_payout = _claim(_addr, false);

        uint256 payout_taxed = to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding

        //Recycle baby!
        _deposit(_addr, payout_taxed);

        //track rolls for net positive
        users[_addr].rolls += payout_taxed;

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;

    }


    //@dev Claim, transfer, and topoff
    function _claim_out(address _addr) internal {

        uint256 to_payout = _claim(_addr, true);

        uint256 vaultBalance = earthToken.balanceOf(earthVaultAddress);
        if (vaultBalance < to_payout) {
            uint256 differenceToMint = to_payout.sub(vaultBalance);
            tokenMint.mint(earthVaultAddress, differenceToMint);
        }

        earthVault.withdraw(to_payout);

        uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(100); // 10% tax on withdraw
        require(earthToken.transfer(address(msg.sender), realizedPayout));

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;

    }

    //@dev Claim current payouts
    function _claim(address _addr, bool isClaimedOut) internal returns (uint256) {
        (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
        require(users[_addr].payouts < _max_payout, "Full payouts");

        // Deposit payout
        if(_to_payout > 0) {

            // payout remaining allowable divs if exceeds
            if(users[_addr].payouts + _to_payout > _max_payout) {
                _to_payout = _max_payout.safeSub(users[_addr].payouts);
            }

            users[_addr].payouts += _gross_payout;

            if (!isClaimedOut){
                //Payout referrals
                uint256 compoundTaxedPayout = _to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
                _refPayout(_addr, compoundTaxedPayout, 5);
            }
        }

        require(_to_payout > 0, "Zero payout");

        //Update the payouts
        total_withdraw += _to_payout;

        //Update time!
        users[_addr].deposit_time = block.timestamp;
        users[_addr].accumulatedDiv = 0;

        emit Withdraw(_addr, _to_payout);

        if(users[_addr].payouts >= _max_payout) {
            emit LimitReached(_addr, users[_addr].payouts);
        }

        return _to_payout;
    }

    /********* Views ***************************************/

    //@dev Returns true if the address is net positive
    function isNetPositive(address _addr) public view returns (bool) {

        (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);

        return _credits > _debits;

    }

    //@dev Returns the total credits and debits for a given address
    function creditsAndDebits(address _addr) public view returns (uint256 _credits, uint256 _debits) {
        User memory _user = users[_addr];
        Airdrop memory _airdrop = airdrops[_addr];

        _credits = _airdrop.airdrops + _user.rolls + _user.deposits;
        _debits = _user.payouts;

    }

    //@dev Returns whether BR34P balance matches level
    function isBalanceCovered(address _addr, uint8 _level) public view returns (bool) {
        if (users[_addr].upline == address(0)){
            return true;
        }
        return balanceLevel(_addr) >= _level;
    }

    //@dev Returns the level of the address
    function balanceLevel(address _addr) public view returns (uint8) {
        uint8 _level = 0;
        for (uint8 i = 0; i < ref_depth; i++) {
            if (storm.balanceOf(_addr) < ref_balances[i]) break;
            _level += 1;
        }

        return _level;
    }

    //@dev Returns custody info of _addr
    function getCustody(address _addr) public view returns (address _beneficiary, uint256 _heartbeat_interval, address _manager) {
        return (custody[_addr].beneficiary, custody[_addr].heartbeat_interval, custody[_addr].manager);
    }

    //@dev Returns account activity timestamps
    function lastActivity(address _addr) public view returns (uint256 _heartbeat, uint256 _lapsed_heartbeat, uint256 _checkin, uint256 _lapsed_checkin) {
        _heartbeat = custody[_addr].last_heartbeat;
        _lapsed_heartbeat = block.timestamp.safeSub(_heartbeat);
        _checkin = custody[_addr].last_checkin;
        _lapsed_checkin = block.timestamp.safeSub(_checkin);
    }

    //@dev Returns amount of claims available for sender
    function claimsAvailable(address _addr) public view returns (uint256) {
        (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
        return _to_payout;
    }

    //@dev Maxpayout of 3.65 of deposit
    function maxPayoutOf(uint256 _amount) public pure returns(uint256) {
        return _amount * 365 / 100;
    }

    function sustainabilityFeeV2(address _addr, uint256 _pendingDiv) public view returns (uint256) {
        uint256 _bracket = users[_addr].payouts.add(_pendingDiv).div(deposit_bracket_size);
        _bracket = SafeMath.min(_bracket, deposit_bracket_max);
        return _bracket * 5;
    }

    //@dev Calculate the current payout and maxpayout of a given address
    function payoutOf(address _addr) public view returns(uint256 payout, uint256 max_payout, uint256 net_payout, uint256 sustainability_fee) {
        //The max_payout is capped so that we can also cap available rewards daily
        max_payout = maxPayoutOf(users[_addr].deposits).min(max_payout_cap);

        uint256 share;

        if(users[_addr].payouts < max_payout) {
            uint256 calcValue =ABDKMath64x64.mulu ((payoutRate) * 1e18, users[_addr].deposits);
            //Using 1e18 we capture all significant digits when calculating available divs
            share = calcValue.div(100e18).div(2 minutes); //divide the profit by payout rate and seconds in the day

            payout = share * block.timestamp.safeSub(users[_addr].deposit_time);

            payout += users[_addr].accumulatedDiv;

            // payout remaining allowable divs if exceeds
            if(users[_addr].payouts + payout > max_payout) {
                payout = max_payout.safeSub(users[_addr].payouts);
            }

            uint256 _fee = sustainabilityFeeV2(_addr, payout);

            sustainability_fee = payout * _fee / 100;

            net_payout = payout.safeSub(sustainability_fee);

        }
    }

    //@dev Get current user snapshot
    function userInfo(address _addr) external view returns(address upline, uint256 deposit_time, uint256 deposits, uint256 payouts, uint256 direct_bonus, uint256 match_bonus, uint256 last_airdrop) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposits, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus, airdrops[_addr].last_airdrop);
    }

    //@dev Get user totals
    function userInfoTotals(address _addr) external view returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 airdrops_total, uint256 airdrops_received) {
        return (users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
    }

    //@dev Get contract snapshot
    function contractInfo() external view returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_bnb, uint256 _total_txs, uint256 _total_airdrops) {
        return (total_users, total_deposited, total_withdraw, total_bnb, total_txs, total_airdrops);
    }

    /////// Airdrops ///////

    //@dev Send specified DRIP amount supplying an upline referral
    function airdrop(address _to, uint256 _amount) external {

        address _addr = msg.sender;

        (uint256 _realizedAmount, uint256 taxAmount) = earthToken.calculateTransferTaxes(_addr, _amount);
        //This can only fail if the balance is insufficient
        require(
            earthToken.transferFrom(
                _addr,
                address(earthVaultAddress),
                _amount
            ),
            "DRIP to contract transfer failed; check balance and allowance, airdrop"
        );

        //Make sure _to exists in the system; we increase
        require(users[_to].upline != address(0), "_to not found");

        (uint256 gross_payout,,,) = payoutOf(_to);

        users[_to].accumulatedDiv = gross_payout;

        //Fund to deposits (not a transfer)
        users[_to].deposits += _realizedAmount;
        users[_to].deposit_time = block.timestamp;

        //User stats
        airdrops[_addr].airdrops += _realizedAmount;
        airdrops[_addr].last_airdrop = block.timestamp;
        airdrops[_to].airdrops_received += _realizedAmount;

        //Keep track of overall stats
        total_airdrops += _realizedAmount;
        total_txs += 1;


        //Let em know!
        emit NewAirdrop(_addr, _to, _realizedAmount, block.timestamp);
        emit NewDeposit(_to, _realizedAmount);
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
   */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
   */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
     * @dev Adds two numbers, throws on overflow.
   */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}