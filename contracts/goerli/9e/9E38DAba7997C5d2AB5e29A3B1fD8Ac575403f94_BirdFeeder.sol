/**
 * 
 * 

 * 
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


pragma solidity ^0.4.26;

import "./ReleasableToken.sol";
import "./MintableToken.sol";


/**
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract BirdFeeder is ReleasableToken, MintableToken {

  /** Name and symbol were updated. */
  event UpdatedTokenInformation(string newName, string newSymbol);
  event DonationReceived(address donatee, uint256 amount);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  

  string public name;

  string public symbol;

  uint public decimals;

  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   * @param _name Token name
   * @param _symbol Token symbol - should be all caps
   * @param _initialSupply How many tokens we start with
   * @param _decimals Number of decimal places
   * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
   * @param _birdguardMasterWallet Wallet tokens will be minted to and ownership of token must be set to this wallet
   */
  constructor(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, address _birdguardMasterWallet) public{

    // Create any address, can be transferred
    // to team multisig via changeOwner(),
    // also remember to call setUpgradeMaster()
    owner = msg.sender;
    
    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;
    
    decimals = _decimals;

    // Create initially all balance on the team multisig
    balances[_birdguardMasterWallet] = totalSupply;
    emit Minted(_birdguardMasterWallet, totalSupply);
    emit Transfer(address(this), _birdguardMasterWallet, totalSupply);
    



    // No more new supply allowed after the token creation
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        revert(); // Cannot create a token without supply and no minting
      }
    }
  }

  /**
   * When token is released to be transferable, enforce no new tokens can be created.
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

  
  function donate() public payable {
    if(msg.value>0){
      emit DonationReceived(msg.sender, msg.value);
    }
    
  }
  /**
   * Owner can update token information here.
   *
   * It is often useful to conceal the actual token association, until
   * the token operations, like central issuance or reissuance have been completed.
   *
   * This function allows the token owner to rename the token after the operations
   * have been completed and then point the audience to use the token contract.
   */
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;

    emit UpdatedTokenInformation(name, symbol);
  }

}